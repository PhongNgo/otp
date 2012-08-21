%-ifdef(BIT32).
%-define(WORD_WIDTH, 32).
%-define(NR_PINNED_REGS, 2).
%-define(NR_ARG_REGS, 3).
%-define(ARCH_REGISTERS, hipe_x86_registers).
%-define(FLOAT_OFFSET, 2).
%-else.
%-define(WORD_WIDTH, 64).
%-define(NR_PINNED_REGS, 2).
%-define(NR_ARG_REGS, 4).
%-define(ARCH_REGISTERS, hipe_amd64_registers).
%-define(FLOAT_OFFSET, 6).
%-endif.

%----Modified for crossing compilation for ARM enviroment-----------------------
-define(WORD_WIDTH, 32).
-define(NR_PINNED_REGS, 3).   %native stack pointer = r10, heap pointer = r9, process pointer = r11
-define(NR_ARG_REGS, 3).	% 3+ 3 = r1-r6
-define(ARCH_REGISTERS, hipe_arm_registers).
-define(FLOAT_OFFSET, 2).

