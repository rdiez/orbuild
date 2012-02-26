
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

# This flag allows disabling the actual downloading to prevent overloading the remote servers during development of this makefile.
DISABLE_SUBVERSION_CHECKOUT := 0

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

$(eval $(call subversion_checkout_template,OR1KSIM,or1ksim,$(OR_SVN_BASE_URL)/or1ksim,$(ORBUILD_REPOSITORIES_TIMESTAMP)))
all: $(OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call subversion_checkout_template,DOCS,OpenRISC docs,$(OR_SVN_BASE_URL)/docs,$(ORBUILD_REPOSITORIES_TIMESTAMP)))
all: $(DOCS_CHECKOUT_SENTINEL)
$(DOCS_CHECKOUT_SENTINEL): $(OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call subversion_checkout_template,ORPSOCV2,ORPSoC v2,$(OR_SVN_BASE_URL)/orpsocv2,$(ORBUILD_REPOSITORIES_TIMESTAMP)))
all: $(ORPSOCV2_CHECKOUT_SENTINEL)
$(ORPSOCV2_CHECKOUT_SENTINEL): $(DOCS_CHECKOUT_SENTINEL)

# This is the biggest repository by far, so it's the last one to be checked out from OpenCores.
$(eval $(call subversion_checkout_template,GNUSRC,GNU sources,$(OR_SVN_BASE_URL)/gnu-src,$(ORBUILD_REPOSITORIES_TIMESTAMP)))
all: $(GNUSRC_CHECKOUT_SENTINEL)
$(GNUSRC_CHECKOUT_SENTINEL): $(ORPSOCV2_CHECKOUT_SENTINEL)

all: $(GNUSRC_CHECKOUT_SENTINEL)


# ----------- Verilator -----------

$(eval $(call git_checkout_template,VERILATOR,Verilator,http://git.veripool.org/git/verilator,$(ORBUILD_REPOSITORIES_TIMESTAMP)))

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

