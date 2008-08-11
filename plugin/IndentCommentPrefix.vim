" IndentCommentPrefix.vim: Keep comment prefix in column 1 when indenting. 
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
" DEPENDENCIES:
"   - repeat.vim autoload script (optional)
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
"	001	11-Aug-2008	file creation

function! s:DoIndent( isDedent, isInsertMode )
    if a:isInsertMode
	call feedkeys( (a:isDedent ? "\<C-d>" : "\<C-t>"), 'n' )
    else
	execute 'normal!' (a:isDedent ? '<<' : '>>')
    endif
endfunction
function! s:IndentKeepCommentPrefix( isDedent, isInsertMode )
    let l:line = line('.')
    let l:matches = matchlist( getline(l:line), '\(^\S\+\)\(\s\)' )
    let l:prefix = get(l:matches, 1, '')
    let l:indent = get(l:matches, 2, '')

    if empty(l:prefix) || &l:comments !~# l:prefix  
	" No prefix in this line or the prefix is not registered as a comment. 
	call s:DoIndent( a:isDedent, a:isInsertMode )
	return
    endif

    "****D echomsg l:indent == ' ' ? 'spaces' : 'tab'
    let l:virtCol = virtcol('.')

    " If the actual indent is a <Tab>, remove the prefix. If it is <Space>,
    " replace prefix with spaces so that the overall indentation remains fixed. 
    " Note: We have to decide based on the actual indent, because with the
    " softtabstop setting, there may be spaces though the overall indenting is
    " done with <Tab>. 
    execute 's/^\C\V' . escape(l:prefix, '/\') . '/' . (l:indent == ' ' ? repeat(' ', len(l:prefix)) : '') . '/'

    call s:DoIndent( a:isDedent, 0 )

    " If the first indent is a <Tab>, re-insert the prefix. If it is <Space>,
    " replace spaces with prefix so that the overall indentation remains fixed. 
    " Note: We have to re-evaluate because the softtabstop setting may have
    " changed <Tab> into spaces and vice versa. 
    let l:newIndent = matchstr( getline(l:line), '^\s' )
    " Dedenting may have eaten up all indent spaces. In that case, just
    " re-insert the comment prefix as is done with <Tab> indenting. 
    execute 's/^' . (l:newIndent == ' ' ? '\%( \{' . len(l:prefix) . '}\)\?' : '') . '/' . escape(l:prefix, '/\&~') . '/'

    
    " Adjust cursor column based on the _virtual_ column. (Important since we're
    " dealing with <Tab> characters here!) 
    " Note: If the former indent was less than one shiftwidth, it is ignored, so
    " that the cursor is positioned on the first tabstop. 
    let l:newVirtCol = (l:virtCol <= &l:sw ? 1 : l:virtCol) + (a:isDedent ? -1 : 1) * &l:sw
    call cursor(l:line, 1)
    if l:newVirtCol > 1
	call search('\%>' . (l:newVirtCol - 1) . 'v', 'c', l:line)
    endif
endfunction

inoremap <silent> <C-t> <C-o>:call <SID>IndentKeepCommentPrefix(0,1)<CR>
inoremap <silent> <C-d> <C-o>:call <SID>IndentKeepCommentPrefix(1,1)<CR>

function! s:IndentKeepCommentPrefixRange( isDedent ) range
    for l in range(a:firstline, a:lastline)
	execute l . 'call s:IndentKeepCommentPrefix(' . a:isDedent . ',0)'
    endfor

    " Go back to first line, like the default >> commands. 
    execute a:firstline

    " Integration into repeat.vim. 
    silent! call repeat#set("\<Plug>IndentCommentPrefix" . a:isDedent)
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
