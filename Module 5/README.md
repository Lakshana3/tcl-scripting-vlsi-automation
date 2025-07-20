## Module 5: QOR Report Generation
- Runtime and delay extraction using TCL procs
- Converting constraints to OpenTimer format and bit-blasting bussed signals
- Generating Quality of Results (QOR): WNS, FEP, instance count, runtime

<pre lang="tcl"> 
# tclify_core.tcl

# --------------------------- Main Synthesis Script --------------------------------#

# Print a message to indicate the script creation process has started
puts "\nInfo: Creating main synthesis script to be used by Yosys"

# Set the command to read the liberty file, marking it as a blackbox (used for synthesis reference)
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"

# Set the filename for the synthesis script as <DesignName>.ys
set filename "$DesignName.ys"

# Open the synthesis script file in write mode at the output directory
set fileId [open $OutputDirectory/$filename "w"]

# Write the read_liberty command to the script file (no newline at end)
puts -nonewline $fileId $data

# Get a list of all .v (Verilog) files in the NetlistDirectory
set netlist [glob -dir $NetlistDirectory *.v]

# Loop through each Verilog file and add a read_verilog command to the synthesis script
foreach f $netlist {
    set data $f
    puts -nonewline $fileId "\nread_verilog $f"
}

# Add synthesis commands to the script
# These commands direct Yosys how to synthesize the top-level design

puts $fileId "\nhierarchy -top $DesignName"                           ;# Set the top module
puts $fileId "\nsynth -top $DesignName"                               ;# Start synthesis
puts $fileId "splitnets -ports -format ___"                           ;# Split nets connected to ports
puts $fileId "dfflibmap -liberty ${LateLibraryPath}"                  ;# Map flip-flops using liberty lib
puts $fileId "opt"                                                    ;# Optimize the design
puts $fileId "abc -liberty ${LateLibraryPath}"                        ;# Perform logic optimization
puts $fileId "flatten"                                                ;# Flatten hierarchy
puts $fileId "clean -purge"                                           ;# Clean unused logic
puts $fileId "iopadmap -outpad BUFX2 A:Y -bits"                       ;# Map IO pads
puts $fileId "opt"                                                    ;# Re-optimize after mapping pads
puts $fileId "clean"                                                  ;# Final clean-up
puts $fileId "write_verilog $OutputDirectory/$DesignName.synth.v"     ;# Write final synthesized design

# Close the script file
close $fileId

# Inform the user that the script was created
puts "\nInfo: Synthesis script created and can be accessed from path $OutputDirectory/$DesignName.ys"

# Start the synthesis process
puts "\nInfo: Running synthesis ......"

# --------------------------- Run synthesis script using yosys --------------------------------#

# Try to run yosys using the generated synthesis script
# Redirect both stdout and stderr to synthesis.log
if {[catch {exec yosys -s $OutputDirectory/$DesignName.ys >& $OutputDirectory/$DesignName.synthesis.log} msg]} {
    # If an error occurs during execution, print error and exit
    puts "\nError: Synthesis failed due to errors. Please refer to log $OutputDirectory/$DesignName.synthesis.log for errors"
    exit
} else {
    # If synthesis runs successfully
    puts "\nInfo: Synthesis finished successfully"
}

# Print the log file location
puts "\nInfo: Please refer to log $OutputDirectory/$DesignName.synthesis.log"
</pre>

| Tcl Syntax             | Meaning                                                            |
| ---------------------- | ------------------------------------------------------------------ |
| `set var value`        | Assigns `value` to `var`                                           |
| `puts "text"`          | Prints `text` to the console                                       |
| `puts -nonewline`      | Prints without adding a newline character                          |
| `open <file> <mode>`   | Opens a file in a specific mode (`"r"` for read, `"w"` for write)  |
| `close <fileId>`       | Closes the opened file                                             |
| `glob -dir <path> *.v` | Lists all `.v` files in the specified directory                    |
| `foreach var list {}`  | Loop that iterates over each item in `list`, assigning it to `var` |
| `catch {command} var`  | Catches any error during command execution, stores output in `var` |
| `if {condition} {}`    | If condition is true, execute the block                            |
| `${var}` or `$var`     | Gets the value of the variable `var`                               |
| `exec command`         | Executes an external shell command                                 |
| `>&`                   | Redirects both stdout and stderr to a file (used in shell via Tcl) |
  
![image](/Images/D5/1.png)  

Remove output dir and run tclify.

![image](/Images/D5/2.png)  

Output after running tclify command is shown.
Use grep to check for errors in synthesis log file.

![image](/Images/D5/3.png)  

Modify the osmp_clock_module instance name in the openMSP430.v top module to create ERROR.

![image](/Images/D5/4.png)  

Remove output dir and run tclify.

![image](/Images/D5/5.png)  

Output after running tclify command is shown.
Use grep to check for errors in synthesis log file.

![image](/Images/D5/6.png)  

Modify the osmp_clock_module instance name back to how it was.

![image](/Images/D5/7.png)  

The .synth.v file is not created yet because of the error. So run tclify again.

![image](/Images/D5/8.png)  

Next task:

![image](/Images/D5/9.png)  

Check if .synth.v file is present and open it. 

![image](/Images/D5/10.png)  

All the * portions have to be removed.

![image](/Images/D5/11.png)  

Use grep to filter out * portions.

![image](/Images/D5/12.png)  

Using ``grep  "*" file_name | wc`` to get the word count of the filtered portions and remove all lines containing * as a whole word from the synthesized Verilog file.

![image](/Images/D5/13.png)  

Output of the above command. 

![image](/Images/D5/14.png)  

From the synthesized Verilog file, remove lines containing '*' (as a whole word), then filter and display only the lines that contain a backslash '\'.

![image](/Images/D5/15.png)  

Check their word count.

![image](/Images/D5/16.png)  

The code should be converted to the right side snippet by removing '\'.

![image](/Images/D5/17.png)  

<pre lang="tcl"> 
# tclify_core.tcl
#--------------------------- Edit synth.v to be usable by Opentimer --------------------------------#

# Open a temporary file "/tmp/1" for writing. This will hold a filtered version of the synthesized netlist.
set fileId [open /tmp/1 "w"]

# Run a shell command using 'exec' to filter out lines containing only "*" from the netlist.
# 'grep -v -w "*"' removes lines with just a "*" from the synthesized Verilog.
# 'puts -nonewline' writes the result to the temp file without adding an extra newline.
puts -nonewline $fileId [exec grep -v -w "*" $OutputDirectory/$DesignName.synth.v]

# Close the temporary file after writing is done.
close $fileId

# Now open the final output file where the cleaned netlist will be written.
set output [open $OutputDirectory/$DesignName.final.synth.v "w"]

# Open the temporary file "/tmp/1" for reading.
set filename "/tmp/1"
set fid [open $filename r]

# Read the file line by line using a while loop until end-of-file (gets returns -1).
while {[gets $fid line] != -1} {
    # Replace any backslashes "\" in the line with nothing (remove them).
    # This ensures compatibility with OpenTimer which may not accept backslash escape characters.
    puts -nonewline $output [string map {"\\" ""} $line]

    # Add a newline after each cleaned line.
    puts -nonewline $output "\n"
}

# Close both input and output files after processing is done.
close $fid
close $output

# Print final information about where the cleaned synthesized netlist is saved.
puts "\nInfo: Please find the synthesized netlist for $DesignName at below path. You can use this netlist for STA or PNR"
puts "\n$OutputDirectory/$DesignName.final.synth.v"
</pre>

| **Syntax**                         | **Purpose**                                                         |
| ---------------------------------- | ------------------------------------------------------------------- |
| `set var value`                    | Assigns a value to a variable                                       |
| `open filename mode`               | Opens a file in read (`"r"`), write (`"w"`), or append (`"a"`) mode |
| `puts $var`                        | Prints the value of a variable followed by newline                  |
| `puts -nonewline $file data`       | Writes data to file without a newline                               |
| `exec`                             | Executes shell commands                                             |
| `[gets $fid line] != -1`           | Reads a line from file until EOF                                    |
| `string map {pattern replacement}` | Replaces a pattern in a string                                      |
| `while {condition} {}`             | Repeats code block while condition is true                          |
| `close $fileId`                    | Closes the file handle                                              |
| `$variable`                        | Accesses the value of a variable                                    |

![image](/Images/D5/18.png)  

Remove out dir and run tclify.

![image](/Images/D5/19.png)  

Output after running tclify command is shown.
Check if .synth.v is there and open it.

![image](/Images/D5/20.png)  
![image](/Images/D5/21.png)  

Use split screen ``:sp`` command to open the .final.synth.v file also in the same tab.

![image](/Images/D5/22.png)  

Alternate between windows uusing ctrl+w. 
Go to last line using G.

![image](/Images/D5/23.png)  

Use ``:set number`` to show line numbers. 
The .final.synth.v file has edited out more lines.

![image](/Images/D5/24.png)  

Using procs:

![image](/Images/D5/25.png)  

<pre lang="tcl"> 
# set_num_threads.proc

