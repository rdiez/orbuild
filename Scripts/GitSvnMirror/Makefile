
# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

# Fetching the whole version history from Subversion takes a long time.
# If you don't need the history, starting from the latest version
# can save hours of downloading.
#
# Allegedly, you can fetch the rest of the history afterwards, but that
# has not worked for me, at least with opencores.org and git 1.7.0.4 .
# I have tried "git svn fetch -r BASE:HEAD", "-r 0:5", "-r 0" and "-r4 -p" to no avail.
#
# See this article for more information:
#   http://stackoverflow.com/questions/1554222/git-svn-clone-how-to-defer-fetch-of-revision-history

# Leave this variable empty to fetch the whole history.
#   FIRST_GIT_SVN_FETCH_ARGS :=
FIRST_GIT_SVN_FETCH_ARGS := -r HEAD


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
#  $(3) is the "git svn init" command used to clone the repository,
#       but note that the target directory $(2) is appended at the end.
#  $(4) is the repository description.
#

define update_giv_svn_mirror_template_variables

  $(1)_CREATE_REPORT_FILE      := $(ORBUILD_REPORTS_DIR)/$(2).Create.report
  $(1)_CREATE_LOG_FILE         := $(ORBUILD_LOGS_DIR)/$(2).CreateLog.txt
  $(1)_UPDATE_REPORT_FILE      := $(ORBUILD_REPORTS_DIR)/$(2).Update.report
  $(1)_UPDATE_LOG_FILE         := $(ORBUILD_LOGS_DIR)/$(2).UpdateLog.txt

  # Note that file .git/OrbuildGitSvnInit gets created under the .git directory,
  # although this file does not belong to git.
  $(1)_INIT_FILE        := $(ORBUILD_GIT_BASE_DIR)/$(2)/.git/OrbuildGitSvnInit

  $(1)_DESCRIPTION_FILE := $(ORBUILD_GIT_BASE_DIR)/$(2)/.git/description

endef

define update_giv_svn_mirror_template

  $(eval $(call update_giv_svn_mirror_template_variables,$(1),$(2)))

  # This step initialises the git repository and is only done once.
  #
  # The user should do this initialisation manually, so that he gets
  # a chance to interactively enter the right username and password.
  #
  # As part of the initialisation, a first update is performed. If this fails,
  # the initialisation will be done again from scratch the next time around.
  # This is in case the repository was initialised with the wrong parameters,
  # and the user changes them and tries again. Otherwise, the user must remember
  # to manually delete the initialised repository before retrying.
  $(value $(1)_INIT_FILE):
	"$(ORBUILD_SANDBOX)/Scripts/Tools/RunAndReport.sh"  "$(2)"  \
                                                        "$(value $(1)_CREATE_LOG_FILE)" \
                                                        "$(value $(1)_CREATE_REPORT_FILE)" \
                                                        report-always \
        "$(MIRROR_TOOLS)/CreateSvnToGitRepoMirror.sh" \
             "$(ORBUILD_GIT_BASE_DIR)" \
             "$(2)" \
             "$(3)" \
             "$(FIRST_GIT_SVN_FETCH_ARGS)" \
             "$(4)" \
             "$(value $(1)_INIT_FILE)" \
             "$(value $(1)_DESCRIPTION_FILE)"

  $(2): $(value $(1)_INIT_FILE)
	"$(ORBUILD_SANDBOX)/Scripts/Tools/RunAndReport.sh"  "$(2)"  \
                                                        "$(value $(1)_UPDATE_LOG_FILE)" \
                                                        "$(value $(1)_UPDATE_REPORT_FILE)" \
                                                        report-always \
        "$(MIRROR_TOOLS)/UpdateSvnToGitRepoMirror.sh" \
             "$(ORBUILD_GIT_BASE_DIR)/$(2)" \
             "" && \
        echo "GitRepositoryDir=$(2)" >>"$(value $(1)_UPDATE_REPORT_FILE)"

  ALL_GIT_DIRS += $(2)

endef


# Here is the list of repositories to mirror. You can add other Subversion repositories below.

# OpenCores repositories under http://opencores.org/ocsvn/openrisc/openrisc/
$(eval $(call update_giv_svn_mirror_template,DOCS,docs,git svn init http://opencores.org/ocsvn/openrisc/openrisc/trunk/docs,Documentation))
$(eval $(call update_giv_svn_mirror_template,OR1200,or1200,git svn init http://opencores.org/ocsvn/openrisc/openrisc/trunk/or1200,Processor Core))
$(eval $(call update_giv_svn_mirror_template,OR1KSIM,or1ksim,git svn init http://opencores.org/ocsvn/openrisc/openrisc/trunk/or1ksim,Simulator))
$(eval $(call update_giv_svn_mirror_template,ORPSOCV2,orpsocv2,git svn init http://opencores.org/ocsvn/openrisc/openrisc/trunk/orpsocv2,System on a Chip - orpsocv2))
$(eval $(call update_giv_svn_mirror_template,GNU_SRC,gnu-src,git svn init http://opencores.org/ocsvn/openrisc/openrisc/trunk/gnu-src,GNU Toolchain))

# Other OpenCores repositories.
$(eval $(call update_giv_svn_mirror_template,ADV_DEBUG_SYS,adv_debug_sys,git svn init --stdlayout http://opencores.org/ocsvn/adv_debug_sys/adv_debug_sys,advanced debug system))
$(eval $(call update_giv_svn_mirror_template,MINSOC,minsoc,git svn init --stdlayout http://opencores.org/ocsvn/minsoc/minsoc,System on a Chip - MinSoC))


.PHONY: $(ALL_GIT_DIRS)
.PHONY: update-all-git-svn-mirrors

update-all-git-svn-mirrors: $(ALL_GIT_DIRS)
