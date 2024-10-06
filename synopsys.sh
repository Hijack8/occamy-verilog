#!/bin/bash

# Define functions
function setup_env() {
    # The function accepts two parameters:
    # $1 - Top module name (defaults to the current directory name)
    # $2 - DC installation path (No default value, Missing lead to Wrong!)

    # Check if the DC installation path is set
    # if so, following arguments are not required and of course they will be ignored
    # Set a judge flag
    local flag_DC_PATH=0
    # check all the path in the PATH environment variable
    for path in $(echo "$PATH" | tr ':' '\n'); do
        if [ -f "$path/dc_shell" ]; then
            export DC_PATH="$path"
            flag_DC_PATH=1
            break
        fi
    done

    # Set the DC installation path according to the argu#2 and flag
    if [ -n "$2" ] && [ $flag_DC_PATH -eq 0 ]; then
        export DC_PATH="$2"
    elif [ $flag_DC_PATH -eq 0 ]; then
        echo "ERROR: DC installation path is not set!"
        exit 1
    fi

    # Check if the TOP_MODULE is set
    local flag_TOP_MODULE=0
    if [ -n "$TOP_MODULE" ]; then
        flag_TOP_MODULE=1
    fi
    # Set the top module name according to the argu#1 and flag
    # Write the top module name to the environment variable
    if [ -n "$1" ] && [ $flag_TOP_MODULE -eq 0 ]; then
        export TOP_MODULE="$1"
    elif [ $flag_TOP_MODULE -eq 0 ]; then
        export TOP_MODULE=$(basename $(pwd))
    fi


    # Get the current path
    export SYN_ROOT_PATH=$(pwd)
    export RTL_PATH="$SYN_ROOT_PATH/rtl"
    export WORK_PATH="$SYN_ROOT_PATH/work"
    export CONFIG_PATH="$SYN_ROOT_PATH/config"
    export SCRIPT_PATH="$SYN_ROOT_PATH/script"
    export MAPPED_PATH="$SYN_ROOT_PATH/mapped"
    export REPORT_PATH="$SYN_ROOT_PATH/report"
    export UNMAPPED_PATH="$SYN_ROOT_PATH/unmapped"
    export LIB_PATH="$SYN_ROOT_PATH/library"

    
    echo "${TAB} Environment variables have been set:"
    echo "${TAB} ${TAB} TOP_MODULE=$TOP_MODULE"
    echo "${TAB} ${TAB} DC_PATH=$DC_PATH"
    echo "${TAB} ${TAB} SYN_ROOT_PATH=$SYN_ROOT_PATH"
    echo "${TAB} ${TAB} RTL_PATH=$RTL_PATH"
    echo "${TAB} ${TAB} WORK_PATH=$WORK_PATH"
    echo "${TAB} ${TAB} CONFIG_PATH=$CONFIG_PATH"
    echo "${TAB} ${TAB} SCRIPT_PATH=$SCRIPT_PATH"
    echo "${TAB} ${TAB} MAPPED_PATH=$MAPPED_PATH"
    echo "${TAB} ${TAB} REPORT_PATH=$REPORT_PATH"
    echo "${TAB} ${TAB} UNMAPPED_PATH=$UNMAPPED_PATH"
    echo "${TAB} ${TAB} LIB_PATH=$LIB_PATH"
}

function run_script() {
    # Set up the environment
    setup_env

    # Ensure the work directory exists
    if [ ! -d "$WORK_PATH" ]; then
        mkdir -p "$WORK_PATH"
    fi

    cd "$WORK_PATH" || exit 1

    echo "--------------------- START Synopsys ---------------------"

    # Ensure the TCL script exists
    if [ ! -f "$SCRIPT_PATH/main.tcl" ]; then
        echo "ERROR: TCL script $SCRIPT_PATH/main.tcl not found!"
        exit 1
    fi

    # Run the Design Compiler script without echoing commands
    dc_shell -f "$SCRIPT_PATH/main.tcl" > "$SYN_ROOT_PATH/execute.log" 2>&1

    echo "--------------------- END Synopsys ---------------------"

    cd "$SYN_ROOT_PATH" || exit 1
}

function clean_env() {

    # Remove the TOP_MODULE
    if [ -n "$TOP_MODULE" ]; then
        unset TOP_MODULE
    fi

    echo "${TAB} Cleaning execute.log..."
    if [ -f "$SYN_ROOT_PATH/execute.log" ]; then
        rm "$SYN_ROOT_PATH/execute.log"
    else
        echo "${TAB} ${TAB} No execute.log found to clean."
    fi

    # Clean files under specified directories
    echo "${TAB} Cleaning files under $REPORT_PATH..."
    if [ -d "$REPORT_PATH" ]; then
        rm -rf "$REPORT_PATH"/*
    else
        echo "${TAB} ${TAB} No $REPORT_PATH directory found."
    fi

    echo "${TAB} Cleaning files under $UNMAPPED_PATH..."
    if [ -d "$UNMAPPED_PATH" ]; then
        rm -rf "$UNMAPPED_PATH"/*
    else
        echo "${TAB} ${TAB} No $UNMAPPED_PATH directory found."
    fi

    echo "${TAB} Cleaning files under $MAPPED_PATH..."
    if [ -d "$MAPPED_PATH" ]; then
        rm -rf "$MAPPED_PATH"/*
    else
        echo "${TAB} ${TAB} No $MAPPED_PATH directory found."
    fi

    echo "${TAB} Cleaning files under $WORK_PATH, keeping .synopsys_dc.setup..."
    if [ -d "$WORK_PATH" ]; then
        find "$WORK_PATH" -type f ! -name '.synopsys_dc.setup' -delete
    else
        echo "${TAB} ${TAB} No $WORK_PATH directory found."
    fi
}


# -------------------------------------------- Main program  --------------------------------------------
TAB=$'\t'
if [ $# -lt 1 ]; then
    echo "Usage: $0 --setup [TopModuleName] [DCInstallationPath] | --run | --clean"
    exit 1
fi

case "$1" in
    --setup|-s)
        echo "Setting environment variables..."
        shift
        setup_env "$@"
        export TOP_MODULE
        ;;
    --run|-r)
        echo "Running script..."
        # clean_env
        run_script
        ;;
    --clean|-c)
        # Set up the environment
        echo "Cleaning files..."
        setup_env
        clean_env
        ;;
    *)
        echo "Usage: $0 --setup [TopModuleName] [DCInstallationPath] | --run | --clean"
        exit 1
        ;;
esac
