## Module 4: Synthesis & Yosys Integration
- Developing complete synthesis scripts
- Memory module synthesis using Yosys
- Hierarchy checks and error handling in TCL

<pre lang="tcl"> 
# tclify_core.tcl

#-------------------create output delay and load constraints--------------------##

# These commands locate the starting row index of specific timing constraints from a constraints matrix
# The matrix is searched from the column of clocks ($clock_start_column) to the last column, and from
# the output port section to the last row. 
# Each command isolates the row corresponding to a specific constraint.

set output_early_rise_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_rise_delay] 0 ] 0]
set output_early_fall_delay_start [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] early_fall_delay] 0 ] 0]
set output_late_rise_delay_start  [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_rise_delay] 0 ] 0]
set output_late_fall_delay_start  [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] late_fall_delay] 0 ] 0]
set output_load_start             [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] load] 0 ] 0]
set related_clock                 [lindex [lindex [constraints search rect $clock_start_column $output_ports_start [expr {$number_of_columns-1}] [expr {$number_of_rows-1}] clocks] 0 ] 0]

# Initialize iteration: Start just after output_ports_start
set i [expr {$output_ports_start+1}]
# Define where to stop the loop: at the bottom of the matrix (last row)
set end_of_ports [expr {$number_of_rows}]

puts "\nInfo-SDC: Working on IO constraints ..... "
puts "\nInfo-SDC: Categorizing output ports as bits and bussed"

# Loop through each output port row
while { $i < $end_of_ports } {
    # Search all .v Verilog files in the netlist directory
    set netlist [glob -dir $NetlistDirectory *.v]
    set tmp_file [open /tmp/1 w]

    # Go through each file to find the current port
    foreach f $netlist {
        set fd [open $f r]
        while {[gets $fd line] != -1} {
            # Form a pattern to search the Verilog line
            set pattern1 " [constraints get cell 0 $i];"
            if {[regexp -all -- $pattern1 $line]} {
                set pattern2 [lindex [split $line ";"] 0]
                
                # Check if the line declares an output
                if {[regexp -all {output} [lindex [split $pattern2 "\S+"] 0]]} {
                    # Extract the first 3 tokens (e.g., output [3:0] led)
                    set s1 "[lindex [split $pattern2 "\S+"] 0] [lindex [split $pattern2 "\S+"] 1] [lindex [split $pattern2 "\S+"] 2]"

                    # Remove extra whitespace and write to temp file
                    puts -nonewline $tmp_file "\n[regsub -all {\s+} $s1 " "]"
                }
            }
        }
        close $fd
    }
    close $tmp_file

    # Re-open the tmp file, clean duplicates and count lines
    set tmp_file [open /tmp/1 r]
    set tmp2_file [open /tmp/2 w]
    puts -nonewline $tmp2_file "[join [lsort -unique [split [read $tmp_file] \n]] \n]"
    close $tmp_file
    close $tmp2_file

    # Read cleaned tmp2 file and count how many lines (tokens)
    set tmp2_file [open /tmp/2 r]
    set count [llength [read $tmp2_file]]

    # Decide if output is bussed (e.g., led[3:0]) or bit
    if {$count > 2} {
        set op_ports [concat [constraints get cell 0 $i]*]
    } else {
        set op_ports [constraints get cell 0 $i]
    }

    # Write SDC timing constraints for output ports
    puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -rise -source_latency_included [constraints get cell $output_early_rise_delay_start $i] \[get_ports $op_ports\]"
    puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -min -fall -source_latency_included [constraints get cell $output_early_fall_delay_start $i] \[get_ports $op_ports\]"
    puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -rise -source_latency_included [constraints get cell $output_late_rise_delay_start $i] \[get_ports $op_ports\]"
    puts -nonewline $sdc_file "\nset_output_delay -clock \[get_clocks [constraints get cell $related_clock $i]\] -max -fall -source_latency_included [constraints get cell $output_late_fall_delay_start $i] \[get_ports $op_ports\]"

    # Add output load
    puts -nonewline $sdc_file "\nset_load [constraints get cell $output_load_start $i] \[get_ports $op_ports\]"

    # Move to next port
    set i [expr {$i+1}]
}

# Cleanup: Close temp file and final SDC file
close $tmp2_file
close $sdc_file

puts "\nInfo: SDC created. Please use constraints in path  $OutputDirectory/$DesignName.sdc"
</pre>
  
![image](/Images/D4/1.png)
![image](/Images/D4/2.png)

Output of running tclify command. 

![image](/Images/D4/3.png)
![image](/Images/D4/4.png)
![image](/Images/D4/5.png)

Displaying contents of the sdc file.

![image](/Images/D4/6.png)
![image](/Images/D4/7.png)