# Define a procedure (function) named 'set_multi_cpu_usage' that takes variable arguments
proc set_multi_cpu_usage {args} {

    # Define an array 'options' with default keys and values
    # -localCpu will be assigned to the number of threads passed by the user
    # -help is a flag that prints usage info
    array set options {-localCpu <num_of_threads> -help "" }

    # Iterate over key-value pairs in the 'options' array
    foreach {switch value} [array get options] {
        puts "Option $switch is $value" ;# Print each option and its value
    }

    # While there are still arguments in the args list
    while {[llength $args]} {
        puts "llength is [llength $args]" ;# Print how many args are left
        puts "lindex 0 of \"$args\" is [lindex $args 0]" ;# Print the first argument

        # Use switch statement to match first argument to known options
        switch -glob -- [lindex $args 0] {
            -localCpu {
                puts "old args is $args"
                # lassign assigns the value after -localCpu to options(-localCpu)
                # and removes the used arguments from the args list
                set args [lassign $args - options(-localCpu)]
                puts "new args is \"$args\""
                puts "set_num_threads $options(-localCpu)" ;# Print how many threads were set
            }

            -help {
                puts "old args is $args"
                # Assign a dummy value to options(-help), just to consume the flag from args
                set args [lassign $args - options(-help)]
                puts "new args is \"$args\""
                puts "Usage: set_multi_cpu_usage -localCpu <num_of_threads>" ;# Show help message
            }
        }
    }
}

# Call the procedure with test arguments
set_multi_cpu_usage -localCpu 8 -help
</pre>

| **Syntax**                          | **Purpose**                                                        |
| ----------------------------------- | ------------------------------------------------------------------ |
| `proc name {args} {body}`           | Defines a procedure                                                |
| `array set arrName {key value ...}` | Initializes an associative array                                   |
| `array get arrName`                 | Returns list of key-value pairs from array                         |
| `foreach {key val} $list {}`        | Iterates over key-value pairs in a list                            |
| `puts "string"`                     | Prints string to console with newline                              |
| `return`                            | Exits the current procedure                                        |
| `[llength $list]`                   | Returns number of elements in a list                               |
| `[lindex $list n]`                  | Gets the nth element of a list (indexing starts from 0)            |
| `switch -glob -- $value {cases}`    | Matches value against patterns and executes corresponding block    |
| `lassign $list var1 var2`           | Assigns values from list to variables (e.g., from args to options) |
| `set var value`                     | Assigns value to a variable                                        |
| `$var`                              | Fetches the value of a variable                                    |

![image](/Images/D5/26.png)  

Running the proc using tclsh. 

![image](/Images/D5/27.png)  

Modifying the proc file and running it again.

![image](/Images/D5/28.png)  
![image](/Images/D5/29.png)  

Modifying the proc file and running it again.

![image](/Images/D5/30.png)  
![image](/Images/D5/31.png)  

Modifying the proc file and running it again.

![image](/Images/D5/32.png)  
![image](/Images/D5/33.png)  

<pre lang="tcl"> 
# tclify_core.tcl
  
#--------------------------- Static timing analysis using OpenTimer --------------------------------#

# Print a message to indicate the start of timing analysis
puts "\nInfo: Timing Analysis Started .... "

# Print a message about setting up the environment (threads, libraries, constraints, netlist)
puts "\nInfo: Initializing number of threads, libraries, sdc, verilog netlist path ... "

# Load external Tcl procedure to redirect stdout (standard output) to a file
source /home/vsduser/vsdsynth/reopenStdout.proc

# Load external Tcl procedure to set the number of CPU threads
source /home/vsduser/vsdsynth/set_num_threads.proc

# Call the reopenStdout procedure with the configuration file path
# This redirects output to the file $DesignName.conf under $OutputDirectory
reopenStdout $OutputDirectory/$DesignName.conf

# Call the set_multi_cpu_usage procedure (defined earlier) with the number of local CPUs (threads)
# This is used to set how many threads the tool can utilize
set_multi_cpu_usage -localCpu 4
</pre>

| **Tcl Keyword / Concept**         | **Purpose**                                                  |
| --------------------------------- | ------------------------------------------------------------ |
| `puts "text"`                     | Prints the given text to console or file                     |
| `\n`                              | Newline character in strings                                 |
| `source file_path`                | Executes another Tcl script located at `file_path`           |
| `set var value`                   | Assigns `value` to a variable named `var`                    |
| `$varName`                        | Refers to the value stored in variable `varName`             |
| `proc name {args} {body}`         | Declares a procedure with name, arguments, and body          |
| `reopenStdout path`               | Custom procedure (likely redirects stdout to a log file)     |
| `set_multi_cpu_usage -localCpu 4` | Custom procedure to set number of threads (multi-core usage) |
| `#`                               | Comment in Tcl                                               |

![image](/Images/D5/34.png)  

<pre lang="tcl"> 
# reopenStdout.proc

# Define a procedure named 'reopenStdout' that takes one argument 'file'
proc reopenStdout {file} {

    # Close the default stdout (standard output), which usually prints to the terminal
    close stdout

    # Open the given file (overwrite mode: 'w') and assign it to stdout
    # From now on, all 'puts' output will go into this file instead of the terminal
    open $file w
}
</pre>

| **Command**               | **Description**                               |
| ------------------------- | --------------------------------------------- |
| `proc name {args} {body}` | Defines a new procedure                       |
| `close fileID`            | Closes a file or stream (like `stdout`)       |
| `open $file mode`         | Opens a file with a given mode (`w` = write)  |
| `stdout`                  | The standard output stream (default terminal) |
| `$var`                    | Refers to the value of variable `var`         |

![image](/Images/D5/35.png)  

Place on the link and click gf or use :e to open link without closing the current file. 

![image](/Images/D5/36.png)  
![image](/Images/D5/37.png)  

Return using :e#.

![image](/Images/D5/38.png)  

Remove out dir and run tclify.

![image](/Images/D5/39.png)  

Output after running tclify command is shown.
Open conf file.

![image](/Images/D5/40.png)  
![image](/Images/D5/41.png)  

Modify the proc file to remove debugging lines.

![image](/Images/D5/42.png)  

Output after running tclify command is shown.

![image](/Images/D5/43.png)  

Output present in conf file is shown.

![image](/Images/D5/44.png)  

<pre lang="tcl"> 
# tclify_core.tcl

# Load (or "source") the file containing the definition of the read_lib procedure
# This lets us use 'read_lib' like a built-in command
source /home/vsduser/vsdsynth/read_lib.proc

# Call the read_lib procedure to load the standard cell library for early timing analysis
# "Early" refers to best-case conditions (e.g., fastest delays)
read_lib -early /home/vsduser/vsdsynth/osu018_stdcells.lib

# Call the read_lib procedure again for late timing analysis
# "Late" refers to worst-case conditions (e.g., slowest delays)
read_lib -late /home/vsduser/vsdsynth/osu018_stdcells.lib
</pre>

| **Tcl Command**       | **Description**                                                   |
| --------------------- | ----------------------------------------------------------------- |
| `source filename`     | Executes the Tcl code from the given file                         |
| `proc name {args} {}` | Defines a new procedure                                           |
| `read_lib`            | A user-defined procedure (from `read_lib.proc`)                   |
| `-early` / `-late`    | Options or flags passed to a procedure to control its behavior    |
| `""` (quotes)         | Used for paths or strings containing special characters or spaces 

![image](/Images/D5/45.png)  

<pre lang="tcl"> 
# read_lib.proc

# Define a procedure named 'read_lib' that accepts variable arguments (args)
proc read_lib args {

    # Create an associative array 'options' to store default values for each supported flag
    # -late and -early expect values (paths), while -help just exists without a value
    array set options {-late <late_lib_path> -early <early_lib_path> -help ""}

    # Loop as long as there are arguments left to process
    while {[llength $args]} {

        # Use 'switch' to match the first element of the args list
        # '-glob' allows pattern matching, '--' ends option parsing
        switch -glob -- [lindex $args 0] {

            # If the argument is '-late', extract the next value (library path)
            -late {
                # lassign takes items from args and assigns them:
                # '-' is just a placeholder, value goes into options(-late)
                set args [lassign $args - options(-late)]
                # Output what would happen — in real tool, this would set the late library
                puts "set_late_celllib_fpath $options(-late)"
            }

            # If the argument is '-early', extract the early lib path
            -early {
                set args [lassign $args - options(-early)]
                puts "set_early_celllib_fpath $options(-early)"
            }

            # If '-help' is passed, print usage instructions
            -help {
                set args [lassign $args - options(-help)]
                puts "Usage: read_lib -late <late_lib_path> -early <early_lib_path>"
                puts "-late <provide late library path>"
                puts "-early <provide early library path>"
            }

            # If no recognized option is found, break the switch
            default break
        }
    }
}
</pre>

| **Tcl Command / Construct**   | **Explanation**                                                     |
| ----------------------------- | ------------------------------------------------------------------- |
| `proc name args {body}`       | Defines a procedure with a variable-length argument list `args`     |
| `array set arrName {key val}` | Initializes a Tcl associative array with keys and values            |
| `while {condition} {}`        | Repeats the body while the condition is true                        |
| `llength list`                | Returns the number of items in a list                               |
| `lindex list index`           | Returns the element at the specified index in a list                |
| `lassign list var1 var2`      | Assigns elements of a list to variables; returns the remaining list |
| `switch -glob -- val {}`      | Compares a value to patterns using glob-style matching              |
| `puts "text"`                 | Prints text to the terminal                                         |
| `break`                       | Exits a loop or switch early                                        |

![image](/Images/D5/46.png)  

