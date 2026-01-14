# Tcl diff

The `diff-1.tm` module provides diff functionality for Tcl based on Python's
`difflib` module.

Like Tcllib's `struct::list longestCommonSubsequence`, the diff module can
diff sequences of strings or of numbers. But unlike
`longestCommonSubsequence`, the diff module can also diff sequences of
_objects_, providing a function is supplied to provide a “key” that can be
used to compare objects. For example, if the objects have a “name” field
with a `name` getter, the function passed could be `lambda obj { $obj name
}`.

See the tests in `tdiff.tcl` for examples of use.

Note: I use [Store](https://github.com/mark-summerfield/store) for version
control so github is only used to make the code public.

## Dependencies

Tcl/Tk >= 9.0.2; Tcllib >= 2.0; Tklib >= 0.9.

## License

GPL-3

---
