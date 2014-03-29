NAME
====
  `grep` - search a file for a pattern

SYNOPSIS
========
  `grep [-E| -F][-c| -l| -q][-insvx] -e pattern_list...
         [-f pattern_file]...[file...]`

  `grep [-E| -F][-c| -l| -q][-insvx][-e pattern_list]...
         -f pattern_file...[file...]`

  `grep [-E| -F][-c| -l| -q][-insvx] pattern_list[file...]`

DESCRIPTION
===========
  The grep utility searches the input files, selecting lines matching one or
more patterns; the types of patterns are controlled by the options 
specified. The patterns are specified by the `-e` or `-f` optiont, or the 
`pattern_list` operand. The `pattern_list`'s value shall consist of one 
pattern; the `pattern_file`'s contents shall consist of one or more  
patterns terminated by `<newline>`. An input line shall be selected if any 
pattern, treated as a Lua pattern, matches any part of the line excluding 
the terminating `<newline>`; a null pattern shall match every line. By 
default, each selected input line shall be written to the standard output.

  Regular expression matching shall be based on text lines. Since a 
`<newline>` separates or terminates patterns (see the `-e` and `-f` options
 below), regular expressions cannot contain a `<newline>`. Similarly, since
 patterns are matched against individual lines (excluding the terminating 
`<newline>`s) of the input, there is no way for a pattern to match a 
`<newline>` found in the input.

OPTIONS
=======
* `-F` Match using fixed strings. Treats each pattern specified as a string
    instead of a regular expression.

* `-c` Write only a count of selected lines to standard output.

* `-e pattern`
     Specify one pattern to be used during the search fot input. Unless the
    `-F` option is also specified, each pattern is treated as a Lua pattern.
    Multiple `-e` or `-f` options are accepted.

* `-f pattern_file`
    Read one or more patterns to be used during the search fo input. The 
    patterns in `pattern_file` should be terminated by a `<newline>`. Unless
    the `-F` option is also specified, each pattern is treated as a Lua
    pattern.

* `-i` Perform pattern matching in searches without regard of case.

* `-l` (the letter ell.) Write only the names of files containing selected lines to standard output. Pathnames shall be written once per file searched.

* `-n` Preced each output line by its relative line number in each file, each file starting at line 1.

* `-q` Quiet. Nothing is written to the standard output, regardless of mathcing lines.

* `-s` Suppress the error messages ordinarly written for nonexistent or unreadable files. Other error messages will not be suppressed.

* `-v` Select lines not matching any of the specified patterns.

* `-x` Consider only inptu lines that use all characters in the line excluding the terminating <newline> to match an entire fixed string or regular expression to be matching lines.

EXAMPLES
========
*   `grep -n local file.lua`
    Look for the word local in the file file.lua and print line numbers

*   `grep -F % file`
    Look for the string % in file.

*   `grep -n -e local -e (.-)=(.-) file.lua`
    Look for variable declarations and assignments in the file file.lua and
    print line numbers
