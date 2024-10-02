# read_design.tcl

# Source common functions
source "$SCRIPT_PATH/common_functions.tcl"

# Stage 3: Read design files
stage_message 3 "Reading design files" 1

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
