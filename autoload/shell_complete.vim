" shell_complete.vim
" Author: Ted Tibbetts
" License: Licensed under the same terms as Vim itself.
" Provides completion functions which complete in a manner similar to |:!|.
" The author has attempted to provide cross-platform compatibility,
" but the addon has not been tested on systems other than linux.

" TODO: Find out how escaping should work on Windows.
" TODO: Figure out what special characters to disallow on Windows.

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
  let args = escape#SplitOnUnescaped(a:line, '\s\+')
  return map(args, 'escape#Unescape(v:val, '' \t'')')
endfunction


" Transform a partial command into a glob expression.
" Only adds an asterisk if the command
function! shell_complete#AppendStar(expr)
  if len(a:expr) == 0
    return '*'
  elseif a:expr !~ g:escape#unescaped . '\*$'
    return a:expr . '*'
  else
    return a:expr
  endif
endfunction

function! shell_complete#Unique(strings)
  let d = {}
  for s in a:strings
    let d[s] = 1
  endfor
  return keys(d)
endfunction

" Lists commands which start with a:partialCommand.
" This is analogous to `expand_shellcmd` in vim's `src/ex_getln.c`.
function! shell_complete#CompleteCommand(partialCommand)
  if s:path.IsAbsPath(a:partialCommand) ||
        \ s:path.IsRelPath(a:partialCommand)
    let expr = shell_complete#AppendStar(a:partialCommand)
    return split(glob(expr), "\n")
  else
    let path = s:path.MakeVimPath($PATH)
    let expr = shell_complete#AppendStar(a:partialCommand)
    let matchedFiles = split(globpath(path, expr), "\n")
    let executables = filter(matchedFiles, 'executable(v:val) == 1')
    let baseFiles = map(executables, 'split(v:val, s:path.pathsep)[-1]')
    return sort(shell_complete#Unique(baseFiles))
  endif
endfunction

function! shell_complete#CompleteFilename(partialFilename)
  let expr = shell_complete#AppendStar(a:partialFilename)
  let matchedFiles = split(glob(expr))
  return matchedFiles
endfunction

function! shell_complete#Complete(argLead, cmdLine, cursorPos)
  let partial = a:cmdLine[0 : a:cursorPos - 1]
  let partialArgs = shell_complete#SplitArgs(partial)
  if len(partialArgs) == 0 ||
        \ (len(partialArgs) == 1 && a:cmdLine[a:cursorPos] =~ '\S')
    return shell_complete#CompleteCommand(a:argLead)
  else
    return shell_complete#CompleteFilename(a:argLead)
  endif
endfunction
