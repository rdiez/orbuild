
# -----------------------------------------------------
#
# Runs an arbitrary command with the RunAndReport.sh script. If successful,
# create or update the sentinel file automatically.
#
#  $(1) is: - The name prefix for the related makefile variables. For example, for prefix "NEWLIB"
#              variables named in the form NEWLIB_xxx will be defined.
#           - Part of the name in all files and directories created for this component.
#  $(2) is the user-friendly name.
#  $(3) is the command to run
#
# In order to trigger this rule, add to some target a dependency to $(1)_SENTINEL .

define run_and_report_template_variables_1

  ifeq ($(origin $(1)_PREPEND_PATH), undefined)
    $(1)_PATH_TO_USE := $(PATH)
  else
    $(1)_PATH_TO_USE := $(value $(1)_PREPEND_PATH):$(PATH)
  endif

  ifeq ($(origin $(1)_MAKEFLAGS_FILTER), undefined)
    $(1)_MAKEFLAGS_FILTER := pass-all
  endif

  $(1)_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).CmdLog.txt
  $(1)_REPORT_FILENAME    := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).Cmd.report
  $(1)_SENTINEL           := $(ORBUILD_COMMAND_SENTINELS_DIR)/$(1).Cmd.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)

endef

define run_and_report_template_variables_2
  ifeq "$(value $(1)_MAKEFLAGS_FILTER)" "clear"
    $(1)_MAKEFLAGS_VALUE :=
  else ifeq "$(value $(1)_MAKEFLAGS_FILTER)" "pass-j"
    $(1)_MAKEFLAGS_VALUE := $$$$(filter --jobserver-fds=%,$$$$(MAKEFLAGS)) $$$$(filter -j,$$$$(MAKEFLAGS))
  else ifeq "$(value $(1)_MAKEFLAGS_FILTER)" "pass-all"
    $(1)_MAKEFLAGS_VALUE := $$$$(MAKEFLAGS)
  endif
endef

define run_and_report_template_variables_3
  $(if $(filter undefined,$(origin $(1)_MAKEFLAGS_VALUE)),$(error Invalid $(1)_MAKEFLAGS_FILTER value of "$(value $(1)_MAKEFLAGS_FILTER)"))
endef


define run_and_report_template

  $(eval $(call run_and_report_template_variables_1,$(1)))
  $(eval $(call run_and_report_template_variables_2,$(1)))
  $(eval $(call run_and_report_template_variables_3,$(1)))

  $(value $(1)_SENTINEL):
	export PATH="$(value $(1)_PATH_TO_USE)" && \
    export MAKEFLAGS="$(value $(1)_MAKEFLAGS_VALUE)" && \
      "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2)" \
                  "$(value $(1)_LOG_FILENAME)" \
                  "$(value $(1)_REPORT_FILENAME)" \
                  report-always \
                  $(3) && \
      echo "Command was run successfully." >"$(value $(1)_SENTINEL)"
endef


# Same as run_and_report_template, adds a "+" at the front so that GNU Make
# supplies the necessary environment information for any submakes.
define run_makefile_and_report_template

  $(eval $(call run_and_report_template_variables_1,$(1)))
  $(eval $(call run_and_report_template_variables_2,$(1)))
  $(eval $(call run_and_report_template_variables_3,$(1)))

  $(if $(filter pass-all,$(value $(1)_MAKEFLAGS_FILTER)),$(error Variable $(1)_MAKEFLAGS_FILTER has a value of "pass-all". This is theoretically allowed but should probably not be used in practice.))

  $(value $(1)_SENTINEL):
	+export PATH="$(value $(1)_PATH_TO_USE)" && \
    export MAKEFLAGS="$(value $(1)_MAKEFLAGS_VALUE)" && \
    "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2)" \
                  "$(value $(1)_LOG_FILENAME)" \
                  "$(value $(1)_REPORT_FILENAME)" \
                  report-always \
                  $(3) && \
      echo "Command was run successfully." >"$(value $(1)_SENTINEL)"
endef
