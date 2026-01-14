#!/usr/bin/env tclsh9
# Copyright © 2026 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require diff
package require lambda 1

proc main {} {
    set debug 0
    set verbose 0
    foreach arg $::argv {
        switch $arg {
            -D - --debug { set debug 1 }
            -v - --verbose { set verbose 1 }
        }
    }
    set ok 0
    foreach i [lseq 1 9] {
        incr ok [test$i $debug $verbose]
    }
    puts "tdiff.tcl: $ok/$i OK"
}

oo::class create Place {
    variable X
    variable Y
    variable Name
}

oo::define Place constructor {x y name} {
    set X $x
    set Y $y
    set Name $name
}

oo::define Place method x {} { return $X }
oo::define Place method set_x x { set X $x }

oo::define Place method y {} { return $Y }
oo::define Place method set_y y { set Y $y }

oo::define Place method name {} { return $Name }
oo::define Place method set_name name { set Name $name }

oo::define Place method to_string {} { return "Place new $X $Y \"$Name\"" }

proc test1 {debug verbose} {
    if $debug { puts test1 } elseif $verbose { puts -nonewline "test1 " }
    set expected [list "= Place new 1 2 \"foo\"" \
                       "+ Place new 6 2 \"baz\"" \
                       "= Place new 3 4 \"bar\"" \
                       "- Place new 5 6 \"baz\"" \
                       "= Place new 7 8 \"quux\""]
    set a [list [Place new 1 2 "foo"] [Place new 3 4 "bar"] \
		[Place new 5 6 "baz"] [Place new 7 8 "quux"]]
    set b [list [Place new 1 2 "foo"] [Place new 6 2 "baz"] \
		[Place new 3 4 "bar"] [Place new 7 8 "quux"]]
    set diffs [diff::Diff new $a $b [lambda x { $x name }]]
    set i 0
    foreach block [$diffs blocks] {
        foreach item [$block items] {
            set line "[diff::symbol_for_tag [$block tag]] [$item to_string]"
            set want [lindex $expected $i]
            if {$line ne $want} {
                puts "FAIL\nexpected: $want\ngot:      $line"
            } else {
                if {$debug} { puts $line }
            }
            incr i
        }
    }
    if {$verbose && $i == [llength $expected]} { puts OK }
    expr {$i == [llength $expected] ? 1 : 0}
}

proc test2 {debug verbose} {
    if $debug { puts test2 } elseif $verbose { puts -nonewline "test2 " }
    set expected [list "= Place new 1 2 \"foo\"" \
                       "+ Place new 6 2 \"bar\"" \
                       "= Place new 3 4 \"baz\"" \
                       "- Place new 5 6 \"baz\"" \
                       "= Place new 7 8 \"quux\""]
    set a [list [Place new 1 2 "foo"] [Place new 3 4 "bar"] \
		[Place new 5 6 "baz"] [Place new 7 8 "quux"]]
    set b [list [Place new 1 2 "foo"] [Place new 6 2 "bar"] \
		[Place new 3 4 "baz"] [Place new 7 8 "quux"]]
    set diffs [diff::Diff new $a $b [lambda x { $x x }]]
    set i 0
    foreach block [$diffs blocks] {
        foreach item [$block items] {
            set line "[diff::symbol_for_tag [$block tag]] [$item to_string]"
            set want [lindex $expected $i]
            if {$line ne $want} {
                puts "FAIL\nexpected: $want\ngot:      $line"
            } else {
                if {$debug} { puts $line }
            }
            incr i
        }
    }
    if {$verbose && $i == [llength $expected]} { puts OK }
    expr {$i == [llength $expected] ? 1 : 0}
}

proc test3 {debug verbose} {
    if $debug { puts test3 } elseif $verbose { puts -nonewline "test3 " }
    set expected [list [diff::Span new delete 0 1 0 0] \
                       [diff::Span new equal 1 3 0 2] \
                       [diff::Span new delete 3 4 2 2] \
                       [diff::Span new equal 4 5 2 3] \
                       [diff::Span new replace 5 6 3 4]]
    set a [list 1 2 3 4 5 6]
    set b [list 2 3 5 7]
    set diffs [diff::Diff new $a $b]
    set i 0
    set ok 0
    set spans [$diffs spans]
    foreach span $spans {
        set espan [lindex $expected $i]
        if {![$span equal $espan]} {
            puts "FAIL\nexpected:\
                [$espan to_string]\ngot:      [$span to_string]"
        } else {
            incr ok
        }
        incr i
    }
    if {$verbose && $ok == [llength $spans]} { puts OK }
    expr {$i == [llength $expected] ? 1 : 0}
}