Next sub task.
![image](/Images/D4/8.png)

Explanation of the memory module.
![image](/Images/D4/9.png)
![image](/Images/D4/10.png)
![image](/Images/D4/11.png)
![image](/Images/D4/12.png)

```verilog
//memory.v
  
// Define a module named 'memory' with ports: CLK (clock), ADDR (address), DIN (data input), DOUT (data output)
module memory (CLK, ADDR, DIN, DOUT);
    
// Define parameters: wordSize (width of data) and addressSize (number of address bits)
// These can be overridden during module instantiation
parameter wordSize = 1;
parameter addressSize = 1;
    
// Declare input signals:
// ADDR: address to access memory
// CLK : clock signal to trigger memory operations
input ADDR, CLK;
    
// DIN: input data of width [wordSize - 1:0]
input [wordSize-1:0] DIN;
    
// DOUT: output data, declared as 'reg' since it is assigned in always block
output reg [wordSize-1:0] DOUT;
    
// Declare memory: an array of 2^addressSize locations
// Each location stores [wordSize:0] bits
reg [wordSize:0] mem [0:(1<<addressSize)-1];
                               
// Always block triggered on the rising edge of CLK
// This simulates synchronous memory behavior (write and read on clock edge)
always @(posedge CLK) begin
    mem[ADDR] <= DIN;   // Write input data (DIN) to memory at address ADDR
    DOUT <= mem[ADDR];  // Read data from memory at address ADDR and output it
end
        
endmodule
        
// Add this file inside the verilog module directory
```

<pre lang="markdown">
# memory.ys - file containing all yosys commands
    
# Read the standard cell library used for synthesis
# -lib             : tells yosys it's a library file, not a design file
# -ignore_miss_dir : avoids errors if pin directions are missing
# -setattr blackbox: marks cells as blackbox modules (used for logic synthesis)
read_liberty -lib -ignore_miss_dir -setattr blackbox /home/vsduser/vsdsynth/osu018_stdcells.lib
# Read the Verilog RTL source file
read_verilog memory.v
# Define the top-level module for synthesis
# This is necessary if there are multiple modules or hierarchy
synth -top memory
# Split multi-bit nets connected to ports into separate 1-bit wires
# Useful for older tools or gate-level synthesis
splitnets -ports -format
# Map flip-flops and sequential elements using the provided standard cell library
dfflibmap -liberty /home/vsduser/vsdsynth/osu018_stdcells.lib
# Perform generic optimizations (remove redundant logic, constant folding, etc.)
opt
# Run technology mapping using ABC tool (And-Inverter Graph based logic synthesis)
# Converts RTL-level logic into gates from the given library
abc -liberty /home/vsduser/vsdsynth/osu018_stdcells.lib
# Flatten hierarchical modules into a single-level netlist
flatten
# Clean up unnecessary wires, cells, and modules aggressively
clean -purge
# Run another round of optimizations after flattening
opt
# Clean up again to remove anything unused after optimization
clean
# Write the final synthesized gate-level Verilog netlist to a file
write_verilog memory_synth.v
</pre>

![image](/Images/D4/13.png)

Open yosys.

![image](/Images/D4/14.png)

Put in the commands present in the .ys file.

![image](/Images/D4/15.png)

```show```command opens a GUI window showing the schematic of the current design.

![image](/Images/D4/16.png)
![image](/Images/D4/17.png)

Next task.

![image](/Images/D4/18.png)

<pre lang="tcl">
# tclify_core.tcl

# Print message
puts "\nInfo: Creating hierarchy check script to be used by Yosys"

# Set a Tcl variable 'data' with Yosys command to read liberty file as a blackbox
# ${LateLibraryPath} is expected to contain the path to a .lib file
set data "read_liberty -lib -ignore_miss_dir -setattr blackbox ${LateLibraryPath}"

# Print the command that was set (for debugging/logging)
puts "data is \"$data\""

# Construct the output filename as <DesignName>.hier.ys
set filename "$DesignName.hier.ys"
puts "filename is \"$filename\""

# Open a file in write mode (w) inside $OutputDirectory with the name stored in $filename
# The file will store Yosys commands
set fileId [open $OutputDirectory/$filename "w"]
puts "open \"$OutputDirectory/$filename\" in write mode"

# Write the first command to the file without adding a newline at the end
puts -nonewline $fileId $data

# Get a list of all .v files (Verilog files) in the $NetlistDirectory
set netlist [glob -dir $NetlistDirectory *.v]
puts "netlist is \"$netlist\""

# Loop through each Verilog file in the netlist
foreach f $netlist {
    # Store current file name in 'data'
    set data $f
    puts "data is \"$f\""

    # Write 'read_verilog <file>' command to the output file without adding an extra newline
    puts -nonewline $fileId "\nread_verilog $f"
}

