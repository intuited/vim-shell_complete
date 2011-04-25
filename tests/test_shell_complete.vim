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
  Assert shell_complete#SplitOnUnescaped('abcDefg', 'D') == ['abc', 'efg']
  Assert shell_complete#SplitOnUnescaped('abc\Defg', 'D') == ['abc\Defg']
  Assert shell_complete#SplitOnUnescaped('abc\\Defg', 'D') == ['abc\\', 'efg']
  Assert shell_complete#SplitOnUnescaped('abc\\\Defg', 'D') == ['abc\\\Defg']
  Assert shell_complete#SplitOnUnescaped('abc\\\\Defg', 'D') == ['abc\\\\', 'efg']
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

  PrettyPrint path

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

function! s:TestUnescape()
  Comment 'Test the unescape function.'
  Assert shell_complete#Unescape('t', 't') == 't'
  Assert shell_complete#Unescape('\t', 't') == 't'
  Assert shell_complete#Unescape('\t\t', 't') == 'tt'
  Assert shell_complete#Unescape('\\t', 't') == '\t'
  Assert shell_complete#Unescape('\\\t', 't') == '\t'
  Assert shell_complete#Unescape('\\\\t', 't') == '\\t'
  Assert shell_complete#Unescape('t\\\\t', 't') == 't\\t'
  Assert shell_complete#Unescape('\\\\', 't') == '\\'
endfunction

function! s:TestSplitArgs()
  Comment 'Test argument splitting.'
  Assert shell_complete#SplitArgs('one two') == ['one', 'two']
  Assert shell_complete#SplitArgs('one  two') == ['one', 'two']
  Assert shell_complete#SplitArgs("one\ttwo") == ['one', 'two']
  Assert shell_complete#SplitArgs("one \ttwo") == ['one', 'two']
  Assert shell_complete#SplitArgs('one two three') == ['one', 'two', 'three']
  Assert shell_complete#SplitArgs('one') == ['one']
  Assert shell_complete#SplitArgs('one\ two') == ['one two']
  Assert shell_complete#SplitArgs('one\\ two') == ['one\', 'two']
  Assert shell_complete#SplitArgs('one\\\ two') == ['one\ two']
  Assert shell_complete#SplitArgs('one\\\\ two') == ['one\\', 'two']
  Assert shell_complete#SplitArgs('') == []
  Assert shell_complete#SplitArgs(' ') == []
endfunction

function! s:TestUnique()
  Comment 'Test the Unique function.'
  Assert sort(shell_complete#Unique(['1', '2', '3'])) == ['1', '2', '3']
  Assert sort(shell_complete#Unique(['1', '2', '1'])) == ['1', '2']
  Assert sort(shell_complete#Unique(['1', '2', '2'])) == ['1', '2']
  Assert sort(shell_complete#Unique(['1', '1', '1'])) == ['1']
  Assert sort(shell_complete#Unique([])) == []
  Assert sort(shell_complete#Unique(['1'])) == ['1']
  " This happens because Unique typecasts the values to Strings.
  " This is so that they can be used as Dictionary keys.
  " This is really not ideal, but allows the thing to be done more quickly.
  Assert sort(shell_complete#Unique(['1', '2', 2])) == ['1', '2']
  " TODO: Add tests which pass parameters of different types (Dict, List).
endfunction
