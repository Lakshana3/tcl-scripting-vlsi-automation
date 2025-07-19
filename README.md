# TCL Scripting VSD Workshop

## Overview
This repository contains course materials, lab exercises, and scripts from TCL VSD Workshop focused on mastering TCL scripting. 
The content is aimed at enabling automation in digital design flows by providing hands-on examples in TCL scripting, Yosys-based RTL synthesis, and Quality of Results (QOR) generation.

---

## Key Learning Outcomes
- Master TCL scripting 
- Automate constraint file generation (CSV, SDC to OpenTimer)
- Integrate TCL with Yosys for RTL synthesis and memory module generation
- Perform hierarchical design checks and error detection
- Generate and analyze QOR metrics including WNS (Worst Negative Slack) and FEP (False Path)

---

## Module-wise Documentation

| Module | Description |
|--------|-------------|
| Module 1 | Introduction to TCL and VSDSYNTH Toolbox Usage |
| Module 2 | Variable Creation and Processing Constraints from CSV | 
| Module 3 | Processing Clock and Input Constraints | 
| Module 4 | Complete Scripting and Yosys Synthesis Introduction | 
| Module 5 | Advanced Scripting Techniques and Quality of Results Generation |

---

## Tools Required
- TCL Development Suite
- Yosys synthesis tool
- OpenTimer for timing analysis

---

## Module 1 - Introduction to TCL and VSDSYNTH Toolbox Usage

- Learned the overall goal of the TCL-based flow.
- The task involves converting a design description `.csv` file (with fields like design name, output directory, etc.) into a pre-layout synthesis and timing report using a single command.
- This is done using a TCL-based framework/toolbox, here referred to as the TCLIFY TCL box.

- Understood the sub-task workflow and required tools.
- The process starts by creating a shell command (e.g., vsdsynth) to:
  - Pass .csv input files from the UNIX shell to a TCL script.
  - Convert all inputs into format[1] and SDC format.
  - Send these to the Yosys synthesis tool.
- Further convert format[1] and SDC to format[2], which is then passed to the Opentimer timing analysis tool.
- Finally, generate output report.

![image](/Images/D1/1.png)
![image](/Images/D1/2.png)
![image](/Images/D1/3.png)
![image](/Images/D1/4.png)
![image](/Images/D1/5.png)
![image](/Images/D1/6.png)
![image](/Images/D1/7.png)
![image](/Images/D1/8.png)

<pre lang="markdown"> ```tcsh 
#!/bin/tcsh -f
# ---------------------------------------------------------------------------- #
# Script      : tclify.sh
# Description : Shell wrapper for the 'tclify' TCL-based flow
# Author      : Lakshana R
# Usage       : ./tclify <design_details.csv>
# ---------------------------------------------------------------------------- #

echo
echo
echo "  ***********    ******  ***        ***  *********  ***   ***  "
echo "  ***********  ***       ***        ***  *********   **   **   "
echo "      ***     ***        ***        ***  ***          ** **    "
echo "      ***     ***        ***        ***  ******        ***     "
echo "      ***     ***        ***        ***  ******        ***     "
echo "      ***      ***       *********  ***  ***           ***     "
echo "      ***        ******  *********  ***  ***           ***     "
echo
echo "  A simple and intuitive TCL command that takes design-related "
echo "   CSV files as input and generates synthesized netlists and   "
echo "   detailed timing reports as output. It leverages the Yosys   "
echo "     open-source synthesis tool and Opentimer for accurate     "
echo "                  pre-layout timing analysis                   "
echo
echo "             A tcl command created by Lakshana R               "
echo

# -------------------------- #
#   Set Working Directory    #
# -------------------------- #
# This stores the current working directory in a variable.
# It may be useful if later you want to return to this directory.
set my_work_dir = `pwd`

# ----------------------------- #
#     Tool Initialization       #
# ----------------------------- #

# Check if the number of arguments is not equal to 1
# $#argv → Number of command-line arguments
# If user did not provide exactly one argument → show message and exit
if ($#argv != 1) then
    echo "Info: Please provide the csv file"
    exit 1
endif

# Check if:
# - The file provided does not exist (`! -f $argv[1]`) OR
# - The user typed `-help` instead of a filename
if (! -f $argv[1] || $argv[1] == "-help") then

    # If argument is NOT "-help", then file is missing
    if ($argv[1] != "-help") then
        echo "Error: Cannot find csv file $argv[1]. Exiting..."
        exit 1
    else
        # --------------------------- #
        #        Help Section         #
        # --------------------------- #
        echo "USAGE: ./tclify <csv file>"
        echo
        echo "The <csv file> must contain 2 columns with the following keywords (case-sensitive) in the first column:"
        echo
        echo "<Design Name>         : Name of the top-level Verilog module"
        echo "<Output Directory>    : Path to the folder to store synthesis scripts, netlist, and reports"
        echo "<Netlist Directory>   : Directory containing the input RTL Verilog files"
        echo "<Early Library Path>  : File path to early timing library (.lib) for STA"
        echo "<Late Library Path>   : File path to late timing library (.lib) for STA"
        echo "<Constraints file>    : Path to CSV file containing timing constraints"
        echo
        exit 1
    endif

else
    # If input is valid, call the TCL script and pass the CSV file to it
    # $argv[1] = input CSV file
    tclsh tclify_core.tcl $argv[1]
endif
``` </pre>

