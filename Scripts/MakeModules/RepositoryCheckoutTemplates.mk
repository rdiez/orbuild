
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

# -----------------------------------------------------
#
# Subversion repository checkout.
#
#  $(1) is: - The name prefix for the related makefile variables. For example, for prefix "NEWLIB"
#              variables named in the form NEWLIB_xxx will be defined.
#           - Part of the name in all files and directories created for this component.
#  $(2) is the user-friendly name.
#  $(3) is the base repository URL like "svn://localhost".
#  $(4) is the timestamp to check out at
#
# Set variable DISABLE_SUBVERSION_CHECKOUT to a non-zero value in order to skip this step. This is useful
# while developing the orbuild makefiles, in order to prevent overloading the remote servers.
#

define subversion_checkout_template_variables

  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(1).SvnCheckoutSentinel
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).SvnCheckoutLog.txt
  $(1)_CHECKOUT_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).SvnCheckout.report

  ifeq ($(origin DISABLE_SUBVERSION_CHECKOUT), undefined)
    DISABLE_SUBVERSION_CHECKOUT := 0
  endif

endef

define subversion_checkout_template

  $(eval $(call subversion_checkout_template_variables,$(1)))

  $(value $(1)_CHECKOUT_SENTINEL):
    ifeq "$(DISABLE_SUBVERSION_CHECKOUT)" "0"
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2) svn checkout" \
                  "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                  "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                  report-always \
	      "$(ORBUILD_TOOLS)/CheckoutSvnRepo.sh" \
              "$(3)/$(1)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CHECKOUT_SENTINEL)" \
              "$(4)" \
              "" \
              ""
    else
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(2) svn checkout (skipped)" \
                  "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                  "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                  report-always \
	      echo "(svn checkout skipped)" && touch --no-create "$(value $(1)_CHECKOUT_SENTINEL)"
    endif

endef


# -----------------------------------------------------
#
# Git repository checkout.
#
#  $(1) is: - The name prefix for the related makefile variables. For example, for "NEWLIB"
#             variables named NEWLIB_CHECKOUT_SENTINEL and so on will be defined
#           - Part of the name in all related files and directories created for this component.
#  $(2) is the user-friendly repository name, like "my repo".
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
  $(1)_CLONE_SENTINEL           := $(ORBUILD_REPOSITORIES_DIR)/GitCloneSentinels/$(1).GitCloneSentinel
  $(1)_FETCH_SENTINEL           := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(1).GitFetchSentinel
  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(1).GitCheckoutSentinel

  $(1)_CLONE_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitCloneLog.txt
  $(1)_FETCH_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitFetchLog.txt
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitCheckoutLog.txt

  $(1)_CLONE_REPORT_FILENAME     := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitClone.report
  $(1)_FETCH_REPORT_FILENAME     := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitFetch.report
  $(1)_CHECKOUT_REPORT_FILENAME  := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitCheckout.report

  $(1)_CHECKOUT_DIR := $(ORBUILD_REPOSITORIES_DIR)/$(1)

  ifeq ($(origin $(1)_EXTRA_GIT_CHECKOUT_ARGS), undefined)
    $(1)_EXTRA_GIT_CHECKOUT_ARGS :=
  endif

endef

define git_checkout_template

  $(eval $(call git_checkout_template_variables,$(1)))

  $(value $(1)_CLONE_SENTINEL):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(2) git clone" \
                   "$(value $(1)_CLONE_LOG_FILENAME)" \
                   "$(value $(1)_CLONE_REPORT_FILENAME)" \
                   report-on-error \
	      "$(ORBUILD_TOOLS)/CloneGitRepo.sh" \
              "$(3)" \
              "$(1)" \
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
              "$(1)" \
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
              "$(1)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CHECKOUT_SENTINEL)" \
              "$(4)" \
              "$(value $(1)_EXTRA_GIT_CHECKOUT_ARGS)"
endef
