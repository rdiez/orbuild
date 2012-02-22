
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

# -----------------------------------------------------
#
# Subversion repository checkout.
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
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2) svn checkout" \
                  "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                  "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                  report-always \
	      "$(ORBUILD_TOOLS)/CheckoutSvnRepo.sh" \
              "$(3)/$(2)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CHECKOUT_SENTINEL)" \
              "$(4)" \
              "$(5)" \
              "$(6)"

endef


# -----------------------------------------------------
#
# Git repository checkout.
#
#  $(1) is the name prefix for the related mafile variables. For example, for prefix "NEWLIB"
#       variable NEWLIB_CHECKOUT_SENTINEL and so on will be defined.
#  $(2) is the repository name, like "myrepo", which will also be used
#       as the checkout subdir name.
#  $(3) is the git clone URL like "git://localhost/myrepo".
#  $(4) is the timestamp to check out at
#
# There are several steps to checking out and updating a git repository:
#   1) The first time, a clone is performed. A clone operation cannot be resumed.
#      If it fails, the whole directory is deleted and created again the next time around.
#   2) The next time around, instead of cloning, a "git fetch" is performed,
#      in order to update the repository.
#   3) A checkout is performed at the given timestamp or branch.

define git_checkout_template_variables

  # The clone sentinel must not live inside the current build directory,
  # or the repository will be deleted and re-cloned every time a new build directory is created.
  $(1)_CLONE_SENTINEL           := $(ORBUILD_REPOSITORIES_DIR)/GitCloneSentinels/$(2).GitCloneSentinel
  $(1)_FETCH_SENTINEL           := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(2).GitFetchSentinel
  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(2).GitCheckoutSentinel

  $(1)_CLONE_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).GitCloneLog.txt
  $(1)_FETCH_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).GitFetchLog.txt
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).GitCheckoutLog.txt

  $(1)_CLONE_REPORT_FILENAME     := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).GitClone.report
  $(1)_FETCH_REPORT_FILENAME     := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).GitFetch.report
  $(1)_CHECKOUT_REPORT_FILENAME  := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).GitCheckout.report

  $(1)_CHECKOUT_DIR := $(ORBUILD_REPOSITORIES_DIR)/$(2)

  ifeq ($(origin $(1)_EXTRA_GIT_CHECKOUT_ARGS), undefined)
    $(1)_EXTRA_GIT_CHECKOUT_ARGS :=
  endif

endef

define git_checkout_template

  $(eval $(call git_checkout_template_variables,$(1),$(2)))

  $(value $(1)_CLONE_SENTINEL):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(2) git clone" \
                   "$(value $(1)_CLONE_LOG_FILENAME)" \
                   "$(value $(1)_CLONE_REPORT_FILENAME)" \
                   report-on-error \
	      "$(ORBUILD_TOOLS)/CloneGitRepo.sh" \
              "$(3)" \
              "$(2)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CLONE_SENTINEL)"

  $(value $(1)_FETCH_SENTINEL): $(value $(1)_CLONE_SENTINEL)
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(2) git fetch" \
                   "$(value $(1)_FETCH_LOG_FILENAME)" \
                   "$(value $(1)_FETCH_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/FetchGitRepo.sh" \
              "$(3)" \
              "$(2)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_FETCH_SENTINEL)"

  $(value $(1)_CHECKOUT_SENTINEL): $(value $(1)_FETCH_SENTINEL)
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(2) git merge" \
                   "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                   "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/CheckoutGitRepo.sh" \
              "$(3)" \
              "$(2)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CHECKOUT_SENTINEL)" \
              "$(4)" \
              "$(value $(1)_EXTRA_GIT_CHECKOUT_ARGS)"
endef
