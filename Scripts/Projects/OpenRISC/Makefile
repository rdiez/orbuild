
.DELETE_ON_ERROR:

SHELL := bash  # This makefile has only been tested with bash.

include $(ORBUILD_SANDBOX)/Scripts/MakeModules/MakeUtils.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/DownloadAndUnpackTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RepositoryCheckoutTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/AutotoolsTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RunAndReportTemplates.mk


# ----------- General options -----------

# Option --no-builtin-variables implies --no-builtin-rules, which accelerates GNU Make considerably.
FASTER_MAKE := --no-builtin-variables

# This flag allows disabling the actual downloading of the source-control repository updates
# so as to prevent overloading the remote servers during development of this makefile.
# It must be set before using any of the repository checkout templates.
# In order for the build to work properly, the repositories must have been checked out at least one.
SKIP_REPOSITORY_UPDATE := 0

.PHONY: all


# ----------- OpenRISC-specific options -----------

OPENRISC_TARGET := --target=or32-elf

# In order for the GCC cross-compiler to automatically pick up the right assembler and so on,
# it must be configured to use the same bin directory as Binutils.
TOOLCHAIN_DIR := $(ORBUILD_BUILD_DIR)/ToolchainOr32


# ----------- Check out a number of OpenCores repositories under http://opencores.org/ocsvn/openrisc/openrisc/ -----------

# Each repository depends on the previous one, therefore they are checked out sequentially instead of in parallel,
# in order to prevent overloading the OpenCores server.

OR_SVN_BASE_URL := http://opencores.org/ocsvn/openrisc/openrisc/trunk

$(eval $(call subversion_checkout_template,OR1KSIM,or1ksim,$(OR_SVN_BASE_URL)/or1ksim))
all: $(OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call subversion_checkout_template,DOCS,OpenRISC docs,$(OR_SVN_BASE_URL)/docs))
all: $(DOCS_CHECKOUT_SENTINEL)
$(DOCS_CHECKOUT_SENTINEL): $(OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call subversion_checkout_template,ORPSOCV2,ORPSoC v2,$(OR_SVN_BASE_URL)/orpsocv2))
all: $(ORPSOCV2_CHECKOUT_SENTINEL)
$(ORPSOCV2_CHECKOUT_SENTINEL): $(DOCS_CHECKOUT_SENTINEL)

# This is the biggest repository by far, so it's the last one to be checked out from OpenCores.
$(eval $(call subversion_checkout_template,GNUSRC,GNU sources,$(OR_SVN_BASE_URL)/gnu-src))
all: $(GNUSRC_CHECKOUT_SENTINEL)
$(GNUSRC_CHECKOUT_SENTINEL): $(ORPSOCV2_CHECKOUT_SENTINEL)

all: $(GNUSRC_CHECKOUT_SENTINEL)


# ----------- Icarus Verilog -----------

