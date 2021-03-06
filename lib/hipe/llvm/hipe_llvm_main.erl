%% -*- erlang-indent-level: 2 -*-
-module(hipe_llvm_main).

-export([rtl_to_native/4]).

-include("../../kernel/src/hipe_ext_format.hrl").
-include("hipe_llvm_arch.hrl").
-include("elf_format.hrl").

%% @doc Translation of RTL to a loadable object. This functions takes the RTL
%%      code and calls hipe_rtl2llvm:translate/2 to translate the RTL code to
%%      LLVM code. After this, LLVM asm is printed to a file and the LLVM tool
%%      chain is invoked in order to produce an object file.
rtl_to_native(MFA, RTL, Roots, Options) ->
  %% Compile to LLVM and get Instruction List (along with infos)
  {LLVMCode, RelocsDict, ConstTab} =
    hipe_rtl2llvm:translate(RTL, Roots),
  %% Fix function name to an acceptable LLVM identifier (needed for closures)
  {_Module, Fun, Arity} = hipe_rtl2llvm:fix_mfa_name(MFA),
  %% Write LLVM Assembly to intermediate file (on disk)
  {ok, Dir, ObjectFile} = compile_with_llvm(Fun, Arity, LLVMCode, Options, false),
  %%
  %% Extract information from object file
  %%
  ObjBin = open_object_file(ObjectFile),
  %% Read and set the ELF class
  elf_format:set_architecture_flag(ObjBin),
  %% Get labels info (for switches and jump tables)
  Labels = get_rodata_relocs(ObjBin),
  {Switches, Closures} = get_tables(ObjBin),
  %% Associate Labels with Switches and Closures with stack args
  {SwitchInfos, ExposedClosures} =
    correlate_labels(Switches++Closures, Labels),
    %% SwitchInfos:     [{"table_50", [Labels]}]
    %% ExposedClosures: [{"table_closures", [Labels]}]

  %% Labelmap contains the offsets of the labels in the code that are
  %% used for switch's jump tables
  LabelMap = create_labelmap(MFA, SwitchInfos, RelocsDict),
  %% Get relocation info
  TextRelocs = get_text_relocs(ObjBin),
  %% AccRefs contains the offsets of all references to relocatable symbols in
  %% the code:
  AccRefs  = fix_relocations(TextRelocs, RelocsDict, MFA),
  %% Get stack descriptors
  SDescs   = get_sdescs(ObjBin),

  %% FixedSDescs are the stack descriptors after correcting calls that have
  %% arguments in the stack
  FixedSDescs = fix_stack_descriptors(RelocsDict, AccRefs, SDescs, ExposedClosures),
  Refs = AccRefs++FixedSDescs,

  %% Get binary code from object file
  BinCode = elf_format:extract_text(ObjBin),

  %% Remove temp files (if needed)
  %----Modified for crossing compilation for ARM enviroment------------------- 
  % remove_temp_folder(Dir, Options),
  %% Return the code together with information that will be used in the
  %% hipe_llvm_merge module to produce the final binary that will be loaded
  %% by the hipe unified loader.
  {MFA, BinCode, byte_size(BinCode), ConstTab, Refs, LabelMap}.

%%------------------------------------------------------------------------------
%% LLVM tool chain
%%------------------------------------------------------------------------------

%% @doc Compile function FunName/Arity to LLVM. Return Dir (in order to remove
%%      it if we do not want to store temporary files) and ObjectFile name that
%%      is created by the LLVM tools.
compile_with_llvm(FunName, Arity, LLVMCode, Options, UseBuffer) ->
  Filename = atom_to_list(FunName) ++ "_" ++ integer_to_list(Arity),
  %% Save temp files in a unique folder
  Dir = unique_folder(FunName, Arity, Options),
  ok = file:make_dir(Dir),
  %% Print LLVM assembly to file
  OpenOpts = [append, raw] ++
    case UseBuffer of
      %% true  -> [delayed_write]; % Use delayed_write!
      false -> []
    end,
  {ok, File_llvm} = file:open(Dir ++ Filename ++ ".ll", OpenOpts),
  hipe_llvm:pp_ins_list(File_llvm, LLVMCode),
  %% delayed write can cause file:close not to do a close
  file:close(File_llvm),
  file:close(File_llvm),
  %% Invoke LLVM compiler tools to produce an object file
  ObjectFile = invoke_llvm_tools(Dir, Filename, Options),
  {ok, Dir, ObjectFile}.