![image](/Images/D1/10.png)
![image](/Images/D1/11.png)

## Module 2: Variable Creation and Processing Constraints from CSV
- Working with matrices and arrays in TCL
- Parsing and validating CSV/SDC constraint files

![image](/Images/D2/1.png)
![image](/Images/D2/2.png)
![image](/Images/D2/3.png)
![image](/Images/D2/4.png)
![image](/Images/D2/5.png)
![image](/Images/D2/6.png)
![image](/Images/D2/7.png)
![image](/Images/D2/8.png)
![image](/Images/D2/9.png)
![image](/Images/D2/10.png)

<pre lang="markdown"> ```tcsh 
#!/bin/env tclsh
# The shebang tells the system to use Tcl shell to run this script.

# ---------------------------------------------
# This script reads a .csv file and extracts initial design variables.
# These variables can be used for synthesis and timing flow.
# ---------------------------------------------

# Get the filename from the command-line arguments
# [lindex $argv 0] returns the first element (index 0) of the list $argv
set filename [lindex $argv 0]

# Load required Tcl packages
package require csv         ;# for parsing CSV files
package require struct      ;# provides data structures like matrix

# Create a matrix named 'm' to store CSV contents
::struct::matrix m

# Open the CSV file for reading
# 'open $filename' returns a file handle
set f [open $filename r]

# Read the CSV into the matrix 'm'
# '::csv::read2matrix $f m "," auto' reads CSV with ',' separator and stores in 'm'
::csv::read2matrix $f m "," auto

# Close the file after reading
close $f

# Get number of columns and rows
# 'm columns' returns number of columns in m
set columns [m columns]

# Link the matrix to an array called 'my_arr'
# Now we can use 'my_arr' to access matrix elements
m link my_arr

# 'm rows' returns total number of rows in the matrix
set num_of_rows [m rows]

# Initialize a counter variable
set i 0

# We can loop through each row of the matrix here if needed. 
# Here we extract key-value pairs for variables
while {$i < $num_of_rows} {
      puts "\nInfo: Setting $my_arr(0,$i) as '$my_arr(1,$i)'"     ;# Log variable name and value
      if {$i == 0} {                                              ;# For header row (usually variable names)
          set [string map {" " ""} $my_arr(0,$i)] $my_arr(1,$i)   ;# Set variable without spaces
      } else {
          set [string map {" " ""} $my_arr(0,$i)] [file normalize $my_arr(1,$i)]  ;# Normalize paths
      }
      set i [expr {$i + 1}]                                       ;# Increment loop counter
}

# Print basic info for debugging
puts "\nInfo: Below are the list of initial variables and their values."
puts "User can use these variables for further debug."
puts "Use 'puts <variable name>' command to query value of below variables"

# These variables are expected to be populated from the CSV or elsewhere in your flow.
puts "DesignName        = $DesignName"
puts "OutputDirectory   = $OutputDirectory"
puts "NetlistDirectory  = $NetlistDirectory"
puts "EarlyLibraryPath  = $EarlyLibraryPath"
puts "LateLibraryPath   = $LateLibraryPath"
puts "ConstraintsFile   = $ConstraintsFile"

# Exit the script
return
``` </pre>

![image](/Images/D2/11.png)
![image](/Images/D2/12.png)
![image](/Images/D2/13.png)
![image](/Images/D2/14.png)
![image](/Images/D2/15.png)
![image](/Images/D2/16.png)
![image](/Images/D2/17.png)
![image](/Images/D2/18.png)
![image](/Images/D2/19.png)
![image](/Images/D2/20.png)
![image](/Images/D2/21.png)
![image](/Images/D2/22.png)
![image](/Images/D2/23.png)
![image](/Images/D2/24.png)
![image](/Images/D2/25.png)
![image](/Images/D2/26.png)
![image](/Images/D2/27.png)
![image](/Images/D2/28.png)
![image](/Images/D2/29.png)
![image](/Images/D2/30.png)


## Module 3: Clock & Input Constraint Scripting
- Writing clock constraints with periods and duty cycles
- Using regular expressions for input port classification

## Module 4: Synthesis & Yosys Integration
- Developing complete synthesis scripts
- Memory module synthesis using Yosys and TCL error handling

## Module 5: QOR Report Generation
- Runtime and delay extraction using TCL procs
- Converting constraints to OpenTimer format and bit-blasting bussed signals




---

## Acknowledgements

I extend my sincere gratitude to Mr. Kunal Ghosh for sharing his profound expertise throughout the workshop.
