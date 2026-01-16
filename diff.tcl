#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require diff
package require util

proc main {} {
    set debug 0
    foreach arg $::argv {
        switch $arg {
            -h - --help { usage }
            -D - --debug { set debug 1 }
        }
    }
}

proc usage {{code 2} {msg ""}} {
    # -f|--format context (default) full unified patch
    # -o|--outfile (default stdout)
    puts [ansi "<b>diff.tcl<!> <g>\[OPTIONS\]<!> <e>\<file1\> \<file2\><!>"]
    if {$msg ne ""} { puts $msg }
    exit $code
}

main
