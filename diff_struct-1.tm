# Copyright © 2025-26 Mark Summerfield. All rights reserved.

oo::class create diff::Block {
    variable Tag
    variable Aitems
    variable Bitems
}

oo::define diff::Block constructor {tag aitems bitems} {
    set Tag $tag
    set Aitems $aitems
    set Bitems $bitems
}

oo::define diff::Block method tag {} { return $Tag }

oo::define diff::Block method aitems {} { return $Aitems }

oo::define diff::Block method bitems {} { return $Bitems }

oo::define diff::Block method items {} {
    expr {$Tag eq "delete" ? $Aitems : $Bitems }
}

oo::class create diff::Match {
    variable Astart
    variable Bstart
    variable Length
}

oo::define diff::Match constructor {astart bstart length} {
    set Astart $astart
    set Bstart $bstart
    set Length $length
}

oo::define diff::Match method astart {} { return $Astart }

oo::define diff::Match method bstart {} { return $Bstart }

oo::define diff::Match method length {} { return $Length }

oo::define diff::Match classmethod compare {a b} {
    set aastart [$a astart] 
    set bastart [$b astart] 
    if {$aastart < $bastart} { return -1 }
    if {$aastart > $bastart} { return 1 }
    set abstart [$a bstart] 
    set bbstart [$b bstart] 
    if {$abstart < $bbstart} { return -1 }
    if {$abstart > $bbstart} { return 1 }
    set alength [$a length] 
    set blength [$b length] 
    if {$alength < $blength} { return -1 }
    if {$alength > $blength} { return 1 }
    return 0
}

oo::class create diff::Quad {
    variable Astart
    variable Aend
    variable Bstart
    variable Bend
}

oo::define diff::Quad constructor {astart aend bstart bend} {
    set Astart $astart
    set Aend $aend
    set Bstart $bstart
    set Bend $bend
}

oo::define diff::Quad method astart {} { return $Astart }

oo::define diff::Quad method aend {} { return $Aend }

oo::define diff::Quad method bstart {} { return $Bstart }

oo::define diff::Quad method bend {} { return $Bend }

oo::define diff::Quad method equal other {
    expr {$Astart == [$other astart] && $Aend == [$other aend] &&
          $Bstart == [$other bstart] && $Bend == [$other bend]}
}

oo::class create diff::Span {
    variable Tag
    variable Quad
}

oo::define diff::Span constructor {tag astart aend bstart bend} {
    set Tag $tag
    set Quad [diff::Quad new $astart $aend $bstart $bend]
}

oo::define diff::Span method tag {} { return $Tag }

oo::define diff::Span method quad {} { return $Quad }

oo::define diff::Span method astart {} { $Quad astart }

oo::define diff::Span method aend {} { $Quad aend }

oo::define diff::Span method bstart {} { $Quad bstart }

oo::define diff::Span method bend {} { $Quad bend }

oo::define diff::Span method to_string {} {
    return "diff::Span new $Tag [my astart] [my aend] [my bstart] [my bend]"
}

oo::define diff::Span method equal other {
    expr {$Tag eq [$other tag] && [$Quad equal [$other quad]]}
}
