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

<pre lang="markdown"> 
# tclify_core.tcl

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
</pre>

`return` will be included to test every part of the code hereon.

| **Tcl Syntax**                  | **Meaning**                                              |
| ------------------------------- | -------------------------------------------------------- |
| `set var value`                 | Assigns a value to a variable                            |
| `[lindex $list n]`              | Returns the *n*th item from a list                       |
| `while {condition} {}`          | Loops while the condition is true                        |
| `switch -- $var { case {...} }` | Matches a variable’s value to defined cases              |
| `puts "text"`                   | Prints text to terminal                                  |
| `incr i`                        | Increments variable `i` by 1                             |
| `package require name`          | Loads an external module or extension (like csv, struct) |
| `::namespace::command`          | Refers to a command in a specific Tcl namespace          |

![image](/Images/D2/11.png)
![image](/Images/D2/12.png)
![image](/Images/D2/13.png)

<pre lang="markdown">
# tclify_core.tcl
  
# ------------------------------------------------------------
# Validate that required files and directories mentioned in 
# the CSV file exist or not. If a file is missing, exit.
# ------------------------------------------------------------

# Check if early cell library file exists
if {![file exists $EarlyLibraryPath]} {
    # If not found, print error and exit script
    puts "\nError: Cannot find early cell library in path $EarlyLibraryPath. Exiting ..."
    exit   ;# 'exit' command stops the script
} else {
    # If found, print confirmation
    puts "\nInfo: Early cell library found in path $EarlyLibraryPath"
}

# Check if late cell library file exists
if {![file exists $LateLibraryPath]} {
    puts "\nError: Cannot find late cell library in path $LateLibraryPath. Exiting ..."
    exit
} else {
    puts "\nInfo: Late cell library found in path $LateLibraryPath"
}

# Check if output directory exists
if {![file isdirectory $OutputDirectory]} {
    # If not found, print info and create the directory
    puts "\nInfo: Cannot find output directory $OutputDirectory. Creating $OutputDirectory"
    file mkdir $OutputDirectory   ;# 'file mkdir' creates a new directory
} else {
    puts "\nInfo: Output directory found in path $OutputDirectory"
}

# Check if RTL netlist directory exists
if {![file isdirectory $NetlistDirectory]} {
    puts "\nError: Cannot find RTL netlist directory in path $NetlistDirectory. Exiting ..."
    exit
} else {
    puts "\nInfo: RTL netlist directory found in path $NetlistDirectory"
}

# Check if constraints file exists
if {![file exists $ConstraintsFile]} {
    puts "\nError: Cannot find constraints file in path $ConstraintsFile. Exiting ..."
    exit
} else {
    puts "\nInfo: Constraints file found in path $ConstraintsFile"
}
</pre>

| **Tcl Syntax**            | **Description**                                                         |
| ------------------------- | ----------------------------------------------------------------------- |
| `{ ... }`                 | Used to group code blocks in control structures (e.g., `if`, `while`).  |
| **Spacing rule**          | Always leave spaces between operators (`!`, `==`, etc.) and variables.  |
| `file exists <path>`      | Returns true if the file exists at the given path.                      |
| `file isdirectory <path>` | Returns true if the given path is a directory.                          |
| `puts`                    | Prints a message to the console or terminal.                            |
| `exit`                    | Stops the script immediately.                                           |
| `file mkdir <path>`       | Creates a directory at the specified path if it does not already exist. |

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

<pre lang="markdown"> 
# tclify_core.tcl

#----------------------  Constraints FILE creation --------------------------#
#----------------------------- SDC Format -----------------------------------#

# Print message to indicate SDC constraint dumping process has started for the design
puts "\nInfo: Dumping SDC constraints for $DesignName"

# Create a matrix named 'constraints' using Tcllib's struct module
::struct::matrix constraints

# Open the constraints CSV file for reading and store the file in variable 'chan'
set chan [open $ConstraintsFile]

# Read the contents of the CSV file into the 'constraints' matrix
# - Delimiter is comma (',')
# - 'auto' lets Tcl auto-detect the data types
csv::read2matrix $chan constraints , auto

