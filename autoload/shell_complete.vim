" shell_complete.vim
" Author: Ted Tibbetts
" License: Licensed under the same terms as Vim itself.
" Provides completion functions which complete in a manner similar to |:!|.
" The author has attempted to provide cross-platform compatibility,
" but the addon has not been tested on systems other than linux.

" TODO: Find out how escaping should work on Windows.
" TODO: Figure out what special characters to disallow on Windows.

let s:path = g:tt#path#path

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
  let args = tt#escape#SplitOnUnescaped(a:line, '\s\+')
  return map(args, 'tt#escape#Unescape(v:val, '' \t'')')
endfunction


" Transform a partial command into a glob expression.
" Only adds an asterisk if the command
function! shell_complete#AppendStar(expr)
  if len(a:expr) == 0
    return '*'
  elseif a:expr !~ g:tt#escape#unescaped . '\*$'
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
  let matchedFiles = split(glob(expr), "\n")
  " Append a closing path separator to directories.
  let withsep =  map(matchedFiles,
        \            's:path.Join([v:val] + (isdirectory(v:val) ? [""] : []))')
  return sort(withsep)
endfunction

" Completes a shell command.
" a:shellCommand is the portion of the shell command before the cursor.
" The command is split along unescaped spaces into arguments.
" Backslashes are stripped from escaped spaces.
" The last argument is completed.
function! shell_complete#Complete(shellCommand)
  let args = shell_complete#SplitArgs(a:shellCommand)
  if len(args) == 0 ||
        \ (len(args) == 1 && (a:shellCommand =~ '\S$'))
    return shell_complete#CompleteCommand(args[-1])
  else
    let lastArg = (a:shellCommand =~ '\S$') ? args[-1] : ''
    return shell_complete#CompleteFilename(lastArg)
  endif
endfunction

" Function usable as the parameter of -complete=customlist.
" Passes the shell command which precedes the cursor to Complete.
" The initial part of the command line (the Ex command) is dropped.
" Spaces in results are escaped by prefixing them with a backslash.
" Backslashes are similarly escaped.
" TODO: Maybe add support for shell-style quoting.
" TODO: Do completion via shell forking if/when possible.
function! shell_complete#CustomListComplete(argLead, cmdLine, cursorPos)
  let partial = a:cmdLine[0 : a:cursorPos - 1]
  let shellCommand = substitute(partial, '^\S\+\s\+', '', '')
  let names = shell_complete#Complete(shellCommand)
  " TODO: It may be necessary to escape other characters
  "       in a filesystem-specific way.
  call map(names, 'escape(v:val, ''\ '')')
  return names
endfunction
