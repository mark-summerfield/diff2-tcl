#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require config
package require diff
package require util

const VERSION 0.1.0

proc main {} {
    set config [get_config]
    puts [$config to_string]
}

proc get_config {} {
    set config [Config new 0 context]
    # TODO set args [util::pre_process_args $::argv]
    set args $::argv
    for {set i 0} {$i < [llength $args]} {incr i} {
        set arg [lindex $args $i]
        switch $arg {
            -f - --format {
                $config set_fmt [lindex $args [incr i]]
            }
            -h - --help { usage }
            -D - --debug { $config set_debug 1 }
            -o - --outfile {
                $config set_outfile [lindex $args [incr i]]
            }
            -v - --version { puts $::VERSION ; exit }
            default {
                $config set_file1 [lindex $args $i]
                $config set_file2 [lindex $args [incr i]]
            }
        }
    }
    validate_config $config
}

proc validate_config config {
    set filename [$config file1]
    if {$filename eq ""} { usage 1 "file1 to compare required" }
    if {![file isfile $filename]} { usage 1 "$filename isn’t a file" }
    set filename [$config file2]
    if {$filename eq ""} { usage 1 "file2 to compare required" }
    if {![file isfile $filename]} { usage 1 "$filename isn’t a file" }
    if {[$config fmt] ni {context full unified patch}} {
        usage 1 "unrecognized output format"
    }
    return $config
}

proc usage {{code 2} {msg ""}} {
    puts [ansi "<b>ddiff.tcl<!> <y>\[OPTIONS\]<!> <e>\<file1\>\
        \<file2\><!>\n\nCompares <e>\<file1\>\<!> and <e>\<file2\><!> line\
        by line.\n\n<y><i>OPTIONS:<!>\n<g>-f<!> <i>or<!> <g>--format<!> \
        Output format: context \[default\]; full; unified;\
        patch (for nonbinary files).\n<g>-o<!> <i>or<!> <g>--outfile<!>\
        File to output the diff to \[default: stdout\].\n<g>-v<!>\
        <i>or<!> <g>--version<!> Print the program’s version and\
        quit.\n<g>-h<!> <i>or<!> <g>--help<!>    Print this usage message\
        and quit."]
    if {$msg ne ""} { puts \n[ansi "<r>error: $msg<!>"] }
    exit $code
}

main