# Close the CSV file after reading its contents
close $chan

# Get the number of rows in the matrix and store in variable
set number_of_rows [constraints rows]
puts "number_of_rows = $number_of_rows"

# Get the number of columns in the matrix and store in variable
set number_of_columns [constraints columns]
puts "number_of_columns = $number_of_columns"

# --- Now, locate important sections (like CLOCKS, INPUTS, OUTPUTS) based on labeled headers in CSV ---

# Find the row index where "CLOCKS" section starts
# 'constraints search all CLOCKS' returns a list of matched {col row} pairs. We take the first match.
set clock_start [lindex [lindex [constraints search all CLOCKS] 0 ] 1]
puts "clock_start = $clock_start"

# Similarly, get the column index where "CLOCKS" section starts
set clock_start_column [lindex [lindex [constraints search all CLOCKS] 0 ] 0]
puts "clock_start_column = $clock_start_column"

# Find the row index where "INPUTS" section starts
set input_ports_start [lindex [lindex [constraints search all INPUTS] 0 ] 1]
puts "input_ports_start = $input_ports_start"

# Find the row index where "OUTPUTS" section starts
set output_ports_start [lindex [lindex [constraints search all OUTPUTS] 0 ] 1]
puts "output_ports_start = $output_ports_start"
</pre>

| **Tcl Syntax**              | **Explanation**                                                                                   |
| --------------------------- | ------------------------------------------------------------------------------------------------- |
| `puts "message"`            | Prints the message to the terminal/output.                                                        |
| `set var value`             | Assigns a value to a variable.                                                                    |
| `open <filename>`           | Opens a file (for reading or writing) and returns a file handle (channel).                        |
| `close <channel>`           | Closes the opened file channel.                                                                   |
| `::struct::matrix`          | Part of Tcllib – creates a matrix data structure (like a table or spreadsheet).                   |
| `csv::read2matrix`          | Reads a CSV file and loads it into a matrix.                                                      |
| `matrix rows`               | Returns the number of rows in the matrix.                                                         |
| `matrix columns`            | Returns the number of columns in the matrix.                                                      |
| `matrix search all <value>` | Searches for all cells in the matrix that contain `<value>`, returning their {col row} positions. |
| `lindex list index`         | Returns the item at the given position from a list. Nested `lindex` is used to drill down.        |

![image](/Images/D2/29.png)
![image](/Images/D2/30.png)

## Module 3: Clock & Input Constraint Scripting
- Writing clock constraints with periods and duty cycles
- Using regular expressions for input port classification

![image](/Images/D3/1.png)
![image](/Images/D3/2.png)
![image](/Images/D3/3.png)
![image](/Images/D3/4.png)

<pre lang="markdown"> 
# tclify_core.tcl

# ---------------------- Extract clock constraint start indices ---------------------- #

# Locate timing-related values (e.g., early_rise_delay, late_fall_slew) in the CSV matrix
# by searching specific rectangular regions based on section boundaries.

# For CLOCK-related constraints:
# - Search the matrix in the "CLOCKS" section — from 'clock_start_column' to the last column,
#   and from the 'clock_start' row to one row before 'input_ports_start'.
# - Use: constraints search rect <col_start> <row_start> <col_end> <row_end> <value>
# - This returns a list of {col row} positions where the target value is found.
# - Extract the column index of the first match for each delay/slew type.

# --- Clock latency constraints --- #
set clock_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_delay] 0 ] 0]
# Find the column index where "early_rise_delay" is located in the CLOCKS section
# 1. Search the 'constraints' matrix within a rectangular region:
#    - Columns: from $clock_start_column to ($number_of_columns - 1)
#    - Rows: from $clock_start to ($input_ports_start - 1)
# 2. The search looks for the string "early_rise_delay"
# 3. [constraints search rect ...] returns a list of matching {column row} pairs
# 4. The first [lindex ... 0] extracts the first match (e.g., {5 8})
# 5. The second [lindex ... 0] extracts the column index from that pair (e.g., 5)
# 6. Store this column index in the variable 'clock_early_rise_delay_start'
set clock_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_delay] 0 ] 0]
set clock_late_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_delay] 0 ] 0]
set clock_late_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_delay] 0 ] 0]

