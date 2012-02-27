
# -----------------------------------------------------
#
# Runs an arbitrary command with the RunAndReport.sh script.
#
#  $(1) is: - The name prefix for the related makefile variables. For example, for prefix "NEWLIB"
#              variables named in the form NEWLIB_xxx will be defined.
#           - Part of the name in all files and directories created for this component.
#  $(2) is the user-friendly name.
#  $(3) is the command to run
#
# In order to trigger this rule, add to some target a dependency to $(1)_SENTINEL .

define run_and_report_template_variables

  $(1)_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).CmdLog.txt
  $(1)_REPORT_FILENAME    := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).Cmd.report
  $(1)_SENTINEL           := $(ORBUILD_COMMAND_SENTINELS_DIR)/$(1).Cmd.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)

endef

define run_and_report_template

  $(eval $(call run_and_report_template_variables,$(1)))

  $(value $(1)_SENTINEL):
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

  $(eval $(call run_and_report_template_variables,$(1)))

  $(value $(1)_SENTINEL):
	  +"$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2)" \
                  "$(value $(1)_LOG_FILENAME)" \
                  "$(value $(1)_REPORT_FILENAME)" \
                  report-always \
          $(3) && \
      echo "Command was run successfully." >"$(value $(1)_SENTINEL)"
endef
