## Module 1 - Introduction to TCL and VSDSYNTH Toolbox Usage

- The goal of the TCL-based flow involves converting a design description `.csv` file (with fields like design name, output directory, etc.) into a pre-layout synthesis and timing report using a single command.
- This is done using a TCL-based framework/toolbox, here referred to as the TCLIFY TCL box.
  
![image](/Images/D1/1.png)

![image](/Images/D1/2.png)

- The process starts by creating a shell command (e.g., tclify) to:
  - Pass .csv input files from the UNIX shell to a TCL script.
  - Convert all inputs into format[1] and SDC format.
  - Send these to the Yosys synthesis tool.
- Further convert format[1] and SDC to format[2], which is then passed to the Opentimer timing analysis tool.
- Finally, generate output report.
  
![image](/Images/D1/3.png)

This is the design details csv file.

![image](/Images/D1/4.png)

The tclify command should handle these scenarios:
- No input file
- Invalid CSV
- Help message
  
![image](/Images/D1/5.png)

![image](/Images/D1/6.png)

![image](/Images/D1/7.png)

![image](/Images/D1/8.png)

Create wrapper called ``tclify.sh``.

<pre lang="sh"> 
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
</pre>

Change permissions recursively (-R) on the 'tclify' file granting read (4), write (2), and execute (1) permissions to everyone (owner, group, others). This makes 'tclify' fully accessible to all users.

The output of each scenario is shown.

![image](/Images/D1/10.png)

![image](/Images/D1/11.png)
