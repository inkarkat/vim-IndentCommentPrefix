INDENT COMMENT PREFIX
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Indent commands like &gt;&gt;, &lt;&lt; and i\_CTRL-T, i\_CTRL-D in insert mode
indent the entire line. For some kinds of comments, like the big boilerplate
at the file header etc., the comment prefix (e.g. # for Perl scripts) should
remain at the first column, though.
This plugin modifies these indent commands so that the comment prefix remains
in the first column, and the indenting takes place between the comment prefix
and the comment text. For that, it uses the comment configuration provided by
the buffer's 'comment' option, which is set by most filetype plugins; this can
be tweaked via plugin configuration.

USAGE
------------------------------------------------------------------------------

    On a line like this:
    # My comment.

    The >> command now keeps the # prefix in column 1, and just indents the
    comment text:
    #       My comment.

    This only works if there is at least one whitespace character after the prefix
    (so that comments like ###### do not become #       ######).
    Progressive de-indenting will remove all whitespace between prefix and comment
    text, or leave a single space in between if the 'comments' setting requires a
    blank after the comment prefix.

    An optional [count] of lines can be supplied to the >> and << commands, as
    before.
    In visual mode, the optional [count] specifies how many 'shiftwidth's should
    be indented; the v_> and v_< commands operate on all highlighted lines.

    With the optional repeat.vim script, the commands can also be repeated via ..

    The same behavior is available in insert mode via the i_CTRL-T and
    i_CTRL-D mappings:

    CTRL-T          Insert one shiftwidth of indent at the start of the current
                    line, after any comment prefix. The indent is always rounded
                    to a 'shiftwidth'.

    CTRL-D          Delete one shiftwidth of indent at the start of the current
                    line, after any comment prefix. The indent is always rounded
                    to a 'shiftwidth'.

    CTRL-G CTRL-T   Insert a single space of indent at the start of the current
                    line, after any comment prefix, and toggle the behavior of
                    i_CTRL-D to continue inserting a single space instead of one
                    shiftwidth.

    CTRL-G CTRL-D   Delete a single space of indent at the start of the current
                    line, after any comment prefix, and toggle the behavior of
                    i_CTRL-D to continue deleting a single space instead of one
                    shiftwidth.

### GETTING BACK THE ORIGINAL BEHAVIOR

    g>>
    {Visual}g>
    g<<
    {Visual}g<
    In case you want to indent lines including the comment prefix, the original
    indent behavior is mapped to g>> in normal mode and g> in visual mode.
    There's only a need for the corresponding g<< dedent mappings when using the
    g:IndentCommentPrefix_Whitelist, because those prefixes will work not just
    in column 1 (where dedenting is not possible), but in any column.
    Alternatively, you could also use the >{motion} command, as the > and <
    operators aren't modified by this plugin.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-IndentCommentPrefix
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim IndentCommentPrefix*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.037 or
  higher.
- repeat.vim ([vimscript #2136](http://www.vim.org/scripts/script.php?script_id=2136)) plugin (optional)

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

By default, indenting behavior with all comment prefixes defined in the
'comments' option is modified. To disable the keeping in column 1 for some
prefixes, add each prefix to the following (buffer-local or global) List
variable:

    let g:IndentCommentPrefix_Blacklist = ['#', '>']

If you want to modify the indenting behavior for certain prefixes not just in
column 1, but with any existing indent, add each prefix to the following
(buffer-local or global) List variable. These prefixes do not need to be
contained in 'comments' then.

    let g:IndentCommentPrefix_Whitelist = ['REMARK:']

You may want to use a different 'shiftwidth' or 'expandtab' setting for
indenting with a comment prefix (vs. "normal" indenting without comments), you
can define the settings globally (or alternatively for the current buffer)
via:

    let g:IndentCommentPrefix_IndentSettingsOverride = 'shiftwidth=3 expandtab'

The settings value can also be determined dynamically by supplying a Funcref;
this is called (without arguments) on each plugin indent action and should
return the corresponding indent settings as a String.

If you want to use different mappings instead of overriding the default
commands, map your keys to the &lt;Plug&gt;IndentCommentPrefix... mapping targets
_before_ sourcing the script (e.g. in your vimrc):

    imap <C-t> <Plug>IndentCommentPrefixIndent
    imap <C-d> <Plug>IndentCommentPrefixDedent
    nmap <Leader>>     <Plug>IndentCommentPrefix0
    vmap <Leader>>     <Plug>IndentCommentPrefix0
    nmap <Leader><lt>  <Plug>IndentCommentPrefix1
    vmap <Leader><lt>  <Plug>IndentCommentPrefix1

If you don't want the alternative g&gt;&gt; and g&lt;&lt; mappings for the original indent
commands, set the following variable _before_ sourcing the plugin:

    let g:IndentCommentPrefix_alternativeOriginalCommands = 0

KNOWN PROBLEMS
------------------------------------------------------------------------------

- When indenting in insert mode via &lt;C-T&gt;/&lt;C-D&gt;, the cursor position may be
  off if there are &lt;Tab&gt; characters in the indented text itself (not just
  between the prefix and the indented text), and the cursor is positioned
  somewhere behind such a &lt;Tab&gt; character. The changing virtual width of these
  &lt;Tab&gt; characters isn't considered when calculating the new virtual cursor
  column.
- With ':set list' and if ':set listchars' does not include a 'tab:xy' item,
  tabs show up as ^I and do not occupy the full width (up to 'tabstop'
  characters). This shortened representation throws off the cursor position
  when indenting in insert mode via &lt;C-T&gt;/&lt;C-D&gt;.
- If a visual mode '.' repeat command is defined to repeat the last change on
  all highlighted lines, and the previous indent operation used a [count]
  greater than 1, the highlighted lines will be indented multiple times and
  lines after the current visual selection will be erroneously indented, too.
  (So it's a big mess up, don't do this.) This is because the previous [count]
  will now be used repeatedly to select multiple lines.

### TODO

- Does it make sense to also modify the &gt;{motion} operators?

### CONTRIBUTING

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-IndentCommentPrefix/issues or email (address
below).

HISTORY
------------------------------------------------------------------------------

##### 1.41    10-Nov-2024
- ENH: Allow dynamic g:IndentCommentPrefix\_IndentSettingsOverride via Funcref.
  For example, to expand tabs only if the comment prefix isn't in column 1.
- Support double-width indent prefix characters.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.037!__

##### 1.40    23-Dec-2017
- Supply 'i' flag (since Vim 7.4.601) to execute the insert mode in/dedent
  before typeahead (to avoid breaking macro playbacks).
- ENH: Define &lt;Plug&gt;-imaps for &lt;C-d&gt; / &lt;C-t&gt; to allow remapping of those, too.
- ENH: Add IndentCommentPrefix#InsertToggled() wrapper for
  IndentCommentPrefix#InsertMode() that implements toggling of 'shiftwidth' /
  single space indenting via a separate toggle mapping.
- ENH: Allow overriding the 'shiftwidth' and 'expandtab' indent settings for
  indenting of comment prefixes via

##### 1.32    19-Nov-2013
- Add special case to handle the (rather obscure) i\_0\_CTRL-D and
  i\_^\_CTRL-D commands, which were broken by the plugin's insert mode
  mapping.
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)).

__You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.005 (or higher)!__

##### 1.31    25-Jan-2013
- Also define opposite g&lt;&lt; commands with
g:IndentCommentPrefix\_alternativeOriginalCommands. It's good for consistency
(my muscle memory often cannot distingish indenting from dedenting), and
necessary when using the g:IndentCommentPrefix\_Whitelist, because those work
not just in column 1 (where dedenting is not possible), but in any column.

##### 1.30    13-Dec-2012
- ENH: Add global and buffer-local whitelists / blacklists to explicitly
  include / exclude certain comment prefixes.
- Handle readonly and nomodifiable buffers by printing just the warning /
  error, without the multi-line function error.

##### 1.20    22-Sep-2011 (unreleased)
- FIX: Now handling three-piece comments correctly. The start may set a
  positive indent offset for the middle and end comment prefixes that must be
  considered.
- FIX: Suppress 'ignorecase' in s:Literal().

##### 1.10    30-Mar-2011
- Split off separate documentation and autoload script. Now publishing as
  Vimball.
- BUG: Only report changes if more than 'report' lines where indented; I got
  the meaning of 'report' wrong the first time.
- BUG: Could not use 999&gt;&gt; to indent all remaining lines.
- BUG: Normal-mode mapping didn't necessarily put the cursor on the first
  non-blank character after the comment prefix if 'nostartofline' is set.
- ENH: In normal and visual mode, set the change marks '[ and ]' similar to
  what Vim does.

##### 1.02    06-Oct-2009
- Do not define mappings for select mode; printable characters should start
insert mode.

##### 1.01.009    05-Jul-2009
- BF: When 'report' is less than the default 2, the :substitute and &lt;&lt; / &gt;&gt;
commands created additional messages, causing a hit-enter prompt.  Now also
reporting a single-line change when 'report' is 0 (to be consistent with the
built-in indent commands).

##### 1.00.008    23-Feb-2009
- BF: Fixed "E61: Nested \*" that occurred when shifting a line with a comment
  prefix containing multiple asterisks in a row (e.g. '\*\*').
- BF: Info message (given when indenting multiple lines) always printed "1
  time" even when a [count] was specified in visual mode.

##### 1.00.007    29-Jan-2009
- Initial publish.

##### 0.01    11-Aug-2008
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2008-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
