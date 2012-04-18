
.DELETE_ON_ERROR:

SHELL := bash  # This makefile has only been tested with bash.

include $(ORBUILD_SANDBOX)/Scripts/MakeModules/MakeUtils.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/DownloadAndUnpackTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RepositoryCheckoutTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/AutotoolsTemplates.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RunAndReportTemplates.mk

.PHONY: all

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_1,Example Component 1,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 100))
all: $(EXAMPLE_COMPONENT_1_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_2,Example Component 2,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 200))
all: $(EXAMPLE_COMPONENT_2_SENTINEL)
