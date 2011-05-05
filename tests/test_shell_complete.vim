" Test suite for use with the UT unit testing addon.
" http://code.google.com/p/lh-vim/wiki/UT

UTSuite 'Test various aspects of the shell_complete addon.'

" TODO: Figure out the right way to communicate
"       dependency on the testutils addon for testing only.
ActivateAddons testutils

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

" Complete a:partialFilename after creating the List of a:files in a temp dir.
" Clobbers the previous current directory.
" TODO: Be robust against failures when changing directory
"       or creating the directory structure.
function! s:CompleteFilenameInTestDir(partialFilename, filespec) abort
  let testdir = tempname()
  call mkdir(testdir)
  try
    let original_dir = getcwd()
    exec 'cd' fnameescape(testdir)
    try
      call testutils#CreateDirectoryStructure(a:filespec)
      try
        " return shell_complete#CompleteFilename(a:partialFilename)
        let ret = shell_complete#CompleteFilename(a:partialFilename)
        return ret
      finally
        call testutils#RemoveDirectoryStructure(a:filespec)
      endtry
    finally
      exec 'cd' fnameescape(original_dir)
    endtry
  finally
    call g:path#path.Rmdir(testdir)
  endtry
endfunction

" TODO: Add tests for edge cases like filenames containing backslashes
"       and other special characters.
"       This needs to be filesystem-specific.
function! s:TestCompleteFilename()
  Comment 'Test filename completion using the actual filesystem.'

  let path = g:path#path
  let sep = path.pathsep

  let Complete = function('s:CompleteFilenameInTestDir')

  let contents = {
        \ 'a': [],
        \ 'a b': [],
        \ 'a c': [],
        \ 'ad': {
        \   'b': [],
        \   'c': [],
        \   'cc': [] } }

  let root_filenames = sort(['a', 'a b', 'a c', path.Join(['ad', ''])])
  let ad_filenames = sort(map(keys(contents.ad),
        \                     'path.Join(["ad", v:val])'))
  let adb_filenames = [path.Join(['ad', 'b'])]
  let adc_filenames = sort(map(['c', 'cc'], 'path.Join(["ad", v:val])'))

  let all = sort(root_filenames + ad_filenames)

  Assert Complete('', contents) == root_filenames
  Assert Complete('*', contents) == root_filenames
  Assert Complete('a', contents) == root_filenames
  Assert Complete('a*', contents) == root_filenames
  Assert Complete('a ', contents) == sort(['a b', 'a c'])
  Assert Complete('a b', contents) == ['a b']
  Assert Complete('a b*', contents) == ['a b']
  Assert Complete('ad', contents) == [path.Join(['ad', ''])]
  Assert Complete(path.Join(['ad', '']), contents) == ad_filenames
  Assert Complete(path.Join(['ad', 'b']), contents) == adb_filenames
  Assert Complete(path.Join(['ad', 'c']), contents) == adc_filenames
  Assert Complete('**', contents) == all
  Assert Complete('a**', contents) == all
endfunction