Output after running tclify command is shown.
Use cat command to output the contents of conf file.

![image](/Images/D5/47.png)  

<pre lang="tcl"> 
# tclify_core.tcl

# Load and execute the Tcl procedure file 'read_verilog.proc' from the specified path.
# This file likely contains the definition of the 'read_verilog' procedure used below.
source /home/vsduser/vsdsynth/read_verilog.proc

# Call the 'read_verilog' procedure with the synthesized Verilog file as argument.
# This command instructs the tool to read and process the synthesized Verilog netlist located at:
#   $OutputDirectory/$DesignName.final.synth.v
read_verilog $OutputDirectory/$DesignName.final.synth.v
</pre>

| **Tcl Command / Construct** | **Explanation**                                              |
| --------------------------- | ------------------------------------------------------------ |
| `source filename`           | Reads and executes the Tcl script file `filename`            |
| `command arg1 arg2 ...`     | Calls a procedure or command with given arguments            |
| `$variable`                 | Accesses the value stored in a Tcl variable named `variable` |

![image](/Images/D5/48.png)  

<pre lang="tcl"> 
# read_verilog.proc

# Define a procedure named 'read_verilog' that takes one argument 'arg1'
proc read_verilog {arg1} {
    # Print the string "set_verilog_fpath" followed by the value of 'arg1'
    # This simulates setting the file path for the Verilog netlist
    puts "set_verilog_fpath $arg1"
}
</pre>

| **Tcl Command / Construct** | **Explanation**                      |
| --------------------------- | ------------------------------------ |
| `proc name {args} {body}`   | Defines a new procedure named `name` |
| `puts string`               | Prints `string` to standard output   |
| `$var`                      | Access the value of variable `var`   |

![image](/Images/D5/49.png)  

Output after running tclify command is shown.
Use cat command to output the contents of conf file.

![image](/Images/D5/50.png)  

Next task:

![image](/Images/D5/51.png)  
![image](/Images/D5/52.png)   

<pre lang="tcl"> 
# test.tcl

# Define a procedure named 'read_sdc' that takes one argument 'arg1' (expected to be a full file path to an SDC file)
proc read_sdc {arg1} {

    # Extract the directory path from the full file path (e.g., "/home/user/folder")
    # This is useful if you want to do operations relative to the file's folder later
    set sdc_dirname [file dirname $arg1]

    # Extract the filename from the path, removing its extension:
    # Step 1: get the filename part from the full path, e.g. "openMSP430.sdc"
    # Step 2: split the filename string by '.' so "openMSP430.sdc" becomes {"openMSP430" "sdc"}
    # Step 3: select the first part, which is the filename without extension "openMSP430"
    # This helps in naming output files related to this input SDC
    set sdc_filename [lindex [split [file tail $arg1] .] 0]

    # Open the SDC file for reading ('r' mode)
    # This file contains the timing constraints in Synopsys Design Constraints (SDC) format
    set sdc [open $arg1 r]

    # Open a temporary file /tmp/1 for writing ('w' mode)
    # We will write a cleaned-up version of the SDC file here (remove unwanted characters)
    set tmp_file [open /tmp/1 w]

    # Debugging prints - print directory path, filename, and parts extracted
    # Useful for confirming that variables hold expected values during execution
    puts "sdc_dirname is $sdc_dirname"
    puts "arg1 is $arg1"
    puts "part1 is [file tail $arg1]"
    puts "part2 is [split [file tail $arg1] .]"
    puts "part3 is [lindex [split [file tail $arg1] .] 0 ]"
    puts "sdc filename is $sdc_filename"

    # Read entire contents of the SDC file into a string
    # Remove all '[' characters by replacing them with empty string ""
    # Replace all ']' characters by a space " "
    # This is probably done because '[' and ']' may interfere with later parsing
    # Then write this cleaned-up string to the temporary file without adding a newline at the end
    puts -nonewline $tmp_file [string map {"\[" "" "\]" " "} [read $sdc]]

    # Close the temporary file after writing the cleaned contents to it
    close $tmp_file

    #--------------------------- Start processing clock constraints ------------------------------#

    # Re-open the cleaned temporary file for reading the modified SDC contents line-by-line
    set tmp_file [open /tmp/1 r]

    # Open another temporary file /tmp/3 for writing processed timing data, e.g., extracted clock info
    set timing_file [open /tmp/3 w]

    # Read the entire cleaned file into a string, then split the string into a list of lines by newline character "\n"
    # This converts the entire file into a list where each element is one line of text
    set lines [split [read $tmp_file] "\n"]

    # Print the list of lines for debugging purposes to see what the cleaned data looks like
    puts $lines

    # Search the 'lines' list for every line that starts with "create_clock"
    # -all means find all matching elements
    # -inline means return the matched elements themselves (not just indices)
    set find_clocks [lsearch -all -inline $lines "create_clock*"]

    # Print the found clock creation lines for debugging
    puts $find_clocks

    # For each line found that creates a clock, perform further extraction
    foreach elem $find_clocks {

        # Find the position of the token "get_ports" in the current line (list)
        # Then, get the token immediately after "get_ports" which is the clock port name
        # This tells us the port on which the clock is created
        set clock_port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]

        # Print details about the location of "get_ports" and the extracted port name
        puts "part1 is [lsearch $elem  \"get_ports\"]"
        puts "part2 is [expr {[lsearch $elem  \"get_ports\"]+1}]"
        puts "part3 is $clock_port_name"
        puts "clock_port_name is $clock_port_name"

        # Similarly, find "-period" keyword position, then extract the clock period value
        # Clock period defines how often the clock toggles
        set clock_period [lindex $elem [expr {[lsearch $elem "-period"]+1} ]]

        # Print debug info about clock period extraction
        puts "cp part1 is [lsearch $elem \"-period\"]"
        puts "cp_part2 is [expr {[lsearch $elem \"-period\"]+1}]"
        puts "cp_part3 is $clock_period"
        puts "clock_period is $clock_period"

        # Calculate the duty cycle of the clock signal:
        # Duty cycle is the percentage of the clock period for which the clock is high
        # Formula: 100 - ((waveform_high_time * 100) / clock_period)
        # Get waveform info right after "-waveform" keyword, which contains timing info (e.g., {0 5})
        # We extract the second value (high time), multiply by 100 and divide by clock period,
        # then subtract from 100 to get duty cycle
        set duty_cycle [expr {100 - [expr {[lindex [lindex $elem [expr {[lsearch $elem "-waveform"]+1}]] 1]*100/$clock_period}]}]

        # Print detailed debugging info about waveform parsing and duty cycle calculation steps
        puts "dc_part1 is [lsearch $elem \"-waveform\"]"
        puts "dc_part2 is [expr {[lsearch $elem \"-waveform\"]+1}]"
        puts "dc_part3 is [lindex $elem [expr {[lsearch $elem \"-waveform\"]+1} ]]"
        puts "dc_part4 is [lindex [lindex $elem [expr {[lsearch $elem \"-waveform\"]+1} ] ] 1]"
        puts "dc_part5 is [expr {[lindex [lindex $elem [expr {[lsearch $elem \"-waveform\"]+1}]] 1]*100/$clock_period}]"
        puts "dc_part6 is $duty_cycle"
        puts "duty_cycle is $duty_cycle"

        # Write a cleaned, easy-to-use clock constraint line in the format:
        # "clock <clock_port_name> <clock_period> <duty_cycle>"
        # to the timing output file /tmp/3
        puts $timing_file "clock $clock_port_name $clock_period $duty_cycle"

        # Also print this line to console for verification/debugging
        puts "clock $clock_port_name $clock_period $duty_cycle\n"
    }

    # Close the input temporary file after reading all lines
    close $tmp_file
}
# Call read_sdc procedure to process the SDC file for the design
read_sdc /home/vsduser/vsdsynth/outdir_openMSP430/openMSP430.sdc  
</pre>

| **Tcl Syntax**                            | **Description**                                                               |
| ----------------------------------------- | ----------------------------------------------------------------------------- |
| `proc name {args} {body}`                 | Define a procedure named `name` with parameters `args` and body `body`        |
| `set var value`                           | Assign `value` to variable `var`                                              |
| `[file dirname path]`                     | Extract the directory part of a file path                                     |
| `[file tail path]`                        | Extract the filename (tail) from a file path                                  |
| `[split string sep]`                      | Split `string` into a list using separator `sep`                              |
| `[lindex list idx]`                       | Get the element at index `idx` from list `list`                               |
| `open filename mode`                      | Open a file for reading (`r`) or writing (`w`)                                |
| `[read fileId]`                           | Read entire contents of file opened with fileId                               |
| `puts string`                             | Print `string` to stdout                                                      |
| `puts -nonewline fileId string`           | Write `string` to file without appending newline                              |
| `string map {pattern replace ...} string` | Replace occurrences of `pattern` in `string` with `replace`                   |
| `[lsearch -all -inline list pattern]`     | Search all elements in `list` matching `pattern` and return matched elements  |
| `foreach var list {body}`                 | Iterate over each element of `list` with loop variable `var` executing `body` |
| `[expr {expression}]`                     | Evaluate mathematical or logical `expression`                                 |

Create test.tcl file nd run it using tclsh command.

![image](/Images/D5/54.png)  
![image](/Images/D5/55.png)  

Contents of /tmp/3 file.

