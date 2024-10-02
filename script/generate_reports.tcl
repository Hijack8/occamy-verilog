# generate_reports.tcl

# Source common functions
source "$SCRIPT_PATH/common_functions.tcl"

# Stage 7: Generate reports
stage_message 7 "Generating reports" 1

# Create report directory if it doesn't exist
file mkdir "$REPORT_PATH"

# Generate various reports
report_compile_options > "$REPORT_PATH/compile_options.rpt"
report_constraint -all_violators > "$REPORT_PATH/constraint_violators.rpt"
report_timing > "$REPORT_PATH/timing.rpt"
report_timing -delay max -max_paths 10 > "$REPORT_PATH/timing_max_paths.rpt"
report_area > "$REPORT_PATH/area.rpt"
report_power > "$REPORT_PATH/power.rpt"
report_resources > "$REPORT_PATH/resources.rpt"
report_design > "$REPORT_PATH/design.rpt"
report_clock > "$REPORT_PATH/clock.rpt"
report_netlist > "$REPORT_PATH/netlist.rpt"

stage_message 7 "Reports generated" 0
