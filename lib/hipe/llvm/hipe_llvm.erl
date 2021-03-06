%% -*- erlang-indent-level: 2 -*-
-module(hipe_llvm).

-export([
    mk_ret/1,
    ret_ret_list/1,

    mk_br/1,
    br_dst/1,

    mk_br_cond/3,
    mk_br_cond/4,
    br_cond_cond/1,
    br_cond_true_label/1,
    br_cond_false_label/1,
    br_cond_meta/1,

    mk_indirectbr/3,
    indirectbr_type/1,
    indirectbr_address/1,
    indirectbr_label_list/1,

    mk_switch/4,
    switch_type/1,
    switch_value/1,
    switch_default_label/1,
    switch_value_label_list/1,

    mk_invoke/9,
    invoke_dst/1,
    invoke_cconv/1,
    invoke_ret_attrs/1,
    invoke_type/1,
    invoke_fnptrval/1,
    invoke_arglist/1,
    invoke_fn_attrs/1,
    invoke_to_label/1,
    invoke_unwind_label/1,

    mk_operation/6,
    operation_dst/1,
    operation_op/1,
    operation_type/1,
    operation_src1/1,
    operation_src2/1,
    operation_options/1,

    mk_extractvalue/5,
    extractvalue_dst/1,
    extractvalue_type/1,
    extractvalue_val/1,
    extractvalue_idx/1,
    extractvalue_idxs/1,

    mk_insertvalue/7,
    insertvalue_dst/1,
    insertvalue_val_type/1,
    insertvalue_val/1,
    insertvalue_elem_type/1,
    insertvalue_elem/1,
    insertvalue_idx/1,
    insertvalue_idxs/1,

    mk_alloca/4,
    alloca_dst/1,
    alloca_type/1,
    alloca_num/1,
    alloca_align/1,

    mk_load/6,
    load_dst/1,
    load_p_type/1,
    load_pointer/1,
    load_alignment/1,
    load_nontemporal/1,
    load_volatile/1,

    mk_store/7,
    store_type/1,
    store_value/1,
    store_p_type/1,
    store_pointer/1,
    store_alignment/1,
    store_nontemporal/1,
    store_volatile/1,

    mk_getelementptr/5,
    getelementptr_dst/1,
    getelementptr_p_type/1,
    getelementptr_value/1,
    getelementptr_typed_idxs/1,
    getelementptr_inbounds/1,

    mk_conversion/5,
    conversion_dst/1,
    conversion_op/1,
    conversion_src_type/1,
    conversion_src/1,
    conversion_dst_type/1,

    mk_sitofp/4,
    sitofp_dst/1,
    sitofp_src_type/1,
    sitofp_src/1,
    sitofp_dst_type/1,

    mk_ptrtoint/4,
    ptrtoint_dst/1,
    ptrtoint_src_type/1,
    ptrtoint_src/1,
    ptrtoint_dst_type/1,

    mk_inttoptr/4,
    inttoptr_dst/1,
    inttoptr_src_type/1,
    inttoptr_src/1,
    inttoptr_dst_type/1,

    mk_icmp/5,
    icmp_dst/1,
    icmp_cond/1,
    icmp_type/1,
    icmp_src1/1,
    icmp_src2/1,

    mk_fcmp/5,
    fcmp_dst/1,
    fcmp_cond/1,
    fcmp_type/1,
    fcmp_src1/1,
    fcmp_src2/1,

    mk_phi/3,
    phi_dst/1,
    phi_type/1,
    phi_value_label_list/1,

    mk_select/6,
    select_dst/1,
    select_cond/1,
    select_typ1/1,
    select_val1/1,
    select_typ2/1,
    select_val2/1,

    mk_call/8,
    call_dst/1,
    call_is_tail/1,
    call_cconv/1,
    call_ret_attrs/1,
    call_type/1,
    call_fnptrval/1,
    call_arglist/1,
    call_fn_attrs/1,

    mk_fun_def/10,
    fun_def_linkage/1,
    fun_def_visibility/1,
    fun_def_cconv/1,
    fun_def_ret_attrs/1,
    fun_def_type/1,
    fun_def_name/1,
    fun_def_arglist/1,
    fun_def_fn_attrs/1,
    fun_def_align/1,
    fun_def_body/1,

    mk_fun_decl/8,
    fun_decl_linkage/1,
    fun_decl_visibility/1,
    fun_decl_cconv/1,
    fun_decl_ret_attrs/1,
    fun_decl_type/1,
    fun_decl_name/1,
    fun_decl_arglist/1,
    fun_decl_align/1,

    mk_comment/1,
    comment_text/1,

    mk_label/1,
    label_label/1,

    mk_const_decl/4,
    const_decl_dst/1,
    const_decl_decl_type/1,
    const_decl_type/1,
    const_decl_value/1,

    mk_asm/1,
    asm_instruction/1,

    mk_adj_stack/3,
    adj_stack_offset/1,
    adj_stack_register/1,
    adj_stack_type/1,

    mk_branch_meta/3,
    branch_meta_id/1,
    branch_meta_true_weight/1,
    branch_meta_false_weight/1

  ]).


