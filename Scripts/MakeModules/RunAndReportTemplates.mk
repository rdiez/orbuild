
# -----------------------------------------------------
#
# Runs an arbitrary command with the RunAndReport.sh script.
#
#  $(1) is the variable name prefix, like "NEWLIB"
#       Variables NEWLIB_xxx will be defined.
#  $(2) is used to form the log and sentinel filenames.
#  $(3) is the command to run
#
# In order to trigger this rule, add to some target a dependency to $(1)_SENTINEL_FILENAME .

define run_and_report_template_variables

  $(1)_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).CmdLog.txt
  $(1)_REPORT_FILENAME    := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).Cmd.report
  $(1)_SENTINEL_FILENAME  := $(ORBUILD_COMMAND_SENTINELS_DIR)/$(2).orbuild-unpack-sentinel

endef

define run_and_report_template

  $(eval $(call run_and_report_template_variables,$(1),$(2)))

  $(value $(1)_SENTINEL_FILENAME):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2)" \
                  "$(value $(1)_LOG_FILENAME)" \
                  "$(value $(1)_REPORT_FILENAME)" \
                  report-always \
          $(3) && \
      echo "Command was run successfully." >"$(value $(1)_SENTINEL_FILENAME)"
endef
