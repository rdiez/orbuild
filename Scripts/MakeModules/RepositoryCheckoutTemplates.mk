
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

# -----------------------------------------------------
#
# Subversion repository checkout.
#
# Note that checking out over an existing repository just updates it,
# therefore only one rule is needed for Subversion repositories.
#
#  $(1) is: - The name prefix for the related makefile variables. For example, for prefix "NEWLIB"
#              variables named in the form NEWLIB_xxx will be defined.
#           - Part of the name in all files and directories created for this component.
#  $(2) is the user-friendly name.
#  $(3) is the base repository URL like "svn://localhost".
#
# Set variable SKIP_REPOSITORY_UPDATE to a non-zero value in order to skip this step. This is useful
# while developing the orbuild makefiles, in order to prevent overloading the remote servers.
#

define subversion_checkout_template_variables

  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(1).SvnCheckout.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).SvnCheckoutLog.txt
  $(1)_CHECKOUT_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).SvnCheckout.report
  $(1)_CHECKOUT_DIR             := $(ORBUILD_REPOSITORIES_DIR)/$(1)

  ifeq ($(origin SKIP_REPOSITORY_UPDATE), undefined)
    SKIP_REPOSITORY_UPDATE := 0
  endif

endef

define subversion_checkout_template

  $(eval $(call subversion_checkout_template_variables,$(1)))

  $(value $(1)_CHECKOUT_SENTINEL):
    ifeq "$(SKIP_REPOSITORY_UPDATE)" "0"
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(1)_SVN_CHECKOUT" \
                  "$(2) svn checkout" \
                  "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                  "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                  report-always \
	      "$(ORBUILD_TOOLS)/SvnCheckout.sh" \
              "$(3)" \
              "$(value $(1)_CHECKOUT_DIR)" \
              "$(value $(1)_CHECKOUT_SENTINEL)" \
              "" \
              "" \
              ""
    else
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                  "$(1)_SVN_CHECKOUT" \
                  "$(2) svn checkout (skipped)" \
                  "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                  "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                  report-always \
	      "$(ORBUILD_TOOLS)/SkipRepoUpdate.sh" "$(2)" "svn update skipped" "$(value $(1)_CHECKOUT_SENTINEL)"
    endif

endef


# -----------------------------------------------------
#
# Git repository clone/update.
#
#  $(1) is: - The name prefix for the related makefile variables. For example, for "NEWLIB"
#             variables named NEWLIB_CHECKOUT_SENTINEL and so on will be defined
#           - Part of the name in all related files and directories created for this component.
#  $(2) is the user-friendly repository name, like "my repo".
#  $(3) is the git clone URL like "git://localhost/myrepo".
#
# Set variable SKIP_REPOSITORY_UPDATE to a non-zero value in order to skip this step. This is useful
# while developing the orbuild makefiles, in order to prevent overloading the remote servers.
#
# There are several steps to checking out and updating a git repository:
#   1) The first time, a clone is performed. A clone operation cannot be resumed.
#      If it fails, the whole directory is deleted and created again the next time around.
#   2) Optionally, create a branch.
#   3) The next time around, instead of cloning, "git fetch" and "git merge" are performed,
#      in order to update the repository.

define git_checkout_template_variables

  # Remember the user-friendly name in case the git_branch_template macro is invoked later.
  $(1)_USER_FRIENDLY_NAME := $(2)

  $(1)_CHECKOUT_DIR := $(ORBUILD_REPOSITORIES_DIR)/$(1)

  ifeq ($(origin $(1)_EXTRA_GIT_CHECKOUT_ARGS), undefined)
    $(1)_EXTRA_GIT_CHECKOUT_ARGS :=
  endif

  ifeq ($(origin SKIP_REPOSITORY_UPDATE), undefined)
    SKIP_REPOSITORY_UPDATE := 0
  endif

  # The clone sentinel file must not live inside the current build directory,
  # or the repository will be deleted and re-cloned every time a new build directory is created.
  #
  # The clone sentinel file used to live in $(ORBUILD_REPOSITORIES_DIR)/GitCloneSentinels/$(1).GitCloneSentinel ,
  # but now lives inside the hidden ".git" directory inside its repository, which means
  # the repository metadata gets a little polluted.
  # If something is not quite right with the repository, the user will instinctively delete it and will
  # not look for its sentinel file. This way, when the repository is deleted, the sentinel file is gone too,
  # triggering a new git clone the next time around.

  $(1)_CLONE_SENTINEL           := $(ORBUILD_REPOSITORIES_DIR)/$(1)/.git/$(1).GitClone.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)
  $(1)_BRANCH_SENTINEL          := $(ORBUILD_REPOSITORIES_DIR)/$(1)/.git/$(1).GitBranch.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)
  $(1)_FETCH_SENTINEL           := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(1).GitFetch.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)
  $(1)_CHECKOUT_SENTINEL        := $(ORBUILD_CHECKOUT_SENTINELS_DIR)/$(1).GitCheckOut.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)

  $(1)_CLONE_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitCloneLog.txt
  $(1)_FETCH_LOG_FILENAME       := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitFetchLog.txt
  $(1)_CHECKOUT_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitCheckoutLog.txt
  $(1)_BRANCH_LOG_FILENAME      := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(1).GitBranchLog.txt

  $(1)_CLONE_REPORT_FILENAME     := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitClone.report
  $(1)_FETCH_REPORT_FILENAME     := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitFetch.report
  $(1)_CHECKOUT_REPORT_FILENAME  := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitCheckout.report
  $(1)_BRANCH_REPORT_FILENAME    := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(1).GitBranch.report

