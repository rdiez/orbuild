
.DELETE_ON_ERROR:

SHELL := bash  # This makefile has only been tested with bash.

include $(ORBUILD_SANDBOX)/Scripts/MakeModules/MakeUtils.mk
include $(ORBUILD_SANDBOX)/Scripts/MakeModules/RunAndReportTemplates.mk

.PHONY: all generate_groups_file generate_subproject_files

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_1,Example Component 1,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 2))
all: $(EXAMPLE_COMPONENT_1_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_2,Example Component 2,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 3))
all: $(EXAMPLE_COMPONENT_2_SENTINEL)


$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_3_1,Example Component 3.1,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 2))
all: $(EXAMPLE_COMPONENT_3_1_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_3_2,Example Component 3.2,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 3))
all: $(EXAMPLE_COMPONENT_3_2_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_3_3,Example Component 3.3,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 3))
all: $(EXAMPLE_COMPONENT_3_3_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_3_4,Example Component 3.4,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 3))
all: $(EXAMPLE_COMPONENT_3_4_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_3_5,Example Component 3.5,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 3))
all: $(EXAMPLE_COMPONENT_3_5_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_4_1,Example Component 4.1,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 2))
all: $(EXAMPLE_COMPONENT_4_1_SENTINEL)

$(eval $(call run_and_report_template,EXAMPLE_COMPONENT_4_2,Example Component 4.2,"$(ORBUILD_TOOLS)/GenerateLongLogTest.sh" 3))
all: $(EXAMPLE_COMPONENT_4_2_SENTINEL)


# ------- Subproject 1 -------
EXAMPLE_SUBPROJECT_1_OBJ_DIR := $(ORBUILD_BUILD_DIR)/EXAMPLE_SUBPROJECT_1
EXAMPLE_SUBPROJECT_1_CMD := \"$(ORBUILD_PROJECT_DIR)/subproject.sh\" 1 \"$(EXAMPLE_SUBPROJECT_1_OBJ_DIR)\" SubprojectPublicReports SubprojectReport.html
EXAMPLE_SUBPROJECT_1_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,EXAMPLE_SUBPROJECT_1,Example Subproject 1,$(SHELL) -c "$(EXAMPLE_SUBPROJECT_1_CMD)"))
all: $(EXAMPLE_SUBPROJECT_1_SENTINEL)


# ------- Subproject 2 -------
EXAMPLE_SUBPROJECT_2_OBJ_DIR := $(ORBUILD_BUILD_DIR)/EXAMPLE_SUBPROJECT_2
EXAMPLE_SUBPROJECT_2_CMD := \"$(ORBUILD_PROJECT_DIR)/subproject.sh\" 2 \"$(EXAMPLE_SUBPROJECT_2_OBJ_DIR)\" SubprojectPublicReports SubprojectReport.html
EXAMPLE_SUBPROJECT_2_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,EXAMPLE_SUBPROJECT_2,Example Subproject 2,$(SHELL) -c "$(EXAMPLE_SUBPROJECT_2_CMD)"))
all: $(EXAMPLE_SUBPROJECT_2_SENTINEL)


# ------- Subproject 31 -------
EXAMPLE_SUBPROJECT_31_OBJ_DIR := $(ORBUILD_BUILD_DIR)/EXAMPLE_SUBPROJECT_31
EXAMPLE_SUBPROJECT_31_CMD := \"$(ORBUILD_PROJECT_DIR)/subproject.sh\" 31 \"$(EXAMPLE_SUBPROJECT_31_OBJ_DIR)\" SubprojectPublicReports SubprojectReport.html
EXAMPLE_SUBPROJECT_31_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,EXAMPLE_SUBPROJECT_31,Example Subproject 31,$(SHELL) -c "$(EXAMPLE_SUBPROJECT_31_CMD)"))
all: $(EXAMPLE_SUBPROJECT_31_SENTINEL)

# ------- Subproject 32 -------
EXAMPLE_SUBPROJECT_32_OBJ_DIR := $(ORBUILD_BUILD_DIR)/EXAMPLE_SUBPROJECT_32
EXAMPLE_SUBPROJECT_32_CMD := \"$(ORBUILD_PROJECT_DIR)/subproject.sh\" 32 \"$(EXAMPLE_SUBPROJECT_32_OBJ_DIR)\" SubprojectPublicReports SubprojectReport.html
EXAMPLE_SUBPROJECT_32_MAKEFLAGS_FILTER := pass-j
$(eval $(call run_makefile_and_report_template,EXAMPLE_SUBPROJECT_32,Example Subproject 32,$(SHELL) -c "$(EXAMPLE_SUBPROJECT_32_CMD)"))
all: $(EXAMPLE_SUBPROJECT_32_SENTINEL)


# ------- Distribute the components into groups for report purposes -------

EXAMPLE_COMPONENT_3 := EXAMPLE_COMPONENT_3_1
EXAMPLE_COMPONENT_3 += EXAMPLE_COMPONENT_3_2
EXAMPLE_COMPONENT_3 += EXAMPLE_COMPONENT_3_3
EXAMPLE_COMPONENT_3 += EXAMPLE_COMPONENT_3_4
EXAMPLE_COMPONENT_3 += EXAMPLE_COMPONENT_3_5
EXAMPLE_COMPONENT_3 += EXAMPLE_SUBPROJECT_31
EXAMPLE_COMPONENT_3 += EXAMPLE_SUBPROJECT_32

EXAMPLE_COMPONENT_4 := EXAMPLE_COMPONENT_4_1
EXAMPLE_COMPONENT_4 += EXAMPLE_COMPONENT_4_2

generate_groups_file:
	echo "My Group 3 = $(EXAMPLE_COMPONENT_3)" >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)
	echo "My Group 4 = $(EXAMPLE_COMPONENT_4)" >>$(ORBUILD_COMPONENT_GROUPS_FILENAME)

generate_subproject_files:
	echo "EXAMPLE_SUBPROJECT_1 = $(EXAMPLE_SUBPROJECT_1_OBJ_DIR)/SubprojectPublicReports/SubprojectReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "EXAMPLE_SUBPROJECT_2 = $(EXAMPLE_SUBPROJECT_2_OBJ_DIR)/SubprojectPublicReports/SubprojectReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "EXAMPLE_SUBPROJECT_31 = $(EXAMPLE_SUBPROJECT_31_OBJ_DIR)/SubprojectPublicReports/SubprojectReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)
	echo "EXAMPLE_SUBPROJECT_32 = $(EXAMPLE_SUBPROJECT_32_OBJ_DIR)/SubprojectPublicReports/SubprojectReport.html" >>$(ORBUILD_SUBPROJECTS_FILENAME)

all: generate_groups_file generate_subproject_files
