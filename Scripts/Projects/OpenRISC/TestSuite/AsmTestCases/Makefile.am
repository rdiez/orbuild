
# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

bin_PROGRAMS = asm-basic \
               asm-add   \
               asm-ext   \
               asm-and   \
               asm-or    \
               asm-sub   \
               asm-xor   \
               asm-mfspr \
               asm-ror   \
               asm-shift \
               asm-mul   \
               asm-div   \
               asm-mac   \
               asm-find  \
               asm-lws   \
               asm-jump  \
               asm-flag

# Unfortunately, we cannot use the patsubst function in Makefile.am, so we have
# to manually type a similar file list here:
dist_data_DATA = asm-basic.TestResults \
                 asm-add.TestResults   \
                 asm-ext.TestResults   \
                 asm-and.TestResults   \
                 asm-or.TestResults    \
                 asm-sub.TestResults   \
                 asm-xor.TestResults   \
                 asm-mfspr.TestResults \
                 asm-ror.TestResults   \
                 asm-shift.TestResults \
                 asm-mul.TestResults   \
                 asm-div.TestResults   \
                 asm-mac.TestResults   \
                 asm-find.TestResults  \
                 asm-lws.TestResults   \
                 asm-jump.TestResults  \
                 asm-flag.TestResults

# Unfortunately, if you wish to create a map file per program, you have
# to manually type a similar file list, see above. Example:
#  asm_basic_CFLAGS = -Wl,-Map=asm-basic.map $(AM_CFLAGS)
#  asm_jump_CFLAGS  = -Wl,-Map=asm-jump.map  $(AM_CFLAGS)


asm_basic_SOURCES = asm-basic.S
asm_add_SOURCES   = asm-add.S
asm_ext_SOURCES   = asm-ext.S
asm_and_SOURCES   = asm-and.S
asm_or_SOURCES    = asm-or.S
asm_sub_SOURCES   = asm-sub.S
asm_xor_SOURCES   = asm-xor.S
asm_mfspr_SOURCES = asm-mfspr.S
asm_ror_SOURCES   = asm-ror.S
asm_shift_SOURCES = asm-shift.S
asm_mul_SOURCES   = asm-mul.S
asm_div_SOURCES   = asm-div.S
asm_mac_SOURCES   = asm-mac.S
asm_find_SOURCES  = asm-find.S
asm_lws_SOURCES   = asm-lws.S
asm_jump_SOURCES  = asm-jump.S
