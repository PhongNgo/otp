%% -*- erlang-indent-level: 2 -*-

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Provides abstract datatypes for LLVM Assembly.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%---------------------------------------------------------------------

%% Terminator Instructions
-record(llvm_ret, {type, value}).
-record(llvm_br, {dst}).
-record(llvm_br_cond, {'cond', true_label, false_label}).
%% Binary Operations
-record(llvm_add, {dst, type, src1, src2, options=[]}).
-record(llvm_fadd, {dst, type, src1, src2, options=[]}).
-record(llvm_sub, {dst, type, src1, src2, options=[]}).
-record(llvm_fsub, {dst, type, src1, src2, options=[]}).
-record(llvm_mul, {dst, type, src1, src2, options=[]}).
-record(llvm_fmul, {dst, type, src1, src2, options=[]}).
-record(llvm_udiv, {dst, type, src1, src2, options=[]}).
-record(llvm_sdiv, {dst, type, src1, src2, options=[]}).
-record(llvm_fdiv, {dst, type, src1, src2, options=[]}).
-record(llvm_urem, {dst, type, src1, src2, options=[]}).
-record(llvm_srem, {dst, type, src1, src2, options=[]}).
-record(llvm_frem, {dst, type, src1, src2, options=[]}).
%% Bitwise Binary Operations
-record(llvm_shl, {dst, type, src1, src2, options=[]}).
-record(llvm_lshr, {dst, type, src1, src2, options=[]}).
-record(llvm_ashr ,{dst, type, src1, src2, options=[]}).
-record(llvm_and,{dst, type, src1, src2}).
-record(llvm_or, {dst, type, src1, src2}).
-record(llvm_xor, {dst, type, src1, src2}).
%% Aggregate Operations
-record(llvm_extractvalue, {dst, type, val, idx, idxs=[]}).
%% Memory Access And Addressing Operations
-record(llvm_alloca, {dst, type, num = [], align = []}).
-record(llvm_load, {dst, type, pointer, alignment = [], nontemporal = [],
    volatile = false}).
-record(llvm_store, {dst, type, pointer, alignment = [], nontemporal = [],
    volatile = false}).
%%Other Operations
-record(llvm_icmp, {dst, 'cond', type, src1, src2}).
-record(llvm_fcmp, {dst, 'cond', type, src1, src2}).
-record(llvm_phi, {dst, type, value_label_list}). 
%%---------------------------------------------------------------------