" Test suite for use with the UT unit testing addon.
" http://code.google.com/p/lh-vim/wiki/UT

UTSuite 'Test various aspects of the shell_complete addon.'

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
