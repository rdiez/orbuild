
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

.DELETE_ON_ERROR:

SHELL := bash  # This makefile has only been tested with bash.

include $(ORBUILD_SANDBOX)/Scripts/MakeModules/MakeUtils.mk

$(call verify_variable_is_defined,ORBUILD_GIT_BASE_DIR)
$(call verify_variable_is_defined,ORBUILD_REPORTS_DIR)
$(call verify_variable_is_defined,ORBUILD_LOGS_DIR)

MIRROR_TOOLS := $(ORBUILD_SANDBOX)/Scripts/GitSvnMirror

ALL_GIT_DIRS :=  # This variable ends up holding all the git directories, see below.


# -----------------------------------------------------
#
#  $(1) is the variable name prefix, like "REPO1"
#       Variable REPO1_REPORT_FILE and so on will be defined.
#  $(2) is the directory where the git repository is
#

define update_giv_svn_mirror_template_variables

  $(1)_REPORT_FILE := $(ORBUILD_REPORTS_DIR)/$(2).report
  $(1)_LOG_FILE    := $(ORBUILD_LOGS_DIR)/$(2).txt

endef

define update_giv_svn_mirror_template

  $(eval $(call update_giv_svn_mirror_template_variables,$(1),$(2)))

  $(2):
	"$(ORBUILD_SANDBOX)/Scripts/Tools/RunAndReport.sh"  "$(2)"  \
                                                        "$(value $(1)_LOG_FILE)" \
                                                        "$(value $(1)_REPORT_FILE)" \
                                                        report-always \
        "$(MIRROR_TOOLS)/UpdateSvnToGitRepoMirror.sh"  "$(ORBUILD_GIT_BASE_DIR)/$(2)"

  ALL_GIT_DIRS += $(2)

endef


# Add here the repositories like this:
#
# $(eval $(call update_giv_svn_mirror_template,REPO1,repo1))
# $(eval $(call update_giv_svn_mirror_template,REPO2,repo2))


.PHONY: $(ALL_GIT_DIRS)
.PHONY: update-all-git-svn-mirrors

update-all-git-svn-mirrors: $(ALL_GIT_DIRS)
