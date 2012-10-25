
# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

.DELETE_ON_ERROR:

SHELL := bash  # This makefile has only been tested with bash.

include $(ORBUILD_SANDBOX)/Scripts/MakeModules/MakeUtils.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/DownloadAndUnpackTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RepositoryCheckoutTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/AutotoolsTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RunAndReportTemplates.mk


# ----------- Repository download options -----------

# This flag allows disabling the actual downloading of the source-control repository updates
# so as to prevent overloading the remote servers during development of this makefile.
# It must be set before using any of the repository checkout templates.
# In order for the build to work properly, the repositories must have been checked out at least once.
SKIP_REPOSITORY_UPDATE := 0

ONLY_ANONYMOUS_CHECKOUTS := 0


# ----------- OpenRISC-specific options -----------

ENABLE_PGAVIN := 0  # Build and use Peter Gavin's toolchain, which supports OpenRISC implementations
                    # without the jump delay slot.

ENABLE_LLVM := 0
ENABLE_LLVM_CHECK := 0

ENABLE_ICARUS_VERILOG := 0  # If you enable this flag, orbuild will build its own Icarus Verilog
                            # from the latest sources. Alternatively, you can install Icarus Verilog
                            # from your Linux distribution's repository.

ENABLE_VERILATOR := 0       # If you enable this flag, orbuild will build its own Verilator
                            # from the latest sources. Alternatively, you can install Verilator
                            # from your Linux distribution's repository.

ENABLE_XILINX := 0  # If enabled, orbuild assumes the Xilinx ISim simulator and other such tools
                    # are available. Please do not source the usual settings64.sh or similar
                    # before running orbuild, as that breaks other software. Instead,
                    # set environment variable ORBUILD_XILINX_HOME beforehand, so that orbuild
                    # can find and run settings64.sh itself. For example:
                    #  export ORBUILD_XILINX_HOME=/opt/Xilinx/13.4

# ------ Test Suite options ------

ENABLE_OPEN_RISC_TEST_SUITE := 0  # Whether to run the Test Suite against the OpenRISC implementations built.
                                  # Please note that all CPU simulators and implementations except for the OR10 CPU
                                  # are known to fail at least some of the tests.

ENABLE_ORTS_ORPSOC := 0  # Please note that the current OR1200 implementation (as of July 2012) fails some of the tests.
ENABLE_ORTS_OR10 := 0


# ------ eCos options (eCos is a real-time operating system) ------

ENABLE_ECOS := 0
ENABLE_ECOS_TEST := 0
ENABLE_ECOS_REDBOOT := 0
ENABLE_ECOS_REDBOOT_TEST_OR1KSIM   := 0  # Warning: This test never ends (it hangs forever).
ENABLE_ECOS_REDBOOT_TEST_VERILATOR := 0  # Warning: This test never ends (it hangs forever).

# ------ Other options ------

ENABLE_ORPSOC_RTL_TESTS := 0
ENABLE_OTHER_TESTS := 0


# ------ End of the user-defined options. From here on you should not normally need to change anything. ------

# Option --no-builtin-variables implies --no-builtin-rules, which accelerates GNU Make considerably.
FASTER_MAKE := --no-builtin-variables

LINUX_ARCH                    := or32
OPENRISC_BARE_TARGET          := $(LINUX_ARCH)-elf
OPENRISC_LINUX_TARGET         := $(LINUX_ARCH)-linux

PGAVIN_LINUX_ARCH             := or1k
PGAVIN_OPENRISC_BARE_TARGET   := $(PGAVIN_LINUX_ARCH)-elf
PGAVIN_OPENRISC_LINUX_TARGET  := $(PGAVIN_LINUX_ARCH)-linux

JBONN_LINUX_ARCH              := openrisc

LLVM_ARCH                     := or1k
LLVM_LINUX_TARGET             := $(LLVM_ARCH)-linux

# In order for the GCC cross-compiler to automatically pick up the right assembler and so on,
# it must be configured to use the same bin directory as Binutils.
BARE_TOOLCHAIN_DIR            := $(ORBUILD_BUILD_DIR)/ToolchainOr32Bare
LINUX_TOOLCHAIN_DIR           := $(ORBUILD_BUILD_DIR)/ToolchainOr32Linux

PGAVIN_BARE_TOOLCHAIN_DIR     := $(ORBUILD_BUILD_DIR)/PGavinToolchainOr1kBare
PGAVIN_LINUX_TOOLCHAIN_DIR    := $(ORBUILD_BUILD_DIR)/PGavinToolchainOr1kLinux
PGAVIN_LINUX_TOOLCHAIN_PREFIX := $(PGAVIN_LINUX_TOOLCHAIN_DIR)/$(PGAVIN_OPENRISC_LINUX_TARGET)

.PHONY: all all_tests all_pgavin all_llvm

ifeq "$(strip $(ENABLE_PGAVIN))" "1"
all: all_pgavin
endif

ifeq "$(strip $(ENABLE_LLVM))" "1"
all: all_llvm
endif

ifeq "$(strip $(ENABLE_OTHER_TESTS))" "1"
all: all_tests
endif

ifeq "$(strip $(ENABLE_ORTS_OR10))" "1"
ifneq "$(strip $(ENABLE_PGAVIN))" "1"
  $(call assertion_failure,The OR10 CPU has no jump delay slot and needs Peter Gavin's toolchain at least for the C test cases)
endif
endif

ifeq "$(strip $(ENABLE_XILINX))" "1"
  $(if $(filter undefined,$(origin ORBUILD_XILINX_HOME)),$(error "Option ENABLE_XILINX is set, but environment variable ORBUILD_XILINX_HOME is not defined."))
endif


COLON_CHAR := :
EMPTY_VAR_TRICK :=
SPACE_CHAR := $(EMPTY_VAR_TRICK) $(EMPTY_VAR_TRICK)


# ----------- Check out a number of OpenCores repositories under http://opencores.org/ocsvn/ -----------

# Each repository depends on the previous one, therefore they are checked out sequentially instead of in parallel,
# in order to prevent overloading the OpenCores server.

OC_SVN_BASE_URL    := http://opencores.org/ocsvn
OC_OR_SVN_BASE_URL := $(OC_SVN_BASE_URL)/openrisc/openrisc/trunk

$(eval $(call subversion_checkout_template,OR1KSIM,or1ksim,$(OC_OR_SVN_BASE_URL)/or1ksim))
all: $(OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call subversion_checkout_template,DOCS,OpenRISC docs,$(OC_OR_SVN_BASE_URL)/docs))
all: $(DOCS_CHECKOUT_SENTINEL)
$(DOCS_CHECKOUT_SENTINEL): $(OR1KSIM_CHECKOUT_SENTINEL)


$(eval $(call subversion_checkout_template,ORPSOCV2,ORPSoC v2,$(OC_OR_SVN_BASE_URL)/orpsocv2))
all: $(ORPSOCV2_CHECKOUT_SENTINEL)
$(ORPSOCV2_CHECKOUT_SENTINEL): $(DOCS_CHECKOUT_SENTINEL)

$(eval $(call subversion_checkout_template,ECOS,eCos realtime operating system,$(OC_OR_SVN_BASE_URL)/rtos/ecos-3.0))
ifeq "$(strip $(ENABLE_ECOS))" "1"
  all: $(ECOS_CHECKOUT_SENTINEL)
  $(ECOS_CHECKOUT_SENTINEL): $(ORPSOCV2_CHECKOUT_SENTINEL)
  PREV_SVN_REPO_SENTINEL := $(ECOS_CHECKOUT_SENTINEL)
else
  PREV_SVN_REPO_SENTINEL := $(ORPSOCV2_CHECKOUT_SENTINEL)
endif

# This is the biggest repository by far, so it's the last one to be checked out from OpenCores.
# WARNING: The OC_BLD_ALL task cleans the whole repository every time it runs.
$(eval $(call subversion_checkout_template,GNUSRC,GNU sources,$(OC_OR_SVN_BASE_URL)/gnu-stable))
all: $(GNUSRC_CHECKOUT_SENTINEL)
$(GNUSRC_CHECKOUT_SENTINEL): $(PREV_SVN_REPO_SENTINEL)


$(eval $(call subversion_checkout_template,MINSOC,MinSoC,$(OC_SVN_BASE_URL)/minsoc/minsoc/trunk))
$(MINSOC_CHECKOUT_SENTINEL): $(GNUSRC_CHECKOUT_SENTINEL)
ifeq "$(strip $(ONLY_ANONYMOUS_CHECKOUTS))" "0"
  # Only download the repository if we are going to use it, and we only use it for testing.
  all_tests: $(MINSOC_CHECKOUT_SENTINEL)
endif


# ----------- Check out a number of Peter Gavin's repositories under https://github.com/pgavin/ -----------

# Each repository depends on the previous one, therefore they are checked out sequentially instead of in parallel,
# in order to prevent overloading the Github server.

PGAVIN_GIT_BASE_URL := git://github.com/pgavin

