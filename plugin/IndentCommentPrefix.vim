" IndentCommentPrefix.vim: Keep comment prefix in column 1 when indenting. 
"
" DESCRIPTION:
"   Indent commands like >>, << and <C-T>/<C-D> in insert mode indent the entire
"   line. For some kinds of comments, like the big boilerplate at the file
"   header etc., the comment prefix (e.g. # for Perl scripts) should remain at
"   the first column, though. 
"   This plugin modifies some indent commands so that the comment prefix remains
"   in the first column, and the indenting takes place between the comment
"   prefix and the comment text. For that, it uses the comment configuration
"   provided by the buffer's 'comment' option, which is set by most filetype
"   plugins. 
"
" USAGE:
"   On a line like this:
"   # My comment. 
"   The >> command now keeps the # prefix in column 1, and just indents the
"   comment text:
"   #       My comment. 
"   This only works if there is at least one whitespace character after the
"   prefix (so that comments like ###### do not become #       ######). 
"   Progressive de-indenting will remove all whitespace between prefix and
"   comment text, or leave a single space in between if the 'comments' setting
"   requires a blank after the comment prefix. 
"
"   An optional [count] can be supplied to the >> and << commands, as before. 
"   With the optional repeat.vim script, the command can also be repeated via '.'. 
"   
"   The same behavior is available in insert mode via <C-T>/<C-D> mappings. 
"
"   The visual mode > and < commands are not modified, so you can get access to
"   the original indent behavior by first selecting the line(s) in visual mode
"   before indenting. 
"
" INSTALLATION:
" DEPENDENCIES:
"   - vimscript #2136 repeat.vim autoload script (optional)
"
" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	004	21-Aug-2008	BF: Didn't consider that removing the comment
"				prefix could cause changes in folding (e.g. in
"				vimscript if the line ends with "if"), which
"				then affects all indent operations, which now
"				work on the closed fold instead of the current
"				line. Now temporarily disabling folding. 
"				BF: The looping over the passed range in
"				s:IndentKeepCommentPrefixRange() didn't consider
"				closed folds, so those (except for a last-line
"				fold) would be processed multiple times. Now
"				that folding is temporarily disabling, need to
"				account for the net end of the range. 
"				Added echo message when operating on more than
"				one line, like the original >> commands. 
"	003	19-Aug-2008	BF: Indenting/detenting at the first shiftwidth
"				caused cursor to move to column 1; now adjusting
"				for the net reduction caused by the prefix. 
"	002	12-Aug-2008	Do not clobber search history with :s command. 
"				If a blank is required after the comment prefix,
"				make sure it still exists when dedenting. 
"	001	11-Aug-2008	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_IndentCommentPrefix') || (v:version < 700)
    finish
endif
let g:loaded_IndentCommentPrefix = 1

function! s:DoIndent( isDedent, isInsertMode )
    if a:isInsertMode
	call feedkeys( (a:isDedent ? "\<C-d>" : "\<C-t>"), 'n' )
    else
	execute 'normal!' (a:isDedent ? '<<' : '>>')
    endif
