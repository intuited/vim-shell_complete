" Test suite for use with the UT unit testing addon.
" http://code.google.com/p/lh-vim/wiki/UT

UTSuite Test various aspects of the shell_complete addon.

function! s:TestUnescapedRegexp()
  Comment "Test various levels of escaping using the unescaped regexp fragment."
  Assert 'oneDtwo' =~# g:shell_complete#unescaped . 'D'
  Assert 'one\Dtwo' !~# g:shell_complete#unescaped . 'D'
  Assert 'one\\Dtwo' =~# g:shell_complete#unescaped . 'D'
  Assert 'one\\\Dtwo' !~# g:shell_complete#unescaped . 'D'
  Assert 'one\\\\Dtwo' =~# g:shell_complete#unescaped . 'D'
  Assert 'one\\\\\Dtwo' !~# g:shell_complete#unescaped . 'D'
endfunction

function! s:TestAppendStar()
  Comment 'Test the appending of wildcards.'
  Assert shell_complete#AppendStar('') == '*'
  Assert shell_complete#AppendStar('*') == '*'
  Assert shell_complete#AppendStar('star') == 'star*'
  Assert shell_complete#AppendStar('star*') == 'star*'
  Assert shell_complete#AppendStar('**') == '**'
  Assert shell_complete#AppendStar('\*') == '\**'
  Assert shell_complete#AppendStar('\\*') == '\\*'
endfunction

function! s:TestSplitOnUnescaped()
  Comment 'Test splitting on unescaped characters.'
  Assert shell_complete#SplitOnUnescaped('D', 'abcDefg') == ['abc', 'efg']
  Assert shell_complete#SplitOnUnescaped('D', 'abc\Defg') == ['abc\Defg']
  Assert shell_complete#SplitOnUnescaped('D', 'abc\\Defg') == ['abc\\', 'efg']
  Assert shell_complete#SplitOnUnescaped('D', 'abc\\\Defg') == ['abc\\\Defg']
  Assert shell_complete#SplitOnUnescaped('D', 'abc\\\\Defg') == ['abc\\\\', 'efg']
endfunction

let s:vals = {}
function! s:vals.True()
  return 1
endfunction
function! s:vals.False()
  return 0
endfunction

function! s:TestMakeVimPathsWin()
  Comment 'Test creation of comma-delimited paths'
        \ .' from `;`-delimited system paths.'
  let path = copy(g:shell_complete#path)
  let path.UseWindowsPaths = s:vals.True
  call path.Init()

  Assert path.MakeVimPath('one') == 'one'
  Assert path.MakeVimPath('one;two;three') == 'one,two,three'
  Assert path.MakeVimPath('o,n,e;two;three') == 'o\,n\,e,two,three'
endfunction

function! s:TestMakeVimPathsNonWin()
  Comment 'Test creation of comma-delimited paths'
        \ .' from `:`-delimited system paths.'
  let path = copy(g:shell_complete#path)
  let path.UseWindowsPaths = s:vals.False
  call path.Init()

  Assert path.MakeVimPath('one') == 'one'
  Assert path.MakeVimPath('one:two:three') == 'one,two,three'
  Assert path.MakeVimPath('o\:n\:e:two') == 'o:n:e,two'
  Assert path.MakeVimPath('o,n,e:two:three') == 'o\,n\,e,two,three'
endfunction