# --- Clock transition (slew) constraints --- #
set clock_early_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_rise_slew] 0 ] 0]
set clock_early_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] early_fall_slew] 0 ] 0]
set clock_late_rise_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_rise_slew] 0 ] 0]
set clock_late_fall_slew_start [lindex [lindex [constraints search rect $clock_start_column $clock_start [expr {$number_of_columns-1}] [expr {$input_ports_start-1}] late_fall_slew] 0 ] 0]

# Create the .sdc output file for writing clock constraints
set sdc_file [open $OutputDirectory/$DesignName.sdc "w"]

# Initialize 'i' to the row just after the clock header
set i [expr {$clock_start + 1}]

# Calculate the last row index for clock constraints (just before input ports start)
set end_of_ports [expr {$input_ports_start - 1}]

puts "\nInfo-SDC: Working on clock constraints ....."

# Loop over each clock row in the CSV and generate SDC commands
while { $i < $end_of_ports } {

    # Construct create_clock command:
    # -name : name of the clock from the matrix cell at col 0, row i
    # -period : period value from matrix cell col 1, row i
    # -waveform : waveform rising edge calculated as (period * duty_cycle / 100)
    # [get_ports ...] : SDC syntax to specify the clock port
    puts -nonewline $sdc_file "\ncreate_clock -name [constraints get cell 0 $i] -period [constraints get cell 1 $i] -waveform \{0 [expr {[constraints get cell 1 $i]*[constraints get cell 2 $i]/100}]\} \[get_ports [constraints get cell 0 $i]\]"

    # Set clock transition (slew) minimum and maximum values for rise and fall edges
    puts -nonewline $sdc_file "\nset_clock_transition -rise -min [constraints get cell $clock_early_rise_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
    # Write a line into the SDC file without adding a newline at the end
    # This line sets the minimum rise transition time for a clock
    # Format being written:
    # set_clock_transition -rise -min <value> [get_clocks <clock_name>]
    # 1. [constraints get cell $clock_early_rise_slew_start $i]
    #    → Fetches the actual rise transition value from the constraints matrix at:
    #       - Column: $clock_early_rise_slew_start
    #       - Row: $i
    # 2. [constraints get cell 0 $i]
    #    → Fetches the clock name from column 0 (first column) at row $i
    # 3. \[ and \] are used to escape square brackets inside a string (so they are not evaluated by Tcl)
    # 4. -nonewline means the output won't automatically add a newline after this line
    puts -nonewline $sdc_file "\nset_clock_transition -fall -min [constraints get cell $clock_early_fall_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
    puts -nonewline $sdc_file "\nset_clock_transition -rise -max [constraints get cell $clock_late_rise_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"
    puts -nonewline $sdc_file "\nset_clock_transition -fall -max [constraints get cell $clock_late_fall_slew_start $i] \[get_clocks [constraints get cell 0 $i]\]"

    # Set clock latency for early and late, rise and fall edges
    puts -nonewline $sdc_file "\nset_clock_latency -source -early -rise [constraints get cell $clock_early_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
    puts -nonewline $sdc_file "\nset_clock_latency -source -early -fall [constraints get cell $clock_early_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
    puts -nonewline $sdc_file "\nset_clock_latency -source -late -rise [constraints get cell $clock_late_rise_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"
    puts -nonewline $sdc_file "\nset_clock_latency -source -late -fall [constraints get cell $clock_late_fall_delay_start $i] \[get_clocks [constraints get cell 0 $i]\]"

    # Increment row index to process next clock constraint
    set i [expr {$i + 1}]
}
</pre>