![image](/Images/D5/56.png)  

Contents of /tmp/1 file. 
![image](/Images/D5/58.png)  

<pre lang="tcl"> 
# test.tcl

#-------------------- Converting set_clock_latency constraints --------------------#

# Search for all elements in the list `$lines` that match the pattern "set_clock_latency*"
# `lsearch -all -inline` returns all matching elements (not just indices).
set find_keyword [lsearch -all -inline $lines "set_clock_latency*"]
puts $find_keyword ;# Print the matched lines containing set_clock_latency

# Open a temporary file for writing the processed clock latency data
set tmp2_file [open /tmp/2 w]
set new_port_name "" ;# Initialize a variable to track the current port being processed

# Iterate over each matched line containing set_clock_latency
foreach elem $find_keyword {
    
    # Extract the port name by locating the word after "get_clocks" in the line
    set port_name [lindex $elem [expr {[lsearch $elem "get_clocks"]+1} ]]

    # Debugging outputs to show the intermediate steps in port name extraction
    puts "pn_part1 is [lsearch $elem "get_clocks"]" ;# Index where "get_clocks" appears
    puts "pn_part2 is [expr {[lsearch $elem "get_clocks"]+1} ]" ;# Index of actual port name
    puts "pn_part3 is [lindex $elem [expr {[lsearch $elem "get_clocks"]+1} ]]" ;# Port name
    puts "port_name is $port_name"

    # Process only if the port name has changed (to avoid duplicate processing)
    if {![string match $new_port_name $port_name]} {
        set new_port_name $port_name ;# Update to the new port
        puts "dont match"
        puts "new_port_name is changed to $new_port_name"

        # This part searches for all elements (lines) in find_keyword
        # that contain the current port name.
        # join [list "*" " " $port_name " " "*"] ""
        #     --> Combines the list into a string like "* port_name *"
        # lsearch -all -inline $find_keyword "pattern"
        #     --> Searches for this combined pattern in the full list
        set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]

        # Debug prints to understand pattern formation and matches
        puts "dl_part1 is [list "*" " " $port_name " " "*"]"
        puts "dl_part2 is [join [list "*" " " $port_name " " "*"] ""]"  
        puts "delays_list is $delays_list"

        set delay_value "" ;# Initialize an empty list to store latency values for the current clock port

        # For each matching line in delay_list, extract the delay value
        foreach new_elem $delays_list {
            set port_index [lsearch $new_elem "get_clocks"] ;# Find where get_clocks is
            puts "old delay_value is $delay_value"
            puts "port_index is $port_index"

            # The delay value is usually the element just *before* "get_clocks"
            lappend delay_value [lindex $new_elem [expr {$port_index - 1}]]
            puts "new delay_value is $delay_value"
        }

        # Now write the processed port name and delay values to the tmp2 file
        puts "entering"
        puts -nonewline $tmp2_file "\nat $port_name $delay_value"
        puts "at $port_name $delay_value\n"
    }
}

# Close the temporary write file
close $tmp2_file

# Reopen the temp file for reading and write its contents to the final timing file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file
</pre>

| Tcl Command         | Purpose                                                  |
| ------------------- | -------------------------------------------------------- |
| `set var value`     | Assigns a value to a variable                            |
| `puts "text"`       | Prints text to the terminal                              |
| `lsearch list val`  | Searches for `val` in a list and returns the index       |
| `lsearch -inline`   | Returns matching *elements* instead of indices           |
| `lsearch -all`      | Returns *all* matches, not just the first one            |
| `join list sep`     | Joins elements of a list using a separator string        |
| `lindex list idx`   | Fetches the item at index `idx` from `list`              |
| `foreach var list`  | Iterates over elements in a list                         |
| `if {condition} {}` | Conditional execution                                    |
| `expr {math}`       | Evaluates a mathematical expression                      |
| `lappend list item` | Appends an item to the end of a list                     |
| `open path mode`    | Opens a file in specified mode (`r` = read, `w` = write) |
| `read file`         | Reads content from a file handle                         |
| `close file`        | Closes an open file handle                               |
| `string match`      | Compares strings with pattern matching                   |

Modify and run the test.tcl file. 

![image](/Images/D5/59.png)  

Output after running test.tcl file is shown.

![image](/Images/D5/60.png)  
![image](/Images/D5/61.png)  

Contents of /tmp/2 file.
![image](/Images/D5/62.png)  

Contents of /tmp/3 file.

![image](/Images/D5/63.png)  

<pre lang="tcl"> 
# test.tcl

# ---------------------- converting set_clock_transition constraints ---------------------- #

# Search all lines in the $lines list that start with or include "set_clock_transition"
# - lsearch: searches through the list
# - -all: finds all matches
# - -inline: returns the matching elements, not their indices
set find_keyword [lsearch -all -inline $lines "set_clock_transition*"]

# Open a temporary file in write mode to store formatted output
set tmp2_file [open /tmp/2 w]

# Initialize a variable to track the most recently processed port name
set new_port_name ""

# Iterate over each matching line
foreach elem $find_keyword {

    # Extract the clock port name from the command
    # - lsearch finds index of "get_clocks"
    # - [expr {index + 1}] gives the next word, which is the clock name
    set port_name [lindex $elem [expr {[lsearch $elem "get_clocks"]+1}]]

    # Only process if this port hasn't already been processed
    if {![string match $new_port_name $port_name]} {

        # Update the current port name
        set new_port_name $port_name

        # Search again for all entries in the original list that contain this port name
        # We construct a pattern like "* port_name *"
        # [list "*" " " $port_name " " "*"] creates: {"*" " " "clk" " " "*"}
        # [join ... ""] joins them into a single string: "* clk *"
        # This will match any line with the clock name in it
        set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]

        # Debug print
        puts "delays list is $delays_list"

        # Initialize empty list to collect transition (slew) values
        set delay_value ""

        # For every matching element (with the same clock port)
        foreach new_elem $delays_list {

            # Find the index of "get_clocks"
            set port_index [lsearch $new_elem "get_clocks"]

            # The actual delay value (transition/slew) is just before "get_clocks"
            lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
        }

        # Write the final formatted output for this clock: "slew clk_name {value1 value2 ...}"
        puts -nonewline $tmp2_file "\nslew $port_name $delay_value"
    }
}

# Close the write file
close $tmp2_file

# Reopen the same file in read mode and append its contents to the output file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file
</pre>

| Tcl Command                | Description                                                            |
| -------------------------- | ---------------------------------------------------------------------- |
| `set var value`            | Assigns `value` to `var`.                                              |
| `lsearch list pattern`     | Finds the index of the first element in `list` that matches `pattern`. |
| `lsearch -all -inline`     | Returns all matching elements, not just indices.                       |
| `lindex list index`        | Gets the item at position `index` from `list`.                         |
| `expr {...}`               | Evaluates a mathematical expression.                                   |
| `string match pattern str` | Checks if `str` matches the `pattern`.                                 |
| `lappend list_var value`   | Appends `value` to the list `list_var`.                                |
| `open file mode`           | Opens a file for reading (`r`) or writing (`w`).                       |
| `puts var`                 | Prints to console.                                                     |
| `puts -nonewline`          | Prints without a newline at the end.                                   |
| `close file`               | Closes the file handle.                                                |
| `join list sep`            | Joins a list into a string with `sep` as separator.                    |

Modify and run the test.tcl file.

![image](/Images/D5/64.png)  

Output after running test.tcl file is shown.

![image](/Images/D5/65.png) 

Contents of /tmp/2 file.

![image](/Images/D5/66.png)  

Contents of /tmp/3 file.

![image](/Images/D5/67.png)  

<pre lang="tcl"> 
# test.tcl

# ---------------------- Converting set_input_delay constraints ---------------------- #

# Find all lines containing the command 'set_input_delay' from the SDC file
set find_keyword [lsearch -all -inline $lines "set_input_delay*"]

# Open a temporary file for writing delay constraints
set tmp2_file [open /tmp/2 w]

# Initialize a variable to track the most recent port name
set new_port_name ""

# Loop through each matched line (which has 'set_input_delay')
foreach elem $find_keyword {
    
    # Extract the port name that comes immediately after 'get_ports' in the line
    set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]
    
    # Only process new ports (skip repeated ports)
    if {![string match $new_port_name $port_name]} {
        set new_port_name $port_name  ;# Update current port being processed

        # Find all matching lines related to this specific port
        set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        
        # Display which delays are found (for debugging/confirmation)
        puts "delays list is $delays_list"

        # Create a list to hold delay values for this port
        set delay_value ""

        # Loop through each matching line and extract the delay value (which comes before get_ports)
        foreach new_elem $delays_list {
            set port_index [lsearch $new_elem "get_ports"]
            lappend delay_value [lindex $new_elem [expr {$port_index - 1}]]
        }

        # Write the extracted info into the temp file in the form: "at <port_name> <delay_values>"
        puts -nonewline $tmp2_file "\nat $port_name $delay_value"
    }
}

# Close the write stream to the temporary file
close $tmp2_file

# Reopen the temporary file for reading its contents
set tmp2_file [open /tmp/2 r]

# Append the contents to the final timing file
puts -nonewline $timing_file [read $tmp2_file]

# Close the file after reading
close $tmp2_file

# ---------------------- Converting set_input_transition constraints ---------------------- #

