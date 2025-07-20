## Module 2: Variable Creation and Processing Constraints from CSV

- Working with matrices and arrays in TCL
- Parsing and validating CSV/SDC constraint files

Subtasks are shown.

![image](/Images/D2/1.png)

Understanding $argv.

![image](/Images/D2/2.png)

Understanding how csv file will be represented in matrix form and can be manipulated to extract constraints. 

![image](/Images/D2/3.png)

```cat filename	Displays the contents of the file named filename to the terminal.```

![image](/Images/D2/4.png)

Explanation of how ```string map``` command works.

![image](/Images/D2/5.png)

Matrix manipulations to extract constraints.

![image](/Images/D2/6.png)

![image](/Images/D2/7.png)

![image](/Images/D2/8.png)

Working of ```file normalize```command.

![image](/Images/D2/9.png)

Creating ```tclify_core.tcl``` script.

![image](/Images/D2/10.png)

<pre lang="tcl"> 
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

Run the 'tclify' program/script located in the current directory, using 'openMSP430_design_details.csv' as the input CSV file.
````./tclify openMSP430_design_details.csv````

![image](/Images/D2/12.png)

![image](/Images/D2/13.png)

<pre lang="tcl">
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

Run tclify.

![image](/Images/D2/15.png)

![image](/Images/D2/16.png)

Change values and check how tclify executes.

![image](/Images/D2/17.png)
![image](/Images/D2/18.png)

![image](/Images/D2/19.png)
![image](/Images/D2/20.png)

![image](/Images/D2/21.png)
![image](/Images/D2/22.png)
![image](/Images/D2/23.png)

Next task - Readd constraints file and extract.

![image](/Images/D2/24.png)
![image](/Images/D2/25.png)
![image](/Images/D2/26.png)

Shows how ```lindex```works.

![image](/Images/D2/27.png)

The openMSP430_design_constraints.csv file.

![image](/Images/D2/28.png)

<pre lang="tcl"> 
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

Output of running tclify is shown.

![image](/Images/D2/30.png)