| **Syntax / Command**                              | **Explanation**                                                                             |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `set var value`                                   | Assigns a value to a variable.                                                              |
| `[expr {...}]`                                    | Evaluates an arithmetic expression (e.g., `expr {$a + $b}` returns sum of a and b).         |
| `constraints search rect col1 row1 col2 row2 val` | Searches for a string `val` inside a rectangle in the matrix. Returns `{column row}` pairs. |
| `lindex $list n`                                  | Retrieves the nth element of a list. Useful for extracting matrix cell positions.           |
| `constraints get cell col row`                    | Fetches the actual content of the cell at the given column and row index in the matrix.     |
| `open $file "w"`                                  | Opens a file in write mode.                                                                 |
| `puts $file "..."`                                | Prints to a file. Add `-nonewline` to avoid adding newline after the print.                 |
| `while {condition} { ... }`                       | A loop that executes as long as the condition is true.                                      |
| `\[...\]` (in strings)                            | Escapes square brackets inside strings, needed when generating Tcl commands in strings.     |

![image](/Images/D3/5.png)
![image](/Images/D3/6.png)
![image](/Images/D3/7.png)
![image](/Images/D3/8.png)
![image](/Images/D3/9.png)
![image](/Images/D3/10.png)
![image](/Images/D3/11.png)

<pre lang="markdown"> 
# tclify_core.tcl
  
# ------------------- Create input delay and slew constraints ------------------- #
# Setup index locations in the CSV matrix for each input-related delay/slew value

# Find column index for each constraint type within the INPUTS section of CSV
# --- Input delay constraints --- #
set input_early_rise_delay_start  [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_delay] 0] 0]
set input_early_fall_delay_start  [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_delay] 0] 0]
set input_late_rise_delay_start   [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_delay] 0] 0]
set input_late_fall_delay_start   [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_delay] 0] 0]

# --- Input slew constraints --- #
set input_early_rise_slew_start   [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_rise_slew] 0] 0]
set input_early_fall_slew_start   [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] early_fall_slew] 0] 0]
set input_late_rise_slew_start    [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_rise_slew] 0] 0]
set input_late_fall_slew_start    [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] late_fall_slew] 0] 0]

# Get the column index where the "clocks" keyword appears (used to fetch related clocks for each input)
set related_clock [lindex [lindex [constraints search rect $clock_start_column $input_ports_start  [expr {$number_of_columns-1}] [expr {$output_ports_start-1}] clocks] 0] 0]

# Initialize row indices for looping through input ports
# Initialize loop index 'i' to start from the first input port row after the header row
set i [expr {$input_ports_start+1}]
# Calculate last row index to stop before the output ports section begins
set end_of_ports [expr {$output_ports_start-1}]

# Print info message
puts "\nInfo-SDC: Working on IO constraints ..... "
puts "\nInfo-SDC: Categorizing input ports as bits and bussed"

