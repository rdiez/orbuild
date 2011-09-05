
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

# -----------------------------------------------------
#
# Subversion repository checkout.
#
# A temporary .log file is created. If the unpacking is successful,
# the log file is deleted, otherwise it's left behind, so that
# the user can inspect the error messages.
#
#  $(1) is the variable name prefix, like "NEWLIB"
#    Variable NEWLIB_CHECKOUT_SENTINEL and so on will be defined.
#  $(2) is the repository name, like "myrepo".
#  $(3) is the base repository URL like "svn://localhost".
#  $(4) is the timestamp to check out at
#  $(5) is the user
#  $(6) is the password
#

define subversion_checkout_template_variables

  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(2).SvnCheckoutSentinel
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).SvnCheckoutLog.txt
  $(1)_CHECKOUT_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).SvnCheckout.report

endef

define subversion_checkout_template

  $(eval $(call subversion_checkout_template_variables,$(1),$(2)))

  $(value $(1)_CHECKOUT_SENTINEL):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" "$(2) svn checkout" "$(value $(1)_CHECKOUT_LOG_FILENAME)" "$(value $(1)_CHECKOUT_REPORT_FILENAME)" report-always \
	      "$(ORBUILD_TOOLS)/CheckoutSvnRepo.sh" "$(3)/$(2)" "$(ORBUILD_REPOSITORIES_DIR)" "$(value $(1)_CHECKOUT_SENTINEL)" "$(4)" "$(5)" "$(6)"

endef


# -----------------------------------------------------
#
# Git repository checkout.
#
#  $(1) is the variable name prefix, like "NEWLIB"
#    Variable NEWLIB_CHECKOUT_SENTINEL and so on will be defined.
#  $(2) is the repository name, like "myrepo".
#  $(3) is the base repository URL like "git://localhost".
#  $(4) is the timestamp to check out at
#
# There are several steps to checking out and updating a git repository:
#   1) The first time, a clone is performed. A clone operation cannot be resumed.
#      If it fails, the whole directory is deleted and created again the next time around.
#   2) After the cloning, a checkout is performed at the given timestamp.
# If the timestamp changes, the status file changes. This triggers the following:
#   3) A "git fetch" is performed, in order to update the repository.
#   4) A checkout is performed, in order to move the sandbox to the given timestamp.

define git_checkout_template_variables

  $(1)_CLONE_FETCH_SENTINEL     := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(2).GitCloneFetchSentinel
  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(2).GitCheckoutSentinel

  $(1)_CLONE_FETCH_LOG_FILENAME := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).GitCloneFetchLog.txt
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).GitCheckoutLog.txt

  $(1)_CLONE_FETCH_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).GitCloneFetch.report
  $(1)_CHECKOUT_REPORT_FILENAME    := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).GitCheckout.report

endef

define git_checkout_template

  $(eval $(call git_checkout_template_variables,$(1),$(2)))

  $(value $(1)_CLONE_FETCH_SENTINEL):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" "$(2) git clone/fetch" "$(value $(1)_CLONE_FETCH_LOG_FILENAME)" "$(value $(1)_CLONE_FETCH_REPORT_FILENAME)" report-always \
	      "$(ORBUILD_TOOLS)/CloneFetchGitRepo.sh" "$(3)/$(2)" "$(ORBUILD_REPOSITORIES_DIR)" "$(value $(1)_CLONE_FETCH_SENTINEL)"

  $(value $(1)_CHECKOUT_SENTINEL): $(value $(1)_CLONE_FETCH_SENTINEL)
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" "$(2) git checkout" "$(value $(1)_CHECKOUT_LOG_FILENAME)" "$(value $(1)_CHECKOUT_REPORT_FILENAME)" report-always \
	      "$(ORBUILD_TOOLS)/CheckoutGitRepo.sh" "$(3)/$(2)" "$(ORBUILD_REPOSITORIES_DIR)" "$(value $(1)_CHECKOUT_SENTINEL)" "$(4)"

endef