%% Types
-export([
    mk_int/1,
    int_width/1,

    mk_pointer/1,
    pointer_type/1,

    mk_array/2,
    array_size/1,
    array_type/1,

    mk_vector/2,
    vector_size/1,
    vector_type/1,

    mk_struct/1,
    struct_type_list/1,

    mk_fun/2,
    function_ret_type/1,
    function_arg_type_list/1
  ]).

-export([pp_ins_list/2, pp_ins/2]).


%%-----------------------------------------------------------------------------

-include("hipe_llvm.hrl").

%%-----------------------------------------------------------------------------


%%
%% ret
%%
mk_ret(Ret_list) -> #llvm_ret{ret_list=Ret_list}.
ret_ret_list(#llvm_ret{ret_list=Ret_list}) -> Ret_list.

%%
%% br
%%
mk_br(Dst) -> #llvm_br{dst=Dst}.
br_dst(#llvm_br{dst=Dst}) -> Dst.


%%
%% br_cond
%%
mk_br_cond(Cond, True_label, False_label) ->
  #llvm_br_cond{'cond'=Cond, true_label=True_label, false_label=False_label}.
mk_br_cond(Cond, True_label, False_label,Metadata) ->
  #llvm_br_cond{'cond'=Cond, true_label=True_label, false_label=False_label,
    meta=Metadata}.
br_cond_cond(#llvm_br_cond{'cond'=Cond}) -> Cond.
br_cond_true_label(#llvm_br_cond{true_label=True_label}) -> True_label.
br_cond_false_label(#llvm_br_cond{false_label=False_label}) ->
  False_label.
br_cond_meta(#llvm_br_cond{meta=Metadata}) -> Metadata.

%%
%% indirectbr
%%
mk_indirectbr(Type, Address, Label_list) -> #llvm_indirectbr{type=Type, address=Address, label_list=Label_list}.
indirectbr_type(#llvm_indirectbr{type=Type}) -> Type.
indirectbr_address(#llvm_indirectbr{address=Address}) -> Address.
indirectbr_label_list(#llvm_indirectbr{label_list=Label_list}) -> Label_list.

%%
%% invoke
%%
mk_invoke(Dst, Cconv, Ret_attrs, Type, Fnptrval, Arglist, Fn_attrs, To_label, Unwind_label) ->
  #llvm_invoke{dst=Dst, cconv=Cconv, ret_attrs=Ret_attrs, type=Type,
    fnptrval=Fnptrval, arglist=Arglist, fn_attrs=Fn_attrs, to_label=To_label,
              unwind_label=Unwind_label}.
invoke_dst(#llvm_invoke{dst=Dst}) -> Dst.
invoke_cconv(#llvm_invoke{cconv=Cconv}) -> Cconv.
invoke_ret_attrs(#llvm_invoke{ret_attrs=Ret_attrs}) -> Ret_attrs.
invoke_type(#llvm_invoke{type=Type}) -> Type.
invoke_fnptrval(#llvm_invoke{fnptrval=Fnptrval}) -> Fnptrval.
invoke_arglist(#llvm_invoke{arglist=Arglist}) -> Arglist.
invoke_fn_attrs(#llvm_invoke{fn_attrs=Fn_attrs}) -> Fn_attrs.
invoke_to_label(#llvm_invoke{to_label=To_label}) -> To_label.
invoke_unwind_label(#llvm_invoke{unwind_label=Unwind_label}) -> Unwind_label.

%%
%% switch
%%
mk_switch(Type, Value, Default_label, Value_label_list) ->
  #llvm_switch{type=Type, value=Value, default_label=Default_label,
              value_label_list=Value_label_list}.
switch_type(#llvm_switch{type=Type}) -> Type.
switch_value(#llvm_switch{value=Value}) -> Value.
switch_default_label(#llvm_switch{default_label=Default_label}) ->
  Default_label.
switch_value_label_list(#llvm_switch{value_label_list=Value_label_list}) ->
  Value_label_list.

%%
%% operation
%%
mk_operation(Dst, Op, Type, Src1, Src2, Options) ->
  #llvm_operation{dst=Dst, op=Op, type=Type, src1=Src1, src2=Src2,
    options=Options}.
operation_dst(#llvm_operation{dst=Dst}) -> Dst.
operation_op(#llvm_operation{op=Op}) -> Op.
operation_type(#llvm_operation{type=Type}) -> Type.
operation_src1(#llvm_operation{src1=Src1}) -> Src1.
operation_src2(#llvm_operation{src2=Src2}) -> Src2.
operation_options(#llvm_operation{options=Options}) -> Options.

%%
%% extractvalue
%%
mk_extractvalue(Dst, Type, Val, Idx, Idxs) ->
  #llvm_extractvalue{dst=Dst,type=Type,val=Val,idx=Idx,idxs=Idxs}.
extractvalue_dst(#llvm_extractvalue{dst=Dst}) -> Dst.
extractvalue_type(#llvm_extractvalue{type=Type}) -> Type.
extractvalue_val(#llvm_extractvalue{val=Val}) -> Val.
extractvalue_idx(#llvm_extractvalue{idx=Idx}) -> Idx.
extractvalue_idxs(#llvm_extractvalue{idxs=Idxs}) -> Idxs.

%%
%% insertvalue
%%
mk_insertvalue(Dst, Val_type, Val, Elem_type, Elem, Idx, Idxs) ->
  #llvm_insertvalue{dst=Dst, val_type=Val_type, val=Val, elem_type=Elem_type,
                    elem=Elem, idx=Idx, idxs=Idxs}.
insertvalue_dst(#llvm_insertvalue{dst=Dst}) -> Dst.
insertvalue_val_type(#llvm_insertvalue{val_type=Val_type}) -> Val_type.
insertvalue_val(#llvm_insertvalue{val=Val}) -> Val.
insertvalue_elem_type(#llvm_insertvalue{elem_type=Elem_type}) -> Elem_type.
insertvalue_elem(#llvm_insertvalue{elem=Elem}) -> Elem.
insertvalue_idx(#llvm_insertvalue{idx=Idx}) -> Idx.
insertvalue_idxs(#llvm_insertvalue{idxs=Idxs}) -> Idxs.

%%
%% alloca
%%
mk_alloca(Dst, Type, Num, Align) ->
  #llvm_alloca{dst=Dst, type=Type, num=Num, align=Align}.
alloca_dst(#llvm_alloca{dst=Dst}) -> Dst.
alloca_type(#llvm_alloca{type=Type}) -> Type.
alloca_num(#llvm_alloca{num=Num}) -> Num.
alloca_align(#llvm_alloca{align=Align}) -> Align.

%%
%% load
%%
mk_load(Dst, Type, Pointer, Alignment, Nontemporal, Volatile) ->
  #llvm_load{dst=Dst, p_type=Type, pointer=Pointer, alignment=Alignment,
    nontemporal=Nontemporal, volatile=Volatile}.
load_dst(#llvm_load{dst=Dst}) -> Dst.
load_p_type(#llvm_load{p_type=Type}) -> Type.
load_pointer(#llvm_load{pointer=Pointer}) -> Pointer.
load_alignment(#llvm_load{alignment=Alignment}) -> Alignment.
load_nontemporal(#llvm_load{nontemporal=Nontemporal}) -> Nontemporal.
load_volatile(#llvm_load{volatile=Volatile}) -> Volatile.

%%
%% store
%%
mk_store(Type, Value, P_Type, Pointer, Alignment, Nontemporal, Volatile) ->
  #llvm_store{type=Type, value=Value, p_type=P_Type, pointer=Pointer, alignment=Alignment,
    nontemporal=Nontemporal, volatile=Volatile}.
store_type(#llvm_store{type=Type}) -> Type.
store_value(#llvm_store{value=Value}) -> Value.
store_p_type(#llvm_store{p_type=P_Type}) -> P_Type.
store_pointer(#llvm_store{pointer=Pointer}) -> Pointer.
store_alignment(#llvm_store{alignment=Alignment}) -> Alignment.
store_nontemporal(#llvm_store{nontemporal=Nontemporal}) -> Nontemporal.
store_volatile(#llvm_store{volatile=Volatile}) -> Volatile.

%%
%% getelementptr
%%
mk_getelementptr(Dst, P_Type, Value, Typed_Idxs, Inbounds) ->
  #llvm_getelementptr{dst=Dst,p_type=P_Type, value=Value,
                      typed_idxs=Typed_Idxs, inbounds=Inbounds}.
getelementptr_dst(#llvm_getelementptr{dst=Dst}) -> Dst.
getelementptr_p_type(#llvm_getelementptr{p_type=P_Type}) -> P_Type.
getelementptr_value(#llvm_getelementptr{value=Value}) -> Value.
getelementptr_typed_idxs(#llvm_getelementptr{typed_idxs=Typed_Idxs}) -> Typed_Idxs.
getelementptr_inbounds(#llvm_getelementptr{inbounds=Inbounds}) -> Inbounds.

%%
%% conversion
%%
mk_conversion(Dst, Op, Src_type, Src, Dst_type) ->
  #llvm_conversion{dst=Dst, op=Op, src_type=Src_type, src=Src, dst_type=Dst_type}.
conversion_dst(#llvm_conversion{dst=Dst}) -> Dst.
conversion_op(#llvm_conversion{op=Op}) -> Op.
conversion_src_type(#llvm_conversion{src_type=Src_type}) -> Src_type.
conversion_src(#llvm_conversion{src=Src}) -> Src.
conversion_dst_type(#llvm_conversion{dst_type=Dst_type}) -> Dst_type.

%%
%% sitofp
%%
mk_sitofp(Dst, Src_type, Src, Dst_type) ->
  #llvm_sitofp{dst=Dst, src_type=Src_type, src=Src, dst_type=Dst_type}.
sitofp_dst(#llvm_sitofp{dst=Dst}) -> Dst.
sitofp_src_type(#llvm_sitofp{src_type=Src_type}) -> Src_type.
sitofp_src(#llvm_sitofp{src=Src}) -> Src.
sitofp_dst_type(#llvm_sitofp{dst_type=Dst_type}) -> Dst_type.

%%
%% ptrtoint
%%
mk_ptrtoint(Dst, Src_Type, Src, Dst_Type) ->
  #llvm_ptrtoint{dst=Dst, src_type=Src_Type, src=Src, dst_type=Dst_Type}.
ptrtoint_dst(#llvm_ptrtoint{dst=Dst}) -> Dst.
ptrtoint_src_type(#llvm_ptrtoint{src_type=Src_Type}) -> Src_Type.
ptrtoint_src(#llvm_ptrtoint{src=Src}) -> Src.
ptrtoint_dst_type(#llvm_ptrtoint{dst_type=Dst_Type}) -> Dst_Type .

%%
%% inttoptr
%%
mk_inttoptr(Dst, Src_Type, Src, Dst_Type) ->
  #llvm_inttoptr{dst=Dst, src_type=Src_Type, src=Src, dst_type=Dst_Type}.
inttoptr_dst(#llvm_inttoptr{dst=Dst}) -> Dst.
inttoptr_src_type(#llvm_inttoptr{src_type=Src_Type}) -> Src_Type.
inttoptr_src(#llvm_inttoptr{src=Src}) -> Src.
inttoptr_dst_type(#llvm_inttoptr{dst_type=Dst_Type}) -> Dst_Type .

%%
%% icmp
%%
mk_icmp(Dst, Cond, Type, Src1, Src2) ->
  #llvm_icmp{dst=Dst,'cond'=Cond,type=Type,src1=Src1,src2=Src2}.
icmp_dst(#llvm_icmp{dst=Dst}) -> Dst.
icmp_cond(#llvm_icmp{'cond'=Cond}) -> Cond.
icmp_type(#llvm_icmp{type=Type}) -> Type.
icmp_src1(#llvm_icmp{src1=Src1}) -> Src1.
icmp_src2(#llvm_icmp{src2=Src2}) -> Src2.

%%
%% fcmp
%%
mk_fcmp(Dst, Cond, Type, Src1, Src2) ->
  #llvm_fcmp{dst=Dst,'cond'=Cond,type=Type,src1=Src1,src2=Src2}.
fcmp_dst(#llvm_fcmp{dst=Dst}) -> Dst.
fcmp_cond(#llvm_fcmp{'cond'=Cond}) -> Cond.
fcmp_type(#llvm_fcmp{type=Type}) -> Type.
fcmp_src1(#llvm_fcmp{src1=Src1}) -> Src1.
fcmp_src2(#llvm_fcmp{src2=Src2}) -> Src2.

%%
%% phi
%%
mk_phi(Dst, Type, Value_label_list) ->
  #llvm_phi{dst=Dst, type=Type,value_label_list=Value_label_list}.
phi_dst(#llvm_phi{dst=Dst}) -> Dst.
phi_type(#llvm_phi{type=Type}) -> Type.
phi_value_label_list(#llvm_phi{value_label_list=Value_label_list}) ->
  Value_label_list.

%%
%% select
%%
mk_select(Dst, Cond, Typ1, Val1, Typ2, Val2) ->
  #llvm_select{dst=Dst, 'cond'=Cond, typ1=Typ1, val1=Val1, typ2=Typ2, val2=Val2}.
select_dst(#llvm_select{dst=Dst}) -> Dst.
select_cond(#llvm_select{'cond'=Cond}) -> Cond.
select_typ1(#llvm_select{typ1=Typ1}) -> Typ1.
select_val1(#llvm_select{val1=Val1}) -> Val1.
select_typ2(#llvm_select{typ2=Typ2}) -> Typ2.
select_val2(#llvm_select{val2=Val2}) -> Val2.

%%
%% call
%%
mk_call(Dst, Is_tail, Cconv, Ret_attrs, Type, Fnptrval, Arglist, Fn_attrs) ->
  #llvm_call{dst=Dst, is_tail=Is_tail, cconv=Cconv, ret_attrs=Ret_attrs,
    type=Type, fnptrval=Fnptrval, arglist=Arglist, fn_attrs=Fn_attrs}.
call_dst(#llvm_call{dst=Dst}) -> Dst.
call_is_tail(#llvm_call{is_tail=Is_tail}) -> Is_tail.
call_cconv(#llvm_call{cconv=Cconv}) -> Cconv.
call_ret_attrs(#llvm_call{ret_attrs=Ret_attrs}) -> Ret_attrs.
call_type(#llvm_call{type=Type}) -> Type.
call_fnptrval(#llvm_call{fnptrval=Fnptrval}) -> Fnptrval.
call_arglist(#llvm_call{arglist=Arglist}) -> Arglist.
call_fn_attrs(#llvm_call{fn_attrs=Fn_attrs}) -> Fn_attrs.

%%
%% fun_def
%%
mk_fun_def(Linkage, Visibility, Cconv, Ret_attrs, Type, Name, Arglist,
           Fn_attrs, Align, Body) ->
  #llvm_fun_def{
    linkage=Linkage,
    visibility=Visibility,
    cconv=Cconv,
    ret_attrs=Ret_attrs,
    type=Type,
    'name'=Name,
    arglist=Arglist,
    fn_attrs=Fn_attrs,
    align=Align,
    body=Body
  }.

fun_def_linkage(#llvm_fun_def{linkage=Linkage}) -> Linkage.
fun_def_visibility(#llvm_fun_def{visibility=Visibility}) -> Visibility.
fun_def_cconv(#llvm_fun_def{cconv=Cconv}) -> Cconv .
fun_def_ret_attrs(#llvm_fun_def{ret_attrs=Ret_attrs}) -> Ret_attrs.
fun_def_type(#llvm_fun_def{type=Type}) -> Type.
fun_def_name(#llvm_fun_def{'name'=Name}) -> Name.
fun_def_arglist(#llvm_fun_def{arglist=Arglist}) -> Arglist.
fun_def_fn_attrs(#llvm_fun_def{fn_attrs=Fn_attrs}) -> Fn_attrs.
fun_def_align(#llvm_fun_def{align=Align}) -> Align.
fun_def_body(#llvm_fun_def{body=Body}) -> Body.

%%
%% fun_decl
%%
mk_fun_decl(Linkage, Visibility, Cconv, Ret_attrs, Type, Name, Arglist, Align)->
  #llvm_fun_decl{
    linkage=Linkage,
    visibility=Visibility,
    cconv=Cconv,
    ret_attrs=Ret_attrs,
    type=Type,
    'name'=Name,
    arglist=Arglist,
    align=Align
  }.

fun_decl_linkage(#llvm_fun_decl{linkage=Linkage}) -> Linkage.
fun_decl_visibility(#llvm_fun_decl{visibility=Visibility}) -> Visibility.
fun_decl_cconv(#llvm_fun_decl{cconv=Cconv}) -> Cconv .
fun_decl_ret_attrs(#llvm_fun_decl{ret_attrs=Ret_attrs}) -> Ret_attrs.
fun_decl_type(#llvm_fun_decl{type=Type}) -> Type.
fun_decl_name(#llvm_fun_decl{'name'=Name}) -> Name.
fun_decl_arglist(#llvm_fun_decl{arglist=Arglist}) -> Arglist.
fun_decl_align(#llvm_fun_decl{align=Align}) -> Align.

%%
%% comment
%%
mk_comment(Text) -> #llvm_comment{text=Text}.
comment_text(#llvm_comment{text=Text}) -> Text.

%%
%% label
%%
mk_label(Label) -> #llvm_label{label=Label}.
label_label(#llvm_label{label=Label}) -> Label.

%%
%% constant declaration
%%
mk_const_decl(Dst, Decl_type, Type, Value) ->
  #llvm_const_decl{dst=Dst, decl_type=Decl_type, type=Type, value=Value}.
const_decl_dst(#llvm_const_decl{dst=Dst}) -> Dst.
const_decl_decl_type(#llvm_const_decl{decl_type=Decl_type}) -> Decl_type.
const_decl_type(#llvm_const_decl{type=Type}) -> Type.
const_decl_value(#llvm_const_decl{value=Value}) -> Value.

mk_asm(Instruction) -> #llvm_asm{instruction=Instruction}.
asm_instruction(#llvm_asm{instruction=Instruction}) -> Instruction.

mk_adj_stack(Offset, Register, Type) ->
  #llvm_adj_stack{offset=Offset, 'register'=Register, type=Type}.
adj_stack_offset(#llvm_adj_stack{offset=Offset}) -> Offset.
adj_stack_register(#llvm_adj_stack{'register'=Register}) -> Register.
adj_stack_type(#llvm_adj_stack{type=Type}) -> Type.

%%
%% Branch Metadata
%%
mk_branch_meta(Id, True_weight, False_weight) ->
  #llvm_branch_meta{id=Id, true_weight=True_weight, false_weight=False_weight}.
branch_meta_id(#llvm_branch_meta{id=Id}) -> Id.
branch_meta_true_weight(#llvm_branch_meta{true_weight=True_weight}) -> True_weight.
branch_meta_false_weight(#llvm_branch_meta{false_weight=False_weight}) -> False_weight.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% Types
%%

mk_int(Width) -> #llvm_int{width=Width}.
int_width(#llvm_int{width=Width}) -> Width.

mk_pointer(Type) -> #llvm_pointer{type=Type}.
pointer_type(#llvm_pointer{type=Type}) -> Type.

mk_array(Size, Type) -> #llvm_array{'size'=Size, type=Type}.
array_size(#llvm_array{'size'=Size}) -> Size.
array_type(#llvm_array{type=Type}) -> Type.

mk_vector(Size, Type) -> #llvm_vector{'size'=Size, type=Type}.
vector_size(#llvm_vector{'size'=Size}) -> Size.
vector_type(#llvm_vector{type=Type}) -> Type.

mk_struct(Type_list) -> #llvm_struct{type_list=Type_list}.
struct_type_list(#llvm_struct{type_list=Type_list}) -> Type_list.

mk_fun(Ret_type, Arg_type_list) ->
  #llvm_fun{ret_type=Ret_type, arg_type_list=Arg_type_list}.
function_ret_type(#llvm_fun{ret_type=Ret_type}) -> Ret_type.
function_arg_type_list(#llvm_fun{arg_type_list=Arg_type_list}) ->
  Arg_type_list.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% @doc Pretty-print a list of LLVM instructions to a Device.
pp_ins_list(_Dev, []) -> ok;
pp_ins_list(Dev, [I|Is]) ->
  pp_ins(Dev, I),
  pp_ins_list(Dev, Is).

pp_ins(Dev, I) ->
  case indent(I) of
    true  -> write(Dev, "  ");
    false -> ok
  end,
  case I of
    #llvm_ret{} ->
      write(Dev, "ret "),
      case ret_ret_list(I) of
        [] -> write(Dev, "void");
        List -> pp_args(Dev, List)
      end,
      write(Dev, "\n");
    #llvm_br{} ->
      write(Dev, ["br label ", br_dst(I), "\n"]);
    #llvm_switch{} ->
      write(Dev, "switch "),
      pp_type(Dev, switch_type(I)),
      write(Dev, [" ", switch_value(I), ", label ", switch_default_label(I),
                  " \n   [\n"]),
      pp_switch_value_label_list(Dev, switch_type(I),
                                 switch_value_label_list(I)),
      write(Dev, "    ]\n");
    #llvm_invoke{} ->
      write(Dev, [invoke_dst(I), " = invoke ", invoke_cconv(I), " "]),
      pp_options(Dev, invoke_ret_attrs(I)),
      pp_type(Dev, invoke_type(I)),
      write(Dev, [" ", invoke_fnptrval(I), "("]),
      pp_args(Dev, invoke_arglist(I)),
      write(Dev, ") "),
      pp_options(Dev, invoke_fn_attrs(I)),
      write(Dev, [" to label ", invoke_to_label(I)," unwind label ",
                  invoke_unwind_label(I), " \n"]);
    #llvm_br_cond{} ->
      write(Dev, ["br i1 ", br_cond_cond(I), ", label ", br_cond_true_label(I),
                  ", label ", br_cond_false_label(I)]),
      case br_cond_meta(I) of
        [] -> ok;
        Metadata ->
          write(Dev, [", !prof !", Metadata])
      end,
      write(Dev, "\n");
    #llvm_indirectbr{} ->
      write(Dev, "indirectbr "),
      pp_type(Dev, indirectbr_type(I)),
      write(Dev, [" ", indirectbr_address(I), ", [ "]),
      pp_args(Dev, indirectbr_label_list(I)),
      write(Dev, " ]\n");
    #llvm_operation{} ->
      write(Dev, [operation_dst(I), " = ", atom_to_list(operation_op(I)), " "]),
      case op_has_options(operation_op(I)) of
        true -> pp_options(Dev, operation_options(I));
        false -> ok
      end,
      pp_type(Dev, operation_type(I)),
      write(Dev, [" ", operation_src1(I), ", ", operation_src2(I), "\n"]);
    #llvm_extractvalue{} ->
      write(Dev, [extractvalue_dst(I), " = extractvalue "]),
      pp_type(Dev, extractvalue_type(I)),
      %% TODO Print idxs
      write(Dev, [" ", extractvalue_val(I), ", ", extractvalue_idx(I), "\n"]);
    #llvm_insertvalue{} ->
      write(Dev, [insertvalue_dst(I), " = insertvalue "]),
      pp_type(Dev, insertvalue_val_type(I)),
      write(Dev, [" ", insertvalue_val(I), ", "]),
      pp_type(Dev, insertvalue_elem_type(I)),
      %%TODO Print idxs
      write(Dev, [" ", insertvalue_elem(I), ", ", insertvalue_idx(I), "\n"]);
    #llvm_alloca{} ->
      write(Dev, [alloca_dst(I), " = alloca "]),
      pp_type(Dev, alloca_type(I)),
      case alloca_num(I) of
        [] -> ok;
        Num ->
          write(Dev, ", "),
          pp_type(Dev, alloca_type(I)),
          write(Dev, [" ", Num, " "])
      end,
      case alloca_align(I) of
        [] -> ok;
        Align -> write(Dev, [",align ", Align])
      end,
      write(Dev, "\n");
    #llvm_load{} ->
      write(Dev, [load_dst(I), " = "]),
      write(Dev, "load "),
      case load_volatile(I) of
        true -> write(Dev, "volatile ");
        false -> ok
      end,
      pp_type(Dev, load_p_type(I)),
      write(Dev, [" ", load_pointer(I), " "]),
      case load_alignment(I) of
        [] -> ok;
        Al -> write(Dev, [", align ", Al, " "])
      end,
      case load_nontemporal(I) of
        [] -> ok;
        In -> write(Dev, [", !nontemporal !", In])
      end,
      write(Dev, "\n");
    #llvm_store{} ->
      write(Dev, "store "),
      case store_volatile(I) of
        true -> write(Dev, "volatile ");
        false -> ok
      end,
      pp_type(Dev, store_type(I)),
      write(Dev, [" ", store_value(I), ", "]),
      pp_type(Dev, store_p_type(I)),
      write(Dev, [" ", store_pointer(I), " "]),
      case store_alignment(I) of
        [] -> ok;
        Al -> write(Dev, [", align ", Al, " "])
      end,
      case store_nontemporal(I) of
        [] -> ok;
        In -> write(Dev, [", !nontemporal !", In])
      end,
      write(Dev, "\n");
    #llvm_getelementptr{} ->
      write(Dev, [getelementptr_dst(I), " = getelementptr "]),
      case getelementptr_inbounds(I) of
        true -> write(Dev, "inbounds ");
        false -> ok
      end,
      pp_type(Dev, getelementptr_p_type(I)),
      write(Dev, [" ", getelementptr_value(I)]),
      pp_typed_idxs(Dev, getelementptr_typed_idxs(I)),
      write(Dev, "\n");
    #llvm_conversion{} ->
      write(Dev, [conversion_dst(I), " = ", atom_to_list(conversion_op(I)), " "]),
      pp_type(Dev, conversion_src_type(I)),
      write(Dev, [" ", conversion_src(I), " to "]),
      pp_type(Dev, conversion_dst_type(I)),
      write(Dev, "\n");
    #llvm_icmp{} ->
      write(Dev, [icmp_dst(I), " = icmp ", atom_to_list(icmp_cond(I)), " "]),
      pp_type(Dev, icmp_type(I)),
      write(Dev, [" ", icmp_src1(I), ", ", icmp_src2(I), "\n"]);
    #llvm_fcmp{} ->
      write(Dev, [fcmp_dst(I), " = fcmp ", atom_to_list(fcmp_cond(I)), " "]),
      pp_type(Dev, fcmp_type(I)),
      write(Dev, [" ", fcmp_src1(I), ", ", fcmp_src2(I), "\n"]);
    #llvm_phi{} ->
      write(Dev, [phi_dst(I), " = phi "]),
      pp_type(Dev, phi_type(I)),
      pp_phi_value_labels(Dev, phi_value_label_list(I)),
      write(Dev, "\n");
    #llvm_select{} ->
      write(Dev, [select_dst(I), " = select i1 ", select_cond(I), ", "]),
      pp_type(Dev, select_typ1(I)),
      write(Dev, [" ", select_val1(I), ", "]),
      pp_type(Dev, select_typ2(I)),
      write(Dev, [" ", select_val2(I), "\n"]);
    #llvm_call{} ->
      case call_dst(I) of
        [] -> ok;
        Dst -> write(Dev, [Dst, " = "])
      end,
      case call_is_tail(I) of
        true -> write(Dev, "tail ");
        false -> ok
      end,
      write(Dev, ["call ", call_cconv(I), " "]),
      pp_options(Dev, call_ret_attrs(I)),
      pp_type(Dev, call_type(I)),
      write(Dev, [" ", call_fnptrval(I), "("]),
      pp_args(Dev, call_arglist(I)),
      write(Dev, ") "),
      pp_options(Dev, call_fn_attrs(I)),
      write(Dev, "\n");
    #llvm_fun_def{} ->
      write(Dev, "define "),
      pp_options(Dev, fun_def_linkage(I)),
      pp_options(Dev, fun_def_visibility(I)),
      case fun_def_cconv(I) of
        [] -> ok;
        Cc -> write(Dev, [Cc, " "])
      end,
      pp_options(Dev, fun_def_ret_attrs(I)),
      write(Dev, " "),
      pp_type(Dev, fun_def_type(I)),
      write(Dev, [" @", fun_def_name(I), "("]),
      pp_args(Dev, fun_def_arglist(I)),
      write(Dev, ") "),
      pp_options(Dev, fun_def_fn_attrs(I)),
      case fun_def_align(I) of
        [] -> ok;
        N -> write(Dev, ["align ", N])
      end,
      write(Dev, "{\n"),
      pp_ins_list(Dev, fun_def_body(I)),
      write(Dev, "}\n");
    #llvm_fun_decl{} ->
      write(Dev, "declare "),
      pp_options(Dev, fun_decl_linkage(I)),
      pp_options(Dev, fun_decl_visibility(I)),
      case fun_decl_cconv(I) of
        [] -> ok;
        Cc -> write(Dev, [Cc, " "])
      end,
      pp_options(Dev, fun_decl_ret_attrs(I)),
      pp_type(Dev, fun_decl_type(I)),
      write(Dev, [" ", fun_decl_name(I), "("]),
      pp_type_list(Dev, fun_decl_arglist(I)),
      write(Dev, ") "),
      case fun_decl_align(I) of
        [] -> ok;
        N -> write(Dev, ["align ", N])
      end,
      write(Dev, "\n");
    #llvm_comment{} ->
      write(Dev, ["; ", atom_to_list(comment_text(I)), "\n"]);
    #llvm_label{} ->
      write(Dev, [label_label(I), ":\n"]);
    #llvm_const_decl{} ->
      write(Dev, [const_decl_dst(I), " = ", const_decl_decl_type(I), " "]),
      pp_type(Dev, const_decl_type(I)),
      write(Dev, [" ", const_decl_value(I), "\n"]);
    #llvm_landingpad{} ->
      write(Dev, "landingpad { i8*, i32 } personality i32 (i32, i64, i8*,i8*)*
            @__gcc_personality_v0 cleanup\n");
    #llvm_asm{} ->
      write(Dev, [asm_instruction(I), "\n"]);
    #llvm_adj_stack{} ->
      write(Dev, ["call void asm sideeffect \"sub $0, ",
          adj_stack_register(I), "\", \"r\"("]),
      pp_type(Dev, adj_stack_type(I)),
      write(Dev, [" ", adj_stack_offset(I),")\n"]);
    #llvm_branch_meta{} ->
      write(Dev, ["!", branch_meta_id(I), " = metadata !{metadata !\"branch_weights\",
          i32 ", branch_meta_true_weight(I), ", i32 ",
          branch_meta_false_weight(I), "}\n"]);
    Other -> exit({?MODULE, pp_ins, {"Unknown LLVM instruction", Other}})
  end.

%% @doc Pretty-print a list of types
pp_type_list(_Dev, []) -> ok;
pp_type_list(Dev, [T]) ->
  pp_type(Dev, T);
pp_type_list(Dev, [T|Ts]) ->
  pp_type(Dev, T),
  write(Dev, ", "),
  pp_type_list(Dev, Ts).

pp_type(Dev, Type) ->
  case Type of
    #llvm_void{} ->
      write(Dev, "void");
    #llvm_label_type{} ->
      write(Dev, "label");
    %% Integer
    #llvm_int{} ->
      write(Dev, ["i", integer_to_list(int_width(Type))]);
    %% Float
    #llvm_float{} ->
      write(Dev, "float");
    #llvm_double{} ->
      write(Dev, "double");
    #llvm_fp80{} ->
      write(Dev, "x86_fp80");
    #llvm_fp128{} ->
      write(Dev, "fp128");
    #llvm_ppc_fp128{} ->
      write(Dev, "ppc_fp128");
    %% Pointer
    #llvm_pointer{} ->
      pp_type(Dev, pointer_type(Type)),
      write(Dev, "*");
    %% Function
    #llvm_fun{} ->
      pp_type(Dev, function_ret_type(Type)),
      write(Dev, " ("),
      pp_type_list(Dev, function_arg_type_list(Type)),
      write(Dev, ")");
    %% Aggregate
    #llvm_array{} ->
      write(Dev, ["[", integer_to_list(array_size(Type)), " x "]),
      pp_type(Dev, array_type(Type)),
      write(Dev, "]");
    #llvm_struct{} ->
      write(Dev, "{"),
      pp_type_list(Dev, struct_type_list(Type)),
      write(Dev, "}");
    #llvm_vector{} ->
      write(Dev, ["{", integer_to_list(vector_size(Type)), " x "]),
      pp_type(Dev, vector_type(Type)),
      write(Dev, "}")
  end.

op_has_options(Op) ->
  case Op of
    'and' -> false;
    'or' -> false;
    'xor' -> false;
    _ -> true
  end.

%% @doc Pretty-print a list of typed arguments
pp_args(_Dev, []) -> ok;
pp_args(Dev, [{Type, Arg} | []]) ->
  pp_type(Dev, Type),
  write(Dev, [" ", Arg]);
pp_args(Dev, [{Type, Arg} | Args]) ->
  pp_type(Dev, Type),
  write(Dev, [" ", Arg, ", "]),
  pp_args(Dev, Args).

%% @doc Pretty-print a list of options
pp_options(_Dev, []) -> ok;
pp_options(Dev, [O|Os]) ->
  write(Dev, [atom_to_list(O), " "]),
  pp_options(Dev, Os).

%% @doc Pretty-print a list of phi value-labels
pp_phi_value_labels(_Dev, []) -> ok;
pp_phi_value_labels(Dev, [{Value, Label}|[]]) ->
  write(Dev, ["[ ", Value, ", ", Label, " ]"]);
pp_phi_value_labels(Dev,[{Value, Label}|VL]) ->
  write(Dev, ["[ ", Value, ", ", Label, " ], "]),
  pp_phi_value_labels(Dev, VL).

%% @doc Pretty-print a list of typed indexes
pp_typed_idxs(_Dev, []) -> ok;
pp_typed_idxs(Dev, [{Type, Id} | Tids]) ->
  write(Dev, ", "),
  pp_type(Dev, Type),
  write(Dev, [" ", Id]),
  pp_typed_idxs(Dev, Tids).

%% @doc Pretty-print a switch label list
pp_switch_value_label_list(_Dev, _Type,  []) -> ok;
pp_switch_value_label_list(Dev, Type, [{Value, Label} | VLs]) ->
  write(Dev, "      "),
  pp_type(Dev, Type),
  write(Dev, [" ", Value, ", label ", Label, "\n"]),
  pp_switch_value_label_list(Dev, Type, VLs).

%% @doc Returns if an instruction needs to be intended
indent(I) ->
  case I of
    #llvm_label{} -> false;
    #llvm_fun_def{} -> false;
    #llvm_fun_decl{} -> false;
    #llvm_const_decl{} -> false;
    #llvm_branch_meta{} -> false;
    _ -> true
  end.

%% @doc Abstracts actual writing to file operations
write(Dev, Msg) ->
  ok = file:write(Dev, Msg).