# Finally, add the 'hierarchy -check' command to ensure hierarchy is well-formed
puts -nonewline $fileId "\nhierarchy -check"

# Close the file to save changes
close $fileId
</pre>

![image](/Images/D4/19.png)

Output after running tclify. 
Open openMSP430.hier.ys file which contains Yosys synthesis commands.

![image](/Images/D4/20.png)

![image](/Images/D4/21.png)

<pre lang="tcl">
# tclify_core.tcl

# Indicates that the file writing is done and the file is now closed
puts "\nclose \"$OutputDirectory/$filename\"\n"

# Print that hierarchy checking is starting
puts "\nChecking hierarchy ....."

# Run the hierarchy check using Yosys and capture both standard output and error output in a log file
# 'exec' is used to run shell commands
# 'yosys -s $OutputDirectory/$DesignName.hier.ys' runs Yosys with the generated .ys script
# '>&' redirects both standard output (stdout) and standard error (stderr) to the same file
# The log is saved to: $OutputDirectory/$DesignName.hierarchy_check.log
# 'catch' is used to trap errors from the exec command; if any error occurs, it returns a non-zero flag
set my_err [catch {
    exec yosys -s $OutputDirectory/$DesignName.hier.ys >& $OutputDirectory/$DesignName.hierarchy_check.log
} msg]

# Print the error flag: 0 means success, 1 means error occurred
puts "err flag is $my_err"
</pre>

![image](/Images/D4/22.png)

Output after running tclify command. 

![image](/Images/D4/23.png)

Changing the ``osmp_clock_module`` instance name in the openMSP430.v top module. 

![image](/Images/D4/26.png)

Output after running tclify command.

![image](/Images/D4/27.png)

Checking the openMSP430_hierarchy_check.log file for ERROR. 

![image](/Images/D4/28.png)
![image](/Images/D4/29.png)

Using ``grep`` command to check error in log file.

![image](/Images/D4/30.png)

Changing the ``osmp_clock_module`` instance name back to normal.

![image](/Images/D4/31.png)

Running tclify again. No error shows up.

![image](/Images/D4/32.png)

Checking the log file for ERROR.

![image](/Images/D4/33.png)

Check where the ``osmp_clock_module`` is present.

![image](/Images/D4/34.png)

<pre lang="tcl">
# tclify_core.tcl

# Check if there was an error (my_err == 1 means error occurred during Yosys execution)
if { $my_err } {

    # Set the log file name where Yosys hierarchy check messages were stored
    set filename "$OutputDirectory/$DesignName.hierarchy_check.log"
    puts "log file name is $filename"

    # Define a pattern to search for in the log: the phrase "referenced in module"
    # This is used to detect if any module was referenced but not defined (i.e., missing from RTL)
    # This pattern is different for different tools
    set pattern {referenced in module}
    puts "pattern is $pattern"

    # Initialize error count
    set count 0

    # Open the log file for reading ('r' = read mode)
    set fid [open $filename r]

    # Read the file line by line till EOL
    while {[gets $fid line] != -1} {

        # Increment count if the pattern is found in the line
        incr count [regexp -all -- $pattern $line]

        # If the pattern is found in the current line
        if {[regexp -all -- $pattern $line]} {
            
            # Extract the third word from the line (module name) and print an error
            puts "\nError: module [lindex $line 2] is not part of design $DesignName. Please correct RTL in the path '$NetlistDirectory'"

            # Notify that the hierarchy check failed
            puts "\nInfo: Hierarchy check FAIL"
        }
    }

    # Close the file after reading
    close $fid

} else {
    # If no error occurred, print PASS message
    puts "\nInfo: Hierarchy check PASS"
}

# Print the full normalized path to the log file for reference
puts "\nInfo: Please find hierarchy check details in [file normalize $OutputDirectory/$DesignName.hierarchy_check.log] for more info"
</pre>

![image](/Images/D4/35.png)

Remove output directory and run tclify.

![image](/Images/D4/37.png)

Output is shown.
Open openMSP430.hier.ys file.

![image](/Images/D4/38.png)
![image](/Images/D4/39.png)

Open log file and check for ERROR.

![image](/Images/D4/40.png)
![image](/Images/D4/41.png)

Use grep command to search for error in log file.

![image](/Images/D4/42.png)

Modify the ``osmp_clock_module`` instance name in the openMSP430.v top module to create ERROR.

![image](/Images/D4/43.png)

Output after running tclify command is shown.

![image](/Images/D4/44.png)

Use grep command to search for error.

![image](/Images/D4/45.png)

Modify the ``osmp_clock_module`` instance name back.

![image](/Images/D4/46.png)
