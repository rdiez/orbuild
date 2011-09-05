
# -----------------------------------------------------
#
# Configure and build a standard autotools-based project.
#
#  $(1) is the variable name prefix, like "NEWLIB"
#       Variables named in the form NEWLIB_xxx will be defined.
#  $(2) is the subdir name, which also acts as the build step name.
#  $(3) is the path to the src directory.
#  $(4) is the extra flags to pass to the ./configure script.

define autotool_project_template_variables

  $(1)_SRC_DIR := $(3)
  $(1)_OBJ_DIR := $(ORBUILD_BUILD_DIR)/$(2)-obj
  $(1)_BIN_DIR := $(ORBUILD_BUILD_DIR)/$(2)-bin

  $(1)_CONFIGURE_FLAGS := $(4)

  $(1)_CONFIG_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).ConfigureLog.txt
  $(1)_MAKE_LOG_FILENAME      := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).MakeLog.txt
  $(1)_INSTALL_LOG_FILENAME   := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).InstallLog.txt
  $(1)_DISTCHECK_LOG_FILENAME := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).DistcheckLog.txt

  $(1)_CONFIG_REPORT_FILENAME    := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).Configure.report
  $(1)_MAKE_REPORT_FILENAME      := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).Make.report
  $(1)_INSTALL_REPORT_FILENAME   := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).Install.report
  $(1)_DISTCHECK_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).Distcheck.report

  $(1)_CONFIGURE_SENTINEL   := $(ORBUILD_BUILD_SENTINELS_DIR)/$(2).ConfigureSentinel
  $(1)_MAKE_SENTINEL        := $(ORBUILD_BUILD_SENTINELS_DIR)/$(2).MakeSentinel
  $(1)_INSTALL_SENTINEL     := $(ORBUILD_BUILD_SENTINELS_DIR)/$(2).InstallSentinel
  $(1)_DISTCHECK_SENTINEL   := $(ORBUILD_BUILD_SENTINELS_DIR)/$(2).DistcheckSentinel

endef

define autotool_project_template

  $(eval $(call autotool_project_template_variables,$(1),$(2),$(3),$(4)))

  $(value $(1)_CONFIGURE_SENTINEL):
	ORBUILD_AUTOCONF_CONFIGURE_ARGS="$(value $(1)_CONFIGURE_FLAGS)" \
    "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                    "$(2) configure" \
                    "$(value $(1)_CONFIG_LOG_FILENAME)" \
                    "$(value $(1)_CONFIG_REPORT_FILENAME)" \
                    report-always \
        "$(ORBUILD_TOOLS)/AutoconfConfigure.sh" \
                "$(value $(1)_SRC_DIR)" \
                "$(value $(1)_OBJ_DIR)" \
                "$(value $(1)_BIN_DIR)" \
                "$(value $(1)_CONFIGURE_SENTINEL)"

  $(value $(1)_MAKE_SENTINEL): $(value $(1)_CONFIGURE_SENTINEL)
	+export MAKEFLAGS="$$(filter --jobserver-fds=%,$$(MAKEFLAGS)) $$(filter -j,$$(MAKEFLAGS))" && \
	"$(ORBUILD_TOOLS)/RunAndReport.sh" \
                    "$(2) make" \
                    "$(value $(1)_MAKE_LOG_FILENAME)" \
                    "$(value $(1)_MAKE_REPORT_FILENAME)" \
                    report-always \
        "$(ORBUILD_TOOLS)/AutoconfMake.sh" \
                "$(value $(1)_OBJ_DIR)" \
                "$(value $(1)_MAKE_SENTINEL)"

  $(value $(1)_INSTALL_SENTINEL): $(value $(1)_MAKE_SENTINEL)
	+export MAKEFLAGS="$$(filter --jobserver-fds=%,$$(MAKEFLAGS)) $$(filter -j,$$(MAKEFLAGS))" && \
	"$(ORBUILD_TOOLS)/RunAndReport.sh" \
                    "$(2) install" \
                    "$(value $(1)_INSTALL_LOG_FILENAME)" \
                    "$(value $(1)_INSTALL_REPORT_FILENAME)" \
                    report-always \
        "$(ORBUILD_TOOLS)/AutoconfInstall.sh" \
                "$(value $(1)_OBJ_DIR)" \
                "$(value $(1)_INSTALL_SENTINEL)"


  $(value $(1)_DISTCHECK_SENTINEL): $(value $(1)_MAKE_SENTINEL)
	+export MAKEFLAGS="$$(filter --jobserver-fds=%,$$(MAKEFLAGS)) $$(filter -j,$$(MAKEFLAGS))" && \
    "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                    "$(2) distcheck" \
                    "$(value $(1)_DISTCHECK_LOG_FILENAME)" \
                    "$(value $(1)_DISTCHECK_REPORT_FILENAME)" \
                    report-always \
        "$(ORBUILD_TOOLS)/AutoconfDistcheck.sh" \
                "$(value $(1)_OBJ_DIR)" \
                "$(value $(1)_DISTCHECK_SENTINEL)"
endef