proc test4 {debug verbose} {
    if $debug { puts test4 } elseif $verbose { puts -nonewline "test4 " }
    set a [list foo bar baz quux]
    set b [list foo baz bar quux]
    set diffs [diff::Diff new $a $b]
    set actuals [list]
    set i 0
    foreach span [$diffs spans] {
        switch [$span tag] {
            equal {
                lappend actuals \
                    "= [lrange $a [$span astart] [$span aend]-1]"
            }
            insert {
                lappend actuals \
                    "+ [lrange $b [$span bstart] [$span bend]-1]"
            }
            delete {
                lappend actuals \
                    "- [lrange $a [$span astart] [$span aend]-1]"
            }
            replace {
                lappend actuals \
                    "% [lrange $b [$span bstart] [$span bend]-1]"
            }
        }
    }
    set ok 1
    set expected [list "= foo" "+ baz" "= bar" "- baz" "= quux"]
    foreach i [lseq [llength $expected]] {
        set actual [lindex $actuals $i]
        set want [lindex $expected $i]
        if {$actual ne $want} {
            puts "FAIL\nexpected: $want\ngot:      $actual"
            set ok 0
        } else {
            if {$debug} { puts $actual }
        }
    }
    if {$verbose && $ok} { puts OK }
    return $ok
}

proc test5 {debug verbose} {
    set expected [list "% a" \
                       "= quick" \
                       "% red" \
                       "= fox" \
                       "= jumped" \
                       "= over" \
                       "% some" \
                       "= lazy" \
                       "% hogs"]
    set a [list the quick brown fox jumped over the lazy dogs]
    set b [list a quick red fox jumped over some lazy hogs]
    testn 5 $debug $verbose $a $b $expected
}

proc test6 {debug verbose} {
    set expected [list "= the" \
                       "= quick" \
                       "% red" \
                       "= fox" \
                       "= jumped" \
                       "= over" \
                       "= the" \
                       "% very" \
                       "% busy" \
                       "= dogs"]
    set a [list the quick brown fox jumped over the lazy dogs]
    set b [list the quick red fox jumped over the very busy dogs]
    testn 6 $debug $verbose $a $b $expected
}

proc test7 {debug verbose} {
    set expected [list "= private" \
                       "+ volatile" \
                       "= Thread" \
                       "= currentThread;"]
    set a [list private Thread "currentThread;"]
    set b [list private volatile Thread "currentThread;"]
    testn 7 $debug $verbose $a $b $expected
}

proc test8 {debug verbose} {
    set expected [list "- the" \
                       "- quick" \
                       "- brown" \
                       "- fox" \
                       "- jumped" \
                       "- over" \
                       "- the" \
                       "- lazy" \
                       "- dogs"]
    set a [list the quick brown fox jumped over the lazy dogs]
    set b [list]
    testn 8 $debug $verbose $a $b $expected
}

proc test9 {debug verbose} {
    set expected [list "+ the" \
                       "+ quick" \
                       "+ brown" \
                       "+ fox" \
                       "+ jumped" \
                       "+ over" \
                       "+ the" \
                       "+ lazy" \
                       "+ dogs"]
    set a [list]
    set b [list the quick brown fox jumped over the lazy dogs]
    testn 9 $debug $verbose $a $b $expected
}

proc testn {n debug verbose a b expected} {
    if $debug { puts test$n } elseif $verbose { puts -nonewline "test$n " }
    set diffs [diff::Diff new $a $b]
    set i 0
    foreach block [$diffs blocks] {
        foreach item [$block items] {
            set line "[diff::symbol_for_tag [$block tag]] $item"
            set want [lindex $expected $i]
            if {$line ne $want} {
                puts "FAIL\nexpected: $want\ngot:      $line"
            } else {
                if {$debug} { puts $line }
            }
            incr i
        }
    }
    if {$verbose && $i == [llength $expected]} { puts OK }
    expr {$i == [llength $expected] ? 1 : 0}
}

main