ICARUS_VERILOG_EXTRA_GIT_CHECKOUT_ARGS := v0_9-branch
$(eval $(call git_checkout_template,ICARUS_VERILOG,Icarus Verilog test,git://github.com/steveicarus/iverilog.git))
all: $(ICARUS_VERILOG_CHECKOUT_SENTINEL)
# We don't actually need to create a local branch like this, checking out branch origin/v0_9-branch will probably do.
$(eval $(call git_branch_template,ICARUS_VERILOG,--track v0_9-branch origin/v0_9-branch))

ICARUS_VERILOG_EXTRA_INSTALL_ARGS := -j 1  # Icarus Verilog's "make install" breaks when running in parallel mode.
$(eval $(call autotool_project_template,ICARUS_VERILOG,Icarus Verilog,$(ICARUS_VERILOG_CHECKOUT_DIR)))

ICARUS_VERILOG_AUTOGEN_CMD = sh autoconf.sh
$(eval $(call autogen_project_template,ICARUS_VERILOG,Icarus Verilog))
$(ICARUS_VERILOG_AUTOGEN_SENTINEL): $(ICARUS_VERILOG_CHECKOUT_SENTINEL)

all: $(ICARUS_VERILOG_INSTALL_SENTINEL)


# ----------- Verilator -----------

$(eval $(call git_checkout_template,VERILATOR,Verilator,http://git.veripool.org/git/verilator))

# Build Verilator as a standard autoconf project.
VERILATOR_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
$(eval $(call autotool_project_template,VERILATOR,Verilator,$(VERILATOR_CHECKOUT_DIR)))
all: $(VERILATOR_INSTALL_SENTINEL)

# Before running the standard autoconf project operations, let autoconf generate the necessary files.
VERILATOR_AUTOGEN_CMD = autoconf --warnings=all
$(eval $(call autogen_project_template,VERILATOR,verilator))
$(VERILATOR_AUTOGEN_SENTINEL): $(VERILATOR_CHECKOUT_SENTINEL)

ifeq "0" "1"  # Run Verilator's install tests, disabled at the moment.
  # Verilator's install_test script sets its own -j flag for GNU Make, therefore remove any inherited flags from MAKEFLAGS.
  VERILATOR_INSTALL_TEST_CMD := export MAKEFLAGS=\"\" &&
  VERILATOR_INSTALL_TEST_CMD += cd $(VERILATOR_CHECKOUT_DIR) && perl nodist/install_test
  $(eval $(call run_and_report_template,VERILATOR_INSTALL_TEST,Verilator installation test,sh -c "$(VERILATOR_INSTALL_TEST_CMD)"))

  $(VERILATOR_INSTALL_TEST_SENTINEL): $(VERILATOR_INSTALL_SENTINEL)
  all: $(VERILATOR_INSTALL_TEST_SENTINEL)
endif


# ----------- or1ksim -----------

# Build or1ksim as a standard autoconf project.
OR1KSIM_EXTRA_CONFIG_ARGS := $(OPENRISC_TARGET)
OR1KSIM_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
$(eval $(call autotool_project_template,OR1KSIM,or1ksim,$(OR1KSIM_CHECKOUT_DIR)))
all: $(OR1KSIM_INSTALL_SENTINEL)
$(OR1KSIM_CONFIGURE_SENTINEL): $(OR1KSIM_CHECKOUT_SENTINEL)


# ----------- Binutils -----------

# Build Binutils as a standard autoconf project.
LOCAL_BINUTILS_SRC := $(GNUSRC_CHECKOUT_DIR)/binutils-2.20.1
BINUTILS_BIN_DIR := $(TOOLCHAIN_DIR)
# TODO: I am not sure whether --enable-fast-install=N/A or --disable-libssp are needed in BINUTILS_EXTRA_CONFIG_ARGS.
BINUTILS_EXTRA_CONFIG_ARGS := $(OPENRISC_TARGET) 
BINUTILS_EXTRA_MAKE_GLOBAL_ARGS := $(FASTER_MAKE)
# TODO: With the following targets, "make install" fails. I'm not sure which targets are the correct ones:
#       BINUTILS_MAKE_TARGETS := all-binutils all-gas all-ld all-build
BINUTILS_CHECK_TARGETS := check-binutils check-gas check-ld
$(eval $(call autotool_project_template,BINUTILS,Binutils,$(LOCAL_BINUTILS_SRC)))


all: $(BINUTILS_INSTALL_SENTINEL)
$(BINUTILS_CONFIGURE_SENTINEL): $(GNUSRC_CHECKOUT_SENTINEL)

# TODO: Some checks fail, investigate why.
#  all: $(BINUTILS_CHECK_SENTINEL)


# ----------- GCC cross-compiler for OpenRISC -----------

COMMON_GCC_OPTIONS :=
COMMON_GCC_OPTIONS += $(OPENRISC_TARGET)
COMMON_GCC_OPTIONS += --disable-shared
COMMON_GCC_OPTIONS += --with-or1ksim=$(OR1KSIM_BIN_DIR)
COMMON_GCC_OPTIONS += --with-newlib
COMMON_GCC_OPTIONS += --disable-libssp

COMMON_GCC_OPTIONS += --disable-multilib

COMMON_GCC_OPTIONS += --disable-lto

# ---------- GCC phase 1 ----------

# In order to build GCC, the OpenRISC binutils binaries are needed.
# TODO: replace with repository
GCC_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/gcc-4.5.1

GCC_PHASE_1_AUTOCONF_PREPEND_PATH := $(TOOLCHAIN_DIR)/bin
GCC_PHASE_1_BIN_DIR := $(TOOLCHAIN_DIR)

GCC_PHASE_1_EXTRA_CONFIG_ARGS        := $(COMMON_GCC_OPTIONS) --enable-languages=c --without-headers
GCC_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS   := $(FASTER_MAKE)
GCC_PHASE_1_MAKE_TARGETS             := all-gcc
GCC_PHASE_1_INSTALL_TARGETS          := install-gcc

$(eval $(call autotool_project_template,GCC_PHASE_1,GCC Phase 1,$(GCC_SRC_DIR)))

# In order to build GCC, the OpenRISC Binutils binaries are needed.
$(GCC_PHASE_1_CONFIGURE_SENTINEL): $(BINUTILS_INSTALL_SENTINEL)


# ---------- newlib ----------

NEWLIB_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/newlib-1.18.0
NEWLIB_BIN_DIR := $(TOOLCHAIN_DIR)
NEWLIB_AUTOCONF_PREPEND_PATH := $(TOOLCHAIN_DIR)/bin

NEWLIB_EXTRA_CONFIG_ARGS :=
NEWLIB_EXTRA_CONFIG_ARGS += $(OPENRISC_TARGET)
NEWLIB_EXTRA_CONFIG_ARGS += --disable-shared
NEWLIB_EXTRA_CONFIG_ARGS += --disable-multilib

NEWLIB_CHECK_TARGETS := check-target-newlib check-target-libgloss

$(eval $(call autotool_project_template,NEWLIB,Newlib,$(NEWLIB_SRC_DIR)))

$(NEWLIB_CONFIGURE_SENTINEL): $(GCC_PHASE_1_INSTALL_SENTINEL)


# ---------- GCC phase 2 ----------
# Note that this installs the final GCC binaries over the ones from phase 1.
# Although everything should be properly overwritten, this method does not look very clean to me.

GCC_PHASE_2_AUTOCONF_PREPEND_PATH := $(TOOLCHAIN_DIR)/bin
GCC_PHASE_2_BIN_DIR := $(TOOLCHAIN_DIR)

GCC_PHASE_2_EXTRA_CONFIG_ARGS := $(COMMON_GCC_OPTIONS) --enable-languages=c,c++
GCC_PHASE_2_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
GCC_PHASE_2_CHECK_TARGETS := check-gcc check-target-libgcc check-target-libstdc++-v3

$(eval $(call autotool_project_template,GCC_PHASE_2,GCC Phase 2,$(GCC_SRC_DIR)))

$(GCC_PHASE_2_CONFIGURE_SENTINEL): $(NEWLIB_INSTALL_SENTINEL)

all: $(GCC_PHASE_2_INSTALL_SENTINEL)


# ----------- GDB cross-debugger for OpenRISC -----------

GDB_SRC_DIR := $(GNUSRC_CHECKOUT_DIR)/gdb-7.2
GDB_BIN_DIR := $(TOOLCHAIN_DIR)
GDB_AUTOCONF_PREPEND_PATH := $(TOOLCHAIN_DIR)/bin

GDB_EXTRA_CONFIG_ARGS :=
GDB_EXTRA_CONFIG_ARGS += $(OPENRISC_TARGET)
GDB_EXTRA_CONFIG_ARGS += --with-or1ksim=$(OR1KSIM_BIN_DIR)

$(eval $(call autotool_project_template,GDB,GDB,$(GDB_SRC_DIR)))

$(GDB_CONFIGURE_SENTINEL): $(GCC_PHASE_2_INSTALL_SENTINEL)

all: $(GDB_INSTALL_SENTINEL)


# ----------- ORPSoC v2 -----------

ORPSOC_NAME := ORPSOC

# Build the documentation.
# Note that this step slightly pollutes the source repository it is run upon.
$(ORPSOC_NAME)_DOCUMENTATION_CMD := export MAKEFLAGS=\"$$(filter --jobserver-fds=%,$$(MAKEFLAGS)) $$(filter -j,$$(MAKEFLAGS))\" &&
$(ORPSOC_NAME)_DOCUMENTATION_CMD += cd $(ORPSOCV2_CHECKOUT_DIR)/doc && ./configure && make $(FASTER_MAKE) pdf
$(eval $(call run_makefile_and_report_template,$(ORPSOC_NAME)_DOCUMENTATION,ORPSoC v2 documentation,sh -c "$($(ORPSOC_NAME)_DOCUMENTATION_CMD)"))
all: $($(ORPSOC_NAME)_DOCUMENTATION_SENTINEL)