endef

define git_checkout_template

  $(eval $(call git_checkout_template_variables,$(1),$(2)))

  $(1)_GIT_GROUP := $(1)_GIT_CLONE   $(1)_GIT_FETCH   $(1)_GIT_CHECKOUT   $(1)_GIT_BRANCH

  $(value $(1)_CLONE_SENTINEL):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(1)_GIT_CLONE" \
                   "$(2) git clone" \
                   "$(value $(1)_CLONE_LOG_FILENAME)" \
                   "$(value $(1)_CLONE_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/GitClone.sh" \
              "$(3)" \
              "$(1)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CLONE_SENTINEL)"

  $(value $(1)_FETCH_SENTINEL): $(value $(1)_CLONE_SENTINEL)
    ifeq "$(SKIP_REPOSITORY_UPDATE)" "0"
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(1)_GIT_FETCH" \
                   "$(2) git fetch" \
                   "$(value $(1)_FETCH_LOG_FILENAME)" \
                   "$(value $(1)_FETCH_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/GitFetch.sh" \
              "$(3)" \
              "$(1)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_FETCH_SENTINEL)"

    else
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(1)_GIT_FETCH" \
                   "$(2) git fetch (skipped)" \
                   "$(value $(1)_FETCH_LOG_FILENAME)" \
                   "$(value $(1)_FETCH_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/SkipRepoUpdate.sh" "$(2)" "git fetch skipped" "$(value $(1)_FETCH_SENTINEL)"
    endif

  $(value $(1)_CHECKOUT_SENTINEL): $(value $(1)_FETCH_SENTINEL)
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(1)_GIT_CHECKOUT" \
                   "$(2) git checkout/merge" \
                   "$(value $(1)_CHECKOUT_LOG_FILENAME)" \
                   "$(value $(1)_CHECKOUT_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/GitCheckout.sh" \
              "$(3)" \
              "$(1)" \
              "$(ORBUILD_REPOSITORIES_DIR)" \
              "$(value $(1)_CHECKOUT_SENTINEL)" \
              "" \
              "$(value $(1)_EXTRA_GIT_CHECKOUT_ARGS)"
endef


# Use this macro after git_checkout_template in order to inject an extra branch-creation step
# between cloning and fetching.
#
#  $(1) is the same as for git_checkout_template
#             variables named NEWLIB_CHECKOUT_SENTINEL and so on will be defined
#           - Part of the name in all related files and directories created for this component.
#  $(2) are the arguments for git branch.

define git_branch_template
  $(value $(1)_FETCH_SENTINEL): $(value $(1)_BRANCH_SENTINEL)

  $(value $(1)_BRANCH_SENTINEL): $(value $(1)_CLONE_SENTINEL)
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" \
                   "$(1)_GIT_BRANCH" \
                   "$(value $(1)_USER_FRIENDLY_NAME) git branch" \
                   "$(value $(1)_BRANCH_LOG_FILENAME)" \
                   "$(value $(1)_BRANCH_REPORT_FILENAME)" \
                   report-always \
	      "$(ORBUILD_TOOLS)/GitBranch.sh" \
              "$(value $(1)_CHECKOUT_DIR)" \
              "$(value $(1)_BRANCH_SENTINEL)" \
              "$(2)"
endef


# This template helps make each git repository depend on the previous one,
# so that they are cloned/fetched sequentially instead of in parallel.
# Otherwise, we could overload the remote server with many parallel requests.
#
# Note that this rule is not perfect: 1 clone and 1 fetch can still run in parallel.
# Note also that a clone target cannot depend on any fetch target, or
# the repositories will be cloned every time a fetch is performed.
#
# There is yet another drawback to these rules: if the user deletes a repository,
# that will delete orbuild's sentinel files inside, which will trigger
# a re-fetch for all subsequent repositories, although they are not actually
# affected by the deletion.
#
#  $(1) is the first git repository to download.
#  $(2) is the second git repository to download when the first one is finished.

define git_download_serializer_template
  $(value $(2)_CLONE_SENTINEL): $(value $(1)_CLONE_SENTINEL)
  $(value $(2)_FETCH_SENTINEL): $(value $(1)_FETCH_SENTINEL)
  $(value $(2)_FETCH_SENTINEL): $(value $(1)_CLONE_SENTINEL)
endef
