# Define a procedure to output formatted stage messages
proc stage_message {stage_num stage_desc is_start} {
    set line "===================================================================================================================================================================================================================================================================================================================="
    if {$is_start} {
        puts "\n$line"
        puts "                          Stage $stage_num Start: $stage_desc"
        puts "$line\n"
    } else {
        puts "\n$line"
        puts "                          Stage $stage_num End: $stage_desc"
        puts "$line\n"
    }
}

# Stage 1: Clean previous design data
stage_message 1 "Cleaning design environment (remove_design -all)" 1
remove_design -all
stage_message 1 "Design environment cleaned" 0

# Stage 2: Set Design Compiler options
stage_message 2 "Setting Design Compiler options" 1

# Retrieve environment variables
set SYN_ROOT_PATH       [getenv "SYN_ROOT_PATH"]
set WORK_PATH           [getenv "WORK_PATH"]
set DC_PATH             [getenv "DC_PATH"]
set RTL_PATH            [getenv "RTL_PATH"]
set CONFIG_PATH         [getenv "CONFIG_PATH"]
set SCRIPT_PATH         [getenv "SCRIPT_PATH"]
set MAPPED_PATH         [getenv "MAPPED_PATH"]
set REPORT_PATH         [getenv "REPORT_PATH"]
set UNMAPPED_PATH       [getenv "UNMAPPED_PATH"]
set LIB_PATH            [getenv "LIB_PATH"]
set TOP_MODULE          [getenv "TOP_MODULE"]

# Output variable values for verification
puts "SYN_ROOT_PATH: $SYN_ROOT_PATH"
puts "WORK_PATH:     $WORK_PATH"
puts "TOP_MODULE:    $TOP_MODULE"

# Set up Design Compiler search paths and libraries
set_app_var search_path [list . $RTL_PATH $LIB_PATH ${DC_PATH}/libraries/syn]
set_app_var target_library  [list gscl45nm.db]
set_app_var link_library    [list * gscl45nm.db]

stage_message 2 "Design Compiler options set" 0

# Stage 3: Read design files
stage_message 3 "Reading design files" 1

# Define a procedure to recursively get Verilog files
proc get_verilog_files {dir} {
    set files [list]
    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            set subfiles [get_verilog_files $item]
            set files [concat $files $subfiles]
        } elseif {[string tolower [file extension $item]] == ".v"} {
            lappend files $item
        }
    }
    return $files
}

# Get all Verilog files under the RTL directory
set rtl_files [get_verilog_files $RTL_PATH]

# Read all Verilog files
foreach file $rtl_files {
    puts "Reading file: $file"
    read_file -format verilog $file
}

# Set the top-level design
current_design $TOP_MODULE

stage_message 3 "Design files read" 0

# Stage 4: Check link and design integrity
stage_message 4 "Checking link and design integrity" 1

if {[link] != 1} {
    puts "ERROR: Link failed!"
    exit 1
}
if {[check_design] != 1} {
    puts "ERROR: Design check failed!"
    exit 1
}

stage_message 4 "Link and design check completed" 0

# Stage 5: Set timing and area constraints
stage_message 5 "Setting timing and area constraints" 1

# Create clock constraint
create_clock -period 10 -name clk [get_ports clk]

# Procedure to set arc delays for black box modules
proc set_blackbox_delays {cell_pattern read_delay write_delay} {
    set cells [get_cells -hierarchical -filter "ref_name =~ \"$cell_pattern\""]
    foreach_in_collection cell $cells {
        # Set read delay
        set_arc_delay -from [all_inputs -hierarchical -pinnames] -to [all_outputs -hierarchical -pinnames] -delay $read_delay $cell
        # Set write delay
        set_arc_delay -from [all_inputs -hierarchical -pinnames] -to [all_outputs -hierarchical -pinnames] -delay $write_delay $cell
    }
}

# Set delays for RAM modules
set_blackbox_delays "dpsram_*" 2 1

# Set delays for FIFO modules
set_blackbox_delays "sfifo_*" 2 1

# Set maximum area (0 means no limit)
set_max_area 0

stage_message 5 "Timing and area constraints set" 0

# Stage 6: Perform synthesis
stage_message 6 "Starting synthesis" 1

# Compile the design with high effort
compile -map_effort high -area_effort high

stage_message 6 "Synthesis completed" 0

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

# Stage 8: Save the synthesized design
stage_message 8 "Saving synthesized design" 1

# Create mapped directory if it doesn't exist
file mkdir "$MAPPED_PATH"

# Save the synthesized netlist (Verilog format)
write -format verilog -hierarchy -output "$MAPPED_PATH/${TOP_MODULE}_synthesized.v"
# Save the synthesized design (DDC format)
write -format ddc -hierarchy -output "$MAPPED_PATH/${TOP_MODULE}.ddc"
# Save the constraint file (SDC format)
write_sdc "$MAPPED_PATH/${TOP_MODULE}.sdc"

stage_message 8 "Synthesized design saved" 0

# Stage 9: Exit Design Compiler
stage_message 9 "Exiting Design Compiler" 1
quit