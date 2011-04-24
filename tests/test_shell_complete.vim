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
