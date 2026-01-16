# Copyright © 2026 Mark Summerfield. All rights reserved.

oo::singleton create Config {
    variable Fmt
    variable Outfile
    variable File1
    variable File2
    variable Debug
}

oo::define Config constructor {debug fmt {outfile ""} {file1 ""} \
        {file2 ""}} {
    set Fmt $fmt
    set Outfile $outfile
    set File1 $file1
    set File2 $file2
    set Debug $debug
}

oo::define Config method fmt {} { return $Fmt }
oo::define Config method set_fmt fmt { set Fmt $fmt }

oo::define Config method outfile {} { return $Outfile }
oo::define Config method set_outfile outfile { set Outfile $outfile }

oo::define Config method file1 {} { return $File1 }
oo::define Config method set_file1 file1 { set File1 $file1 }

oo::define Config method file2 {} { return $File2 }
oo::define Config method set_file2 file2 { set File2 $file2 }

oo::define Config method debug {} { return $Debug }
oo::define Config method set_debug debug { set Debug $debug }

oo::define Config method to_string {} {
    return "Config new $Debug $Fmt \"$Outfile\" \"$File1\" \"$File2\""
}