# Similar steps to input_delay, but now for transition (slew) values
set find_keyword [lsearch -all -inline $lines "set_input_transition*"]
set tmp2_file [open /tmp/2 w]
set new_port_name ""

foreach elem $find_keyword {
    set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1}]]

    if {![string match $new_port_name $port_name]} {
        set new_port_name $port_name

        # Find all transition settings for this port
        set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        puts "delays list is $delays_list"

        set delay_value ""

        foreach new_elem $delays_list {
            set port_index [lsearch $new_elem "get_ports"]
            lappend delay_value [lindex $new_elem [expr {$port_index - 1}]]
        }

        # Write the slew (transition) values in the form: "slew <port_name> <value1> <value2>..."
        puts -nonewline $tmp2_file "\nslew $port_name $delay_value"
    }
}

close $tmp2_file
set tmp2_file [open /tmp/2 r]
puts -nonewline $timing_file [read $tmp2_file]
close $tmp2_file
</pre>

| Syntax                          | Meaning                                                               |
| ------------------------------- | --------------------------------------------------------------------- |
| `set var value`                 | Assigns `value` to the variable `var`                                 |
| `foreach var list { ... }`      | Loops through each item in `list`, assigning it to `var` in the loop  |
| `if {condition} { ... }`        | Runs the block only if `condition` is true                            |
| `lsearch list pattern`          | Finds the index of the item matching the pattern                      |
| `lsearch -all -inline list pat` | Returns all elements matching the pattern (not just indexes)          |
| `lindex list index`             | Gets the item at position `index` from the list                       |
| `lappend list_var item`         | Appends `item` to the list stored in `list_var`                       |
| `expr {...}`                    | Evaluates arithmetic/logic expressions                                |
| `string match pattern string`   | Checks if `string` matches the pattern (like `==` but with wildcards) |
| `join list separator`           | Combines items in a list using the separator string                   |
| `open filename mode`            | Opens a file with a given mode (`r`, `w`, `a`)                        |
| `close fileID`                  | Closes the opened file                                                |
| `puts`                          | Prints output (to console or file)                                    |
| `puts -nonewline fileID string` | Writes a string without adding a new line                             |
| `read fileID`                   | Reads the contents of the file                                        |

![image](/Images/D5/68.png) 

Output after running modified test.tcl file is shown.

![image](/Images/D5/69.png)  
![image](/Images/D5/70.png)  

Contents of /tmp/2 file.

![image](/Images/D5/71.png)  
![image](/Images/D5/72.png)  

<pre lang="tcl"> 
# test.tcl

#---------------------------------- converting set_output_delay constraints ----------------------------------#

# Find all lines that contain "set_output_delay"
set find_keyword [lsearch -all -inline $lines "set_output_delay*"]

# Open a temporary file /tmp/2 in write mode
set tmp2_file [open /tmp/2 w]

# Variable to track the current port name so we don’t repeat the same one
set new_port_name ""

# Loop through each matching "set_output_delay" line
foreach elem $find_keyword {
    
    # Get the port name from the line – it's right after the word "get_ports"
    set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
    
    # If this port name is not the same as the previous one processed
    if {![string match $new_port_name $port_name]} {
        
        # Update the current port name
        set new_port_name $port_name
        
        # Find all set_output_delay lines that include this port name
        set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        
        # Initialize delay values list
        set delay_value ""
        
        # For each matching delay constraint line
        foreach new_elem $delays_list {
            
            # Find the index of "get_ports" in the line
            set port_index [lsearch $new_elem "get_ports"]
            
            # Append the value just before "get_ports" to the delay_value list (the delay value itself)
            lappend delay_value [lindex $new_elem [expr {$port_index-1} ]]
        }

        # Write a new line into the tmp file with port and all its delay values
        puts -nonewline $tmp2_file "\nrat $port_name $delay_value"
    }
}

# Close the write handle
close $tmp2_file

# Reopen the temporary file in read mode
set tmp2_file [open /tmp/2 r]

# Append the contents to the final timing file (assumed already opened)
puts -nonewline $timing_file [read $tmp2_file]

# Close the file after reading
close $tmp2_file


#---------------------------------- converting set_load constraints ----------------------------------#

# Find all lines that contain "set_load"
set find_keyword [lsearch -all -inline $lines "set_load*"]

# Open a temporary file again
set tmp2_file [open /tmp/2 w]

# Reset port tracking variable
set new_port_name ""

# Loop through each matching set_load line
foreach elem $find_keyword {
    
    # Get the port name after the "get_ports" keyword
    set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
    
    # If this is a new port name
    if {![string match $new_port_name $port_name]} {
        
        set new_port_name $port_name
        
        # Find all set_load lines related to this port
        set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
        
        set delay_value ""
        
        # Collect all delay values
        foreach new_elem $delays_list {
            set port_index [lsearch $new_elem "get_ports"]
            lappend delay_value [lindex $new_elem [expr {$port_index-1} ]]
        }

        # Write the port and delays in custom format to tmp file
        puts -nonewline $tmp2_file "\nload $port_name $delay_value"
    }
}

# Close temp file after writing
close $tmp2_file

# Open it again to read contents
set tmp2_file [open /tmp/2 r]

# Read the file, split it into lines, remove duplicates using lsort -unique, and rejoin to string
puts -nonewline $timing_file [join [lsort -unique [split [read $tmp2_file] \n]] \n]

# Close both temp and timing files
close $tmp2_file
close $timing_file
</pre>

| **Tcl Command**        | **Meaning / Usage**                                      |
| ---------------------- | -------------------------------------------------------- |
| `set var value`        | Assigns a value to a variable                            |
| `open path mode`       | Opens a file in specified mode (`r`, `w`, `a`)           |
| `close fileId`         | Closes a file that was opened                            |
| `puts`                 | Prints text to console or writes to a file               |
| `puts -nonewline`      | Same as `puts`, but doesn't add a new line               |
| `foreach var list`     | Loops over each element in a list                        |
| `lindex list index`    | Fetches the value at `index` in `list`                   |
| `lsearch`              | Searches a list and returns index of a match             |
| `lsearch -all -inline` | Returns a list of all matching elements                  |
| `lappend list val`     | Appends a value to a list                                |
| `expr {}`              | Evaluates math expressions (e.g., addition, subtraction) |
| `string match`         | Checks if two strings match (can use wildcards like `*`) |
| `join list sep`        | Joins list elements into a string using separator        |
| `split str sep`        | Splits string into a list using separator                |
| `lsort -unique`        | Sorts a list and removes duplicates                      |

![image](/Images/D5/73.png)  

Output after running modified test.tcl file is shown. 

![image](/Images/D5/74.png)  

Contents of /tmp/2 file.

![image](/Images/D5/75.png)  

Contents of /tmp/3 file.

![image](/Images/D5/76.png)  
![image](/Images/D5/77.png)  

Next task:

![image](/Images/D5/78.png)  

<pre lang="tcl"> 
# test.tcl

# Open a new file to write timing data. The file path is constructed using
# the directory of the SDC file and the base filename with ".timing" extension.
set ot_timing_file [open $sdc_dirname/$sdc_filename.timing w]

# Print the directory where the SDC file is located (for debugging/info)
puts "sdc_dirname is $sdc_dirname"

# Print the base name of the SDC file without extension (for debugging/info)
puts "sdc_filename is $sdc_filename"

# Print the file handle ID returned by open, useful for debugging
puts "ot_timing_file is $ot_timing_file"

# Open a temporary file (/tmp/3) in read mode, which contains processed timing lines
set timing_file [open /tmp/3 r]

# Read the timing file line-by-line
while {[gets $timing_file line] != -1} {

    # Check if the current line contains an asterisk '*' character anywhere
    # This usually indicates a "bussed" signal or a group of signals
    if {[regexp -all -- {\*} $line]} {

        # Extract the "bussed" signal name by:
        # 1) Splitting the line at '*'
        # 2) Taking the part before '*' (index 0)
        # 3) Splitting that part by spaces and taking the second word (index 1)
        set bussed [lindex [lindex [split $line "*"] 0] 1]

        # Print the extracted bussed signal name along with the original line (debugging)
        puts "bussed is $bussed in \"$line\""

        # Open the final synthesized netlist file in read mode
        # This file contains synthesized Verilog code, which we will search through
        set final_synth_netlist [open $sdc_dirname/$sdc_filename.final.synth.v r]

        # Read the synthesized netlist file line-by-line
        while {[gets $final_synth_netlist line2] != -1 } {

            # Check if the current netlist line contains the bussed signal AND the word "input"
            # Also ensure the original timing line is not empty
            if {[regexp -all -- $bussed $line2] && [regexp -all -- {input} $line2] && ![string match "" $line]} {

                # Debug prints showing what matched and why
                puts "bussed $bussed matches line2 $line2 in $sdc_dirname/$sdc_filename.final.synth.v"
                puts "string \"input\" found in $line2"
                puts "null string \"\" doesn't match $line in $timing_file"

                # Write a new line to the timing output file with a custom formatted string:
                # Format is: <first word before '*' in line> <second word before ';' in line2> <part after '*'>
                # This is a way to map the bussed signal timing info to input pins in synthesized netlist
                puts -nonewline $ot_timing_file "\n[lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"

                # More debug prints breaking down parts of the split strings
                puts "ot_part1 is [split $line "*"]"
                puts "input_ot_part1 is [lindex [lindex [split $line "*"] 0 ] 0 ]"
                puts "input_ot_part2 is [lindex [lindex [split $line2 \"; \"] 0 ] 1 ]"
                puts "input_ot_part3 is [lindex [split $line "*"] 1 ]"
                puts "input_ot_part is [lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 \"; \"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"

            # Else if the line contains the bussed signal and the word "output" (not input)
            } elseif {[regexp -all -- $bussed $line2] && [regexp -all -- {output} $line2] && ![string match "" $line]} {

                # Debug print for output port matching
                puts "string \"output\" matches line2 $line2 in $sdc_dirname/$sdc_filename.final.synth.v"

                # Write similarly formatted line to timing output for output ports
                puts -nonewline $ot_timing_file "\n[lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 \";\"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"

                # Debug print for constructed output line
                puts "output_ot_part is [lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 \";\"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
            }
        }
    } else {
        # If the line does not contain '*', write the line as-is to the output timing file
        puts -nonewline $ot_timing_file "\n$line"
    }
}

