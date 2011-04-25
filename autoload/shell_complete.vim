" shell_complete.vim
" Author: Ted Tibbetts
" License: Licensed under the same terms as Vim itself.
" Provides completion functions which complete in a manner similar to |:!|.
" The author has attempted to provide cross-platform compatibility,
" but the addon has not been tested on systems other than linux.

" Platform-specific path functionality.
let shell_complete#path = {}
let s:path = shell_complete#path

  " This is (roughly) how it's done by vim
  " in `src/ex_getln.c`, function `expand_shellcmd`.
  function! s:path.UseWindowsPaths()
    return has('os2') || has('dos32') || has('dos16') ||
          \ has('gui_win32') || has('gui_win32s')
  endfunction

  " Figure out whether ':' or ';' is the path delimiter.
  " Also define the path separator as '/' or '\'
  " and declare a function to test whether or not a path is absolute.
  " TODO: Find out if there's a better way to do this.
  "       Ideally it would be possible to use vim's internal C functions.
  function! s:path.Init()
    if self.UseWindowsPaths()
      let self.pathdelim = ';'
      let self.pathsep = '\'
      function! self.IsAbsPath(path)
        return a:path =~ '^\a:[/\\]' || a:path =~ '^[/\\]\{2}'
      endfunction
    else
      let self.pathdelim = ':'
      let self.pathsep = '/'
      function! self.IsAbsPath(path)
        return a:path[0] == '/'
      endfunction
    endif
  endfunction

  function! s:path.IsRelPath(path)
    return a:path =~ '^\.\{1,2}\V' . escape(shell_complete#pathsep, '\')
  endfunction

  " Makes a comma-delimited path from a system path.
  function! s:path.MakeVimPath(syspath)
    let paths = shell_complete#SplitOnUnescaped(a:syspath,
          \                                     self.pathdelim)
    let paths = map(paths, 'shell_complete#Unescape(v:val, self.pathdelim)')
    let paths = map(paths, 'escape(v:val, '','')')
    return join(paths, ',')
  endfunction

call s:path.Init()

" Assert the presence of an even number (including 0) of '\' characters
" before what follows.
let shell_complete#unescaped = '\m\(\\\@<!\(\\\\\)*\)\@<='

" Splits a:line on unescaped occurrences of a:target.
function! shell_complete#SplitOnUnescaped(line, target)
  let re = g:shell_complete#unescaped . a:target
  return split(a:line, re)
endfunction

" Unescapes the members of the RE collection `a:coll` in `a:text`.
" Escaping on backslash-escaped backslashes is halved.
" Character classes and other escape sequences can be used in `a:text`.
function! shell_complete#Unescape(text, coll)
  let re = '\m\\\@<!\%(\(\\*\)\1\)'
        \ .'\%(\\\([' . escape(a:coll, '[]') . ']\)\)\?'
  return substitute(a:text, re, '\1\2', 'g')
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
  let args = shell_complete#SplitOnUnescaped(a:line, '\s\+')
  return map(args, 'shell_complete#Unescape(v:val, '' \t'')')
endfunction


" Transform a partial command into a glob expression.
" Only adds an asterisk if the command
function! shell_complete#AppendStar(expr)
  if len(a:expr) == 0
    return '*'
  elseif a:expr !~ g:shell_complete#unescaped . '\*$'
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
  if shell_complete#IsAbsPath(a:partialCommand) ||
        \ shell_complete#IsRelPath(a:partialCommand)
    let expr = shell_complete#AppendStar(a:partialCommand)
    return split(glob(expr), "\n")
  else
    let path = s:path.MakeVimPath($PATH)
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
        \ (len(partialArgs) == 1 && a:cmdLine[a:cursorPos] =~ '\S')
    return shell_complete#CompleteCommand(a:argLead)
  else
    return shell_complete#CompleteFilename(a:argLead)
  endif
endfunction
