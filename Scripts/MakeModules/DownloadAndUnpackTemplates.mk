
# -----------------------------------------------------
#
# URL download template for the standard case of downloading
# a file and placing it in the download cache.
#
# A temporary .log file is created. If the download is successful,
# the log file is deleted, otherwise it's left behind, so that
# the user can inspect the error messages.
#
#  $(1) is the variable name prefix, like "NEWLIB"
#       Variable NEWLIB_DOWNLOAD_URL and so on will be defined.
#  $(2) is the archive base name (without extension), like "newlib-1.19.0".
#  $(3) is the archive type (filename extension), like "tar.gz".
#  $(4) is the base download URL, like "ftp://sources.redhat.com/pub/newlib".

define url_download_template_variables

  $(1)_DOWNLOAD_URL      := $(4)/$(2).$(3)
  $(1)_DOWNLOAD_FILENAME := $(ORBUILD_DOWNLOAD_CACHE_DIR)/$(2).$(3)
  $(1)_LOG_FILENAME      := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).$(3).DownloadLog.txt
  $(1)_REPORT_FILENAME   := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).$(3).Download.report

endef

define url_download_template

  $(eval $(call url_download_template_variables,$(1),$(2),$(3),$(4)))

  $(value $(1)_DOWNLOAD_FILENAME):
	  "$(ORBUILD_TOOLS)/RunAndReport.sh" "DOWNLOAD_$(2).$(3)" "download $(2).$(3)" "$(value $(1)_LOG_FILENAME)" "$(value $(1)_REPORT_FILENAME)" report-on-error \
          "$(ORBUILD_TOOLS)/DownloadFile.sh" "$(value $(1)_DOWNLOAD_URL)" "$(ORBUILD_DOWNLOAD_CACHE_DIR)"

endef


# -----------------------------------------------------
#
# URL download and unpack template
#
# A temporary .log file is created. If the unpacking is successful,
# the log file is deleted, otherwise it's left behind, so that
# the user can inspect the error messages.
#
#  $(1) is the variable name prefix, like "NEWLIB"
#       Variable NEWLIB_UNPACK_DIR and so on will be defined.
#  $(2) is the archive base name (without extension), like "newlib-1.19.0".
#  $(3) is the archive type (filename extension), like "tar.gz".
#  $(4) is the base download URL, like "ftp://sources.redhat.com/pub/newlib".

define url_download_and_unpack_template_variables

  $(1)_UNPACK_DIR      := $(ORBUILD_BUILD_DIR)/$(2)
  $(1)_UNPACK_SENTINEL := $(ORBUILD_UNPACK_SENTINELS_DIR)/$(2).Unpack.$(ORBUILD_SENTINEL_FILENAME_SUFFIX)
  $(1)_LOG_FILENAME    := $(ORBUILD_PUBLIC_REPORTS_DIR)/$(2).$(3).UnpackLog.txt
  $(1)_REPORT_FILENAME := $(ORBUILD_INTERNAL_REPORTS_DIR)/$(2).$(3).Unpack.report

endef

define url_download_and_unpack_template

  $(eval $(call url_download_template,$(1),$(2),$(3),$(4)))

  $(eval $(call url_download_and_unpack_template_variables,$(1),$(2),$(3),$(4)))

  $(value $(1)_UNPACK_SENTINEL): $(value $(1)_DOWNLOAD_FILENAME)
	"$(ORBUILD_TOOLS)/RunAndReport.sh" "UNPACK_$(2).$(3)" "unpack $(2).$(3)" "$(value $(1)_LOG_FILENAME)" "$(value $(1)_REPORT_FILENAME)" report-on-error \
	    "$(ORBUILD_TOOLS)/UnpackArchive.sh" "$(value $(1)_DOWNLOAD_FILENAME)" \
	        "$(ORBUILD_BUILD_DIR)" \
	        "$(value $(1)_UNPACK_SENTINEL)" \
	        "$(value $(1)_UNPACK_DIR)"
endef