%% @doc Invoke LLVM tools to compile function Fun_Name/Arity and create an
%%      Object File.
invoke_llvm_tools(Dir, Fun_Name, Options) ->
  llvm_as(Dir, Fun_Name),
  llvm_opt(Dir, Fun_Name, Options),
  llvm_llc(Dir, Fun_Name, Options),
  %----Modified for crossing compilation for ARM enviroment-------------------
  New_Fun_Name = fix_return_address(Dir, Fun_Name),
  compile(Dir, New_Fun_Name, "arm-elf-as").

%% @doc Invoke llvm-as tool to convert LLVM Asesmbly to bitcode.
llvm_as(Dir, Fun_Name) ->
  Source  = Dir ++ Fun_Name ++ ".ll",
  Dest    = Dir ++ Fun_Name ++ ".bc",
  Command = "llvm-as " ++ Source ++ " -o " ++ Dest,
  case os:cmd(Command) of
    "" -> ok;
    Error -> exit({?MODULE, opt, Error})
  end.

%% @doc Invoke opt tool to optimize the bitcode.
llvm_opt(Dir, Fun_Name, Options) ->
  Source   = Dir ++ Fun_Name ++ ".bc",
  Dest     = Source,
  OptLevel = trans_optlev_flag(opt, Options),
  OptFlags = [OptLevel, "-mem2reg", "-strip"],
  Command  = "opt " ++ fix_opts(OptFlags) ++ " " ++ Source ++ " -o " ++ Dest,
  %% io:format("OPT: ~s~n", [Command]),
  case os:cmd(Command) of
    "" -> ok;
    Error -> exit({?MODULE, opt, Error})
  end.

%% @doc Invoke llc tool to compile the bitcode to native assembly.
llvm_llc(Dir, Fun_Name, Options) ->
  Source   = Dir ++ Fun_Name ++ ".bc",
  OptLevel = trans_optlev_flag(llc, Options),
  Align    = find_stack_alignment(),
  LlcFlagsTemp = [OptLevel, "-hipe-prologue", "-load=ErlangGC.so",
                  "-code-model=medium", "-stack-alignment=" ++ Align,
                  "-tailcallopt"], %, "-enable-block-placement"],
  LlcFlags = case proplists:get_bool(llvm_bplace, Options) of
               true -> ["-enable-block-placement" | LlcFlagsTemp];
               false -> LlcFlagsTemp
             end,
  %----Modified for crossing compilation for ARM enviroment-------------------
  Command  = "llc " ++ fix_opts(LlcFlags) ++ " -march=arm " ++ Source,,
  io:format("--------------LLC: ~s~n", [Command]),
  case os:cmd(Command) of
    "" -> ok;
    Error -> exit({?MODULE, opt, Error})
  end.