endfunction
function! s:IndentKeepCommentPrefix( isDedent, isInsertMode )
"*******************************************************************************
"* PURPOSE:
"   Enhanced indent / dedent replacement for >>, <<, i_CTRL-D, i_CTRL-T
"   commands. 
"* ASSUMPTIONS / PRECONDITIONS:
"   "Normal" prefix characters (i.e. they have screen width of 1 and are encoded
"   by one byte); as we're using len(l:prefix) to calculate screen width. 
"   Folding should be turned off (:setlocal nofoldenable); otherwise, the
"   modifications of the line (i.e. removing and re-adding the comment prefix)
"   may result in creation / removal of folds, and suddenly the function
"   operates on multiple lines!
"* EFFECTS / POSTCONDITIONS:
"   Modifies current line. 
"* INPUTS:
"   a:isDedent	    Flag whether indenting or dedenting. 
"   a:isInsertMode  Flag whether normal mode or insert mode replacement. 
"* RETURN VALUES: 
"   none
"*******************************************************************************
    let l:line = line('.')
    let l:matches = matchlist( getline(l:line), '\(^\S\+\)\(\s*\)' )
    let l:prefix = get(l:matches, 1, '')
    let l:indent = get(l:matches, 2, '')
    let l:isSpaceIndent = (l:indent =~# '^ ')

    if empty(l:prefix) || &l:comments !~# l:prefix  
	" No prefix in this line or the prefix is not registered as a comment. 
	call s:DoIndent( a:isDedent, a:isInsertMode )
	return
    endif



"****D echomsg l:isSpaceIndent ? 'spaces' : 'tab'
    let l:virtCol = virtcol('.')

    " If the actual indent is a <Tab>, remove the prefix. If it is <Space>,
    " replace prefix with spaces so that the overall indentation remains fixed. 
    " Note: We have to decide based on the actual indent, because with the
    " softtabstop setting, there may be spaces though the overall indenting is
    " done with <Tab>. 
    execute 's/^\C\V' . escape(l:prefix, '/\') . '/' . (l:isSpaceIndent ? repeat(' ', len(l:prefix)) : '') . '/'
    call histdel('/', -1)

    call s:DoIndent( a:isDedent, 0 )

    " If the first indent is a <Tab>, re-insert the prefix. If it is <Space>,
    " replace spaces with prefix so that the overall indentation remains fixed. 
    " Note: We have to re-evaluate because the softtabstop setting may have
    " changed <Tab> into spaces and vice versa. 
    let l:newIndent = matchstr( getline(l:line), '^\s' )
    " Dedenting may have eaten up all indent spaces. In that case, just
    " re-insert the comment prefix as is done with <Tab> indenting. 
    execute 's/^' . (l:newIndent == ' ' ? '\%( \{' . len(l:prefix) . '}\)\?' : '') . '/' . escape(l:prefix, '/\&~') . '/'
    call histdel('/', -1)

    " If a blank is required after the comment prefix, make sure it still exists
    " when dedenting. 
    if &l:comments =~# 'b:' . l:prefix && a:isDedent
	execute 's/^' . escape(l:prefix, '/\') . '\ze\S/\0 /e'
	call histdel('/', -1)
    endif
    

    " Adjust cursor column based on the _virtual_ column. (Important since we're
    " dealing with <Tab> characters here!) 
    let l:newVirtCol = l:virtCol
    if ! a:isDedent && l:isSpaceIndent && len(l:prefix . l:indent) < &l:sw
	" If the former indent was less than one shiftwidth and indenting was
	" done via spaces, this reduces the net change of cursor position. 
	let l:newVirtCol -= len(l:prefix . l:indent)
    elseif a:isDedent && l:isSpaceIndent && len(l:prefix . l:indent) <= &l:sw
	" Also, on the last possible dedent, the prefix (and one <Space> if blank
	" required) will reduce the net change of cursor position. 
	let l:newVirtCol += len(l:prefix) + (&l:comments =~# 'b:' . l:prefix ? 1 : 0)
    endif
    " Calculate new cursor position based on indent/dedent of shiftwidth,
    " considering the adjustments made before. 
    let l:newVirtCol += (a:isDedent ? -1 : 1) * &l:sw

"****D echomsg '****' l:virtCol l:newVirtCol len(l:prefix . l:indent)
    call cursor(l:line, 1)
    if l:newVirtCol > 1
	call search('\%>' . (l:newVirtCol - 1) . 'v', 'c', l:line)
    endif
endfunction

function! s:IndentKeepCommentPrefixInsertMode( isDedent )
    " Temporarily turn off folding while indenting the line. 
    let l:save_foldenable = &l:foldenable
    setlocal nofoldenable

    call s:IndentKeepCommentPrefix(a:isDedent,1)

    let &l:foldenable = l:save_foldenable
endfunction
inoremap <silent> <C-t> <C-o>:call <SID>IndentKeepCommentPrefixInsertMode(0)<CR>
inoremap <silent> <C-d> <C-o>:call <SID>IndentKeepCommentPrefixInsertMode(1)<CR>

function! s:IndentKeepCommentPrefixRange( isDedent ) range
    " Determine the net last line (different if last line is folded) and
    " temporarily turn off folding while indenting the lines. 
    let l:netLastLine = (foldclosedend(a:lastline) == -1 ? a:lastline : foldclosedend(a:lastline))
    let l:save_foldenable = &l:foldenable
    setlocal nofoldenable

    for l in range(a:firstline, l:netLastLine)
	execute l . 'call s:IndentKeepCommentPrefix(' . a:isDedent . ',0)'
    endfor

    " Go back to first line, like the default >> commands. 
    execute a:firstline

    let &l:foldenable = l:save_foldenable

    " Integration into repeat.vim. 
    silent! call repeat#set("\<Plug>IndentCommentPrefix" . a:isDedent)

    let l:lineNum = l:netLastLine - a:firstline + 1
    if l:lineNum > 1
	echo l:lineNum 'lines' (a:isDedent ? '<' : '>') . 'ed 1 time'
    endif
endfunction
nnoremap <silent> <Plug>IndentCommentPrefix0 :call <SID>IndentKeepCommentPrefixRange(0)<CR>
nnoremap <silent> <Plug>IndentCommentPrefix1 :call <SID>IndentKeepCommentPrefixRange(1)<CR>
if ! hasmapto('<Plug>IndentCommentPrefix0', 'n')
    nmap <silent> >> <Plug>IndentCommentPrefix0
endif
if ! hasmapto('<Plug>IndentCommentPrefix1', 'n')
    nmap <silent> << <Plug>IndentCommentPrefix1
endif

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