$(eval $(call git_checkout_template,PGAVIN_LINUX,Peter Gavin's Linux,$(PGAVIN_GIT_BASE_URL)/linux.git))
all_pgavin: $(PGAVIN_LINUX_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_OR1KSIM,Peter Gavin's or1ksim,$(PGAVIN_GIT_BASE_URL)/or1ksim.git))
$(eval $(call git_download_serializer_template,PGAVIN_LINUX,PGAVIN_OR1KSIM))
all_pgavin: $(PGAVIN_OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_UCLIBC,Peter Gavin's uClibc,$(PGAVIN_GIT_BASE_URL)/uClibc.git))
$(eval $(call git_download_serializer_template,PGAVIN_OR1KSIM,PGAVIN_UCLIBC))
all_pgavin: $(PGAVIN_UCLIBC_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_OR1K_SRC,Peter Gavin's or1k-src,$(PGAVIN_GIT_BASE_URL)/or1k-src.git))
$(eval $(call git_download_serializer_template,PGAVIN_UCLIBC,PGAVIN_OR1K_SRC))
all_pgavin: $(PGAVIN_OR1K_SRC_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_OR1K_GCC,Peter Gavin's or1k-gcc,$(PGAVIN_GIT_BASE_URL)/or1k-gcc.git))
$(eval $(call git_download_serializer_template,PGAVIN_OR1K_SRC,PGAVIN_OR1K_GCC))
all_pgavin: $(PGAVIN_OR1K_GCC_CHECKOUT_SENTINEL)


# ----------- R. Diez's Repositories -----------

$(eval $(call git_checkout_template,JTAG_DPI,JTAG DPI module for Verilator,git://github.com/rdiez/jtag_dpi.git))
all: $(JTAG_DPI_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,UART_DPI,UART DPI module for Verilator,git://github.com/rdiez/uart_dpi.git))
all: $(UART_DPI_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,ETHERNET_DPI,Ethernet DPI module for Verilator,git://github.com/rdiez/ethernet_dpi.git))
all: $(ETHERNET_DPI_CHECKOUT_SENTINEL)

# ----------- Stefan Kristiansson's LLVM / Clang / Linux toolchain -----------

SKRISTIANSSON_BASE_GIT_URL := git://github.com/skristiansson

$(eval $(call git_checkout_template,LLVM,LLVM,$(SKRISTIANSSON_BASE_GIT_URL)/llvm-or1k.git))
all_llvm: $(LLVM_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,LLVM_CLANG,Clang,$(SKRISTIANSSON_BASE_GIT_URL)/clang-or1k.git))
$(eval $(call git_download_serializer_template,LLVM,LLVM_CLANG))
all_llvm: $(LLVM_CLANG_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,LLVM_OR1K_SRC,LLVM or1k src,$(SKRISTIANSSON_BASE_GIT_URL)/or1k-src.git))
$(eval $(call git_download_serializer_template,LLVM_CLANG,LLVM_OR1K_SRC))
all_llvm_linux: $(LLVM_OR1K_SRC_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,LLVM_COMPILER_RT_OR1K,LLVM compiler rt or1k,$(SKRISTIANSSON_BASE_GIT_URL)/compiler-rt-or1k.git))
$(eval $(call git_download_serializer_template,LLVM_OR1K_SRC,LLVM_COMPILER_RT_OR1K))
all_llvm_linux: $(LLVM_COMPILER_RT_OR1K_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,LLVM_UCLIBC,LLVM uClibc,$(SKRISTIANSSON_BASE_GIT_URL)/uClibc-or1k.git))
$(eval $(call git_download_serializer_template,LLVM_COMPILER_RT_OR1K,LLVM_UCLIBC))
all_llvm_linux: $(LLVM_UCLIBC_CHECKOUT_SENTINEL)


# ----------- Jonas Bonn's repositories -----------

$(eval $(call git_checkout_template,JBONN_LINUX,Jonas Bon's Linux,git://openrisc.net/jonas/linux))
all: $(JBONN_LINUX_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,JBONN_UCLIBC,Jonas Bon's uClibc,git://openrisc.net/jonas/uClibc))
all: $(JBONN_UCLIBC_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,JBONN_LINUX,JBONN_UCLIBC))


# ----------- Icarus Verilog -----------

ICARUS_VERILOG_EXTRA_GIT_CHECKOUT_ARGS := v0_9-branch
$(eval $(call git_checkout_template,ICARUS_VERILOG,Icarus Verilog,git://github.com/steveicarus/iverilog.git))

# We don't actually need to create a local branch like this, checking out branch origin/v0_9-branch will probably do.
$(eval $(call git_branch_template,ICARUS_VERILOG,--track v0_9-branch origin/v0_9-branch))

# Icarus Verilog's "make install" breaks when running in parallel mode. I have reported it,
# so it may well have been fixed by now.
ICARUS_VERILOG_INSTALL_MAKEFLAGS_FILTER := clear
ICARUS_VERILOG_EXTRA_INSTALL_ARGS := -j 1  # Not actually needed if MAKEFLAGS gets cleared.

$(eval $(call autotool_project_template,ICARUS_VERILOG,Icarus Verilog,$(ICARUS_VERILOG_CHECKOUT_DIR)))

ICARUS_VERILOG_AUTOGEN_CMD = $(SHELL) autoconf.sh
$(eval $(call autogen_project_template,ICARUS_VERILOG,Icarus Verilog))
$(ICARUS_VERILOG_AUTOGEN_SENTINEL): $(ICARUS_VERILOG_CHECKOUT_SENTINEL)

ifeq "$(strip $(ENABLE_ICARUS_VERILOG))" "1"
  all: $(ICARUS_VERILOG_INSTALL_SENTINEL)
endif


# ----------- Verilator -----------

$(eval $(call git_checkout_template,VERILATOR,Verilator,http://git.veripool.org/git/verilator))

# Build Verilator as a standard autoconf project.
VERILATOR_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
$(eval $(call autotool_project_template,VERILATOR,Verilator,$(VERILATOR_CHECKOUT_DIR)))

# Before running the standard autoconf project operations, let autoconf generate the necessary files.
VERILATOR_AUTOGEN_CMD = autoconf --warnings=all
$(eval $(call autogen_project_template,VERILATOR,Verilator))
$(VERILATOR_AUTOGEN_SENTINEL): $(VERILATOR_CHECKOUT_SENTINEL)

ifeq "$(strip $(ENABLE_VERILATOR))" "1"
  all: $(VERILATOR_INSTALL_SENTINEL)
endif

ifeq "0" "1"  # Run Verilator's install tests, disabled at the moment.
  # Verilator's install_test script sets its own -j flag for GNU Make, therefore remove any inherited flags from MAKEFLAGS.
  VERILATOR_INSTALL_TEST_CMD := cd $(VERILATOR_CHECKOUT_DIR) && perl nodist/install_test
  VERILATOR_INSTALL_TEST_MAKEFLAGS_FILTER := clear
  $(eval $(call run_and_report_template,VERILATOR_INSTALL_TEST,Verilator installation test,$(SHELL) -c "$(VERILATOR_INSTALL_TEST_CMD)"))

  $(VERILATOR_INSTALL_TEST_SENTINEL): $(VERILATOR_INSTALL_SENTINEL)
  all: $(VERILATOR_INSTALL_TEST_SENTINEL)
endif


# ----------- Binutils -----------

# Build Binutils as a standard autoconf project.
#
# Note: I am seeing random build failures around chew.exe under Cygwin,
#       it looks like some random timing issue in the makefile for parallel builds.
#       I also found thees comments about it on the Internet:
#         glitch in bfd/doc
#         using make -j 4 for example leads to failure in bdf/doc at least for the mingw32
#         targets, chew is build 4 times in parallel and the move to chew.exe fails:
#         
#         Re: Missing dependency on chew.exe somewhere?
#         FWIW, I have seen random failures with "make -j 8 check" in bfd
#         on Linux/x86-64. It is not very reproducible.

LOCAL_BINUTILS_SRC := $(GNUSRC_CHECKOUT_DIR)/binutils-2.20.1
BINUTILS_BIN_DIR := $(BARE_TOOLCHAIN_DIR)
# TODO: I am not sure whether --enable-fast-install=N/A or --disable-libssp are needed in BINUTILS_EXTRA_CONFIG_ARGS.
BINUTILS_EXTRA_CONFIG_ARGS := --target=$(OPENRISC_BARE_TARGET) --enable-werror=no
BINUTILS_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
# TODO: With the following targets, "make install" fails. I'm not sure which targets are the correct ones:
#       BINUTILS_MAKE_TARGETS := all-binutils all-gas all-ld all-build
BINUTILS_CHECK_TARGETS := check-binutils check-gas check-ld
$(eval $(call autotool_project_template,BINUTILS,Binutils,$(LOCAL_BINUTILS_SRC)))

$(BINUTILS_CONFIGURE_SENTINEL): $(GNUSRC_CHECKOUT_SENTINEL)

# TODO: Some checks fail, investigate why.
#  all: $(BINUTILS_CHECK_SENTINEL)


# ----------- GCC cross-compiler for OpenRISC -----------

COMMON_GCC_OPTIONS := --disable-shared
COMMON_GCC_OPTIONS += --disable-libssp

COMMON_GCC_OPTIONS += --disable-multilib

COMMON_GCC_OPTIONS += --disable-lto

BARE_COMMON_GCC_OPTIONS += $(COMMON_GCC_OPTIONS) --with-newlib --target=$(OPENRISC_BARE_TARGET)


# ---------- GCC phase 1 (bootstrap) ----------

# In order to build GCC, the OpenRISC binutils binaries are needed.
GCC_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/gcc-4.5.1

GCC_PHASE_1_AUTOCONF_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin
GCC_PHASE_1_BIN_DIR := $(BARE_TOOLCHAIN_DIR)

GCC_PHASE_1_EXTRA_CONFIG_ARGS        := $(BARE_COMMON_GCC_OPTIONS) --enable-languages=c --without-headers
GCC_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS   := $(FASTER_MAKE)
GCC_PHASE_1_MAKE_TARGETS             := all-gcc
GCC_PHASE_1_INSTALL_TARGETS          := install-gcc

$(eval $(call autotool_project_template,GCC_PHASE_1,GCC Phase 1,$(GCC_SRC_DIR)))

# In order to build GCC, the OpenRISC Binutils binaries are needed.
$(GCC_PHASE_1_CONFIGURE_SENTINEL): $(BINUTILS_INSTALL_SENTINEL)


# ---------- newlib ----------

NEWLIB_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/newlib-1.18.0
NEWLIB_BIN_DIR := $(BARE_TOOLCHAIN_DIR)
NEWLIB_AUTOCONF_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin

NEWLIB_EXTRA_CONFIG_ARGS :=
NEWLIB_EXTRA_CONFIG_ARGS += --target=$(OPENRISC_BARE_TARGET)
NEWLIB_EXTRA_CONFIG_ARGS += --disable-shared
NEWLIB_EXTRA_CONFIG_ARGS += --disable-multilib

NEWLIB_CHECK_TARGETS := check-target-newlib check-target-libgloss

$(eval $(call autotool_project_template,NEWLIB,Newlib,$(NEWLIB_SRC_DIR)))

$(NEWLIB_CONFIGURE_SENTINEL): $(GCC_PHASE_1_INSTALL_SENTINEL)


# ---------- GCC phase 2 ----------
# Note that this installs the final GCC binaries over the ones from phase 1.
# Although everything should be properly overwritten, this method does not look very clean to me.

GCC_PHASE_2_AUTOCONF_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin
GCC_PHASE_2_BIN_DIR := $(BARE_TOOLCHAIN_DIR)

GCC_PHASE_2_EXTRA_CONFIG_ARGS := $(BARE_COMMON_GCC_OPTIONS) --enable-languages=c,c++
GCC_PHASE_2_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
GCC_PHASE_2_CHECK_TARGETS := check-gcc check-target-libgcc check-target-libstdc++-v3

$(eval $(call autotool_project_template,GCC_PHASE_2,GCC Phase 2,$(GCC_SRC_DIR)))

$(GCC_PHASE_2_CONFIGURE_SENTINEL): $(NEWLIB_INSTALL_SENTINEL)

all: $(GCC_PHASE_2_INSTALL_SENTINEL)


# ----------- or1ksim -----------

# Build or1ksim as a standard autoconf project.

# About the target used here: or32-elf is the default target, and I don't think that or32-linux
# would have any effect for the simulator itself, although the bundled Test Suite can be built for a Linux target.
OR1KSIM_EXTRA_CONFIG_ARGS := --target=$(OPENRISC_BARE_TARGET)
OR1KSIM_EXTRA_CONFIG_ARGS += --enable-eth-phy
# TODO: optimise compilation for the test suite
# Flag --no-builtin-rules makes the build faster. Flag --no-builtin-variables does not work here because at least one makefile uses built-in variable $(RM).
OR1KSIM_EXTRA_GLOBAL_MAKE_ARGS := --no-builtin-rules

# The test suite bundled with or1ksim needs the target compiler.
OR1KSIM_AUTOCONF_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin

$(eval $(call autotool_project_template,OR1KSIM,or1ksim,$(OR1KSIM_CHECKOUT_DIR)))
all: $(OR1KSIM_INSTALL_SENTINEL)
$(OR1KSIM_CONFIGURE_SENTINEL): $(OR1KSIM_CHECKOUT_SENTINEL) $(GCC_PHASE_2_INSTALL_SENTINEL)

# If the normal installation fails, do not attempt to do any checks.
$(OR1KSIM_DISTCHECK_SENTINEL) : $(OR1KSIM_INSTALL_SENTINEL)
$(OR1KSIM_CHECK_SENTINEL)     : $(OR1KSIM_INSTALL_SENTINEL)

all_tests: $(OR1KSIM_DISTCHECK_SENTINEL)
# all_tests: $(OR1KSIM_CHECK_SENTINEL)


# ----------- GDB cross-debugger for OpenRISC -----------

GDB_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/gdb-7.2
GDB_BIN_DIR := $(BARE_TOOLCHAIN_DIR)
GDB_AUTOCONF_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin

GDB_EXTRA_CONFIG_ARGS :=
GDB_EXTRA_CONFIG_ARGS += --target=$(OPENRISC_BARE_TARGET)
# GDB uses or1ksim as the target simulator.
GDB_EXTRA_CONFIG_ARGS += --with-or1ksim=$(OR1KSIM_BIN_DIR)

$(eval $(call autotool_project_template,GDB,GDB,$(GDB_SRC_DIR)))

$(GDB_CONFIGURE_SENTINEL): $(GCC_PHASE_2_INSTALL_SENTINEL) $(OR1KSIM_INSTALL_SENTINEL)
all: $(GDB_INSTALL_SENTINEL)


# ----------- Verilog Tools Path -----------

ifeq "$(strip $(ENABLE_ICARUS_VERILOG))" "1"
  IVERILOG_PREREQ := $(ICARUS_VERILOG_INSTALL_SENTINEL)
  IVERILOG_PATH := $(ICARUS_VERILOG_BIN_DIR)/bin
else
  IVERILOG_PREREQ :=
  IVERILOG_PATH :=
endif

ifeq "$(strip $(ENABLE_VERILATOR))" "1"
  VERILATOR_PREREQ := $(VERILATOR_INSTALL_SENTINEL)
  VERILATOR_PATH := $(VERILATOR_BIN_DIR)/bin
else
  VERILATOR_PREREQ :=
  VERILATOR_PATH :=
endif


# ----------- ORPSoC v2 -----------

ORPSOC_NAME := ORPSOCv2

# ------- Build the support tools, they are needed when running the Test Suite (see further below).

# Note that this step slightly pollutes the source repository it is run upon.
$(ORPSOC_NAME)_SW_UTILS_CMD := cd $(ORPSOCV2_CHECKOUT_DIR)/sw/utils && make $(FASTER_MAKE) all
$(ORPSOC_NAME)_SW_UTILS_CMD_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,$(ORPSOC_NAME)_SW_UTILS_CMD,ORPSoC v2 sw utils,$(SHELL) -c "$(value $(ORPSOC_NAME)_SW_UTILS_CMD)"))
# These tools are not always needed.
#   all: $(value $(ORPSOC_NAME)_SW_UTILS_CMD_SENTINEL)
$(value $(ORPSOC_NAME)_SW_UTILS_CMD_SENTINEL): $(ORPSOCV2_CHECKOUT_SENTINEL)


# ------- Build the documentation.

# Note that this step slightly pollutes the source repository it is run upon.
$(ORPSOC_NAME)_DOCUMENTATION_CMD := cd $(ORPSOCV2_CHECKOUT_DIR)/doc && ./configure && make $(FASTER_MAKE) pdf
$(ORPSOC_NAME)_DOCUMENTATION_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,$(ORPSOC_NAME)_DOCUMENTATION,ORPSoC v2 documentation,$(SHELL) -c "$(value $(ORPSOC_NAME)_DOCUMENTATION_CMD)"))
all: $(value $(ORPSOC_NAME)_DOCUMENTATION_SENTINEL)
$(value $(ORPSOC_NAME)_DOCUMENTATION_SENTINEL): $(ORPSOCV2_CHECKOUT_SENTINEL)


# ------- Lint (parts of the) Verilog code with Verilator and with Icarus Verilog.

LINT_TEMP_DIR := $(ORBUILD_BUILD_DIR)/temp/LINT_TEMP

$(ORPSOC_NAME)_LINT_PREPEND_PATH_LIST := $(IVERILOG_PATH) $(VERILATOR_PATH)  # Note that any of these 2 may be empty.
$(ORPSOC_NAME)_LINT_PREPEND_PATH := $(subst $(SPACE_CHAR),$(COLON_CHAR),$(strip $($(ORPSOC_NAME)_LINT_PREPEND_PATH_LIST)))

$(ORPSOC_NAME)_LINT_OR1200_PREPEND_PATH        := $($(ORPSOC_NAME)_LINT_PREPEND_PATH)
$(ORPSOC_NAME)_LINT_ORPSOC_PREPEND_PATH        := $($(ORPSOC_NAME)_LINT_PREPEND_PATH)
$(ORPSOC_NAME)_LINT_ORPSOC_ALTCFG_PREPEND_PATH := $($(ORPSOC_NAME)_LINT_PREPEND_PATH)
$(ORPSOC_NAME)_LINT_TESTBENCH_PREPEND_PATH     := $($(ORPSOC_NAME)_LINT_PREPEND_PATH)

$(ORPSOC_NAME)_LINT_CMD := $(ORBUILD_PROJECT_DIR)/Tools/Orpsocv2Lint.sh \"$(ORPSOCV2_CHECKOUT_DIR)\" \"$(LINT_TEMP_DIR)\"

$(eval $(call run_and_report_template,$(ORPSOC_NAME)_LINT_OR1200,ORPSoC v2 lint or1200,$(SHELL) -c "$(value $(ORPSOC_NAME)_LINT_CMD) or1200 minimal-features"))
$(eval $(call run_and_report_template,$(ORPSOC_NAME)_LINT_ORPSOC,ORPSoC v2 lint orpsoc,$(SHELL) -c "$(value $(ORPSOC_NAME)_LINT_CMD) orpsoc maximal-features"))
$(eval $(call run_and_report_template,$(ORPSOC_NAME)_LINT_ORPSOC_ALTCFG,ORPSoC v2 lint orpsoc alt cfg,$(SHELL) -c "$(value $(ORPSOC_NAME)_LINT_CMD) orpsoc maximal-features-alt-cfg"))
$(eval $(call run_and_report_template,$(ORPSOC_NAME)_LINT_TESTBENCH,ORPSoC v2 lint testbench,$(SHELL) -c "$(value $(ORPSOC_NAME)_LINT_CMD) testbench maximal-features"))

$(value $(ORPSOC_NAME)_LINT_OR1200_SENTINEL)       : $(IVERILOG_PREREQ) $(VERILATOR_PREREQ) $(ORPSOCV2_CHECKOUT_SENTINEL)
$(value $(ORPSOC_NAME)_LINT_ORPSOC_SENTINEL)       : $(IVERILOG_PREREQ) $(VERILATOR_PREREQ) $(ORPSOCV2_CHECKOUT_SENTINEL)
$(value $(ORPSOC_NAME)_LINT_ORPSOC_ALTCFG_SENTINEL): $(IVERILOG_PREREQ) $(VERILATOR_PREREQ) $(ORPSOCV2_CHECKOUT_SENTINEL)
$(value $(ORPSOC_NAME)_LINT_TESTBENCH_SENTINEL)    : $(IVERILOG_PREREQ) $(VERILATOR_PREREQ) $(ORPSOCV2_CHECKOUT_SENTINEL)

all: $(value $(ORPSOC_NAME)_LINT_OR1200_SENTINEL)
all: $(value $(ORPSOC_NAME)_LINT_ORPSOC_SENTINEL)
all: $(value $(ORPSOC_NAME)_LINT_ORPSOC_ALTCFG_SENTINEL)
# TODO: not ready yet, must generate test-defines.v properly:
#   all: $(value $(ORPSOC_NAME)_LINT_TESTBENCH_SENTINEL)

LINT_GROUP := $(ORPSOC_NAME)_LINT_OR1200
LINT_GROUP += $(ORPSOC_NAME)_LINT_ORPSOC
LINT_GROUP += $(ORPSOC_NAME)_LINT_ORPSOC_ALTCFG
LINT_GROUP += $(ORPSOC_NAME)_LINT_TESTBENCH


# ------- Run some of the self-tests.

# Note that this step slightly pollutes the source repository its run upon.

$(ORPSOC_NAME)_RTL_TESTS_CMD := cd $(ORPSOCV2_CHECKOUT_DIR)/sim/bin &&
$(ORPSOC_NAME)_RTL_TESTS_CMD += make -j 1 rtl-tests  # About the "-j 1": The rtl-tests target breaks when run in parallel mode.
                                                     # Not actually needed if MAKEFLAGS gets cleared (see below).

# Clear variable MAKEFLAGS, as the rtl-tests target breaks when run in parallel mode.
$(ORPSOC_NAME)_RTL_TESTS_MAKEFLAGS_FILTER := clear

$(ORPSOC_NAME)_RTL_TESTS_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin

ifeq "$(strip $(ENABLE_ICARUS_VERILOG))" "1"
  $(ORPSOC_NAME)_RTL_TESTS_PREPEND_PATH := $(ICARUS_VERILOG_BIN_DIR)/bin:$($(ORPSOC_NAME)_RTL_TESTS_PREPEND_PATH)
endif

$(eval $(call run_makefile_and_report_template,$(ORPSOC_NAME)_RTL_TESTS,ORPSoC v2 RTL tests,$(SHELL) -c "$(value $(ORPSOC_NAME)_RTL_TESTS_CMD)"))

ifeq "$(strip $(ENABLE_ICARUS_VERILOG))" "1"
  $(value $(ORPSOC_NAME)_RTL_TESTS_SENTINEL): $(ICARUS_VERILOG_INSTALL_SENTINEL)
endif

$(value $(ORPSOC_NAME)_RTL_TESTS_SENTINEL): $(GCC_PHASE_2_INSTALL_SENTINEL)

ifeq "$(strip $(ENABLE_ORPSOC_RTL_TESTS))" "1"
  all: $(value $(ORPSOC_NAME)_RTL_TESTS_SENTINEL)
endif

# The rtl-tests target builds some of the sw utils. In order to prevent collisions while building,
# make the tests depend on the full sw utils set.
$(value $(ORPSOC_NAME)_RTL_TESTS_SENTINEL): $(value $(ORPSOC_NAME)_SW_UTILS_CMD_SENTINEL)


# ----------- MinSoC's tools -----------

# Build some of MinSoC's utils. I used to build them from the MinSoC Repository, but after
# several downtimes with OpenCores' Subversion server, I decided to make a copy
# and store them in orbuild's repository.

# Note that this step slightly pollutes the source repository it is run upon.
MINSOC_TOOLS_DIR := $(ORBUILD_PROJECT_DIR)/MinsocTools
MINSOC_SW_UTILS_CMD := cd \"$(MINSOC_TOOLS_DIR)\" && make $(FASTER_MAKE) bin2hex
MINSOC_SW_UTILS_CMD_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,MINSOC_SW_UTILS_CMD,MinSoC sw utils,$(SHELL) -c "$(value MINSOC_SW_UTILS_CMD)"))
# Not needed any more:  $(MINSOC_SW_UTILS_CMD_SENTINEL): $(MINSOC_CHECKOUT_SENTINEL)


# ----------- MinSoC's automatic installation script -----------

MINSOC_INSTALLATION_SCRIPT_DIR := $(ORBUILD_BUILD_DIR)/MINSOC_INSTALLATION_SCRIPT
MINSOC_INSTALLATION_SCRIPT_CMD := $(ORBUILD_PROJECT_DIR)/Tools/MinsocInstallationTest.sh $(MINSOC_CHECKOUT_DIR) $(MINSOC_INSTALLATION_SCRIPT_DIR)

MINSOC_INSTALLATION_SCRIPT_MAKEFLAGS_FILTER := clear

$(eval $(call run_and_report_template,MINSOC_INSTALLATION_SCRIPT,MinSoC's installation script,$(SHELL) -c "$(MINSOC_INSTALLATION_SCRIPT_CMD)"))
$(MINSOC_INSTALLATION_SCRIPT_SENTINEL): $(MINSOC_CHECKOUT_SENTINEL)

ifeq "$(strip $(ONLY_ANONYMOUS_CHECKOUTS))" "0"
# MinSoC's installation script downloads a repository and some files automatically, so skip it if we have globally disabled repository downloading.
ifeq "$(strip $(SKIP_REPOSITORY_UPDATE))" "0"
all_tests: $(MINSOC_INSTALLATION_SCRIPT_SENTINEL)
endif
endif


# ----------- Test OpenCore's gnu-src bld-all.sh -----------

# WARNING: This component waits until all other components have finished with the GNUSRC repository,
#          and then it cleans it before starting its own work. This is to prevent the following error:
#            configure: error: `CC' has changed since the previous run
# For faster runs during testing of this makefile:  OC_BLD_ARGS := --no-or32-linux
OC_BLD_ARGS += --prefix $(ORBUILD_BUILD_DIR)/OC_BLD_ALL/bin
OC_BLD_ARGS += --prefix-tmp $(ORBUILD_BUILD_DIR)/OC_BLD_ALL/tmp
OC_BLD_ARGS += --or1ksim-dir $(OR1KSIM_BIN_DIR)
OC_BLD_ARGS += --uclibc-dir $(JBONN_UCLIBC_CHECKOUT_DIR)
OC_BLD_ARGS += --linux-dir $(JBONN_LINUX_CHECKOUT_DIR)
# Many of the tests are known to fail, so do not enable them for the time being:
#   OC_BLD_ARGS += --check

OC_BLD_ALL_CMD := echo \"Cleaning repository...\" && $(ORBUILD_TOOLS)/SvnCleanRepo.sh $(GNUSRC_CHECKOUT_DIR) &&
OC_BLD_ALL_CMD += echo \"Running bld-all.sh...\" && cd $(GNUSRC_CHECKOUT_DIR) &&
OC_BLD_ALL_CMD += ./bld-all.sh $(OC_BLD_ARGS)

OC_BLD_ALL_MAKEFLAGS_FILTER := clear

$(eval $(call run_and_report_template,OC_BLD_ALL,OpenCore's gnu-src bld-all.sh,$(SHELL) -c "$(OC_BLD_ALL_CMD)"))

$(OC_BLD_ALL_SENTINEL): $(OR1KSIM_INSTALL_SENTINEL) $(GNUSRC_CHECKOUT_SENTINEL) $(JBONN_LINUX_CHECKOUT_SENTINEL) $(JBONN_UCLIBC_CHECKOUT_SENTINEL)

all_tests: $(OC_BLD_ALL_SENTINEL)


# ----------- Peter Gavin's Binutils and other tools, common settings -----------

PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS := --target=$(PGAVIN_OPENRISC_BARE_TARGET)

# Note about target compilation flags:
#   We don't need to specify any flags like -mcompat-delay here, as newlib gets built in all 3 multilib variants
#   (with jump delay slot, without jump delay slot and compatible with both).
#   If you ever want to specify target compilation flags, use this syntax:
#     PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += CFLAGS_FOR_TARGET=\"-some-flag -g -O2\"
#   Keep in mind that the default flags get lost, so you would have to specify "-g -O" manually at this point.
#   Beware that other components, like libgcc, need to get built with compatible flags,
#   as they all get linked together at the end.

PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-shared
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-itcl
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-tk
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-tcl
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-winsup
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-libgui
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-rda
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-sid
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --with-sysroot
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-gdb
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --disable-readline
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS += --with-system-readline
# --disable-multilib:  Multilibs have a meaning now: 1) with jump delay slot, 2) without jump delay slot, 3) compatibility (l.nop after every jump instruction).


# ----------- Peter Gavin's Binutils and other tools (bare), phase 1 -----------

PGAVIN_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS := $(PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS)
PGAVIN_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS += --disable-libgloss
PGAVIN_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS += --disable-newlib
# We could build the CGEN-based simulator in the first phase, but we are using it only after phase 2,
# when the binutils have settled down, so it's not worth building it in phase 1 too.
PGAVIN_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS += --disable-sim

PGAVIN_BINUTILS_PHASE_1_BIN_DIR := $(PGAVIN_BARE_TOOLCHAIN_DIR)

PGAVIN_BINUTILS_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)

$(eval $(call autotool_project_template,PGAVIN_BINUTILS_PHASE_1,Peter Gavin's Binutils etc. phase 1,$(PGAVIN_OR1K_SRC_CHECKOUT_DIR)))

$(PGAVIN_BINUTILS_PHASE_1_CONFIGURE_SENTINEL): $(PGAVIN_OR1K_SRC_CHECKOUT_SENTINEL)


# ----------- Peter Gavin's GCC cross-compiler for OpenRISC (bare), common settings -----------

PGAVIN_COMMON_GCC_OPTIONS := --disable-shared
PGAVIN_COMMON_GCC_OPTIONS += --disable-libssp
PGAVIN_COMMON_GCC_OPTIONS += --disable-lto
PGAVIN_COMMON_GCC_OPTIONS += --disable-libgomp
PGAVIN_COMMON_GCC_OPTIONS += --disable-libmudflap
PGAVIN_COMMON_GCC_OPTIONS += --enable-threads=single
PGAVIN_COMMON_GCC_OPTIONS += --disable-libquadmath

PGAVIN_BARE_COMMON_GCC_OPTIONS := $(PGAVIN_COMMON_GCC_OPTIONS) --with-newlib --target=$(PGAVIN_OPENRISC_BARE_TARGET)


# ---------- Peter Gavin's GCC phase 1 (bootstrap) ----------

# In order to build GCC, the OpenRISC Binutils binaries from phase 1 are needed.
PGAVIN_GCC_PHASE_1_AUTOCONF_PREPEND_PATH := $(PGAVIN_BARE_TOOLCHAIN_DIR)/bin
PGAVIN_GCC_PHASE_1_BIN_DIR := $(PGAVIN_BARE_TOOLCHAIN_DIR)

PGAVIN_GCC_PHASE_1_EXTRA_CONFIG_ARGS        := $(PGAVIN_BARE_COMMON_GCC_OPTIONS) --enable-languages=c --without-headers
PGAVIN_GCC_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS   := $(FASTER_MAKE)
PGAVIN_GCC_PHASE_1_MAKE_TARGETS             := all-gcc
PGAVIN_GCC_PHASE_1_INSTALL_TARGETS          := install-gcc

# I've seen some sporadic error messages like "cannot create regular file '/home/blah blah/bin/or1k-elf-gcc-ar': No such file or directory",
# and that makes me thing that the install phase breaks when run in parallel mode.
PGAVIN_GCC_PHASE_1_INSTALL_MAKEFLAGS_FILTER := clear

$(eval $(call autotool_project_template,PGAVIN_GCC_PHASE_1,Peter Gavin's GCC Phase 1,$(PGAVIN_OR1K_GCC_CHECKOUT_DIR)))

# In order to build GCC, the OpenRISC Binutils binaries are needed.
$(PGAVIN_GCC_PHASE_1_CONFIGURE_SENTINEL): $(PGAVIN_BINUTILS_PHASE_1_INSTALL_SENTINEL) $(PGAVIN_OR1K_GCC_CHECKOUT_SENTINEL)


# ----------- Peter Gavin's Binutils and other tools (bare), phase 2 -----------
# Note that this installs the final Binutils binaries over the ones from phase 1.
# Although everything should be properly overwritten, this method does not look very clean to me.

# It is rather unfortunate that we have to reconfigure and build all components again.
# Maybe there is a way to build just newlib, libgloss and the simulator.

PGAVIN_BINUTILS_PHASE_2_EXTRA_CONFIG_ARGS := $(PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS)

PGAVIN_BINUTILS_PHASE_2_EXTRA_CONFIG_ARGS += --enable-sim-debug
PGAVIN_BINUTILS_PHASE_2_EXTRA_CONFIG_ARGS += --disable-sim-cflags
PGAVIN_BINUTILS_PHASE_2_EXTRA_CONFIG_ARGS += --enable-sim-trace

PGAVIN_BINUTILS_PHASE_2_BIN_DIR := $(PGAVIN_BARE_TOOLCHAIN_DIR)

PGAVIN_BINUTILS_PHASE_2_AUTOCONF_PREPEND_PATH := $(PGAVIN_BARE_TOOLCHAIN_DIR)/bin

# At least one of the OpenRISC parts is not compatible with flag --no-builtin-variables:
#   PGAVIN_BINUTILS_PHASE_2_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)

# TODO: These checks are not working properly. I'm also not sure which targets, if any, should be specified here.
#   PGAVIN_BINUTILS_PHASE_2_CHECK_TARGETS := check-binutils check-gas check-ld
#   PGAVIN_BINUTILS_PHASE_2_CHECK_TARGETS += check-target-newlib check-target-libgloss

$(eval $(call autotool_project_template,PGAVIN_BINUTILS_PHASE_2,Peter Gavin's Binutils etc. phase 2,$(PGAVIN_OR1K_SRC_CHECKOUT_DIR)))

$(PGAVIN_BINUTILS_PHASE_2_CONFIGURE_SENTINEL): $(PGAVIN_GCC_PHASE_1_INSTALL_SENTINEL)

ifeq "$(strip $(ENABLE_PGAVIN))" "1"
# Disabled at the moment, see commentabove:
#    all_tests: $(PGAVIN_BINUTILS_PHASE_2_CHECK_SENTINEL)
endif


# ---------- Peter Gavin's GCC phase 2 ----------
# Note that this installs the final GCC binaries over the ones from phase 1.
# Although everything should be properly overwritten, this method does not look very clean to me.

PGAVIN_GCC_PHASE_2_AUTOCONF_PREPEND_PATH := $(PGAVIN_BARE_TOOLCHAIN_DIR)/bin
PGAVIN_GCC_PHASE_2_BIN_DIR := $(PGAVIN_BARE_TOOLCHAIN_DIR)

PGAVIN_GCC_PHASE_2_EXTRA_CONFIG_ARGS := $(PGAVIN_BARE_COMMON_GCC_OPTIONS) --enable-languages=c,c++
PGAVIN_GCC_PHASE_2_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
PGAVIN_GCC_PHASE_2_CHECK_TARGETS := check-gcc check-target-libgcc check-target-libstdc++-v3

$(eval $(call autotool_project_template,PGAVIN_GCC_PHASE_2,Peter Gavin's GCC Phase 2,$(PGAVIN_OR1K_GCC_CHECKOUT_DIR)))

$(PGAVIN_GCC_PHASE_2_CONFIGURE_SENTINEL): $(PGAVIN_BINUTILS_PHASE_2_INSTALL_SENTINEL)
all_pgavin: $(PGAVIN_GCC_PHASE_2_INSTALL_SENTINEL)


# ----------- Peter Gavin's or1ksim -----------

# Build or1ksim as a standard autoconf project.

PGAVIN_OR1KSIM_EXTRA_CONFIG_ARGS := --target=$(PGAVIN_OPENRISC_BARE_TARGET)
PGAVIN_OR1KSIM_EXTRA_CONFIG_ARGS += --enable-eth-phy
# Flag --no-builtin-rules makes the build faster. Flag --no-builtin-variables does not work here because at least one makefile uses built-in variable $(RM).
PGAVIN_OR1KSIM_EXTRA_GLOBAL_MAKE_ARGS := --no-builtin-rules

# The test suite bundled with or1ksim needs the target compiler.
PGAVIN_OR1KSIM_AUTOCONF_PREPEND_PATH := $(PGAVIN_BARE_TOOLCHAIN_DIR)/bin

$(eval $(call autotool_project_template,PGAVIN_OR1KSIM,Peter Gavin's or1ksim,$(PGAVIN_OR1KSIM_CHECKOUT_DIR)))

$(PGAVIN_OR1KSIM_CONFIGURE_SENTINEL): $(PGAVIN_OR1KSIM_CHECKOUT_SENTINEL) $(PGAVIN_GCC_PHASE_2_INSTALL_SENTINEL)
all_pgavin: $(PGAVIN_OR1KSIM_INSTALL_SENTINEL)


# ----------- Peter Gavin's Binutils and other tools for Linux, common settings -----------

PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS := --target=$(PGAVIN_OPENRISC_LINUX_TARGET)
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-shared
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-itcl
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-tk
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-tcl
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-winsup
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-libgui
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-rda
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-sid
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --with-sysroot
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-gdb
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --disable-readline
PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS += --with-system-readline

# ----------- Peter Gavin's Binutils and other tools for Linux, phase 1 -----------

PGAVIN_LINUX_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS := $(PGAVIN_LINUX_BINUTILS_EXTRA_CONFIG_ARGS)

# TODO: we are using uclibc, right?
PGAVIN_LINUX_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS += --disable-libgloss
PGAVIN_LINUX_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS += --disable-newlib
PGAVIN_LINUX_BINUTILS_PHASE_1_EXTRA_CONFIG_ARGS += --disable-sim

PGAVIN_LINUX_BINUTILS_PHASE_1_BIN_DIR := $(PGAVIN_LINUX_TOOLCHAIN_DIR)

PGAVIN_LINUX_BINUTILS_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)

$(eval $(call autotool_project_template,PGAVIN_LINUX_BINUTILS_PHASE_1,Peter Gavin's Linux Binutils etc. phase 1,$(PGAVIN_OR1K_SRC_CHECKOUT_DIR)))

$(PGAVIN_LINUX_BINUTILS_PHASE_1_CONFIGURE_SENTINEL): $(PGAVIN_OR1K_SRC_CHECKOUT_SENTINEL)


# ---------- Peter Gavin's Linux Headers ----------

PGAVIN_LINUX_HEADERS_OBJ_DIR := $(ORBUILD_BUILD_DIR)/obj/PGAVIN_LINUX_HEADERS_OBJ
PGAVIN_LINUX_HEADERS_INSTALL_DIR := $(PGAVIN_LINUX_TOOLCHAIN_PREFIX)

PGAVIN_LINUX_HEADERS_CMD := if [ -d \"$(PGAVIN_LINUX_HEADERS_OBJ_DIR)\" ]; then echo \"Deleting previous output directory $(PGAVIN_LINUX_HEADERS_OBJ_DIR)...\" && rm -rf \"$(PGAVIN_LINUX_HEADERS_OBJ_DIR)\"; fi &&
PGAVIN_LINUX_HEADERS_CMD += mkdir \"$(PGAVIN_LINUX_HEADERS_OBJ_DIR)\" &&
PGAVIN_LINUX_HEADERS_CMD += echo \"Creating the Linux headers configuration...\" &&
PGAVIN_LINUX_HEADERS_CMD += make -C \"$(PGAVIN_LINUX_CHECKOUT_DIR)\" O=\"$(PGAVIN_LINUX_HEADERS_OBJ_DIR)\" ARCH=$(PGAVIN_LINUX_ARCH) defconfig &&
PGAVIN_LINUX_HEADERS_CMD += echo \"Installing the Linux headers...\" &&
PGAVIN_LINUX_HEADERS_CMD += make -C \"$(PGAVIN_LINUX_HEADERS_OBJ_DIR)\" ARCH=$(PGAVIN_LINUX_ARCH) INSTALL_HDR_PATH=\"$(PGAVIN_LINUX_HEADERS_INSTALL_DIR)\" headers_install

PGAVIN_LINUX_HEADERS_MAKEFLAGS_FILTER := clear

$(eval $(call run_makefile_and_report_template,PGAVIN_LINUX_HEADERS,Peter Gavin's Linux Headers,$(SHELL) -c "$(PGAVIN_LINUX_HEADERS_CMD)"))
$(PGAVIN_LINUX_HEADERS_SENTINEL): $(PGAVIN_LINUX_CHECKOUT_SENTINEL)


# ----------- Peter Gavin's Linux GCC cross-compiler for OpenRISC, common settings -----------

PGAVIN_LINUX_COMMON_GCC_OPTIONS := --disable-shared
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --disable-libssp
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --disable-multilib  # TODO: should we remove this?
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --disable-lto
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --disable-libgomp
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --disable-libmudflap
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --disable-libquadmath
PGAVIN_LINUX_COMMON_GCC_OPTIONS += --target=$(PGAVIN_OPENRISC_LINUX_TARGET)


# ---------- Peter Gavin's Linux GCC phase 1 (bootstrap) ----------

# In order to build GCC, the OpenRISC Binutils binaries are needed.
PGAVIN_LINUX_GCC_PHASE_1_AUTOCONF_PREPEND_PATH := $(PGAVIN_LINUX_TOOLCHAIN_DIR)/bin
PGAVIN_LINUX_GCC_PHASE_1_BIN_DIR := $(PGAVIN_LINUX_TOOLCHAIN_DIR)
PGAVIN_LINUX_GCC_PHASE_1_EXTRA_CONFIG_ARGS        := $(PGAVIN_LINUX_COMMON_GCC_OPTIONS) --enable-languages=c --without-headers --enable-threads=single
PGAVIN_LINUX_GCC_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS   := $(FASTER_MAKE)
PGAVIN_LINUX_GCC_PHASE_1_MAKE_TARGETS             := all-gcc
PGAVIN_LINUX_GCC_PHASE_1_INSTALL_TARGETS          := install-gcc

$(eval $(call autotool_project_template,PGAVIN_LINUX_GCC_PHASE_1,Peter Gavin's Linux GCC Phase 1,$(PGAVIN_OR1K_GCC_CHECKOUT_DIR)))

$(PGAVIN_LINUX_GCC_PHASE_1_CONFIGURE_SENTINEL): $(PGAVIN_LINUX_BINUTILS_PHASE_1_INSTALL_SENTINEL) $(PGAVIN_OR1K_GCC_CHECKOUT_SENTINEL)


# ---------- Peter Gavin's uClibc for Linux ----------

# TODO: The config pollutes the source code repository, but uClibc does not seem to support out-of-tree builds yet:
#       If I add  with O=\"$(PGAVIN_LINUX_UCLIBC_OBJ_DIR)\" , it fails to install file uClibc_config.h .
# PGAVIN_LINUX_UCLIBC_OBJ_DIR := $(ORBUILD_BUILD_DIR)/PGAVIN_LINUX_UCLIBC_OBJ

PGAVIN_LINUX_UCLIBC_CMD :=

# PGAVIN_LINUX_UCLIBC_CMD += if [ -d \"$(PGAVIN_LINUX_UCLIBC_OBJ_DIR)\" ]; then echo \"Deleting previous output directory $(PGAVIN_LINUX_UCLIBC_OBJ_DIR)...\" && rm -rf \"$(PGAVIN_LINUX_UCLIBC_OBJ_DIR)\"; fi &&
# PGAVIN_LINUX_UCLIBC_CMD += mkdir \"$(PGAVIN_LINUX_UCLIBC_OBJ_DIR)\" &&

PGAVIN_LINUX_UCLIBC_CMD += echo \"Cleaning any previous uClibc configuration ...\" &&
PGAVIN_LINUX_UCLIBC_CMD += make -C \"$(PGAVIN_UCLIBC_CHECKOUT_DIR)\" ARCH=$(PGAVIN_LINUX_ARCH) clean &&

PGAVIN_LINUX_UCLIBC_CMD += echo \"Generating the uClibc configuration ...\" &&
PGAVIN_LINUX_UCLIBC_CMD += make -C \"$(PGAVIN_UCLIBC_CHECKOUT_DIR)\"
PGAVIN_LINUX_UCLIBC_CMD +=      ARCH=$(PGAVIN_LINUX_ARCH)
PGAVIN_LINUX_UCLIBC_CMD +=      defconfig &&

PGAVIN_LINUX_UCLIBC_CMD += echo \"Building uClibc ...\" &&
PGAVIN_LINUX_UCLIBC_CMD += make -C \"$(PGAVIN_UCLIBC_CHECKOUT_DIR)\"
PGAVIN_LINUX_UCLIBC_CMD +=      PREFIX=\"$(PGAVIN_LINUX_TOOLCHAIN_PREFIX)\"
PGAVIN_LINUX_UCLIBC_CMD +=      KERNEL_HEADERS=\"$(PGAVIN_LINUX_HEADERS_INSTALL_DIR)/include\"
PGAVIN_LINUX_UCLIBC_CMD +=      DEVEL_PREFIX=/ 
PGAVIN_LINUX_UCLIBC_CMD +=      RUNTIME_PREFIX=/
PGAVIN_LINUX_UCLIBC_CMD +=      install

PGAVIN_LINUX_UCLIBC_MAKEFLAGS_FILTER := pass-j

PGAVIN_LINUX_UCLIBC_PREPEND_PATH := $(PGAVIN_LINUX_TOOLCHAIN_DIR)/bin

$(eval $(call run_makefile_and_report_template,PGAVIN_LINUX_UCLIBC,Peter Gavin's uClibc for Linux,$(SHELL) -c "$(PGAVIN_LINUX_UCLIBC_CMD)"))
$(PGAVIN_LINUX_UCLIBC_SENTINEL): $(PGAVIN_UCLIBC_CHECKOUT_SENTINEL) $(PGAVIN_LINUX_HEADERS_SENTINEL) $(PGAVIN_LINUX_GCC_PHASE_1_INSTALL_SENTINEL)
# TODO: all_pgavin: $(PGAVIN_LINUX_UCLIBC_SENTINEL)


# ---------- Peter Gavin's Linux GCC phase 2 ----------

# Note that this installs the final GCC binaries over the ones from phase 1.
# Although everything should be properly overwritten, this method does not look very clean to me.

PGAVIN_LINUX_GCC_PHASE_2_AUTOCONF_PREPEND_PATH := $(PGAVIN_LINUX_TOOLCHAIN_DIR)/bin
PGAVIN_LINUX_GCC_PHASE_2_BIN_DIR := $(PGAVIN_LINUX_TOOLCHAIN_DIR)

PGAVIN_LINUX_GCC_PHASE_2_EXTRA_CONFIG_ARGS := $(PGAVIN_LINUX_COMMON_GCC_OPTIONS) --enable-languages=c,c++
PGAVIN_LINUX_GCC_PHASE_2_EXTRA_CONFIG_ARGS += --enable-threads=posix
PGAVIN_LINUX_GCC_PHASE_2_EXTRA_CONFIG_ARGS += --with-headers=$(PGAVIN_LINUX_HEADERS_INSTALL_DIR)/include

PGAVIN_LINUX_GCC_PHASE_2_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)

$(eval $(call autotool_project_template,PGAVIN_LINUX_GCC_PHASE_2,Peter Gavin's Linux GCC Phase 2,$(PGAVIN_OR1K_GCC_CHECKOUT_DIR)))

$(PGAVIN_LINUX_GCC_PHASE_2_CONFIGURE_SENTINEL): $(PGAVIN_LINUX_UCLIBC_SENTINEL)
# TODO: all_pgavin: $(PGAVIN_LINUX_GCC_PHASE_2_INSTALL_SENTINEL)

# TODO: The bld-all.sh rebuilds uClibc with the final (phase 2) compiler, maybe we should do the same here.


# ----------- Linux GDB cross-debugger for OpenRISC -----------

# TODO:  This is the old 7.2 debugger, we should probably use a newer one.

LINUX_GDB_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/gdb-7.2
LINUX_GDB_BIN_DIR := $(PGAVIN_LINUX_TOOLCHAIN_DIR)
LINUX_GDB_AUTOCONF_PREPEND_PATH := $(PGAVIN_LINUX_TOOLCHAIN_DIR)/bin

# Peter Gavin's toolchain uses 'or1k' and this old GDB uses 'or32', therefore we need the CROSS_COMPILE argument here:
LINUX_GDB_EXTRA_CONFIG_ARGS := CROSS_COMPILE=$(OPENRISC_LINUX_TARGET)-
LINUX_GDB_EXTRA_CONFIG_ARGS += --target=$(OPENRISC_LINUX_TARGET)
# GDB uses or1ksim as the target simulator.
LINUX_GDB_EXTRA_CONFIG_ARGS += --with-or1ksim=$(PGAVIN_OR1KSIM_BIN_DIR)

$(eval $(call autotool_project_template,LINUX_GDB,GDB 7.2 for Linux with Peter Gavin's toolchain,$(LINUX_GDB_SRC_DIR)))

$(LINUX_GDB_CONFIGURE_SENTINEL): $(PGAVIN_LINUX_GCC_PHASE_2_INSTALL_SENTINEL) $(PGAVIN_OR1KSIM_INSTALL_SENTINEL) $(GNUSRC_CHECKOUT_SENTINEL)
# TODO: all_pgavin: $(LINUX_GDB_INSTALL_SENTINEL)


# ---- Build gdbserver ----

GDBSERVER_SRC_DIR := $(LINUX_GDB_SRC_DIR)/gdb/gdbserver

GDBSERVER_EXTRA_CONFIG_ARGS := CC=$(PGAVIN_OPENRISC_LINUX_TARGET)-gcc
GDBSERVER_EXTRA_CONFIG_ARGS += --target=$(OPENRISC_LINUX_TARGET)
GDBSERVER_EXTRA_CONFIG_ARGS += --host=$(OPENRISC_LINUX_TARGET)

GDBSERVER_AUTOCONF_PREPEND_PATH := $(PGAVIN_LINUX_TOOLCHAIN_DIR)/bin
$(eval $(call autotool_project_template,GDBSERVER,gdbserver,$(GDBSERVER_SRC_DIR)))

$(GDBSERVER_CONFIGURE_SENTINEL): $(LINUX_GDB_INSTALL_SENTINEL)

# Disabled for the time being, as I have not been able to get this to work yet.
ifeq "1" "0"
all_pgavin: $(GDBSERVER_INSTALL_SENTINEL)
endif


# ----------- OpenRISC Test Suite -----------

# NOTE: If PGAVIN is enabled, the Test Suite uses that toolchain instead of the standard one.

# ----- Build the test suite for a generic reference system.

ORTS_DIR := $(ORBUILD_PROJECT_DIR)/TestSuite

ORTS_EXES_INSTALL_MAKEFLAGS_FILTER := pass-j

# Add --enable-debug=yes to ORTS_EXES_EXTRA_CONFIG_ARGS in order to enable debug builds.
ifeq "$(strip $(ENABLE_PGAVIN))" "1"
  ORTS_EXES_EXTRA_CONFIG_ARGS := --build=$$$$($(ORTS_DIR)/config.guess) --host=$(PGAVIN_OPENRISC_BARE_TARGET)
  # The 3 alternatives are: -mno-delay, -mdelay and -mcompat-delay
  ORTS_EXES_EXTRA_CONFIG_ARGS +=  CFLAGS="-mcompat-delay"  CXXFLAGS="-mcompat-delay"
  ORTS_EXES_AUTOCONF_PREPEND_PATH := $(PGAVIN_BARE_TOOLCHAIN_DIR)/bin
  ORTS_EXES_AUTOGEN_PARAM := $(PGAVIN_OPENRISC_BARE_TARGET)
else
  ORTS_EXES_EXTRA_CONFIG_ARGS := --build=$$$$($(ORTS_DIR)/config.guess) --host=$(OPENRISC_BARE_TARGET)
  ORTS_EXES_AUTOCONF_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin
  ORTS_EXES_AUTOGEN_PARAM := $(OPENRISC_BARE_TARGET)
endif

ORTS_EXES_EXTRA_GLOBAL_MAKE_ARGS := --no-builtin-rules

$(eval $(call autotool_project_template,ORTS_EXES,OpenRISC Test Suite executables,$(ORTS_DIR)))
ifeq "$(strip $(ENABLE_PGAVIN))" "1"
  $(ORTS_EXES_CONFIGURE_SENTINEL): $(PGAVIN_GCC_PHASE_2_INSTALL_SENTINEL)
else
  $(ORTS_EXES_CONFIGURE_SENTINEL): $(GCC_PHASE_2_INSTALL_SENTINEL)
endif

ORTS_EXES_AUTOGEN_CMD = $(SHELL) autogen.sh $(ORTS_EXES_AUTOGEN_PARAM)
$(eval $(call autogen_project_template,ORTS_EXES,OpenRISC Test Suite executables))

# During development, it's quite convenient to rerun the tests without rebuilding
# all other components. Uncomment one of the following lines to reconfigure, rebuild and rerun just the tests
# on each "./orbuild --resume" run:
# Just rebuild and rerun:
#   $(shell rm $(ORBUILD_AUTOCONF_SENTINELS_DIR)/ORTS_EXES.Make.$(ORBUILD_SENTINEL_FILENAME_SUFFIX))
# Reconfigure, rebuild and rerun:
#   $(shell rm $(ORBUILD_AUTOCONF_SENTINELS_DIR)/ORTS_EXES.Autogen.$(ORBUILD_SENTINEL_FILENAME_SUFFIX))
# Force a rebuild of all simulators and a re-run of all tests every time, for development purposes only.
# There is a special rule in RunTestSuiteMakefile so that deleting this file re-runs everything.
   $(shell rm $(ORBUILD_AUTOCONF_SENTINELS_DIR)/ORTS_EXES.Install.$(ORBUILD_SENTINEL_FILENAME_SUFFIX))


# Build the "GDB to JTAG Bridge" as a standard autoconf project.

OR10_GDB_JTAG_BRIDGE_EXTRA_CONFIG_ARGS := --enable-debug=yes --enable-jsp-server=no  # When development has settled down, turn off the debug build here.
OR10_GDB_JTAG_BRIDGE_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
OR10_GDB_JTAG_BRIDGE_MAKE_MAKEFLAGS_FILTER  := pass-j
$(eval $(call autotool_project_template,OR10_GDB_JTAG_BRIDGE,OR10 GDB to JTAG Bridge,$(ORBUILD_PROJECT_DIR)/OR10/GdbToJtagBridge))

# Before running the standard autoconf project operations, let autoconf generate the necessary files.
OR10_GDB_JTAG_BRIDGE_AUTOGEN_CMD = $(SHELL) autogen.sh
$(eval $(call autogen_project_template,OR10_GDB_JTAG_BRIDGE,OR10 GDB to JTAG Bridge))

ifeq "$(strip $(ENABLE_ORTS_OR10))" "1"
  all: $(OR10_GDB_JTAG_BRIDGE_INSTALL_SENTINEL)
endif


# ----- Run the test suite against different targets.

ifeq "$(strip $(ENABLE_PGAVIN))" "1"
  ORTS_OR1KSIM_PREPEND_PATH    := $(PGAVIN_OR1KSIM_BIN_DIR)/bin
  ORTS_TOOLCHAIN_PATH          := $(PGAVIN_BARE_TOOLCHAIN_DIR)/bin
  # The following setting can be set to either 'with-jump-delay-slot' or 'without-jump-delay-slot'.
  # The or1ksim simulator is started in the given mode, and one of the assembler test cases
  # is chosen based on this setting. The C/C++ test cases are all compiled with -mcompat-delay (see above),
  # but they can manually be compiled in other modes by modifying this makefile.
  ORTS_OR1KSIM_JUMP_DELAY_SLOT := with-jump-delay-slot
else
  ORTS_OR1KSIM_PREPEND_PATH    := $(OR1KSIM_BIN_DIR)/bin
  ORTS_TOOLCHAIN_PATH          := $(BARE_TOOLCHAIN_DIR)/bin
  ORTS_OR1KSIM_JUMP_DELAY_SLOT := with-jump-delay-slot
endif

# If a path contains multiple elements, use a xxx_LIST variable here (which allows more flexibility in the fugure),
# and convert it below to a colon-separated string.
ORTS_ORPSOC_IVERILOG_PREPEND_PATH_LIST := $(IVERILOG_PATH)  $(ORTS_TOOLCHAIN_PATH)
ORTS_MINSOC_IVERILOG_PREPEND_LIST      := $(IVERILOG_PATH)  $(ORTS_TOOLCHAIN_PATH)
ORTS_OR10_VERILATOR_PREPEND_PATH_LIST  := $(VERILATOR_PATH) $(ORTS_TOOLCHAIN_PATH)
ORTS_OR10_IVERILOG_PREPEND_PATH_LIST   := $(IVERILOG_PATH)  $(ORTS_TOOLCHAIN_PATH)

ORTS_PGAVIN_CGEN_PREPEND_PATH     := $(PGAVIN_BINUTILS_PHASE_2_BIN_DIR)/bin
ORTS_ORPSOC_IVERILOG_PREPEND_PATH := $(subst $(SPACE_CHAR),$(COLON_CHAR),$(strip $(ORTS_ORPSOC_IVERILOG_PREPEND_PATH_LIST)))
ORTS_MINSOC_IVERILOG_PREPEND_PATH := $(subst $(SPACE_CHAR),$(COLON_CHAR),$(strip $(ORTS_MINSOC_IVERILOG_PREPEND_LIST)))
ORTS_OR10_VERILATOR_PREPEND_PATH  := $(subst $(SPACE_CHAR),$(COLON_CHAR),$(strip $(ORTS_OR10_VERILATOR_PREPEND_PATH_LIST)))
ORTS_OR10_IVERILOG_PREPEND_PATH   := $(subst $(SPACE_CHAR),$(COLON_CHAR),$(strip $(ORTS_OR10_IVERILOG_PREPEND_PATH_LIST)))
ORTS_OR10_ISIM_PREPEND_PATH       := $(ORTS_TOOLCHAIN_PATH)


ORTS_COMMON_CMD := \"$(ORBUILD_PROJECT_DIR)/Tools/RunTestSuite.sh\"
ORTS_COMMON_CMD += OrtsPublicReports
ORTS_COMMON_CMD += TestReport.html
ORTS_COMMON_CMD += \"$(ORTS_EXES_BIN_DIR)\"
ORTS_COMMON_CMD += \"$(ORTS_EXES_INSTALL_SENTINEL)\"
ORTS_COMMON_CMD += \"$(ORPSOCV2_CHECKOUT_DIR)\"
ORTS_COMMON_CMD += \"$(MINSOC_CHECKOUT_DIR)\"
ORTS_COMMON_CMD += \"$(JTAG_DPI_CHECKOUT_DIR)\"
ORTS_COMMON_CMD += \"$(UART_DPI_CHECKOUT_DIR)\"
ORTS_COMMON_CMD += \"$(ETHERNET_DPI_CHECKOUT_DIR)\"

ifeq "$(strip $(ENABLE_PGAVIN))" "1"
  ORTS_COMMON_CMD += $(PGAVIN_OPENRISC_BARE_TARGET)
else
  ORTS_COMMON_CMD += $(OPENRISC_BARE_TARGET)
endif

ORTS_OR1KSIM_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_OR1KSIM
ORTS_OR1KSIM_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_OR1KSIM_OBJ_DIR)\" ORTS_OR1KSIM $(ORTS_OR1KSIM_JUMP_DELAY_SLOT) with-mac-instructions
ORTS_OR1KSIM_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_OR1KSIM,Test Suite against or1ksim,$(SHELL) -c "$(ORTS_OR1KSIM_CMD)"))

ORTS_PGAVIN_CGEN_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_PGAVIN_CGEN
ORTS_PGAVIN_CGEN_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_PGAVIN_CGEN_OBJ_DIR)\" ORTS_PGAVIN_CGEN with-jump-delay-slot with-mac-instructions
ORTS_PGAVIN_CGEN_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_PGAVIN_CGEN,Test Suite against Peter Gavin's CGEN simulator,$(SHELL) -c "$(ORTS_PGAVIN_CGEN_CMD)"))

ORTS_ORPSOC_IVERILOG_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_ORPSOC_IVERILOG
ORTS_ORPSOC_IVERILOG_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_ORPSOC_IVERILOG_OBJ_DIR)\" ORTS_ORPSOC_IVERILOG with-jump-delay-slot with-mac-instructions
ORTS_ORPSOC_IVERILOG_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_ORPSOC_IVERILOG,Test Suite against ORPSoC V2 with Icarus Verilog,$(SHELL) -c "$(ORTS_ORPSOC_IVERILOG_CMD)"))

ORTS_MINSOC_IVERILOG_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_MINSOC_IVERILOG
ORTS_MINSOC_IVERILOG_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_MINSOC_IVERILOG_OBJ_DIR)\" ORTS_MINSOC_IVERILOG with-jump-delay-slot with-mac-instructions
ORTS_MINSOC_IVERILOG_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_MINSOC_IVERILOG,Test Suite against MinSoC with Icarus Verilog,$(SHELL) -c "$(ORTS_MINSOC_IVERILOG_CMD)"))

ORTS_OR10_VERILATOR_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_OR10_VERILATOR
ORTS_OR10_VERILATOR_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_OR10_VERILATOR_OBJ_DIR)\" ORTS_OR10_VERILATOR without-jump-delay-slot without-mac-instructions
ORTS_OR10_VERILATOR_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_OR10_VERILATOR,Test Suite against or10 with Verilator,$(SHELL) -c "$(ORTS_OR10_VERILATOR_CMD)"))

ORTS_OR10_IVERILOG_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_OR10_IVERILOG
ORTS_OR10_IVERILOG_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_OR10_IVERILOG_OBJ_DIR)\" ORTS_OR10_IVERILOG without-jump-delay-slot without-mac-instructions
ORTS_OR10_IVERILOG_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_OR10_IVERILOG,Test Suite against or10 with Icarus Verilog,$(SHELL) -c "$(ORTS_OR10_IVERILOG_CMD)"))

ORTS_OR10_ISIM_OBJ_DIR := $(ORBUILD_BUILD_DIR)/temp/ORTS_OR10_ISIM
ORTS_OR10_ISIM_CMD := $(ORTS_COMMON_CMD) \"$(ORTS_OR10_ISIM_OBJ_DIR)\" ORTS_OR10_ISIM without-jump-delay-slot without-mac-instructions
ORTS_OR10_ISIM_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ORTS_OR10_ISIM,Test Suite against or10 with Xilinx' ISim,$(SHELL) -c "$(ORTS_OR10_ISIM_CMD)"))

.PHONY: orts_subproject_files
orts_subproject_files:
	echo "OpenRISC Test Suite = $(ORTS_EXES_AUTOTOOLS_GROUP) ORTS_OR1KSIM ORTS_PGAVIN_CGEN ORTS_ORPSOC_IVERILOG ORTS_MINSOC_IVERILOG ORTS_OR10_VERILATOR ORTS_OR10_IVERILOG ORTS_OR10_ISIM" >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "ORTS_OR1KSIM = $(ORTS_OR1KSIM_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "ORTS_PGAVIN_CGEN = $(ORTS_PGAVIN_CGEN_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "ORTS_ORPSOC_IVERILOG = $(ORTS_ORPSOC_IVERILOG_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "ORTS_MINSOC_IVERILOG = $(ORTS_MINSOC_IVERILOG_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "ORTS_OR10_VERILATOR = $(ORTS_OR10_VERILATOR_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "ORTS_OR10_IVERILOG = $(ORTS_OR10_IVERILOG_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "ORTS_OR10_ISIM = $(ORTS_OR10_ISIM_OBJ_DIR)/OrtsPublicReports/TestReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)

ifeq "$(strip $(ENABLE_PGAVIN))" "1"
  $(ORTS_OR1KSIM_SENTINEL)       : $(ORTS_EXES_INSTALL_SENTINEL) $(PGAVIN_OR1KSIM_INSTALL_SENTINEL)
else
  $(ORTS_OR1KSIM_SENTINEL)       : $(ORTS_EXES_INSTALL_SENTINEL) $(OR1KSIM_INSTALL_SENTINEL)
endif
$(ORTS_PGAVIN_CGEN_SENTINEL)     : $(ORTS_EXES_INSTALL_SENTINEL) $(PGAVIN_BINUTILS_PHASE_2_INSTALL_SENTINEL)
$(ORTS_ORPSOC_IVERILOG_SENTINEL) : $(ORTS_EXES_INSTALL_SENTINEL) $(IVERILOG_PREREQ)  $(value $(ORPSOC_NAME)_SW_UTILS_CMD_SENTINEL)
$(ORTS_MINSOC_IVERILOG_SENTINEL) : $(ORTS_EXES_INSTALL_SENTINEL) $(IVERILOG_PREREQ)  $(MINSOC_SW_UTILS_CMD_SENTINEL)
$(ORTS_OR10_VERILATOR_SENTINEL)  : $(ORTS_EXES_INSTALL_SENTINEL) $(VERILATOR_PREREQ) $(MINSOC_SW_UTILS_CMD_SENTINEL)
$(ORTS_OR10_IVERILOG_SENTINEL)   : $(ORTS_EXES_INSTALL_SENTINEL) $(IVERILOG_PREREQ)  $(MINSOC_SW_UTILS_CMD_SENTINEL)
$(ORTS_OR10_ISIM_SENTINEL)       : $(ORTS_EXES_INSTALL_SENTINEL) $(MINSOC_SW_UTILS_CMD_SENTINEL)

ifeq "$(strip $(ENABLE_OPEN_RISC_TEST_SUITE))" "1"
  all: $(ORTS_OR1KSIM_SENTINEL)

  ifeq "$(strip $(ENABLE_ORTS_ORPSOC))" "1"
    all: $(ORTS_ORPSOC_IVERILOG_SENTINEL)
  endif

  # We cannot run the Test Suite against MinSoC yet, as its l.nop instruction does not support
  # special simulation codes like NOP_REPORT or NOP_EXIT.
  #    all: $(ORTS_MINSOC_IVERILOG_SENTINEL)

  ifeq "$(strip $(ENABLE_ORTS_OR10))" "1"
    all: $(ORTS_OR10_VERILATOR_SENTINEL)
    all: $(ORTS_OR10_IVERILOG_SENTINEL)
    ifeq "$(strip $(ENABLE_XILINX))" "1"
      all: $(ORTS_OR10_ISIM_SENTINEL)
    endif
  endif

  ifeq "$(strip $(ENABLE_PGAVIN))" "1"
    # TODO: Disabled for the time being, as it fails many tests and forever hangs for at least one of them.
    #   all: $(ORTS_PGAVIN_CGEN_SENTINEL)
  endif

  all: orts_subproject_files
endif


# -------------- eCos realtime operating system --------------

# Build eCos with a simple "Hello World" application.

# I'm getting sporadic errors like this:
#   mkdir: cannot create directory `cyg': File exists
# I suspect the config tool's makefile breaks in the 'make' phase when running in parallel mode.
ECOS_CONFIG_TOOL_MAKE_MAKEFLAGS_FILTER    := clear
ECOS_CONFIG_TOOL_INSTALL_MAKEFLAGS_FILTER := clear
$(eval $(call autotool_project_template,ECOS_CONFIG_TOOL,eCos config tool,$(ECOS_CHECKOUT_DIR)/host))
$(ECOS_CONFIG_TOOL_CONFIGURE_SENTINEL): $(ECOS_CHECKOUT_SENTINEL)

ECOS_OBJ_DIR := $(ORBUILD_BUILD_DIR)/bin/ECOS
ECOS_BUILD_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin
ECOS_BUILD_CMD := $(ORBUILD_PROJECT_DIR)/eCosTools/BuildEcos.sh \"$(ECOS_CHECKOUT_DIR)\" \"$(ECOS_CONFIG_TOOL_BIN_DIR)\" \"$(ECOS_OBJ_DIR)\"
ECOS_BUILD_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ECOS_BUILD,eCos build,$(SHELL) -c "$(ECOS_BUILD_CMD)"))
$(ECOS_BUILD_SENTINEL): $(ECOS_CONFIG_TOOL_INSTALL_SENTINEL) $(GCC_PHASE_2_INSTALL_SENTINEL)

ifeq "$(strip $(ENABLE_ECOS))" "1"
  all: $(ECOS_BUILD_SENTINEL)
endif


# Run the eCos-based "Hello World" application on the or1ksim simulator.

ECOS_TEST_OBJ_DIR := $(ORBUILD_BUILD_DIR)/bin/ECOS_TEST
ECOS_TEST_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin:$(OR1KSIM_BIN_DIR)/bin
ECOS_TEST_CMD := $(ORBUILD_PROJECT_DIR)/eCosTools/TestEcos.sh \"$(ECOS_OBJ_DIR)\" \"$(ECOS_TEST_OBJ_DIR)\"
ECOS_TEST_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ECOS_TEST,eCos simple test,$(SHELL) -c "$(ECOS_TEST_CMD)"))

$(ECOS_TEST_SENTINEL): $(ECOS_BUILD_SENTINEL) $(OR1KSIM_INSTALL_SENTINEL)

ifeq "$(strip $(ENABLE_ECOS_TEST))" "1"
  all: $(ECOS_TEST_SENTINEL)
endif


# -------------- eCos' Redboot with Ethernet support --------------

# Build eCos' Redboot bootloader, which has a serial-port debug console and an ethernet interface.

ECOS_REDBOOT_OBJ_DIR := $(ORBUILD_BUILD_DIR)/bin/ECOS_REDBOOT
ECOS_REDBOOT_BUILD_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin
ECOS_REDBOOT_BUILD_CMD := $(ORBUILD_PROJECT_DIR)/eCosTools/BuildEcosRedboot.sh \"$(ECOS_CHECKOUT_DIR)\" \"$(ECOS_CONFIG_TOOL_BIN_DIR)\" \"$(ECOS_REDBOOT_OBJ_DIR)\"
ECOS_REDBOOT_BUILD_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,ECOS_REDBOOT_BUILD,eCos Redboot build,$(SHELL) -c "$(ECOS_REDBOOT_BUILD_CMD)"))
$(ECOS_REDBOOT_BUILD_SENTINEL): $(ECOS_CONFIG_TOOL_INSTALL_SENTINEL) $(GCC_PHASE_2_INSTALL_SENTINEL)

ifeq "$(strip $(ENABLE_ECOS_REDBOOT))" "1"
  all: $(ECOS_REDBOOT_BUILD_SENTINEL)
endif


# Run eCos' Redboot bootloader on the or1ksim simulator.

ECOS_REDBOOT_TEST_OR1KSIM_OBJ_DIR := $(ORBUILD_BUILD_DIR)/bin/ECOS_REDBOOT_TEST_OR1KSIM
ECOS_REDBOOT_TEST_OR1KSIM_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin:$(OR1KSIM_BIN_DIR)/bin
ECOS_REDBOOT_TEST_OR1KSIM_CMD := $(ORBUILD_PROJECT_DIR)/eCosTools/TestEcosRedbootOr1ksim.sh \"$(ECOS_REDBOOT_OBJ_DIR)\" \"$(ECOS_REDBOOT_TEST_OR1KSIM_OBJ_DIR)\"
ECOS_REDBOOT_TEST_OR1KSIM_MAKEFLAGS_FILTER := clear
$(eval $(call run_and_report_template,ECOS_REDBOOT_TEST_OR1KSIM,eCos Redboot or1ksim test,$(SHELL) -c "$(ECOS_REDBOOT_TEST_OR1KSIM_CMD)"))

$(ECOS_REDBOOT_TEST_OR1KSIM_SENTINEL): $(ECOS_REDBOOT_BUILD_SENTINEL) $(OR1KSIM_INSTALL_SENTINEL)
ifeq "$(strip $(ENABLE_ECOS_REDBOOT_TEST_OR1KSIM))" "1"
  all: $(ECOS_REDBOOT_TEST_OR1KSIM_SENTINEL)
endif


# Run eCos' Redboot bootloader on a Verilator simulation.
ECOS_REDBOOT_TEST_VERILATOR_OBJ_DIR := $(ORBUILD_BUILD_DIR)/bin/ECOS_REDBOOT_TEST_VERILATOR
# TODO: adjust this path:
ECOS_REDBOOT_TEST_VERILATOR_PREPEND_PATH := $(BARE_TOOLCHAIN_DIR)/bin:$(OR1KSIM_BIN_DIR)/bin
ECOS_REDBOOT_TEST_VERILATOR_CMD := $(ORBUILD_PROJECT_DIR)/eCosTools/TestEcosRedbootVerilator.sh \"$(ECOS_REDBOOT_OBJ_DIR)\" \"$(ECOS_REDBOOT_TEST_VERILATOR_OBJ_DIR)\"
ECOS_REDBOOT_TEST_VERILATOR_MAKEFLAGS_FILTER := clear
$(eval $(call run_and_report_template,ECOS_REDBOOT_TEST_VERILATOR,eCos Redboot verilator test,$(SHELL) -c "$(ECOS_REDBOOT_TEST_VERILATOR_CMD)"))

$(ECOS_REDBOOT_TEST_VERILATOR_SENTINEL): $(ECOS_REDBOOT_BUILD_SENTINEL) $(OR1KSIM_INSTALL_SENTINEL)  # TODO: adjust
ifeq "$(strip $(ENABLE_ECOS_REDBOOT_TEST_VERILATOR))" "1"
  all: $(ECOS_REDBOOT_TEST_VERILATOR_SENTINEL)
endif


# -------------- LLVM/Clang --------------

# Create the symbolic link from the LLVM repository to the Clang repository.

LINK_FROM_LVM_TO_CLANG_LINK_NAME   := $(LLVM_CHECKOUT_DIR)/tools/clang
LINK_FROM_LVM_TO_CLANG_LINK_TARGET := $(LLVM_CLANG_CHECKOUT_DIR)

LINK_FROM_LVM_TO_CLANG_CMD := if [ -h \"$(LINK_FROM_LVM_TO_CLANG_LINK_NAME)\" ]; then echo \"Deleting previous symbolic link $(LINK_FROM_LVM_TO_CLANG_LINK_NAME)...\" && rm \"$(LINK_FROM_LVM_TO_CLANG_LINK_NAME)\"; fi &&
LINK_FROM_LVM_TO_CLANG_CMD += echo \"Creating symbolic link from the LLVM repository to the Clang repository...\" && ln --symbolic --no-dereference --force \"$(LINK_FROM_LVM_TO_CLANG_LINK_TARGET)\" \"$(LINK_FROM_LVM_TO_CLANG_LINK_NAME)\"
LINK_FROM_LVM_TO_CLANG_MAKEFLAGS_FILTER := clear
$(eval $(call run_and_report_template,LINK_FROM_LVM_TO_CLANG,Symbolic link from LLVM to Clang,$(SHELL) -c "$(LINK_FROM_LVM_TO_CLANG_CMD)"))
$(LINK_FROM_LVM_TO_CLANG_SENTINEL): $(LLVM_CHECKOUT_SENTINEL) $(LLVM_CLANG_CHECKOUT_SENTINEL)


# Build LLVM/Clang.

LLVM_CLANG_EXTRA_GLOBAL_MAKE_ARGS   := $(FASTER_MAKE)
LLVM_TOOLCHAIN_BIN_DIR := $(ORBUILD_BUILD_DIR)/bin/LlvmToolchain
LLVM_LINUX_SYSROOT := $(LLVM_TOOLCHAIN_BIN_DIR)/$(LLVM_LINUX_TARGET)/sys-root

LLVM_CLANG_EXTRA_CONFIG_ARGS        := CC=gcc CXX=g++
# When this process has proved stable, replace --enable-debug-runtime with --enable-optimized
LLVM_CLANG_EXTRA_CONFIG_ARGS        += --enable-debug-runtime
# Without this switch, all targets are built, which is a waste of compilation time for our purposes.
LLVM_CLANG_EXTRA_CONFIG_ARGS        += --enable-targets=$(LLVM_ARCH)
# Switch "--with-sysroot" is needed only for Linux support. The same LLVM toolchain can build
# "bare metal" executables though:
#   clang -ccc-host-triple or1k-elf    # Builds bare metal executables.
#   clang -ccc-host-triple or1k-linux  # Builds Linux executables.
LLVM_CLANG_EXTRA_CONFIG_ARGS        += --with-default-sysroot=$(LLVM_LINUX_SYSROOT)

LLVM_CLANG_MAKE_MAKEFLAGS_FILTER    := pass-j
LLVM_CLANG_INSTALL_MAKEFLAGS_FILTER := clear  # No need to risk it here.
LLVM_CLANG_BIN_DIR := $(LLVM_TOOLCHAIN_BIN_DIR)

$(eval $(call autotool_project_template,LLVM_CLANG,LLVM/Clang,$(LLVM_CHECKOUT_DIR)))

$(LLVM_CLANG_CONFIGURE_SENTINEL): $(LINK_FROM_LVM_TO_CLANG_SENTINEL)

ifeq "$(strip $(ENABLE_LLVM))" "1"
  all: $(LLVM_CLANG_INSTALL_SENTINEL)
endif


# Test LLVM/Clang.
LLVM_CLANG_CHECK_TESTS_CMD := cd $(LLVM_CLANG_OBJ_DIR) &&
# The following tests the compiler for the current build computer, not for the target,
# but the toolchain only supports the or1k target now.
# LLVM_CLANG_CHECK_TESTS_CMD += make $(FASTER_MAKE) check &&
LLVM_CLANG_CHECK_TESTS_CMD += make TESTSUITE=CodeGen/OR1K $(FASTER_MAKE) check &&
LLVM_CLANG_CHECK_TESTS_CMD += make TESTSUITE=MC/OR1K      $(FASTER_MAKE) check
LLVM_CLANG_CHECK_TESTS_MAKEFLAGS_FILTER := pass-j

$(eval $(call run_makefile_and_report_template,LLVM_CLANG_CHECK_TESTS,LLVM/Clang checks,$(SHELL) -c "$(LLVM_CLANG_CHECK_TESTS_CMD)"))

$(LLVM_CLANG_CHECK_TESTS_SENTINEL): $(LLVM_CLANG_INSTALL_SENTINEL)

ifeq "$(strip $(ENABLE_LLVM_CHECK))" "1"
  all: $(LLVM_CLANG_CHECK_TESTS_SENTINEL)
endif


# -------------- Report grouping --------------

SVN_CHECKOUT_GROUP := OR1KSIM_SVN_CHECKOUT
SVN_CHECKOUT_GROUP += DOCS_SVN_CHECKOUT   
SVN_CHECKOUT_GROUP += ORPSOCV2_SVN_CHECKOUT
SVN_CHECKOUT_GROUP += GNUSRC_SVN_CHECKOUT
SVN_CHECKOUT_GROUP += MINSOC_SVN_CHECKOUT
SVN_CHECKOUT_GROUP += ECOS_SVN_CHECKOUT

BARE_TOOLCHAIN_GROUP := $(BINUTILS_AUTOTOOLS_GROUP)
BARE_TOOLCHAIN_GROUP += $(GCC_PHASE_1_AUTOTOOLS_GROUP)
BARE_TOOLCHAIN_GROUP += $(NEWLIB_AUTOTOOLS_GROUP)
BARE_TOOLCHAIN_GROUP += $(GCC_PHASE_2_AUTOTOOLS_GROUP)
BARE_TOOLCHAIN_GROUP += $(OR1KSIM_AUTOTOOLS_GROUP)
BARE_TOOLCHAIN_GROUP += $(GDB_AUTOTOOLS_GROUP)

VERILOG_TOOLS_GROUP := $(ICARUS_VERILOG_AUTOTOOLS_GROUP)
VERILOG_TOOLS_GROUP += $(VERILATOR_AUTOTOOLS_GROUP)

PGAVIN_TOOLCHAIN_GROUP := PGAVIN_LINUX_HEADERS
PGAVIN_TOOLCHAIN_GROUP += PGAVIN_LINUX_UCLIBC
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_BINUTILS_PHASE_1_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_BINUTILS_PHASE_2_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_GCC_PHASE_1_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_GCC_PHASE_2_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_OR1KSIM_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_LINUX_BINUTILS_PHASE_1_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_LINUX_GCC_PHASE_1_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(PGAVIN_LINUX_GCC_PHASE_2_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(LINUX_GDB_AUTOTOOLS_GROUP)
PGAVIN_TOOLCHAIN_GROUP += $(GDBSERVER_AUTOTOOLS_GROUP)

LLVM_CLANG_GROUP := LLVM_CLANG_CHECK_TESTS
LLVM_CLANG_GROUP += LINK_FROM_LVM_TO_CLANG
LLVM_CLANG_GROUP += $(LLVM_CLANG_AUTOTOOLS_GROUP)

LLVM_CLANG_REPOS_GROUP := $(LLVM_GIT_GROUP)
LLVM_CLANG_REPOS_GROUP += $(LLVM_CLANG_GIT_GROUP)
LLVM_CLANG_REPOS_GROUP += $(LLVM_OR1K_SRC_GIT_GROUP)
LLVM_CLANG_REPOS_GROUP += $(LLVM_COMPILER_RT_OR1K_GIT_GROUP)
LLVM_CLANG_REPOS_GROUP += $(LLVM_UCLIBC_GIT_GROUP)

PGAVIN_GIT_GROUP := $(PGAVIN_LINUX_GIT_GROUP)
PGAVIN_GIT_GROUP += $(PGAVIN_OR1KSIM_GIT_GROUP)
PGAVIN_GIT_GROUP += $(PGAVIN_UCLIBC_GIT_GROUP)
PGAVIN_GIT_GROUP += $(PGAVIN_OR1K_SRC_GIT_GROUP)
PGAVIN_GIT_GROUP += $(PGAVIN_OR1K_GCC_GIT_GROUP)

ECOS_GROUP := $(ECOS_CONFIG_TOOL_AUTOTOOLS_GROUP)
ECOS_GROUP += ECOS_BUILD
ECOS_GROUP += ECOS_TEST
ECOS_GROUP += ECOS_REDBOOT_BUILD
ECOS_GROUP += ECOS_REDBOOT_TEST_OR1KSIM
ECOS_GROUP += ECOS_REDBOOT_TEST_VERILATOR

GIT_GROUP := $(JBONN_LINUX_GIT_GROUP)
GIT_GROUP += $(JBONN_UCLIBC_GIT_GROUP)
GIT_GROUP += $(ICARUS_VERILOG_GIT_GROUP)
GIT_GROUP += $(VERILATOR_GIT_GROUP)
GIT_GROUP += $(UART_DPI_GIT_GROUP)
GIT_GROUP += $(JTAG_DPI_GIT_GROUP)
GIT_GROUP += $(ETHERNET_DPI_GIT_GROUP)

.PHONY: generate_groups_file
generate_groups_file:
	echo "Subversion Repositories        = $(SVN_CHECKOUT_GROUP)"     >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "Bare Toolchain                 = $(BARE_TOOLCHAIN_GROUP)"   >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "Verilog Tools                  = $(VERILOG_TOOLS_GROUP)"    >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "Peter Gavin's Toolchain        = $(PGAVIN_TOOLCHAIN_GROUP)" >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "Peter Gavin's Repositories     = $(PGAVIN_GIT_GROUP)"       >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "LLVM/Clang                     = $(LLVM_CLANG_GROUP)"       >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "LLVM/Clang Git Repositories    = $(LLVM_CLANG_REPOS_GROUP)" >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "Lint results                   = $(LINT_GROUP)"             >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "eCos realtime operating system = $(ECOS_GROUP)"             >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "Git Repositories               = $(GIT_GROUP)"              >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)

all: generate_groups_file