# ---------------- Loop through all input ports in csv ---------------- #
while { $i < $end_of_ports } {
    # Find matching input ports in all Verilog netlist files

    # Get list of all Verilog source files (*.v) in the netlist directory
    set netlist [glob -dir $NetlistDirectory *.v]
    # Open temporary file /tmp/1 for writing matched input port lines
    set tmp_file [open /tmp/1 w]

    # Loop through each Verilog file found
    foreach f $netlist {
        # Open the current Verilog file for reading
        set fd [open $f r]
        # Read each line in the file until EOF
        while {[gets $fd line] != -1} {
            # Build search pattern: " <input_port_name>;" | eg: input [7:0] cpu_en;
            set pattern1 " [constraints get cell 0 $i];" 

            # If $pattern1 is found anywhere within $line, then process it
            if {[regexp -all -- $pattern1 $line]} {
                # Split line at semicolon and take first part | eg: input [7:0] cpu_en
                set pattern2 [lindex [split $line ";"] 0]

                # Check if the line starts with the keyword "input"
                if {[regexp -all {input} [lindex [split $pattern2 "\S+"] 0]]} {
                    # Extract first 3 tokens from the line: (e.g., "input [7:0] cpu_en") 
                    # 'split $pattern2 "\S+"' splits the line into tokens by whitespace
                    set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"

                    # Replace multiple spaces in s1 with single space and write to /tmp/1
                    puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"
                }
            }
        }
        # Close the current Verilog file after reading all lines
        close $fd
    }
    # Close the temporary file after writing all matches
    close $tmp_file

    # Read and sort unique port entries from /tmp/1
    # Open /tmp/1 for reading matched lines
    set tmp_file [open /tmp/1 r]
    # Open /tmp/2 for writing unique sorted matched lines
    set tmp2_file [open /tmp/2 w]
    # Read all lines from /tmp/1, split by newline, sort uniquely and write to /tmp/2
    puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
    # Close both temp files after processing
    close $tmp_file
    close $tmp2_file

    # Count the number of entries (used to detect if port is bussed)
    # Reopen /tmp/2 for reading unique matched lines
    set tmp2_file [open /tmp/2 r]
    # Count number of unique matched lines by splitting content by newline
    set count [llength [split [read $tmp2_file] "\n"]]

    # If more than 2 unique lines found, consider the port as bussed (multiple bits)
    if {$count > 2} {
        # Append '*' to port name to indicate bus in SDC commands
        set inp_ports [concat [constraints get cell 0 $i]*]
    } else {
        # Single-bit port, keep name as is
        set inp_ports [constraints get cell 0 $i]
    }

    # ---------------- Generate SDC commands ---------------- #

    # Set input delay (early rise/fall, late rise/fall)
    puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_delay_start $i] \[get_ports $inp_ports\]"
    puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_delay_start $i] \[get_ports $inp_ports\]"
    puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_delay_start $i] \[get_ports $inp_ports\]"
    puts -nonewline $sdc_file "\nset_input_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_delay_start $i] \[get_ports $inp_ports\]"

    # Set input transition (slew) values
    puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $input_early_rise_slew_start $i] \[get_ports $inp_ports\]"
    puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $input_early_fall_slew_start $i] \[get_ports $inp_ports\]"
    puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $input_late_rise_slew_start $i] \[get_ports $inp_ports\]"
    puts -nonewline $sdc_file "\nset_input_transition -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $input_late_fall_slew_start $i] \[get_ports $inp_ports\]"

    # Increment loop counter to process next input port row
    set i [expr {$i+1}]
}
# Close the last opened temporary file
close $tmp2_file
</pre>

| Syntax                  | Meaning                                               |
| ----------------------- | ----------------------------------------------------- |
| `set var value`         | Assigns `value` to variable `var`                     |
| `[command args]`        | Executes `command` and returns its result             |
| `expr {}`               | Evaluates math or logical expression                  |
| `if {condition} {}`     | Conditional execution                                 |
| `while {condition} {}`  | Loop while condition is true                          |
| `foreach var list {}`   | Loop over each element in a list                      |
| `puts "text"`           | Prints text to terminal                               |
| `puts -nonewline`       | Prints without newline                                |
| `open path mode`        | Opens a file (modes: `"r"` for read, `"w"` for write) |
| `close file_id`         | Closes the opened file                                |
| `glob -dir path *.v`    | Gets list of `.v` files in directory                  |
| `split string sep`      | Splits string by separator                            |
| `join list sep`         | Joins list into string with separator                 |
| `lsort -unique list`    | Sorts and removes duplicates                          |
| `regexp pattern string` | Checks regex match                                    |
| `regsub`                | Substitutes regex in string                           |

![image](/Images/D3/12.png)
![image](/Images/D3/13.png)
![image](/Images/D3/14.png)
![image](/Images/D3/15.png)
![image](/Images/D3/16.png)
![image](/Images/D3/17.png)
![image](/Images/D3/18.png)
![image](/Images/D3/19.png)
![image](/Images/D3/20.png)
![image](/Images/D3/21.png)
![image](/Images/D3/22.png)

<pre lang="markdown"> 
# tclify_core.tcl

puts "\nInfo: SDC created. Please use constraints in path $OutputDirectory/$DesignName.sdc"
</pre>

![image](/Images/D3/23.png)
![image](/Images/D3/24.png)
![image](/Images/D3/25.png)
![image](/Images/D3/26.png)

## Module 4: Synthesis & Yosys Integration
- Developing complete synthesis scripts
- Memory module synthesis using Yosys and TCL error handling

## Module 5: QOR Report Generation
- Runtime and delay extraction using TCL procs
- Converting constraints to OpenTimer format and bit-blasting bussed signals




---

## Acknowledgements

I extend my sincere gratitude to Mr. Kunal Ghosh for sharing his profound expertise throughout the workshop.
