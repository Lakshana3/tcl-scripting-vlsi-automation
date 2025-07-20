## Module 3: Clock & Input Constraint Scripting
- Writing clock constraints with periods and duty cycles to SDC format
- Using regular expressions for input port classification

Shows how clock period is calculated.

![image](/Images/D3/1.png)

Shows how a rectangular portion is used to extract the constraints inside it.

![image](/Images/D3/2.png)
![image](/Images/D3/3.png)

<pre lang="tcl"> 
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

Run tclify.

![image](/Images/D3/6.png)

Open sdc file.

![image](/Images/D3/7.png)

Defining bussed ports.

![image](/Images/D3/8.png)

Checking where cpu_en is inside the verilog modules.

![image](/Images/D3/10.png)

The logic for showing the bussed ports is shown.

![image](/Images/D3/11.png)

<pre lang="tcl"> 
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

Changing $end_of_ports to 6 to check fewer lines.

![image](/Images/D3/14.png)

Output of running tclify is shown.

![image](/Images/D3/15.png)

Changing to $end_of_ports and running it fully.

![image](/Images/D3/16.png)
![image](/Images/D3/17.png)
![image](/Images/D3/18.png)

Run the 'tclify' script and pipe the output to 'grep' to filter and show only lines containing the phrase "replace multiple spaces".

![image](/Images/D3/19.png)

Changing $end_of_ports to 6 again.

![image](/Images/D3/20.png)

Output of running tclify is shown.

![image](/Images/D3/21.png)

Run the 'tclify' script and filter the output to show only lines containing the phrase "input port name".

![image](/Images/D3/22.png)

<pre lang="tcl"> 
# tclify_core.tcl

# Print info message.
puts "\nInfo: SDC created. Please use constraints in path $OutputDirectory/$DesignName.sdc"
</pre>

![image](/Images/D3/23.png)

Output of running tclify is shown. 
Open openMSP430.sdc file. 

![image](/Images/D3/24.png)

![image](/Images/D3/25.png)
![image](/Images/D3/26.png)
