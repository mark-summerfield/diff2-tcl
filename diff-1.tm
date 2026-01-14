# Copyright © 2025-26 Mark Summerfield. All rights reserved.

if {![catch {file readlink [info script]} name]} {
    const APPPATH [file dirname $name]
} else {
    const APPPATH [file normalize [file dirname [info script]]]
}
tcl::tm::path add $APPPATH

package require diff_struct
package require lambda 1

namespace eval diff {}

proc diff::symbol_for_tag tag {
    switch $tag {
        delete  { return - }
        equal   { return = }
        insert  { return + }
        replace { return % }
    }
}

# Compares two lists of items given a key function, e.g., something like
#   lambda x { $x text } or the identity function (e.g., for int or
#   string lists), lambda x { return $x }
oo::class create diff::Diff {
    variable Aitems
    variable Bitems
    variable Keyfn
    variable B2j
}

oo::define diff::Diff constructor {aitems bitems {keyfn {}}} {
    set Aitems $aitems
    set Bitems $bitems
    set Keyfn [expr {$keyfn ne {} ? $keyfn : [lambda x { return $x }]}]
    set B2j [dict create]
    my ChainBseq
}

oo::define diff::Diff method ChainBseq {} {
    set i 0
    foreach item $Bitems {
        lappend B2j [{*}$Keyfn $item] $i
        incr i
    }
}

oo::define diff::Diff method blocks {} {
    set blocks [list]
    foreach span [my spans] {
        set aitems [list]
        set bitems [list]
        if {[$span aend] <= [llength $Aitems]} {
            set aitems [lrange $Aitems [$span astart] [$span aend]-1]
        }
        if {[$span bend] <= [llength $Bitems]} {
            set bitems [lrange $Bitems [$span bstart] [$span bend]-1]
        }
        lappend blocks [diff::Block new [$span tag] $aitems $bitems]
    }
    return $blocks
}

oo::define diff::Diff method spans {} { diff::SpansForMatches [my Matches] }

oo::define diff::Diff method Matches {} {
    set alength [llength $Aitems]
    set blength [llength $Bitems]
    set queue [list [diff::Quad new 0 $alength 0 $blength]]
    set matches [list]
    while {[llength $queue] > 0} {
        set qend [expr {[llength $queue] - 1}]
        set quad [lindex $queue end]
        set queue [lrange $queue 0 end-1]
        set match [my LongestMatch $quad]
        set i [$match astart]
        set j [$match bstart]
        if {[set k [$match length]] > 0} {
            lappend matches $match
            if {[$quad astart] < $i && [$quad bstart] < $j} {
                lappend queue [diff::Quad new [$quad astart] $i \
                        [$quad bstart] $j]
            }
            if {$i + $k < [$quad aend] && $j + $k < [$quad bend]} {
                lappend queue [diff::Quad new [expr {$i + $k}] \
                        [$quad aend] [expr {$j + $k}] [$quad bend]]
            }
        }
    }
    set astart 0
    set bstart 0
    set length 0
    set non_adjacent [list]
    foreach match [lsort -command [list diff::Match compare] $matches] {
        if {$astart + $length == [$match astart] &&
                $bstart + $length == [$match bstart]} {
            incr length [$match length]
        } else {
            if {$length} {
                lappend non_adjacent [diff::Match new $astart $bstart \
                        $length]
            }
            set astart [$match astart]
            set bstart [$match bstart]
            set length [$match length]
        }
    }
    if {$length} {
        lappend non_adjacent [diff::Match new $astart $bstart $length]
    }
    lappend non_adjacent [diff::Match new $alength $blength 0]
}

oo::define diff::Diff method LongestMatch quad {
    set astart [$quad astart]
    set aend [$quad aend]
    set bstart [$quad bstart]
    set bend [$quad bend]
    set best_i $astart
    set best_j $bstart
    set best_size 0
    set j2len [dict create]
    for {set i $astart} {$i < $aend} {incr i} {
        set new_j2len [dict create]
        set item [lindex $Aitems $i]
        if {[set indexes [dict getdef $B2j [{*}$Keyfn $item] {}]] ne {}} {
            foreach j $indexes {
                if {$j < $bstart} { continue }
                if {$j >= $bend} { break }
                set j_1 [expr {$j - 1}]
                if {![dict exists $j2len $j_1]} {
                    dict set j2len $j_1 0
                }
                set k [dict get $j2len $j_1]
                incr k
                dict set new_j2len $j $k
                if {$k > $best_size} {
                    set best_i [expr {$i - $k + 1}]
                    set best_j [expr {$j - $k + 1}]
                    set best_size $k
                }
            }
        }
        set j2len $new_j2len
    }
    while {$best_i > $astart && $best_j > $bstart &&
            [{*}$Keyfn [lindex $Aitems $best_i-1]] eq
            [{*}$Keyfn [lindex $Bitems $best_j-1]]} {
        incr best_i -1
        incr best_j -1
        incr best_size
    }
    while {$best_i + $best_size < $aend && $best_j + $best_size < $bend &&
            [{*}$Keyfn [lindex $Aitems $best_i+$best_size]] eq
            [{*}$Keyfn [lindex $Bitems $best_i+$best_size]]} {
        incr best_size
    }
    diff::Match new $best_i $best_j $best_size
}

proc diff::SpansForMatches matches {
    set spans [list]
    set i 0
    set j 0
    foreach match $matches {
        set tag equal
        if {$i < [$match astart]} {
            set tag [expr {$j < [$match bstart] ? "replace" : "delete" }]
        } elseif {$j < [$match bstart]} {
            set tag insert
        }
        if {$tag ne "equal"} {
            lappend spans [diff::Span new $tag $i [$match astart] $j \
                            [$match bstart]]
        }
        set i [expr {[$match astart] + [$match length]}]
        set j [expr {[$match bstart] + [$match length]}]
        if {[$match length]} {
            lappend spans [diff::Span new equal [$match astart] $i \
                            [$match bstart] $j]
        }
    }
    return $spans
}