%------------------ We need to push and store return address------------------------
% str lr, [r11, #-4] when enter a function
% ldr lr, [r11, #-4] when exit a function

fix_return_address(Dir, Fun_Name) ->
  New_Fun_Name = Fun_Name ++ "_1",
  Source_Read   = Dir ++ Fun_Name ++ ".s",
  Source_Write  = Dir ++ New_Fun_Name ++ ".s",	
  
  {ok, Device_Read} = file:open(Source_Read, [read]),
  {ok, Device_Write} = file:open(Source_Write, [append]),

  get_all_lines(Device_Read, Device_Write),
	
  New_Fun_Name.  	

get_all_lines(Device_Read, Device_Write) ->
 case io:get_line(Device_Read, "") of
        eof  -> file:close(Device_Read), 
		file:close(Device_Write);
        Line ->
		Strip_Line = string:strip(Line),
		io:format("|~w", [Strip_Line]), 		
		io:fwrite(Strip_Line),	
		io:format("~w|", ["\tmov\tpc, lr\n"]),		
		case Strip_Line of
			"@ BB#0:\n" -> file:write(Device_Write, Line),
				     file:write(Device_Write, "\tstr\tr14, [r10, #-4]!\n");
			"\tmov\tpc, lr\n" -> file:write(Device_Write, "\tldr\tr14, [r10], #4\n"),
				     	file:write(Device_Write, Line);
			"\tmoveq\tpc, lr\n" -> file:write(Device_Write, "\tldreq\tr14, [r10], #4\n"),
				     	file:write(Device_Write, Line);
			"\tldr\tr7, [r11, #120]\n" -> file:write(Device_Write, "\tldr\tr7, [r11, #128]\n");
			"\tstr\tr7, [r11, #120]\n" -> file:write(Device_Write, "\tstr\tr7, [r11, #128]\n"); 
			_ -> 	file:write(Device_Write, Line)
		end,

		get_all_lines(Device_Read, Device_Write)
 end.


%% @doc Invoke the compiler tool ("gcc", "llvmc", etc.) to generate an object
%%      file from native assembly.
compile(Dir, Fun_Name, Compiler) ->
  Source  = Dir ++ Fun_Name ++ ".s",
  Dest    = Dir ++ Fun_Name ++ ".o",
  Command = Compiler ++ " " ++ Source ++ " -o " ++ Dest,
  io:format("--------------Command: ~s~n", [Command]),
  case os:cmd(Command) of
    "" -> ok;
    Error -> exit({?MODULE, llvmc, Error})
  end,
  Dest.

find_stack_alignment() ->
  case get(hipe_target_arch) of
    x86 -> "8";
    amd64 -> "8";
    arm -> "8";
    _ -> exit({?MODULE, find_stack_alignment, "Unimplemented architecture"})
  end.

%% Join options
fix_opts(Opts) ->
  string:join(Opts, " ").

%% Translate optimization-level flag (default is "none")
trans_optlev_flag(Tool, Options) ->
  Flag =
    case Tool of
      opt -> llvm_opt;
      llc -> llvm_llc
    end,
  case proplists:get_value(Flag, Options) of
    o0 -> ""; % "-O0" does not exist in opt tool
    o1 -> "-O1";
    o2 -> "-O2";
    o3 -> "-O3";
    undefined -> "-O2"
  end.

%%------------------------------------------------------------------------------
%% Functions to manage Relocations
%%------------------------------------------------------------------------------

%% @doc This function gets as argument an ELF binary file and returns a list
%%      with all .rela.rodata labels (i.e. constants and literals in code)
%%      or an empty list if no ".rela.rodata" section exists in code.
get_rodata_relocs(Elf) ->
  case elf_format:is64bit() of
    true ->
      %% Only care about the addends (== offsets):
      [elf_format:get_rela_entry_field(RelaE, r_addend)
       || RelaE <- elf_format:extract_rela(Elf, ?RODATA)];
    false ->
      %% Find offsets hardcoded in ".rodata" entry
      %%XXX: Treat all 0s as padding and skip them!
      [SkipPadding || SkipPadding <- elf_format:extract_rodata(Elf),
                      SkipPadding =/= 0]
  end.

%% @doc Get switch table and closure table.
get_tables(Elf) ->
  %% Search Symbol Table for an entry with name prefixed with "table_":
  SymtabTemp = [{elf_format:get_symtab_entry_field(SymtabE, st_name),
                 elf_format:get_symtab_entry_field(SymtabE, st_value),
                 elf_format:get_symtab_entry_field(SymtabE, st_size) div ?ELF_XWORD_SIZE}
                || SymtabE <- elf_format:extract_symtab(Elf)],
  SymtabTemp2 = [T || T={Name, _, _} <- SymtabTemp, Name =/= 0],
  {NameIndices, ValueOffs, Sizes} = lists:unzip3(SymtabTemp2),
  %% Find the names of the symbols.
  %% Get string table entries ([{Name, Offset in strtab section}]). Keep only
  %% relevant entries:
  Strtab = elf_format:extract_strtab(Elf),
  Relevant = [elf_format:get_strtab_entry(Strtab, Off) || Off <- NameIndices],
  %% Zip back to {Name, ValueOff, Size}:
  Triples = lists:zip3(Relevant, ValueOffs, Sizes),
  Switches = [T || T={"table_"++_, _, _} <- Triples],
  Closures = [T || T={"table_closures"++_, _, _} <- Switches],
  {Switches, Closures}.

%% @doc This functions associates symbols who point to some table of labels with
%%      the corresponding offsets of the labels in the code. These tables can
%%      either be jump tables for switches or a table which contains the labels
%%      of blocks that contain closure calls with more than ?NR_ARG_REGS.
correlate_labels([], _L) -> {[], []};
correlate_labels(Tables, Labels) ->
  %% Sort "Tables" based on "ValueOffsets"
  OffsetSortedTb = lists:ukeysort(2, Tables),
  %% Unzip offset-sorted list of "Switches"
  {Names, _Offsets, TablesSizeList} = lists:unzip3(OffsetSortedTb),
  %% Associate switch names with labels
  L = split_list(Labels, TablesSizeList),
  %% Zip back! (to [{SwitchName, Values}])
  NamesValues = lists:zip(Names, L),
  case lists:keytake("table_closures", 1, NamesValues) of
    false ->  %% No closures in the code, no closure table
      {NamesValues, []};
    {value, ClosureTableNV, SwitchesNV} ->
      {SwitchesNV, ClosureTableNV}
  end.

%% @doc Create a gb_tree which contains information about the labels that used
%%      for switch's jump tables. The keys of the gb_tree are of the form
%%      {MFA, Label} and the values are the actual Offsets.
create_labelmap(MFA, SwitchInfos, RelocsDict) ->
  create_labelmap(MFA, SwitchInfos, RelocsDict, gb_trees:empty()).

create_labelmap(_, [], _, LabelMap) -> LabelMap;
create_labelmap(MFA, [{Name, Offsets} | Rest], RelocsDict, LabelMap) ->
  case dict:fetch(Name, RelocsDict) of
    {switch, {_TableType, LabelList, _NrLabels, _SortOrder}, _JTabLab} ->
      KVDict = lists:ukeysort(1, lists:zip(LabelList, Offsets)),
      NewLabelMap = insert_to_labelmap(KVDict, LabelMap),
      create_labelmap(MFA, Rest, RelocsDict, NewLabelMap);
    _ ->
      exit({?MODULE, create_labelmap, "Not a jump table!~n"})
  end.

%% Insert a list of [{Key,Value}] to a LabelMap (gb_tree)
insert_to_labelmap([], LabelMap) -> LabelMap;
insert_to_labelmap([{Key, Value}|Rest], LabelMap) ->
  case gb_trees:lookup(Key, LabelMap) of
    none ->
      insert_to_labelmap(Rest, gb_trees:insert(Key, Value, LabelMap));
    {value, Value} -> %% Exists with the *exact* same Value.
      insert_to_labelmap(Rest, LabelMap)
  end.

%% @doc Extract a list of the form `[{SymbolName, Offset}]' with all relocatable
%%      symbols and their offsets in the code from the ".text" section.
-spec get_text_relocs(binary()) -> [{string(), integer()}].
get_text_relocs(Elf) ->
  %% Only care about the symbol table index and the offset:
  NameOffsetTemp = [{?ELF_R_SYM(elf_format:get_rela_entry_field(RelaE, r_info)),
                     elf_format:get_rela_entry_field(RelaE, r_offset)}
                    || RelaE <- elf_format:extract_rela(Elf, ?TEXT)],
  {NameIndices, ActualOffsets} = lists:unzip(NameOffsetTemp),
  %% Find the names of the symbols:
  %%
  %% Get those symbol table entries that are related to Text relocs:
  Symtab    = elf_format:extract_symtab(Elf),
  SymtabEs  = [ lists:nth(Index+1, Symtab) || Index <- NameIndices ],
                                                %XXX: not zero-indexed!
  %% Symbol table entries contain the offset of the name of the symbol in
  %% String Table:
  SymtabEs2 = [elf_format:get_symtab_entry_field(SymE, st_name)
               || SymE <- SymtabEs], %XXX: Do we need to sort SymtabE?
  %% Get string table entries ([{Name, Offset in strtab section}]). Keep only
  %% relevant entries:
  Strtab = elf_format:extract_strtab(Elf),
  Relevant = [elf_format:get_strtab_entry(Strtab, Off) || Off <- SymtabEs2],
  %% Zip back with actual offsets:
  lists:zip(Relevant, ActualOffsets).

%% @doc Correlate object file relocation symbols with info from translation to
%%      llvm code.
fix_relocations(Relocs, RelocsDict, MFA) ->
  fix_relocs(Relocs, RelocsDict, MFA, []).

fix_relocs([], _, _, RelocAcc) -> RelocAcc;
fix_relocs([{Name, Offset}|Rs], RelocsDict, {ModName,_,_}=MFA,  RelocAcc) ->
  case dict:fetch(Name, RelocsDict) of
    {atom, AtomName} ->
      fix_relocs(Rs, RelocsDict, MFA,
                 [{?LOAD_ATOM, Offset, AtomName}|RelocAcc]);
    {constant, Label} ->
      fix_relocs(Rs, RelocsDict, MFA,
                [{?LOAD_ADDRESS, Offset, {constant, Label}}|RelocAcc]);
    {switch, _, JTabLab} -> %% Treat switch exactly as constant
      fix_relocs(Rs, RelocsDict, MFA,
                 [{?LOAD_ADDRESS, Offset, {constant, JTabLab}}|RelocAcc]);
    {closure, _}=Closure ->
      fix_relocs(Rs, RelocsDict, MFA,
                 [{?LOAD_ADDRESS, Offset, Closure}|RelocAcc]);
    {call, {bif, BifName, _}} ->
      fix_relocs(Rs, RelocsDict, MFA,
                 [{?CALL_LOCAL, Offset, BifName}|RelocAcc]);
    %% MFA calls to functions in the same module are of type 3, while all
    %% other MFA calls are of type 2.
    {call, {ModName,_F,_A}=CallMFA} ->
      fix_relocs(Rs, RelocsDict, MFA,
                 [{?CALL_LOCAL, Offset, CallMFA}|RelocAcc]);
    {call, CallMFA} ->
      fix_relocs(Rs, RelocsDict, MFA,
                 [{?CALL_REMOTE, Offset, CallMFA}|RelocAcc]);
    Other ->
      exit({?MODULE, fix_relocs, {"Relocation Not In Relocation Dictionary",
                  Other}})
  end.

%%------------------------------------------------------------------------------
%% Functions to manage Stack Descriptors
%%------------------------------------------------------------------------------

%% @doc This function takes an ELF Object File binary and returns a proper sdesc
%%      list for Erlang/OTP System's loader. The return value should be of the
%%      form:
%%        {
%%          4, Safepoint Address,
%%          {ExnLabel OR [], FrameSize, StackArity, {Liveroot stack frame indexes}},
%%        }
get_sdescs(Elf) ->
  case elf_format:extract_note(Elf, ?NOTE_ERLGC_NAME) of
    <<>> -> % Object file has no ".note.gc" section!
      [];
    NoteGC_bin ->
      %% Get safe point addresses (stored in ".rela.note.gc" section):
      RelaNoteGC = elf_format:extract_rela(Elf, ?NOTE(?NOTE_ERLGC_NAME)),
      SPCount = length(RelaNoteGC),
      T = SPCount * ?SP_ADDR_SIZE,
      %% Pattern-match fields of ".note.gc":
      <<_SPCount:(?bits(?SP_COUNT_SIZE))/integer-little, % Skip count
        SPAddrs:T/binary, %NOTE: In 64bit they 're relocs!
        StkFrameSize:(?bits(?SP_STKFRAME_SIZE))/integer-little,
        StkArity:(?bits(?SP_STKARITY_SIZE))/integer-little,
        _LiveRootCount:(?bits(?SP_LIVEROOTCNT_SIZE))/integer-little,
                                                % Skip rootcnt
        Roots/binary>> = NoteGC_bin,
      LiveRoots = get_liveroots(Roots, []),
      %% Extract information about the safe point addresses:
      SPOffs =
        case elf_format:is64bit() of
          true -> %% Find offsets in ".rela.note.gc":
            [elf_format:get_rela_entry_field(RelaE, r_addend)
             || RelaE <- RelaNoteGC];
          false -> %% Find offsets in SPAddrs (in ".note.gc"):
            get_spoffs(SPAddrs, [])
        end,
      %% Extract Exception Handler labels:
      ExnHandlers =
        case elf_format:extract_gccexntab(Elf) of
          [] -> [];
          GccExntab ->
            CallSites   = elf_format:get_gccexntab_field(GccExntab, ge_cstab),
            %% A list with `{Start, End, HandlerOffset}' for all Call Sites in the code
            [{elf_datatypes:gccexntab_callsite_field(CallSite, gee_start),
              elf_datatypes:gccexntab_callsite_field(CallSite, gee_size)
              + elf_datatypes:gccexntab_callsite_field(CallSite, gee_start),
              elf_datatypes:gccexntab_callsite_field(CallSite, gee_lp)}
             || CallSite <- CallSites]
        end,
      %% Combine ExnLbls and Safe point addresses (return addresses) properly:
      ExnAndSPOffs = combine_ras_and_exns(ExnHandlers, SPOffs, []),
      create_sdesc_list(ExnAndSPOffs, StkFrameSize, StkArity, LiveRoots, [])
  end.

%% @doc Extracts a bunch of integers (live roots) from a binary. Returns a tuple
%%      as need for stack descriptors.
get_liveroots(<<>>, Acc) ->
  list_to_tuple(Acc);
get_liveroots(<<Root:?bits(?LR_STKINDEX_SIZE)/integer-little,
                MoreRoots/binary>>, Acc) ->
  get_liveroots(MoreRoots, [Root | Acc]).

%% @doc Extracts a bunch of integers (safepoint offsets) from a binary. Returns
%%      a tuple as need for stack descriptors.
get_spoffs(<<>>, Acc) ->
  lists:reverse(Acc);
get_spoffs(SPOffs, Acc) ->
  <<SPOff:?bits(?ELF_ADDR_SIZE)/integer-little,
    More/binary>> = SPOffs,
  get_spoffs(More, [SPOff | Acc]).

create_sdesc_list([], _, _, _, Acc) ->
  lists:reverse(Acc);
create_sdesc_list([{ExnLbl, SPOff} | MoreExnAndSPOffs],
                 StkFrameSize, StkArity, LiveRoots, Acc) ->
  Hdlr = case ExnLbl of
           0 -> [];
           N -> N
         end,
  create_sdesc_list(MoreExnAndSPOffs, StkFrameSize, StkArity, LiveRoots,
                    [{?SDESC, SPOff, {Hdlr, StkFrameSize, StkArity, LiveRoots}}
                     | Acc]).

combine_ras_and_exns(_, [], Acc) ->
  lists:reverse(Acc);
combine_ras_and_exns(ExnHandlers, [RA | MoreRAs], Acc) ->
  %% FIXME: do something better than O(n^2) by taking advantage of the property
  %% ||ExnHandlers|| <= ||RAs||
  Handler = find_exn_handler(RA, ExnHandlers),
  combine_ras_and_exns(ExnHandlers, MoreRAs, [{Handler, RA} | Acc]).

find_exn_handler(_, []) ->
  [];
find_exn_handler(RA, [{Start, End, Handler} | MoreExnHandlers]) ->
  case (RA >= Start andalso RA =< End) of
    true ->
      Handler;
    false ->
      find_exn_handler(RA, MoreExnHandlers)
  end.

%% @doc This function is responsible for correcting the stack descriptors of
%%      the calls that are found in the code and have more than NR_ARG_REGS
%%      (thus, some of their arguments are passed to the stack). Because of the
%%      Reserved Call Frame feature that the LLVM uses, the stack descriptors
%%      are not correct since at the point of call the frame size is reduced
%%      proportionally to the number of arguments that are passed on the stack.
%%      Also the offsets of the roots need to be re-adjusted.
fix_stack_descriptors(_, _, [], _) ->
  [];
fix_stack_descriptors(RelocsDict, Relocs, SDescs, ExposedClosures) ->
  %% NamedCalls are MFA and BIF calls that need fix
  NamedCalls       = calls_with_stack_args(RelocsDict),
  NamedCallsOffs   = calls_offsets_arity(Relocs, NamedCalls),
  ExposedClosures1 =
    case dict:is_key("table_closures", RelocsDict) of
      true -> %% A Table with closures exists
        {table_closures, ArityList} = dict:fetch("table_closures", RelocsDict),
            case ExposedClosures of
              {_,  Offsets} -> lists:zip(Offsets, ArityList);
              _ -> exit({?MODULE, fix_stack_descriptors,
                        {"Wrong exposed closures", ExposedClosures}})
            end;
      false -> []
    end,
  ClosuresOffs = closures_offsets_arity(ExposedClosures1, SDescs),
  fix_sdescs(NamedCallsOffs++ClosuresOffs, SDescs).

%% @doc This function takes as argument the relocation dictionary as produced by
%%      the translation of RTL code to LLVM and finds the names of the calls
%%      (MFA and BIF calls) that have more than NR_ARG_REGS.
calls_with_stack_args(Dict) ->
  calls_with_stack_args(dict:to_list(Dict), []).

calls_with_stack_args([], Calls) -> Calls;
calls_with_stack_args([ {_Name, {call, {M, F, A}}} | Rest], Calls)
                      when A > ?NR_ARG_REGS ->
  Call =
    case M of
      bif -> {F,A};
      _ -> {M,F,A}
    end,
  calls_with_stack_args(Rest, [Call|Calls]);
calls_with_stack_args([_|Rest], Calls) ->
  calls_with_stack_args(Rest, Calls).

%% @doc This functions extracts the stack arity and the offset in the code of
%%      the named calls (MFAs, BIFs) that have stack arguments.
calls_offsets_arity(AccRefs, CallsWithStackArgs) ->
  calls_offsets_arity(AccRefs, CallsWithStackArgs, []).

calls_offsets_arity([], _, Acc) -> Acc;
calls_offsets_arity([{Type, Offset, Term} | Rest], CallsWithStackArgs, Acc)
                    when Type == ?CALL_REMOTE orelse Type == ?CALL_LOCAL ->
  case lists:member(Term, CallsWithStackArgs) of
    true ->
      Arity =
        case Term of
          {_M, _F, A} -> A;
          {_F, A} -> A
        end,
      calls_offsets_arity(Rest, CallsWithStackArgs,
                          [{Offset + 4, Arity - ?NR_ARG_REGS}|Acc]);
    false ->
      calls_offsets_arity(Rest, CallsWithStackArgs, Acc)
  end;
calls_offsets_arity([_|Rest], CallsWithStackArgs, Acc) ->
  calls_offsets_arity(Rest, CallsWithStackArgs, Acc).

%% @doc This functions extracts the stack arity and the offsets of closures that
%%      have stack arity. The Closures argument represents the
%%      hipe_bifs:llvm_exposure_closure/0 calls in the code. The actual closure
%%      is the next call in the code, so the offset of the next call must be
%%      from calculated from the stack descriptors.
closures_offsets_arity([], _) ->
  [];
closures_offsets_arity(ExposedClosures, SDescs) ->
  Offsets = [ Offset || {_, Offset, _} <- SDescs ],
  SortedOffsets = lists:sort(Offsets), %% Offsets must be sorted in order
                                       %% find_offsets/3 fun to work
  SortedExposedClosures = lists:keysort(1, ExposedClosures), %% Same for
                                                             %% closures
  find_offsets(SortedExposedClosures, SortedOffsets, []).

find_offsets([], _, Acc) -> Acc;
find_offsets([{Off,Arity}|Rest], Offsets, Acc) ->
  [I | RestOffsets] = lists:dropwhile(fun (Y) -> Y<Off end, Offsets),
  find_offsets(Rest, RestOffsets, [{I, Arity}|Acc]).

%% The functions below correct the arity of calls, that are identified by offset,
%% in the stack descriptors.
fix_sdescs([], SDescs) -> SDescs;
fix_sdescs([{Offset, Arity} | Rest], SDescs) ->
  case lists:keyfind(Offset, 2, SDescs) of
    false ->
      fix_sdescs(Rest, SDescs);
    {?SDESC, Offset, SDesc}->
      {ExnHandler, FrameSize, StkArity, Roots} = SDesc,
      DecRoot = fun(X) -> X-Arity end,
      NewRootsList = lists:map(DecRoot, tuple_to_list(Roots)),
      NewSDesc =
        case length(NewRootsList) > 0 andalso hd(NewRootsList) >= 0 of
          true ->
            {?SDESC, Offset, {ExnHandler, FrameSize-Arity, StkArity,
			      list_to_tuple(NewRootsList)}};
          false ->
            {?SDESC, Offset, {ExnHandler, FrameSize, StkArity, Roots}}
        end,
      RestSDescs = lists:keydelete(Offset, 2, SDescs),
      fix_sdescs(Rest, [NewSDesc | RestSDescs])
  end.


%%------------------------------------------------------------------------------
%% Miscellaneous functions
%%------------------------------------------------------------------------------

%% @doc A function that opens a file as binary. The function takes as argument
%%      the name of the file and returns an Erlang binary.
-spec open_object_file( string() ) -> binary().
open_object_file(ObjFile) ->
  case file:read_file(ObjFile) of
    {ok, Binary} ->
      Binary;
    {error, Reason} ->
      exit({?MODULE, open_file, Reason})
  end.

remove_temp_folder(Dir, Options) ->
  case proplists:get_bool(llvm_save_temps, Options) of
    true -> ok;
    false -> spawn(fun () -> "" = os:cmd("rm -rf " ++ Dir) end), ok
  end.

unique_id(FunName, Arity) ->
  integer_to_list(erlang:phash2({FunName, Arity, now()})).

unique_folder(FunName, Arity, Options) ->
  DirName = "llvm_" ++ unique_id(FunName, Arity) ++ "/",
  Dir =
    case proplists:get_bool(llvm_save_temps, Options) of
      true ->  %% Store folder in current directory
        DirName;
      false -> %% Temporarily store folder in tempfs (/dev/shm/)" (rm afterwards)
        "/dev/shm/" ++ DirName
    end,
  %% Make sure it does not exist
  case dir_exists(Dir) of
    true -> %% Dir already exists! Generate again.
      unique_folder(FunName, Arity, Options);
    false ->
      Dir
  end.

%% @doc Function that checks that a given Filename is an existing Directory
%%      Name (from http://rosettacode.org/wiki/Ensure_that_a_file_exists#Erlang)
dir_exists(Filename) ->
  {Flag, Info} = file:read_file_info(Filename),
  (Flag == ok) andalso (element(3, Info) == directory).

%% @doc Function that takes as arguments a list of integers and a list with
%%      numbers indicating how many items should each tuple have and splits
%%      the original list to a list of lists of integers (with the specified
%%      number of elements), e.g. [ [...], [...] ].
-spec split_list([integer()], [integer()]) -> [ [integer()] ].
split_list(List, ElemsPerTuple) ->
  split_list(List, ElemsPerTuple, []).

-spec split_list([integer()], [integer()], [ [integer()] ]) -> [ [integer()] ].
split_list([], [], Acc) ->
  lists:reverse(Acc);
split_list(List, [NumOfElems | MoreNums], Acc) ->
  {L1, L2} = lists:split(NumOfElems, List),
  split_list(L2, MoreNums, [ L1 | Acc]).
