" IndentCommentPrefix.vim: Keep comment prefix in column 1 when indenting.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - IndentCommentPrefix.vim autoload script
"
" Copyright: (C) 2008-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.40.007	24-Nov-2017	ENH: Define separate i_CTRL-G_CTRL-D /
"				i_CTRL-G_CTRL-T mappings that toggle the
"				dedenting / indenting granularity from the
"				default 'shiftwidth' to a single space. This can
"				be helpful to do precise alignments outside of
"				the tabstop grid.
"   1.33.006	24-Nov-2017	ENH: Define <Plug>-imaps for <C-d> / <C-t> to
"				allow remapping of those, too. Consider the
"				i_0_CTRL-D / i_^_CTRL-D overload in the default
"				mapping as before.
"   1.32.005	07-May-2013	Add special case to handle the (rather obscure)
"				|i_0_CTRL-D| and |i_^_CTRL-D| commands, which
"				were broken by the plugin's insert mode mapping.
"   1.31.004	24-Jan-2013	Also define opposite g<< commands with
"				g:IndentCommentPrefix_alternativeOriginalCommands.
"				It's good for consistency (my muscle memory
"				often cannot distingish indenting from
"				dedenting), and necessary when using the
"				g:IndentCommentPrefix_Whitelist, because those
"				work not just in column 1 (where dedenting is
"				not possible), but in any column.
"   1.30.003	13-Dec-2012	Handle readonly and nomodifiable buffers by
"				printing just the warning / error, without
"				the multi-line function error.
"   1.30.002	12-Dec-2012	ENH: Add global and buffer-local whitelists /
"				blacklists to explicitly include / exclude
"				certain comment prefixes.
"   1.10.001	30-Mar-2011	Split off separate documentation and autoload
"				script.
"				file creation.

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_IndentCommentPrefix') || (v:version < 700)
    finish
endif
let g:loaded_IndentCommentPrefix = 1

"- configuration --------------------------------------------------------------

if ! exists('g:IndentCommentPrefix_Whitelist')
    let g:IndentCommentPrefix_Whitelist = []
endif
if ! exists('g:IndentCommentPrefix_Blacklist')
    let g:IndentCommentPrefix_Blacklist = []
endif

if ! exists('g:IndentCommentPrefix_alternativeOriginalCommands')
    let g:IndentCommentPrefix_alternativeOriginalCommands = 1
endif


"- mappings --------------------------------------------------------------------

inoremap <silent> <Plug>IndentCommentPrefixIndent <C-o>:call IndentCommentPrefix#InsertToggled(0, 0)<CR>
if ! hasmapto('<Plug>IndentCommentPrefixIndent')
    imap <C-t> <Plug>IndentCommentPrefixIndent
endif

function! s:ControlDExpression()
    " Special case to handle the |i_0_CTRL-D| and |i_^_CTRL-D| commands.
    let l:characterBeforeCursor = matchstr(getline('.'), '.\%'.col('.').'c')
    if l:characterBeforeCursor =~# '[0^]'
	" FIXME: It would be more correct to check whether the [0^] has been
	" just inserted, but I can't get to the current insertion neither via @.
	" nor via '[,'].
	return "\<C-d>"
    endif

    return "\<C-o>:call IndentCommentPrefix#InsertToggled(1, 0)\<CR>"
endfunction
inoremap <silent> <expr> <Plug>IndentCommentPrefixControlD <SID>ControlDExpression()
inoremap <silent> <Plug>IndentCommentPrefixDedent <C-o>:call IndentCommentPrefix#InsertToggled(1, 0)<CR>
if ! hasmapto('<Plug>IndentCommentPrefixDedent')
    imap <C-d> <Plug>IndentCommentPrefixControlD
endif

inoremap <silent> <Plug>IndentCommentPrefixToggleIndent <C-o>:call IndentCommentPrefix#InsertToggled(0, 1)<CR>
inoremap <silent> <Plug>IndentCommentPrefixToggleDedent <C-o>:call IndentCommentPrefix#InsertToggled(1, 1)<CR>
if ! hasmapto('<Plug>IndentCommentPrefixToggleIndent')
    imap <C-g><C-t> <Plug>IndentCommentPrefixToggleIndent
endif
if ! hasmapto('<Plug>IndentCommentPrefixToggleDedent')
    imap <C-g><C-d> <Plug>IndentCommentPrefixToggleDedent
endif


nnoremap <silent> <Plug>IndentCommentPrefix0 :<C-u>call setline('.', getline('.'))<Bar>call IndentCommentPrefix#Range(0,1,v:count1)<CR>
vnoremap <silent> <Plug>IndentCommentPrefix0 :<C-u>call setline('.', getline('.'))<Bar>'<,'>call IndentCommentPrefix#Range(0,v:count1,1)<CR>
nnoremap <silent> <Plug>IndentCommentPrefix1 :<C-u>call setline('.', getline('.'))<Bar>call IndentCommentPrefix#Range(1,1,v:count1)<CR>
vnoremap <silent> <Plug>IndentCommentPrefix1 :<C-u>call setline('.', getline('.'))<Bar>'<,'>call IndentCommentPrefix#Range(1,v:count1,1)<CR>
if ! hasmapto('<Plug>IndentCommentPrefix0', 'n')
    nmap <silent> >> <Plug>IndentCommentPrefix0
endif
if ! hasmapto('<Plug>IndentCommentPrefix0', 'x')
    xmap <silent> > <Plug>IndentCommentPrefix0
endif
if ! hasmapto('<Plug>IndentCommentPrefix1', 'n')
    nmap <silent> << <Plug>IndentCommentPrefix1
endif
if ! hasmapto('<Plug>IndentCommentPrefix1', 'x')
    xmap <silent> < <Plug>IndentCommentPrefix1
endif

if g:IndentCommentPrefix_alternativeOriginalCommands
    nnoremap g>> >>
    xnoremap g> >
    nnoremap g<< <<
    xnoremap g< <
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
