
.DELETE_ON_ERROR:

SHELL := bash  # This makefile has only been tested with bash.

include $(ORBUILD_SANDBOX)/Scripts/MakeModules/MakeUtils.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/DownloadAndUnpackTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RepositoryCheckoutTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/AutotoolsTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RunAndReportTemplates.mk

.PHONY: all

# ----------- General options -----------

# Option --no-builtin-variables implies --no-builtin-rules, which accelerates GNU Make considerably.
FASTER_MAKE := --no-builtin-variables

# This flag allows disabling the actual downloading of the source-control repository updates
# so as to prevent overloading the remote servers during development of this makefile.
# It must be set before using any of the repository checkout templates.
# In order for the build to work properly, the repositories must have been checked out at least one.
SKIP_REPOSITORY_UPDATE := 0


# ----------- OpenRISC-specific options -----------

OPENRISC_TARGET := --target=or32-elf
PGAVIN_OPENRISC_TARGET := --target=or1k-elf

# In order for the GCC cross-compiler to automatically pick up the right assembler and so on,
# it must be configured to use the same bin directory as Binutils.
TOOLCHAIN_DIR := $(ORBUILD_BUILD_DIR)/ToolchainOr32
PGAVIN_TOOLCHAIN_DIR := $(ORBUILD_BUILD_DIR)/PGavinToolchainOr32


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

$(eval $(call subversion_checkout_template,MINSOC,MinSoC,$(OC_SVN_BASE_URL)/minsoc/minsoc/trunk))
all: $(MINSOC_CHECKOUT_SENTINEL)
$(MINSOC_CHECKOUT_SENTINEL): $(ORPSOCV2_CHECKOUT_SENTINEL)

# This is the biggest repository by far, so it's the last one to be checked out from OpenCores.
# WARNING: The OC_BLD_ALL task cleans the whole repository every time it runs.
$(eval $(call subversion_checkout_template,GNUSRC,GNU sources,$(OC_OR_SVN_BASE_URL)/gnu-src))
all: $(GNUSRC_CHECKOUT_SENTINEL)
$(GNUSRC_CHECKOUT_SENTINEL): $(MINSOC_CHECKOUT_SENTINEL)

all: $(GNUSRC_CHECKOUT_SENTINEL)


# ----------- Check out a number of Peter Gavin's repositories under https://github.com/pgavin/ -----------

# Each repository depends on the previous one, therefore they are checked out sequentially instead of in parallel,
# in order to prevent overloading the Github server.

PGAVIN_GIT_BASE_URL := git://github.com/pgavin