# Close the opened timing input file after processing all lines
close $timing_file

# Print the final timing file path for informational purposes
puts "set_timing_fpath $sdc_dirname/$sdc_filename.timing"
</pre>

| **Command / Syntax**                | **Description**                                                                          |
| ----------------------------------- | ---------------------------------------------------------------------------------------- |
| `lindex list index`                 | Extracts an element from a list at the given 0-based index.                              |
| `split string sep`                  | Splits a string into a list of substrings separated by `sep`.                            |
| `regexp -all -- {pattern} string`   | Checks if `pattern` matches anywhere in `string`. Returns number of matches (0 if none). |
| `puts -nonewline filehandle string` | Writes `string` to the given filehandle without appending a newline.                     |
| `string match pattern string`       | Returns 1 if `string` matches `pattern`, else 0.                                         |

![image](/Images/D5/79.png)  

Output after running modified test.tcl file is shown.

![image](/Images/D5/80.png)  

Contents of /tmp/3 file.

![image](/Images/D5/81.png)  

Contents of timing file.

![image](/Images/D5/82.png)  
![image](/Images/D5/83.png)  

<pre lang="tcl"> 
# tclify_core.tcl

# ----- Checks whether tclify usage is correct or not ----- #

# Enable a flag for pre-layout timing (set to 1 to enable)
set enable_prelayout_timing 1

# Get current working directory by executing shell command 'pwd'
set working_dir [exec pwd]

# Extract the length of the array obtained by splitting the first command line argument ($argv 0) by '.'
set vsd_array_length [llength [split [lindex $argv 0] .]]

# Extract the file extension from the first argument by splitting it on '.' and taking the last element (index = length - 1)
set input [lindex [split [lindex $argv 0] .] [expr {$vsd_array_length - 1}]]

# Check if the file extension is NOT starting with "csv" OR if the number of command line arguments ($argc) is NOT 1
if { ![regexp {^csv} $input] || $argc != 1 } {
    # Print error message for incorrect usage
    puts "Error in usage"
    puts "Usage: ./tclify <.csv>"
    puts "where <.csv> file has below inputs"
    # Exit the script with an error
    exit
} else {
    # Continue with further processing if input is valid
}
</pre>

| **Command / Syntax**      | **Description**                                                     |
| ------------------------- | ------------------------------------------------------------------- |
| `set var value`           | Assigns `value` to variable `var`.                                  |
| `exec command`            | Executes an external shell command and returns its output.          |
| `lindex list index`       | Extracts element at 0-based `index` from `list`.                    |
| `split string sep`        | Splits `string` into a list of substrings separated by `sep`.       |
| `llength list`            | Returns the length (number of elements) of a list.                  |
| `regexp {pattern} string` | Matches `pattern` against `string`, returns 1 if matched, 0 if not. |
| `expr {expression}`       | Evaluates the mathematical or logical `expression`.                 |
| `puts string`             | Prints `string` to standard output.                                 |
| `exit`                    | Terminates the script execution immediately.                        |

![image](/Images/D5/84.png)  

<pre lang="tcl"> 
# tclify_core.tcl

# Source an external Tcl script file 'read_sdc.proc' which defines the procedure 'read_sdc'
source /home/vsduser/vsdsynth/read_sdc.proc

# Call the 'read_sdc' procedure with the full path of the SDC file constructed from variables
read_sdc $OutputDirectory/$DesignName.sdc

# Reopen standard output (stdout) to the terminal device '/dev/tty' so that output can be seen on console
reopenStdout /dev/tty

# Check if pre-layout timing flag is enabled (1 means enabled)
if {$enable_prelayout_timing == 1} {
    puts "\nInfo: enable_prelayout_timing is $enable_prelayout_timing. Enabling zero-wire load parasitics"

    # Open SPEF (Standard Parasitic Exchange Format) file for writing
    set spef_file [open $OutputDirectory/$DesignName.spef w]

    # Write various SPEF header lines describing design info and units
    puts $spef_file "*SPEF \"IEEE 1481-1998\" "
    puts $spef_file "*DESIGN \"$DesignName\" "
    puts $spef_file "*DATE \"Tue Sep 25 11:51:50 2012\" "
    puts $spef_file "*VENDOR \"TAU 2015 Contest\" "
    puts $spef_file "*PROGRAM \"Benchmark Parasitic Generator\" "
    puts $spef_file "*VERSION \"0.0\" "
    puts $spef_file "*DESIGN FLOW \"NETLIST TYPE VERILOG\" "
    puts $spef_file "*DIVIDER / "
    puts $spef_file "*DELIMITER : "
    puts $spef_file "*BUS_DELIMITER [ ] "
    puts $spef_file "*T_UNIT 1 PS "
    puts $spef_file "*C_UNIT 1 FF "
    puts $spef_file "*R_UNIT 1 KOHM "
    puts $spef_file "*L_UNIT 1 UH "

    # Close the SPEF file after writing all header lines
    close $spef_file
}

# Open the configuration file in append mode to add timing commands
set conf_file [open $OutputDirectory/$DesignName.conf a]

# Write commands to the config file for SPEF file path and timer initialization/reporting
puts $conf_file "set_spef_fpath $OutputDirectory/$DesignName.spef"
puts $conf_file "init_timer "
puts $conf_file "report_timer "
puts $conf_file "report_wns "
puts $conf_file "report_worst_paths -numPaths 10000 "

# Close the configuration file after writing all commands
close $conf_file
</pre>

| **Syntax / Command**            | **Description**                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------ |
| `source filename`               | Reads and executes Tcl commands from the specified file.                                   |
| `procedure_name arguments`      | Calls a procedure (function) with specified arguments.                                     |
| `set varName value`             | Assigns a value to a variable.                                                             |
| `if {condition} { then-block }` | Executes the then-block if condition is true.                                              |
| `open filename mode`            | Opens a file; mode can be `r` (read), `w` (write), or `a` (append). Returns a file handle. |
| `puts string`                   | Prints string to standard output or file if preceded by file handle.                       |
| `close filehandle`              | Closes an open file identified by the file handle.                                         |
| `==`                            | Equality operator used inside expressions or conditions.                                   |

<pre lang="tcl"> 
# read_sdc.proc

