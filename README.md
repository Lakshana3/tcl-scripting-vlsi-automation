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
| [Module 1](./Module%201/) | Introduction to TCL and VSDSYNTH Toolbox Usage |
| [Module 2](./Module%202/) | Variable Creation and Processing Constraints from CSV | 
| [Module 3](./Module%203/) | Processing Clock and Input Constraints | 
| [Module 4](./Module%204/) | Complete Scripting and Yosys Synthesis Introduction | 
| [Module 5](./Module%205/) | Advanced Scripting Techniques and Quality of Results Generation |

---

## Tools Required
- TCL Development Suite
- Yosys synthesis tool
- OpenTimer for timing analysis

---

## TCL Syntax used in the course

| **Tcl Syntax**                            | **Description**                                                                                     |
| ----------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `set var value`                           | Assigns a value to a variable.                                                                  |
| `$var` or `${var}`                        | Retrieves the value of a variable.                                                              |
| `puts "text"`                             | Prints text to the console, followed by a newline.                                              |
| `puts -nonewline "text"`                  | Prints without adding a newline.                                                                |
| `open filename mode`                      | Opens a file in a given mode: `"r"` (read), `"w"` (write), `"a"` (append). Returns file handle. |
| `close fileHandle`                        | Closes an open file.                                                                            |
| `gets fileHandle var`                     | Reads a line from file into `var`. Returns -1 at EOF.                                           |
| `read fileHandle`                         | Reads the entire contents of a file.                                                            |
| `glob -dir path *.ext`                    | Lists files matching a pattern (e.g., all `.v` files) in a directory.                           |
| `foreach var list {}`                     | Iterates over each item in a list.                                                              |
| `proc name {args} {body}`                 | Defines a procedure with name, arguments, and body.                                             |
| `return`                                  | Exits the current procedure and returns to caller.                                              |
| `[expr {...}]`                            | Evaluates an arithmetic or logical expression.                                                  |
| `incr var ?amount?`                       | Increments variable by 1 or optional `amount`.                                                  |
| `lindex list index`                       | Retrieves the item at a specific index from a list.                                             |
| `llength list`                            | Returns the number of elements in a list.                                                       |
| `lsearch list pattern`                    | Finds index of first element in list matching pattern.                                          |
| `lsearch -all -inline list pattern`       | Returns all matching elements in a list.                                                        |
| `lappend list_var value`                  | Appends a value to the list.                                                                    |
| `split string sep`                        | Splits a string into a list using a separator.                                                  |
| `join list sep`                           | Joins a list into a string using separator.                                                     |
| `lsort -unique list`                      | Sorts a list and removes duplicates.                                                            |
| `regexp pattern string`                   | Returns 1 if regex `pattern` matches `string`.                                                  |
| `regexp -all -- pattern string`           | Returns number of matches of `pattern` in `string`.                                             |
| `regsub pattern string replacement`       | Replaces first match of pattern. Use `-all` for all.                                            |
| `string match pattern string`             | Checks if string matches pattern (supports wildcards).                                          |
| `string map {pattern replacement} string` | Replaces all pattern occurrences in string.                                                     |
| `[command args]`                          | Executes a command and returns its result.                                                      |
| `exec command`                            | Executes an external shell/system command.                                                      |
| `catch {script} resultVar`                | Runs script, stores error flag in `resultVar`.                                                  |
| `exit`                                    | Terminates the script immediately.                                                              |
| `source filename`                         | Executes another Tcl script from a file.                                                        |
| `format formatStr args`                   | Formats strings like C’s `printf` (e.g., `%04d`).                                               |
| `# comment`                               | Comment line — ignored by interpreter.                                                          |
| `::namespace::command`                    | Calls a command from a specific namespace.                                                      |
| `array set arr {key val ...}`             | Initializes an associative array.                                                               |
| `array get arr`                           | Returns key-value pairs from the array.                                                         |
| `switch -- $var { case {...} }`           | Matches value to defined cases. Use `-glob` for patterns.                                       |
| `file exists path`                        | Checks if a file exists.                                                                        |
| `file isdirectory path`                   | Checks if a path is a directory.                                                                |
| `file normalize path`                     | Converts path to full normalized form.                                                          |
| `[file dirname path]`                     | Extracts the directory from a file path.                                                        |
| `[file tail path]`                        | Gets the filename from a path.                                                                  |
| `time {script} count`                     | Measures execution time of script repeated `count` times.                                       |
| `lassign list var1 var2`                  | Assigns values from a list to variables.                                                        |
| `"\n"` or `"\\n"`                         | Newline character in strings.                                                                   |
| `&>` or `>&` (in `exec`)                  | Redirects both stdout and stderr to a file.                                                     |

---

## Acknowledgements

I extend my sincere gratitude to Mr. Kunal Ghosh, VSD for sharing his profound expertise throughout the workshop.