$(eval $(call git_checkout_template,PGAVIN_LINUX,Peter Gavin's Linux,$(PGAVIN_GIT_BASE_URL)/linux.git))
all: $(PGAVIN_LINUX_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_OR1KSIM,Peter Gavin's or1ksim,$(PGAVIN_GIT_BASE_URL)/or1ksim.git))
all: $(PGAVIN_OR1KSIM_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,PGAVIN_LINUX,PGAVIN_OR1KSIM))

$(eval $(call git_checkout_template,PGAVIN_UCLIBC,Peter Gavin's uClibc,$(PGAVIN_GIT_BASE_URL)/uClibc.git))
all: $(PGAVIN_UCLIBC_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,PGAVIN_OR1KSIM,PGAVIN_UCLIBC))

$(PGAVIN_UCLIBC_CHECKOUT_SENTINEL): $(PGAVIN_OR1KSIM_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_BINUTILS,Peter Gavin's Binutils,$(PGAVIN_GIT_BASE_URL)/binutils.git))
all: $(PGAVIN_BINUTILS_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,PGAVIN_UCLIBC,PGAVIN_BINUTILS))

$(eval $(call git_checkout_template,PGAVIN_NEWLIB,Peter Gavin's Newlib,$(PGAVIN_GIT_BASE_URL)/newlib-1.18.0.git))
all: $(PGAVIN_NEWLIB_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,PGAVIN_BINUTILS,PGAVIN_NEWLIB))

$(PGAVIN_NEWLIB_CHECKOUT_SENTINEL): $(PGAVIN_BINUTILS_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,PGAVIN_GCC,Peter Gavin's GCC,$(PGAVIN_GIT_BASE_URL)/gcc.git))
all: $(PGAVIN_GCC_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,PGAVIN_NEWLIB,PGAVIN_GCC))


# ----------- Jonas Bonn's repositories -----------

$(eval $(call git_checkout_template,JBONN_LINUX,Jonas Bon's Linux,git://openrisc.net/jonas/linux))
all: $(JBONN_LINUX_CHECKOUT_SENTINEL)

$(eval $(call git_checkout_template,JBONN_UCLIBC,Jonas Bon's uClibc,git://openrisc.net/jonas/uClibc))
all: $(JBONN_UCLIBC_CHECKOUT_SENTINEL)
$(eval $(call git_download_serializer_template,JBONN_LINUX,JBONN_UCLIBC))


# ----------- Icarus Verilog -----------

ICARUS_VERILOG_EXTRA_GIT_CHECKOUT_ARGS := v0_9-branch
$(eval $(call git_checkout_template,ICARUS_VERILOG,Icarus Verilog,git://github.com/steveicarus/iverilog.git))
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

# See "or1ksim distcheck" below, which must be after the GCC rules because it depends on $(GCC_PHASE_2_INSTALL_SENTINEL).


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


# ----------- or1ksim distcheck -----------
# Run a distcheck on the simulator, but use a different rule here (as opposed to the standard one provided by AutotoolsTemplates.mk),
# because the checks need to run with a different PATH as the one used to build the simulator.
# Note also that GNU Make's flag "--no-builtin-variables" (in variable FASTER_MAKE) is not compatible with distcheck.
SPECIAL_OR1KSIM_DISTCHECK_SENTINEL        := $(ORBUILD_BUILD_SENTINELS_DIR)/OR1KSIM.SpecialDistcheck.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)
SPECIAL_OR1KSIM_DISTCHECK_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/OR1KSIM.SpecialDistcheckLog.txt
SPECIAL_OR1KSIM_DISTCHECK_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/OR1KSIM.SpecialDistcheck.report

$(SPECIAL_OR1KSIM_DISTCHECK_SENTINEL): $(OR1KSIM_CONFIGURE_SENTINEL) $(GCC_PHASE_2_INSTALL_SENTINEL)
	  +echo "Distcheck or1ksim..." && \
      export MAKEFLAGS="$(filter --jobserver-fds=%,$(MAKEFLAGS)) $(filter -j,$(MAKEFLAGS))" && \
      PATH="$(TOOLCHAIN_DIR)/bin:$$PATH" \
        "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                      "or1ksim distcheck" \
                      "$(SPECIAL_OR1KSIM_DISTCHECK_LOG_FILENAME)" \
                      "$(SPECIAL_OR1KSIM_DISTCHECK_REPORT_FILENAME)" \
                      report-always \
          "$(ORBUILD_TOOLS)/AutoconfMake.sh" \
                  "$(OR1KSIM_OBJ_DIR)" \
                  "distcheck" \
                  "$(SPECIAL_OR1KSIM_DISTCHECK_SENTINEL)"

all: $(SPECIAL_OR1KSIM_DISTCHECK_SENTINEL)


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
# TODO: This rule triggers command "texi2dvi --pdf --batch orpsoc.texi", which fails under Cygwin.
#       The workaround seems to be issuing "export TEX=tex" beforehand, but I don't know yet
#       if that would introduce undesirable side-effects under Linux.
$(ORPSOC_NAME)_DOCUMENTATION_CMD := export MAKEFLAGS=\"$$(filter --jobserver-fds=%,$$(MAKEFLAGS)) $$(filter -j,$$(MAKEFLAGS))\" &&
$(ORPSOC_NAME)_DOCUMENTATION_CMD += cd $(ORPSOCV2_CHECKOUT_DIR)/doc && ./configure && make $(FASTER_MAKE) pdf
$(eval $(call run_makefile_and_report_template,$(ORPSOC_NAME)_DOCUMENTATION,ORPSoC v2 documentation,sh -c "$($(ORPSOC_NAME)_DOCUMENTATION_CMD)"))
all: $($(ORPSOC_NAME)_DOCUMENTATION_SENTINEL)


# Run some of the self-tests.
# Note that this step slightly pollutes the source repository its run upon.

# Clear variable MAKEFLAGS, as the rtl-tests target breaks when run in parallel mode.
#   $(ORPSOC_NAME)_RTL_TESTS_CMD := export MAKEFLAGS=\"$$(filter --jobserver-fds=%,$$(MAKEFLAGS)) $$(filter -j,$$(MAKEFLAGS))\" &&
$(ORPSOC_NAME)_RTL_TESTS_CMD := export MAKEFLAGS=\"\" &&
$(ORPSOC_NAME)_RTL_TESTS_CMD += cd $(ORPSOCV2_CHECKOUT_DIR)/sim/bin &&
$(ORPSOC_NAME)_RTL_TESTS_CMD += PATH=\"$(ICARUS_VERILOG_BIN_DIR)/bin:$(TOOLCHAIN_DIR)/bin:$$$$PATH\" &&
$(ORPSOC_NAME)_RTL_TESTS_CMD += make -j 1 rtl-tests  # About the "-j 1": The rtl-tests target breaks when run in parallel mode.

$(eval $(call run_makefile_and_report_template,$(ORPSOC_NAME)_RTL_TESTS,ORPSoC v2 RTL tests,sh -c "$($(ORPSOC_NAME)_RTL_TESTS_CMD)"))
all: $($(ORPSOC_NAME)_RTL_TESTS_SENTINEL)


# ----------- MinSoC -----------

# Test MinSoC's automatic installation script.
# This script downloads a repository and some files automatically, so skip it if we have disabled repository downloading.
ifeq "$(SKIP_REPOSITORY_UPDATE)" "0"

MINSOC_INSTALLATION_TEST_DIR := $(ORBUILD_BUILD_DIR)/MINSOC_INSTALLATION_SCRIPT

# TODO: MINSOC_INSTALLATION_TEST_CMD := export MAKEFLAGS=\"\" &&
MINSOC_INSTALLATION_TEST_CMD := PATH=\"$(TOOLCHAIN_DIR)/bin:$$$$PATH\" &&
MINSOC_INSTALLATION_TEST_CMD += $(ORBUILD_PROJECT_DIR)/MinsocInstallationTest.sh $(MINSOC_CHECKOUT_DIR) $(MINSOC_INSTALLATION_TEST_DIR)

$(eval $(call run_and_report_template,MINSOC_INSTALLATION_SCRIPT,MinSoC's installation script,bash -c "$(MINSOC_INSTALLATION_TEST_CMD)"))
$(MINSOC_INSTALLATION_SCRIPT_SENTINEL): $(MINSOC_CHECKOUT_SENTINEL)
all: $(MINSOC_INSTALLATION_SCRIPT_SENTINEL)

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

OC_BLD_ALL_CMD := export MAKEFLAGS=\"\" &&
OC_BLD_ALL_CMD += $(ORBUILD_TOOLS)/SvnCleanRepo.sh $(GNUSRC_CHECKOUT_DIR) &&
OC_BLD_ALL_CMD += cd $(GNUSRC_CHECKOUT_DIR) &&
OC_BLD_ALL_CMD += ./bld-all.sh $(OC_BLD_ARGS)

$(eval $(call run_and_report_template,OC_BLD_ALL,OpenCore's gnu-src bld-all.sh,bash -c "$(OC_BLD_ALL_CMD)"))
$(OC_BLD_ALL_SENTINEL): $(GDB_INSTALL_SENTINEL) $(JBONN_LINUX_CHECKOUT_SENTINEL) $(JBONN_UCLIBC_CHECKOUT_SENTINEL)

all: $(OC_BLD_ALL_SENTINEL)


# ----------- Peter Gavin's or1ksim -----------

# Build or1ksim as a standard autoconf project.
PGAVIN_OR1KSIM_EXTRA_CONFIG_ARGS := $(PGAVIN_OPENRISC_TARGET)
PGAVIN_OR1KSIM_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
$(eval $(call autotool_project_template,PGAVIN_OR1KSIM,Peter Gavin's or1ksim,$(PGAVIN_OR1KSIM_CHECKOUT_DIR)))
all: $(PGAVIN_OR1KSIM_INSTALL_SENTINEL)
$(PGAVIN_OR1KSIM_CONFIGURE_SENTINEL): $(PGAVIN_OR1KSIM_CHECKOUT_SENTINEL)


# ----------- Peter Gavin's Binutils -----------

# Build Binutils as a standard autoconf project.
PGAVIN_BINUTILS_BIN_DIR := $(PGAVIN_TOOLCHAIN_DIR)
# TODO: I am not sure whether --enable-fast-install=N/A or --disable-libssp are needed in PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS.
PGAVIN_BINUTILS_EXTRA_CONFIG_ARGS := $(PGAVIN_OPENRISC_TARGET) 
PGAVIN_BINUTILS_EXTRA_MAKE_GLOBAL_ARGS := $(FASTER_MAKE)
# TODO: With the following targets, "make install" fails. I'm not sure which targets are the correct ones:
#       PGAVIN_BINUTILS_MAKE_TARGETS := all-binutils all-gas all-ld all-build
PGAVIN_BINUTILS_CHECK_TARGETS := check-binutils check-gas check-ld
$(eval $(call autotool_project_template,PGAVIN_BINUTILS,Peter Gavin's Binutils,$(PGAVIN_BINUTILS_CHECKOUT_DIR)))

all: $(PGAVIN_BINUTILS_INSTALL_SENTINEL)
$(PGAVIN_BINUTILS_CONFIGURE_SENTINEL): $(PGAVIN_BINUTILS_CHECKOUT_SENTINEL)

all: $(PGAVIN_BINUTILS_CHECK_SENTINEL)


# ----------- Peter Gavin's GCC cross-compiler for OpenRISC -----------

PGAVIN_COMMON_GCC_OPTIONS :=
PGAVIN_COMMON_GCC_OPTIONS += $(PGAVIN_OPENRISC_TARGET)
PGAVIN_COMMON_GCC_OPTIONS += --disable-shared
PGAVIN_COMMON_GCC_OPTIONS += --with-or1ksim=$(PGAVIN_OR1KSIM_BIN_DIR)
PGAVIN_COMMON_GCC_OPTIONS += --with-newlib
PGAVIN_COMMON_GCC_OPTIONS += --disable-libssp

PGAVIN_COMMON_GCC_OPTIONS += --disable-multilib

PGAVIN_COMMON_GCC_OPTIONS += --disable-lto

# ---------- GCC phase 1 ----------

# In order to build GCC, the OpenRISC binutils binaries are needed.

PGAVIN_GCC_PHASE_1_AUTOCONF_PREPEND_PATH := $(PGAVIN_TOOLCHAIN_DIR)/bin
PGAVIN_GCC_PHASE_1_BIN_DIR := $(PGAVIN_TOOLCHAIN_DIR)

PGAVIN_GCC_PHASE_1_EXTRA_CONFIG_ARGS        := $(PGAVIN_COMMON_GCC_OPTIONS) --enable-languages=c --without-headers
PGAVIN_GCC_PHASE_1_EXTRA_GLOBAL_MAKE_ARGS   := $(FASTER_MAKE)
PGAVIN_GCC_PHASE_1_MAKE_TARGETS             := all-gcc
PGAVIN_GCC_PHASE_1_INSTALL_TARGETS          := install-gcc

$(eval $(call autotool_project_template,PGAVIN_GCC_PHASE_1,Peter Gavin's GCC Phase 1,$(PGAVIN_GCC_CHECKOUT_DIR)))

# In order to build GCC, the OpenRISC Binutils binaries are needed.
$(PGAVIN_GCC_PHASE_1_CONFIGURE_SENTINEL): $(PGAVIN_BINUTILS_INSTALL_SENTINEL) $(PGAVIN_GCC_CHECKOUT_SENTINEL)


# ---------- newlib ----------

PGAVIN_NEWLIB_BIN_DIR := $(PGAVIN_TOOLCHAIN_DIR)
PGAVIN_NEWLIB_AUTOCONF_PREPEND_PATH := $(PGAVIN_TOOLCHAIN_DIR)/bin

PGAVIN_NEWLIB_EXTRA_CONFIG_ARGS :=
PGAVIN_NEWLIB_EXTRA_CONFIG_ARGS += $(PGAVIN_OPENRISC_TARGET)
PGAVIN_NEWLIB_EXTRA_CONFIG_ARGS += --disable-shared
PGAVIN_NEWLIB_EXTRA_CONFIG_ARGS += --disable-multilib

PGAVIN_NEWLIB_CHECK_TARGETS := check-target-newlib check-target-libgloss

$(eval $(call autotool_project_template,PGAVIN_NEWLIB,Peter Gavin's Newlib,$(PGAVIN_NEWLIB_CHECKOUT_DIR)))

$(PGAVIN_NEWLIB_CONFIGURE_SENTINEL): $(PGAVIN_GCC_PHASE_1_INSTALL_SENTINEL) $(PGAVIN_NEWLIB_CHECKOUT_SENTINEL)


# ---------- GCC phase 2 ----------
# Note that this installs the final GCC binaries over the ones from phase 1.
# Although everything should be properly overwritten, this method does not look very clean to me.

PGAVIN_GCC_PHASE_2_AUTOCONF_PREPEND_PATH := $(PGAVIN_TOOLCHAIN_DIR)/bin
PGAVIN_GCC_PHASE_2_BIN_DIR := $(PGAVIN_TOOLCHAIN_DIR)

PGAVIN_GCC_PHASE_2_EXTRA_CONFIG_ARGS := $(PGAVIN_COMMON_GCC_OPTIONS) --enable-languages=c,c++
PGAVIN_GCC_PHASE_2_EXTRA_GLOBAL_MAKE_ARGS := $(FASTER_MAKE)
PGAVIN_GCC_PHASE_2_CHECK_TARGETS := check-gcc check-target-libgcc check-target-libstdc++-v3

$(eval $(call autotool_project_template,PGAVIN_GCC_PHASE_2,Peter Gavin's GCC Phase 2,$(PGAVIN_GCC_CHECKOUT_DIR)))

$(PGAVIN_GCC_PHASE_2_CONFIGURE_SENTINEL): $(PGAVIN_NEWLIB_INSTALL_SENTINEL)

all: $(PGAVIN_GCC_PHASE_2_INSTALL_SENTINEL)
