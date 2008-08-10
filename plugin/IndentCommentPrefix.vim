" TODO: summary
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
" DEPENDENCIES:
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
"	001	00-Jan-2008	file creation
"	lalala
"	    tab tab tab
"	tab tab tab
"           spc spc spc
"       spc spc spc
vmap x X

function! s:DoIndent( isDedent, isInsertMode )
    if a:isInsertMode
	call feedkeys( (a:isDedent ? "\<C-d>" : "\<C-t>"), 'n' )
    elseif a:isDedent
	normal! <<
    else
	normal! >>
    endif
endfunction
function! s:IndentKeepCommentPrefix( isDedent, isInsertMode )
    let l:line = line('.')
    let l:matches = matchlist( getline(l:line), '\(^\S\+\)\(\s\)' )
    let l:prefix = get(l:matches, 1, '')
    let l:indent = get(l:matches, 2, '')

    let l:isGoodIndent = (l:indent == ' ' && &l:et) || (l:indent == "\t" && ! &l:et)

    if empty(l:prefix) || ! l:isGoodIndent || &l:comments !~# l:prefix  
	" No prefix in this line or the prefix is not registered as a comment. 
	call s:DoIndent( a:isDedent, a:isInsertMode )
	return
    endif

    "****D echomsg l:indent == ' ' ? 'spaces' : 'tab'
    let l:virtCol = virtcol('.')

    execute 's/^\C\V' . escape(l:prefix, '/\') . '/' . (&l:et ? repeat(' ', len(l:prefix)) : '') . '/'
    call s:DoIndent( a:isDedent, 0 )
    " Dedenting may have eaten up all indent spaces. In that case, just
    " re-insert the comment prefix as is done with <Tab> indenting. 
    execute 's/^' . (&l:et ? '\%( \{' . len(l:prefix) . '}\)\?' : '') . '/' . escape(l:prefix, '/\&~') . '/'

    
    " Adjust cursor column based on the _virtual_ column. (Important since we're
    " dealing with <Tab> characters here!) 
    let l:newVirtCol = l:virtCol + (a:isDedent ? -1 : 1) * &l:sw
    call cursor(l:line, 1)
    if l:newVirtCol > 1
	call search('\%>' . (l:newVirtCol - 1) . 'v', 'c', l:line)
    endif
endfunction

inoremap <silent> <C-t> <C-o>:call <SID>IndentKeepCommentPrefix(0,1)<CR>
inoremap <silent> <C-d> <C-o>:call <SID>IndentKeepCommentPrefix(1,1)<CR>
nnoremap <silent> >> <C-o>:call <SID>IndentKeepCommentPrefix(0,0)<CR>
nnoremap <silent> << <C-o>:call <SID>IndentKeepCommentPrefix(1,0)<CR>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