proc read_sdc {arg1} {
    set sdc_dirname [file dirname $arg1]
    set sdc_filename [lindex [split [file tail $arg1] .] 0 ]
    set sdc [open $arg1 r]
    set tmp_file [open /tmp/1 w]

    #puts "sdc_dirname is $sdc_dirname"
    #puts "arg1 is $arg1"
    #puts "sdc_filename is $sdc_filename"

    puts -nonewline $tmp_file [string map {"\[" "" "\]" " "} [read $sdc]]
    close $tmp_file

    #--------------------------- converting create_clock constraints --------------------------------#

    set tmp_file [open /tmp/1 r]
    set timing_file [open /tmp/3 w]
    set lines [split [read $tmp_file] "\n"]
    #puts $lines

    set find_clocks [lsearch -all -inline $lines "create_clock*"]
    #puts $find_clocks
    foreach elem $find_clocks {
        set clock_port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
        #puts "clock_port_name is $clock_port_name"
        set clock_period [lindex $elem [expr {[lsearch $elem "-period"]+1} ]]
        #puts "clock_period is $clock_period"
        set duty_cycle [expr {100 - [expr {[lindex [lindex $elem [expr {[lsearch $elem "-waveform"]+1}]] 1]*100/$clock_period}]}]
        #puts "duty_cycle is $duty_cycle"
        puts $timing_file "clock $clock_port_name $clock_period $duty_cycle"
        #puts "clock $clock_port_name $clock_period $duty_cycle\n"
    }
    close $tmp_file

    #--------------------------- converting set_clock_latency constraints --------------------------------#

    set find_keyword [lsearch -all -inline $lines "set_clock_latency*"]
    #puts $find_keyword
    set tmp2_file [open /tmp/2 w]
    set new_port_name ""
    foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_clocks"]+1} ]]
        #puts "port_name is $port_name"
        if {![string match $new_port_name $port_name]} {
            set new_port_name $port_name
            #puts "dont match"
            #puts "new_port_name is changed to $new_port_name"
            set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]] 
            #puts "delays_list is $delays_list"
            set delay_value ""
            foreach new_elem $delays_list {
                set port_index [lsearch $new_elem "get_clocks"]
                #puts "old delay_value is $delay_value"
                #puts "port_index is $port_index"
                lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
                #puts "new delay_value is $delay_value"
            }
            #puts "entering"
            puts -nonewline $tmp2_file "\nat $port_name $delay_value"
            #puts "at $port_name $delay_value\n"
        }
    }
    close $tmp2_file
    set tmp2_file [open /tmp/2 r]
    #puts -nonewline $timing_file "[join [lsort -unique [split [read $tmp2_file] \n]] \n]"
    puts -nonewline $timing_file [read $tmp2_file]
    close $tmp2_file

    #--------------------------- converting set_clock_transition constraints --------------------------------#

    set find_keyword [lsearch -all -inline $lines "set_clock_transition*"]
    set tmp2_file [open /tmp/2 w]
    set new_port_name ""
    foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_clocks"]+1}]]
        if {![string match $new_port_name $port_name]} {
            set new_port_name $port_name
            set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
            #puts "delays list is $delays_list"
            set delay_value ""
            foreach new_elem $delays_list {
                set port_index [lsearch $new_elem "get_clocks"]
                lappend delay_value [lindex $new_elem [expr {$port_index-1}]]
            }
            puts -nonewline $tmp2_file "\nslew $port_name $delay_value"
        }
    }
    close $tmp2_file
    set tmp2_file [open /tmp/2 r]
    puts -nonewline $timing_file [read $tmp2_file]
    close $tmp2_file

    #--------------------------- converting set_input_delay constraints --------------------------------#

    set find_keyword [lsearch -all -inline $lines "set_input_delay*"]
    set tmp2_file [open /tmp/2 w]
    set new_port_name ""
    foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
        if {![string match $new_port_name $port_name]} {
            set new_port_name $port_name
            set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
            #puts "delays list is $delays_list"
            set delay_value ""
            foreach new_elem $delays_list {
                set port_index [lsearch $new_elem "get_ports"]
                lappend delay_value [lindex $new_elem [expr {$port_index-1} ]]
            }
            puts -nonewline $tmp2_file "\nat $port_name $delay_value"
        }
    }
    close $tmp2_file
    set tmp2_file [open /tmp/2 r]
    puts -nonewline $timing_file [read $tmp2_file]
    close $tmp2_file

    #--------------------------- converting set_input_transition constraints --------------------------------#

    set find_keyword [lsearch -all -inline $lines "set_input_transition*"]
    set tmp2_file [open /tmp/2 w]
    set new_port_name ""
    foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
        if {![string match $new_port_name $port_name]} {
            set new_port_name $port_name
            set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
            #puts "delays list is $delays_list"
            set delay_value ""
            foreach new_elem $delays_list {
                set port_index [lsearch $new_elem "get_ports"]
                lappend delay_value [lindex $new_elem [expr {$port_index-1} ]]
            }
            puts -nonewline $tmp2_file "\nslew $port_name $delay_value"
        }
    }
    close $tmp2_file
    set tmp2_file [open /tmp/2 r]
    puts -nonewline $timing_file [read $tmp2_file]
    close $tmp2_file

    #--------------------------- converting set_output_delay constraints --------------------------------#

    set find_keyword [lsearch -all -inline $lines "set_output_delay*"]
    set tmp2_file [open /tmp/2 w]
    set new_port_name ""
    foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
        if {![string match $new_port_name $port_name]} {
            set new_port_name $port_name
            set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
            set delay_value ""
            foreach new_elem $delays_list {
                set port_index [lsearch $new_elem "get_ports"]
                lappend delay_value [lindex $new_elem [expr {$port_index-1} ]]
            }
            puts -nonewline $tmp2_file "\nrat $port_name $delay_value"
        }
    }
    close $tmp2_file
    set tmp2_file [open /tmp/2 r]
    puts -nonewline $timing_file [read $tmp2_file]
    close $tmp2_file

    #--------------------------- converting set_load constraints --------------------------------#

    set find_keyword [lsearch -all -inline $lines "set_load*"]
    set tmp2_file [open /tmp/2 w]
    set new_port_name ""
    foreach elem $find_keyword {
        set port_name [lindex $elem [expr {[lsearch $elem "get_ports"]+1} ]]
        if {![string match $new_port_name $port_name]} {
            set new_port_name $port_name
            set delays_list [lsearch -all -inline $find_keyword [join [list "*" " " $port_name " " "*"] ""]]
            set delay_value ""
            foreach new_elem $delays_list {
                set port_index [lsearch $new_elem "get_ports"]
                lappend delay_value [lindex $new_elem [expr {$port_index-1} ]]
            }
            puts -nonewline $tmp2_file "\nload $port_name $delay_value"
        }
    }
    close $tmp2_file
    set tmp2_file [open /tmp/2 r]
    puts -nonewline $timing_file [join [lsort -unique [split [read $tmp2_file] \n]] \n]
    close $tmp2_file
    close $timing_file

    set ot_timing_file [open $sdc_dirname/$sdc_filename.timing w]
    #puts "sdc_dirname is $sdc_dirname"
    #puts "sdc_filename is $sdc_filename"
    #puts "ot_timing_file is $ot_timing_file"
    set timing_file [open /tmp/3 r]
    while {[gets $timing_file line] != -1} {
        if {[regexp -all -- {\*} $line]} {
            set bussed [lindex [lindex [split $line "*"] 0] 1]
            #puts "bussed is $bussed in \"$line\""
            set final_synth_netlist [open $sdc_dirname/$sdc_filename.final.synth.v r]
            while {[gets $final_synth_netlist line2] != -1 } {
                if {[regexp -all -- $bussed $line2] && [regexp -all -- {input} $line2] && ![string match "" $line]} {
                    #puts "bussed $bussed matches line2 $line2 in $sdc_dirname/$sdc_filename.final.synth.v"
                    #puts "string \"input\" found in $line2"
                    #puts "null string \"\" doesn't match $line in $timing_file"
                    puts -nonewline $ot_timing_file "\n[lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
                    #puts "ot_part1 is [split $line "*"]"
                } elseif {[regexp -all -- $bussed $line2] && [regexp -all -- {output} $line2] && ![string match "" $line]} {
                    #puts "string \"output\" matches line2 $line2 in $sdc_dirname/$sdc_filename.final.synth.v"
                    puts -nonewline $ot_timing_file "\n[lindex [lindex [split $line "*"] 0 ] 0 ] [lindex [lindex [split $line2 ";"] 0 ] 1 ] [lindex [split $line "*"] 1 ]"
                }
            }
        } else {
            puts -nonewline $ot_timing_file "\n$line"
        }
    }
    close $timing_file
    puts "set_timing_fpath $sdc_dirname/$sdc_filename.timing"    
}
</pre>

![image](/Images/D5/85.png)

Output after running tclify command is shown.
Open conf file.

![image](/Images/D5/86.png)  

Use gf to open the links without clocking the main file.

![image](/Images/D5/87.png)  
![image](/Images/D5/88.png)  
![image](/Images/D5/89.png)  
![image](/Images/D5/90.png) 

Next task:

![image](/Images/D5/91.png)  

<pre lang="tcl"> 
# tclify_core.tcl

# Set the precision (number of decimal digits) for Tcl's floating-point output to 3
set tcl_precision 3

# Measure the time taken (in microseconds) to execute the OpenTimer STA tool with the config file as input
# 'time {command} 1' runs the command once and returns the elapsed time in microseconds as a list
set time_elapsed_in_us [time {exec /home/vsduser/OpenTimer-1.0.5/bin/OpenTimer < $OutputDirectory/$DesignName.conf >& $OutputDirectory/$DesignName.results} 1]

# Print the elapsed time in microseconds to the console
puts "time elapsed in us is $time_elapsed_in_us"

# Convert the elapsed time from microseconds to seconds:
# - Extract the first element from the list returned by 'time' (which is the elapsed time)
# - Divide by 100,000 (assuming 100,000 microseconds = 0.1 second; but usually it should be 1,000,000 to convert microseconds to seconds)
# - Append the string 'sec' for readability
set time_elapsed_in_sec "[expr {[lindex $time_elapsed_in_us 0] / 100000}]sec"

# Print the elapsed time in seconds to the console
puts "time elapsed in sec is $time_elapsed_in_sec"

# Print a user-friendly info message about the completion of Static Timing Analysis (STA)
puts "\nInfo: STA finished in $time_elapsed_in_sec seconds"

# Inform user where to find warnings and errors generated during the STA run
puts "\nInfo: Refer to $OutputDirectory/$DesignName.results for warnings and errors"
</pre>

| **Syntax / Command**                             | **Description**                                                                                                  |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `set varName value`                              | Assigns a value to a variable.                                                                                   |
| `time {script} count`                            | Measures the execution time (in microseconds) of the Tcl script run `count` times and returns a list of results. |
| `exec command`                                   | Executes an external system command and returns its output.                                                      |
| `puts string`                                    | Prints the string to standard output (console).                                                                  |
| `expr {expression}`                              | Evaluates a mathematical or logical expression and returns the result.                                           |
| `lindex list index`                              | Returns the element at `index` from the list (0-based).                                                          |
| String concatenation by placing strings adjacent | You can concatenate strings by putting them next to each other or inside quotes with variables included.         |
| Comments start with `#`                          | Everything after `#` on a line is ignored by Tcl, used for writing comments.                                     |

