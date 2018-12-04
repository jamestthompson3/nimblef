import os, strutils, sequtils, parseopt, re, docopt, threadpool

{.experimental.}

# TODO:
# Implement a searcher / buffer format
# One thread searches and the other echoes to the buffer
const doc = """
Usage: nf
       nf --help
       nf --no-ignore
       nf --no-hidden
       nf <searchterm>
       nf -s
       nf <searchterm> -s
       nf <searchterm> --no-ignore
       nf <searchterm> --no-hidden

Options:
  --help          show this help message and exit
  --no-ignore     do not ignore files and folders specified in .gitignore
  --no-hidden     do not ignore hidden files
  -s              case sensitive search
  <searchterm>    search for a specific term

Try: nf
     nf mydocument.txt
     nf --no-ignore
     nf controller -s
"""

proc parseGitIgnore(content: seq[string]): seq[string] =
  content.filterIt(not it.contains('#') and it.len > 0).map(
    proc(it: string): string =
      result = it
      result.removePrefix({'*'})
      result.removeSuffix({ '/', '\\' })
    )

proc concatIgnored(ignored: seq[string],
  alwaysIgnored: seq[string]): seq[string] =
    let parsed = parseGitIgnore(ignored)
    result = concat(parsed, alwaysIgnored)

proc buildIgnored(noIgnore: bool): seq[string] =
  let alwaysIgnored: seq[string] = @[
    "node_modules", "target",
    "nimcache", "pycache",
    "build"
    ]
  var f: File
  if open(f,".gitignore") and not noIgnore:
    result = concatIgnored(toSeq(lines(".gitignore")), alwaysIgnored)
  else:
    for kind, path in walkDir("../"):
      if path.contains(".gitignore") and open(f, path):
        result = concatIgnored(toSeq(lines(path)), alwaysIgnored)
      else:
        result = if noIgnore: @[] else: alwaysIgnored

proc searchFiles(dir: string, searchTerm: string,
  caseSensitive: bool, noHidden: bool, parsed: seq[string], rootDir: string,
  channel: ptr Channel[string]
  ) {.thread.} =

  for kind, path in walkDir(dir):
    if parsed.anyIt(contains(path, it)) or path.contains(".git"):
      continue

    var pathString: string = replace(path, rootDir)
    pathString.removePrefix({ '/', '\\' })
    if not noHidden and startsWith(pathString, "."):
      continue

    if kind == pcFile:
      if len(searchTerm) == 0 or pathString.contains(re(searchTerm,
        {if caseSensitive: reStudy else: reIgnoreCase})):
        channel[].send(pathString)
    else:
      searchFiles(
        pathString,
        searchTerm,
        caseSensitive,
        noHidden,
        parsed,
        rootDir,
        channel
      )

proc echoFiles(channel: ptr Channel[string]) {.thread.} =
  while true:
    let message = channel[].recv()
    echo message

proc main =
  let
    argsSeq = toSeq(getopt())
    args = docopt(doc)
    searchTerm = if args["<searchterm>"]: $args["<searchterm>"] else: ""
    currDir = getCurrentDir()
    caseSensitive = args["-s"]
    noIgnore = args["--no-ignore"]
    noHidden = args["--no-hidden"]
    parsed = buildIgnored(noIgnore)

  var channel: Channel[string]

  channel.open()
  spawnX echoFiles(addr(channel))
  searchFiles(
    currDir,
    searchTerm,
    caseSensitive,
    noHidden,
    parsed,
    currDir,
    addr(channel)
    )

main()
