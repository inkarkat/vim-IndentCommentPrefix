" IndentCommentPrefix.vim: Keep comment prefix in column 1 when indenting.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"   - repeat.vim (vimscript #2136) autoload script (optional)
"
" Copyright: (C) 2008-2019 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

function! s:Literal( string )
" Helper: Make a:string a literal search expression.
    return '\V\C' . escape(a:string, '\') . '\m'
endfunction

"------------------------------------------------------------------------------
function! s:DoIndent( isDedent, isInsertMode, count )
    if a:isInsertMode
	call feedkeys(repeat((a:isDedent ? "\<C-d>" : "\<C-t>"), a:count), 'n' . (v:version == 704 && has('patch601') || v:version > 704 ? 'i': ''))
    else
	" Use :silent to suppress reporting of changed line (when 'report' is
	" 0).
	execute 'silent normal!' repeat((a:isDedent ? '<<' : '>>'), a:count)
    endif
endfunction
function! s:DoIndentWithOverride( isDedent, isInsertMode, count, overriddenIndentSettings )
    if empty(a:overriddenIndentSettings)
	call s:DoIndent(a:isDedent, a:isInsertMode, a:count)
	return &l:shiftwidth
    endif

    let [l:save_shiftwidth, l:save_expandtab] = [&l:shiftwidth, &l:expandtab]
    execute 'setlocal' a:overriddenIndentSettings
    try
	call s:DoIndent(a:isDedent, a:isInsertMode, a:count)
	return &l:shiftwidth
    finally
	let [&l:shiftwidth, &l:expandtab] = [l:save_shiftwidth, l:save_expandtab]
    endtry
endfunction
function! s:SubstituteHere( pattern, replacement )
    call setline('.', substitute(getline('.'), a:pattern, a:replacement, ''))
endfunction
function! s:IndentCommentPrefix( isDedent, isInsertMode, count )
"*******************************************************************************
"* PURPOSE:
"   Enhanced indent / dedent replacement for >>, <<, i_CTRL-D, i_CTRL-T
"   commands.
"* ASSUMPTIONS / PRECONDITIONS:
"   Folding should be turned off (:setlocal nofoldenable); otherwise, the
"   modifications of the line (i.e. removing and re-adding the comment prefix)
"   may result in creation / removal of folds, and suddenly the function
"   operates on multiple lines!
"* EFFECTS / POSTCONDITIONS:
"   Modifies current line.
"* INPUTS:
"   a:isDedent	    Flag whether indenting or dedenting.
"   a:isInsertMode  Flag whether normal mode or insert mode replacement.
"   a:count	    Number of 'shiftwidth' that should be indented (i.e. number
"		    of repetitions of the indent command).
"* RETURN VALUES:
"   New virtual cursor column, taking into account a single (a:count == 1)
"   indent operation.
"   Multiple repetitions are not supported here, because the virtual cursor
"   column is only consumed by the insert mode operation, which is always a
"   single indent. The (possibly multi-indent) visual mode operation discards
"   this return value, anyway.
"*******************************************************************************
    let l:line = line('.')
    " The comment prefix may contain indent if it's the middle or end part of a
    " three-piece comment.
    let l:matches = matchlist(getline(l:line), '^\(\s*\(\S\+\)\)\(\s*\)')
    let l:prefix = get(l:matches, 1, '')
    let l:prefixWidth = ingo#compat#strdisplaywidth(l:prefix)
    let l:prefixChars = get(l:matches, 2, '')
    let l:indent = get(l:matches, 3, '')

    if empty(l:prefix)
	" No prefix in this line.
	call s:DoIndent(a:isDedent, a:isInsertMode, a:count)
	return virtcol('.') " The built-in indent commands automatically adjust the cursor column.
    endif

    let l:whitelist = ingo#plugin#setting#GetBufferLocal('IndentCommentPrefix_Whitelist', [])
    if empty(l:whitelist) || index(l:whitelist, l:prefixChars) == -1
	let l:commentPrefixType = ingo#comments#GetCommentPrefixType(l:prefix)
	if empty(l:commentPrefixType) || index(ingo#plugin#setting#GetBufferLocal('IndentCommentPrefix_Blacklist', []), l:prefixChars) != -1
	    " This is not a comment prefix located at the start of the line.
	    " Or this comment prefix is contained in the blacklist.
	    call s:DoIndent(a:isDedent, a:isInsertMode, a:count)
	    return virtcol('.') " The built-in indent commands automatically adjust the cursor column.
	endif
	let l:isBlankRequiredAfterPrefix = l:commentPrefixType[1]
    else
	" This prefix is contained in the whitelist; treat this as a comment
	" prefix regardless of whether it is configured in 'comments'.
	let l:isBlankRequiredAfterPrefix = 0
    endif


    let l:isSpaceIndent = (l:indent =~# '^ ')
    let l:virtCol = virtcol('.')

    " Need to evaluate g:IndentCommentPrefix_IndentSettingsOverride now, before
    " removing the prefix, so that a configured Funcref sees the original line.
    let l:overriddenIndentSettings = ingo#actions#ValueOrFunc(ingo#plugin#setting#GetBufferLocal('IndentCommentPrefix_IndentSettingsOverride'))

    " If the actual indent is a <Tab>, remove the prefix. If it is <Space>,
    " replace prefix with spaces so that the overall indentation remains fixed.
    " Note: We have to decide based on the actual indent, because with the
    " softtabstop setting, there may be spaces though the overall indenting is
    " done with <Tab>.
    call s:SubstituteHere('^\V\C' . escape(l:prefix, '\'), (l:isSpaceIndent ? repeat(' ', l:prefixWidth) : ''))

    let l:actualShiftwidth = s:DoIndentWithOverride(a:isDedent, 0, a:count, l:overriddenIndentSettings)

    " If the first indent is a <Tab>, re-insert the prefix. If it is <Space>,
    " replace spaces with prefix so that the overall indentation remains fixed.
    " Note: We have to re-evaluate because the softtabstop setting may have
    " changed <Tab> into spaces and vice versa.
    let l:newIndent = matchstr(getline(l:line), '^\s')
    " Dedenting may have eaten up all indent spaces. In that case, just
    " re-insert the comment prefix as is done with <Tab> indenting.
    call s:SubstituteHere('^' . (l:newIndent == ' ' ? ' \{0,' . l:prefixWidth . '}' : ''), escape(l:prefix, '\&'))

    " If a blank is required after the comment prefix, make sure it still exists
    " when dedenting.
    if l:isBlankRequiredAfterPrefix && a:isDedent
	call s:SubstituteHere('^\V\C' . escape(l:prefix, '\') . '\ze\S', '\0 ')
    endif


    " Adjust cursor column based on the _virtual_ column. (Important since we're
    " dealing with <Tab> characters here!)
    " Note: This calculation ignores a:count, see note in function
    " documentation.
    let l:newVirtCol = l:virtCol
    if ! a:isDedent && l:isSpaceIndent && l:prefixWidth + len(l:indent) < l:actualShiftwidth
	" If the former indent was less than one shiftwidth and indenting was
	" done via spaces, this reduces the net change of cursor position.
	let l:newVirtCol -= l:prefixWidth + len(l:indent)
    elseif a:isDedent && l:isSpaceIndent && l:prefixWidth + len(l:indent) <= l:actualShiftwidth
	" Also, on the last possible dedent, the prefix (and one <Space> if blank
	" required) will reduce the net change of cursor position.
	let l:newVirtCol += l:prefixWidth + (l:isBlankRequiredAfterPrefix ? 1 : 0)
    endif
    " Calculate new cursor position based on indent/dedent of shiftwidth,
    " considering the adjustments made before.
    let l:newVirtCol += (a:isDedent ? -1 : 1) * l:actualShiftwidth

"****D echomsg '****' l:virtCol l:newVirtCol l:prefixWidth + len(l:indent)
    return l:newVirtCol

    " Note: The cursor column isn't updated here anymore, because the window
    " view had to be saved and restored by the caller of this function, anyway.
    " (Due to the temporary disabling of folding.) As the window position
    " restore also restores the old cursor position, the setting here would be
    " overwritten, anyway.
    " Plus, the IndentCommentPrefix#Range() functionality sets the cursor
    " position in a different way, anyway, and only for the first line in the
    " range, so the cursor movement here would be superfluous, too.
    "call cursor(l:line, 1)
    "if l:newVirtCol > 1
    "	call search('\%>' . (l:newVirtCol - 1) . 'v', 'c', l:line)
    "endif
endfunction

function! IndentCommentPrefix#InsertMode( isDedent )
    " The temporary disabling of folding below may result in a change of the
    " viewed lines, which would be irritating for a command that only modified
    " the current line. Thus, save and restore the view, but afterwards take
    " into account that the indenting changes the cursor column.
    let l:save_view = winsaveview()

    " Temporarily turn off folding while indenting the line.
    let l:save_foldenable = &l:foldenable
    setlocal nofoldenable

    let l:newVirtCol = s:IndentCommentPrefix(a:isDedent, 1, 1)

    let &l:foldenable = l:save_foldenable
    call winrestview(l:save_view)

    " Set new cursor position after indenting; the saved view has reset the
    " position to before indent.
    call cursor('.', 1)
    if l:newVirtCol > 1
	call search('\%>' . (l:newVirtCol - 1) . 'v', 'c', line('.'))
    endif
endfunction
function! IndentCommentPrefix#InsertToggled( isDedent, isToggle )
    if ! exists('b:lastIndentCommentPrefixLine') || b:lastIndentCommentPrefixLine != line('.')
	let b:lastIndentCommentPrefixIsSingleSpace = 0
    endif
    let b:lastIndentCommentPrefixLine = line('.')

    if a:isToggle
	let b:lastIndentCommentPrefixIsSingleSpace = ! b:lastIndentCommentPrefixIsSingleSpace
    endif

    if b:lastIndentCommentPrefixIsSingleSpace
	let l:save_shiftwidth = &l:shiftwidth
	setlocal shiftwidth=1
    endif
    try
	call IndentCommentPrefix#InsertMode(a:isDedent)
    finally
	if exists('l:save_shiftwidth')
	    let &l:shiftwidth = l:save_shiftwidth
	endif
    endtry
endfunction

function! IndentCommentPrefix#Range( isDedent, count, lineNum ) range
    " The temporary disabling of folding below may result in a change of the
    " viewed lines, which would be irritating for a command that only modified
    " the current line. Thus, save and restore the view.
    let l:save_view = winsaveview()

    " From a normal mode mapping, the count in a:lineNum may address more lines
    " than actually existing (e.g. when using 999>> to indent all remaining
    " lines); the calculated last line needs to be capped to avoid errors.
    let l:lastLine = (a:lastline == a:firstline ? min([a:firstline + a:lineNum - 1, line('$')]) : a:lastline)

    " Determine the net last line (different if last line is folded).
    let l:netLastLine = (foldclosedend(l:lastLine) == -1 ? l:lastLine : foldclosedend(l:lastLine))

    " Temporarily turn off folding while indenting the lines.
    let l:save_foldenable = &l:foldenable
    setlocal nofoldenable

    for l in range(a:firstline, l:netLastLine)
	execute l . 'call s:IndentCommentPrefix(' . a:isDedent . ', 0'. ', ' . a:count . ')'
    endfor

    let &l:foldenable = l:save_foldenable
    call winrestview(l:save_view)

    " Go back to first line, like the default >> indent commands.
    execute 'normal!' a:firstline . 'G^'
    let l:startChangePosition = getpos('.')

    " Go back to first line, ...
    " But put the cursor on the first non-blank character after the comment
    " prefix, not on first overall non-blank character, as the default >> indent
    " commands would do. This makes more sense, since we're essentially ignoring
    " the comment prefix during indenting.
    let l:prefix = get(matchlist(getline(a:firstline), '^\(\S\+\)\s*'), 1, '')
    if ! empty(l:prefix) && &l:comments =~# s:Literal(l:prefix)
	" Yes, the first line was a special comment prefix indent, not a normal
	" one.
	call search('^\S\+\s*\%(\S\|$\)', 'ce', a:firstline)
    endif

    " Integration into repeat.vim.
    let l:netIndentedLines = l:netLastLine - a:firstline + 1
    " Passing the net number of indented lines is necessary to correctly repeat
    " (in normal mode) indenting of a visual selection. Otherwise, only the
    " current line would be indented because v:count was 1 during the visual
    " indent operation.
    silent! call repeat#set("\<Plug>IndentCommentPrefix" . a:isDedent, l:netIndentedLines)

    " Set the change marks similar to what Vim does. (I don't grasp the logic
    " for '[, but using the first non-blank character seems reasonable to me.)
    " This must somehow be done after the call to repeat.vim.
    call ingo#change#Set(l:startChangePosition, ingo#pos#Make4(l:netLastLine, strlen(getline(l:netLastLine))))

    let l:lineNum = l:netLastLine - a:firstline + 1
    if l:lineNum > &report
	echo printf('%d line%s %sed %d time%s', l:lineNum, (l:lineNum == 1 ? '' : 's'), (a:isDedent ? '<' : '>'), a:count, (a:count == 1 ? '' : 's'))
    endif
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