![image](/Images/D5/92.png)  

Output after running tclify command is shown.
Open results file.

![image](/Images/D5/93.png)  
![image](/Images/D5/94.png)  

Search ``/RAT`` to find worst output delay violation. Press n to see next result.

![image](/Images/D5/95.png)  

As it goes down, RAT only decreases.

![image](/Images/D5/96.png)  
![image](/Images/D5/97.png) 

Use grep command to filter out "RAT".

![image](/Images/D5/98.png)  

Check the word count of filtered results.

![image](/Images/D5/99.png)  

<pre lang="tcl"> 
# tclify_core.tcl

# Print the current precision setting for floating-point calculations in Tcl
puts "tcl_precision is $tcl_precision"

# --- Find worst output delay violation (RAT slack) from results file --- #
set worst_RAT_slack "-"                   ;# Initialize variable to "-" indicating no violation found yet
set report_file [open $OutputDirectory/$DesignName.results r]  ;# Open the results file for reading
puts "report_file is $OutputDirectory/$DesignName.results"
set pattern {RAT}                         ;# Pattern to search for lines containing "RAT" (Required Arrival Time slack)
puts "pattern is $pattern"

# Read the results file line by line
while {[gets $report_file line] != -1} {
    # If the current line contains the pattern "RAT"
    if {[regexp $pattern $line]} {
        puts "pattern \"$pattern\" found in \"$line\""
        puts "old worst_RAT_slack is $worst_RAT_slack"
        # Extract the 4th element (index 3) of the line (assuming line is a list), convert to ns by dividing by 1000
        set worst_RAT_slack "[expr {[lindex $line 3]/1000}]ns"
        puts "part1 is [lindex $line 3]"
        puts "new worst_RAT_slack is $worst_RAT_slack"
        puts "breaking"
        break                                ;# Exit loop after finding the first occurrence
    } else {
        continue                             ;# Continue reading next lines if pattern not found
    }
}
close $report_file                          ;# Close the results file after reading

# ----- Find number of output violations (count of "RAT" occurrences) ----- #
set report_file [open $OutputDirectory/$DesignName.results r]  ;# Open results file again for counting
set count 0                           ;# Initialize counter to zero
puts "inital count is $count"
puts "being_count"
while {[gets $report_file line] != -1} {
    # Increment count by the number of occurrences of pattern in the current line
    incr count [regexp -all -- $pattern $line]
}
set Number_output_violations $count       ;# Store total count of output violations
puts "Number_output_violations is $Number_output_violations"
close $report_file                        ;# Close file after counting

# ----- Find worst setup violation slack ----- #
set worst_negative_setup_slack "-"        ;# Initialize worst setup slack
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Setup}                       ;# Pattern to search for setup violations

while {[gets $report_file line] != -1} {
    if {[regexp $pattern $line]} {
        # Extract and convert slack value to ns from 4th element of line
        set worst_negative_setup_slack "[expr {[lindex $line 3]/1000}]ns"
        break
    } else {
        continue
    }
}
close $report_file

# ----- Find number of setup violations ----- #
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
    incr count [regexp -all -- $pattern $line]
}
set Number_of_setup_violations $count
close $report_file

# ----- Find worst hold violation slack ----- #
set worst_negative_hold_slack "-"
set report_file [open $OutputDirectory/$DesignName.results r]
set pattern {Hold}                      ;# Pattern for hold violations

while {[gets $report_file line] != -1} {
    if {[regexp $pattern $line]} {
        set worst_negative_hold_slack "[expr {[lindex $line 3]/1000}]ns"
        break
    } else {
        continue
    }
}
close $report_file

# ----- Find number of hold violations ----- #
set report_file [open $OutputDirectory/$DesignName.results r]
set count 0
while {[gets $report_file line] != -1} {
    incr count [regexp -all -- $pattern $line]
}
set Number_of_hold_violations $count
close $report_file

# ----- Find number of instances (gates) ----- #
set pattern {Num of gates}                ;# Pattern that indicates instance count in the report
set report_file [open $OutputDirectory/$DesignName.results r]

while {[gets $report_file line] != -1} {
    if {[regexp -all -- $pattern $line]} {
        # Extract the 5th element (index 4) from the line, assumed to be the instance count
        set Instance_count [lindex [join $line " "] 4]
        puts "pattern \"$pattern\" found at line \"$line\""
        break
    } else {
        continue
    }
}
close $report_file

# ----- Print all extracted results for easy visibility ----- #
puts "DesignName is \{$DesignName\}"
puts "time_elapsed_in_sec is \{$time_elapsed_in_sec\}"
puts "Instance_count is \{$Instance_count\}"
puts "worst_negative_setup_slack is \{$worst_negative_setup_slack\}"
puts "Number_of_setup_violations is \{$Number_of_setup_violations\}"
puts "worst_negative_hold_slack is \{$worst_negative_hold_slack\}"
puts "Number_of_hold_violations is \{$Number_of_hold_violations\}"
puts "worst_RAT_slack is \{$worst_RAT_slack\}"
puts "Number_output_violations is \{$Number_output_violations\}"
</pre>

| **Syntax / Command**                        | **Description**                                                                                 |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `set varName value`                         | Assigns a value to a variable.                                                                  |
| `open filename mode`                        | Opens a file with specified mode (`r` for read, `w` for write, etc.) and returns a file handle. |
| `gets fileHandle var`                       | Reads a single line from the file into variable `var`, returns -1 on EOF.                       |
| `close fileHandle`                          | Closes an opened file.                                                                          |
| `regexp pattern string`                     | Returns 1 if the pattern matches anywhere in the string, else 0.                                |
| `regexp -all -- pattern string`             | Returns the number of occurrences of `pattern` in `string`.                                     |
| `lindex list index`                         | Extracts element at zero-based `index` from a list.                                             |
| `join list ?joinString?`                    | Joins elements of a list into a string separated by `joinString` (default is space).            |
| `incr varName ?increment?`                  | Increments variable `varName` by 1 or by the optional `increment`.                              |
| `expr {expression}`                         | Evaluates a mathematical or logical expression and returns the result.                          |
| `puts string`                               | Prints a string to standard output (console).                                                   |
| `while {condition} { script }`              | Loops while the condition evaluates to true.                                                    |
| `if {condition} { script } else { script }` | Conditional execution based on the evaluation of the condition.                                 |
| Comments start with `#`                     | Everything after `#` on the line is ignored by Tcl and is used for comments/documentation.      |

![image](/Images/D5/100.png)  
![image](/Images/D5/101.png)  

Output after running tclify command is shown.

![image](/Images/D5/103.png)  

<pre lang="tcl"> 
# tclify_core.tcl

puts "\n"  
# Print a newline for better output spacing

# Print the heading line for the prelayout timing results section
puts "                                                    ***** PRELAYOUT TIMING RESULTS *****                                          "

# Define a format string for fixed-width columns, 15 characters each, for 9 columns
set formatStr {%15s%15s%15s%15s%15s%15s%15s%15s%15s}

# Print a line of dashes formatted according to the format string to act as a table border/header separator
puts [format $formatStr "-----------" "----------" "----------" "----------" "----------" "----------" "----------" "----------" "----------"]

# Print the column headers (field names) using the format string for aligned output
puts [format $formatStr "Design Name" "Runtime" "Instance Count" "WNS setup" "FEP Setup" "WNS Hold" "FEP Hold" "WNS RAT" "FEP RAT"]

# Print another separator line under the headers
puts [format $formatStr "-----------" "----------" "----------" "----------" "----------" "----------" "----------" "----------" "----------"]

# Print the actual data row:
# foreach here iterates through all variables, but since your variables are single values, this acts like a single iteration.
foreach design_name $DesignName runtime $time_elapsed_in_sec instance_count $Instance_count wns_setup $worst_negative_setup_slack fep_setup $Number_of_setup_violations wns_hold $worst_negative_hold_slack fep_hold $Number_of_hold_violations wns_rat $worst_RAT_slack fep_rat $Number_output_violations {
    # Format and print the values using the format string, which aligns everything in columns
    puts [format $formatStr $design_name $runtime $instance_count $wns_setup $fep_setup $wns_hold $fep_hold $wns_rat $fep_rat]
}

# Print a closing separator line to end the table
puts [format $formatStr "-----------" "----------" "----------" "----------" "----------" "----------" "----------" "----------" "----------"]

puts "\n"  
# Print another newline for spacing after the table
</pre>

| **Syntax/Command**                        | **Explanation**                                                                                               |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `puts "string"`                           | Prints the string to the console, followed by a newline.                                                      |
| `set varName value`                       | Assigns a value to a variable.                                                                                |
| `format formatStr args`                   | Formats the arguments according to the C-style format string (e.g., `%15s` means a 15-character wide string). |
| `foreach var1 val1 var2 val2 ... { ... }` | Iterates over the list(s), assigning values to variables. Here used to unpack multiple variables.             |

![image](/Images/D5/104.png)  

Output after running tclify command is shown.

![image](/Images/D5/105.png)  

<pre lang="tcl"> 
# tclify_core.tcl

set Instance_count "$Instance_count 6500"
xset worst_negative_hold_slack "$worst_negative_hold_slack -0.0200ns"
</pre>

![image](/Images/D5/106.png)  

Output after running tclify command is shown.

![image](/Images/D5/107.png)
