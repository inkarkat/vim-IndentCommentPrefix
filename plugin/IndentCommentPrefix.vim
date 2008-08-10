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

function! s:IndentKeepCommentPrefix()
    let l:line = line('.')
    let l:matches = matchlist( getline(l:line), '\(^\S\+\)\(\s\)' )
    let l:prefix = get(l:matches, 1, '')
    let l:indent = get(l:matches, 2, '')

    let l:isGoodIndent = (l:indent == ' ' && &l:et) || (l:indent == "\t" && ! &l:et)

    if empty(l:prefix) || ! l:isGoodIndent || &l:comments !~# l:prefix  
	" No prefix in this line or the prefix is not registered as a comment. 
	call feedkeys("\<C-t>", 'n')
	"execute "normal! i\<C-t>"
	return
    endif

    "****D echomsg l:indent == ' ' ? 'spaces' : 'tab'
    let l:virtCol = virtcol('.')

    execute 's/^\C\V' . escape(l:prefix, '/\') . '/' . (&l:et ? repeat(' ', len(l:prefix)) : '') . '/'
    normal! >>
    execute 's/^' . (&l:et ? repeat(' ', len(l:prefix)) : '') . '/' . escape(l:prefix, '/\&~') . '/'

    
    " Adjust cursor column based on the _virtual_ column. (Important since we're
    " dealing with <Tab> characters here!) 
    call cursor(l:line, 1)
    call search('\%>' . (l:virtCol + &l:sw - 1) . 'v', 'c', l:line)
endfunction

inoremap <silent> <C-t> <C-o>:call <SID>IndentKeepCommentPrefix()<CR>

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

