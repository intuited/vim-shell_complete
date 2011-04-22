" shell_complete.vim
" Author: Ted Tibbetts
" License: Licensed under the same terms as Vim itself.
" Provides completion functions which complete in a manner similar to |:!|.
" The author has attempted to provide cross-platform compatibility,
" but the addon has not been tested on systems other than linux.

" Platform-specific functionality.
" Figure out whether ':' or ';' is the path delimiter.
" This is (roughly) how it's done by vim
" in `src/ex_getln.c`, function `expand_shellcmd`.
" Also define the path separator as '/' or '\'
" and declare a function to test whether or not a path is absolute.
" TODO: Find out if there's a better way to do this.
"       Ideally it would be possible to use vim's internal C functions.
if has('os2') || has('dos32') || has('dos16') ||
      \ has('gui_win32') || has('gui_win32s')
  let shell_complete#pathdelim = ';'
  let shell_complete#pathsep = '\'
  function! shell_complete#IsAbsPath(path)
    return a:path =~ '^\a:[/\\]' || a:path =~ '^[/\\]\{2}'
  endfunction
else
  let shell_complete#pathdelim = ':'
  let shell_complete#pathsep = '/'
  function! shell_complete#IsAbsPath(path)
    return a:path[0] == '/'
  endfunction
endif

function! shell_complete#IsRelPath(path)
  return a:path =~ '^\.\{1,2}' . escape(shell_complete#pathsep, '\')
endfunction

" Assert an absence of an odd number of '\' characters behind what follows.
let shell_complete#unescaped = '\m\(\(\\\\\)*\\\)\@<!'

" Splits a:line on unescaped occurrences of a:target.
function! shell_complete#SplitOnUnescaped(target, line)
  let re = shell_complete#unescaped . a:target
  return split(a:line, re)
endfunction

" Splits the command line, respecting escaping.
" This is an inherently flawed way of doing this,
" since it should really be done by the shell that will handle the command.
" Here we just watch for backslash-escaped spaces and backslashes.
" Note that Vim's built-in stuff doesn't actually work correctly here:
" completing a double-quoted filename that contains spaces
" will result in the spaces being backslash-escaped within the quotes.
" TODO: Find out if Vim does this differently on different platforms.
" Return: a List of the arguments in the String a:line.
function! shell_complete#SplitArgs(line)
  " Split at any series of spaces not preceded by an uneven number of \'s
  return shell_complete#SplitOnUnescaped('\s\+', a:line)
endfunction


" Makes a comma-delimited path from a system path.
function! shell_complete#MakeVimPath(syspath)
  let paths = shell_complete#SplitOnUnescaped(shell_complete#pathdelim)
  let paths = map(paths, 'escape(v:val, '','')')
  return join(paths, ',')
endfunction

" Transform a partial command into a glob expression.
" Only adds an asterisk if the command
function! shell_complete#AppendStar(expr)
  if len(a:expr) == 0
    return '*'
  elseif a:expr !~ shell_complete#unescaped . '\*$'
    return expr . '*'
  endif
endfunction

function! shell_complete#Unique(strings)
  let d = {}
  for s in strings
    let d[s] = 1
  endfor
  return keys(d)
endfunction

" Lists commands which start with a:partialCommand.
" This is analogous to `expand_shellcmd` in vim's `src/ex_getln.c`.
function! shell_complete#CompleteCommand(partialCommand)
  if shell_complete#IsAbsPath(a:partialCommand) ||
        \ shell_complete#IsRelPath(a:partialCommand)
    let expr = shell_complete#AppendStar(partialCommand)
    return split(glob(expr), "\n")
  else
    let path = shell_complete#MakeVimPath($PATH)
    let expr = shell_complete#AppendStar(a:partialCommand)
    let matchedFiles = split(globpath(path, expr), "\n")
    let baseFiles = map(matchedFiles, 'split(v:val, shell_complete#pathsep)[-1]')
    return sort(shell_complete#unique(baseFiles))
  endif
endfunction

function! shell_complete#Complete(argLead, cmdLine, cursorPos)
  let partial = a:cmdLine[0 : a:cursorPos - 1]
  let partialArgs = shell_complete#SplitArgs(partial)
  if len(partialArgs) == 0 ||
        \ (len(partialArgs) == 1 && cmdLine[cursorPos] =~ '\S')
    return shell_complete#CompleteCommand(argLead)
  else
    return shell_complete#CompleteFilename(argLead)
  endif
endfunction
