import os, strutils, sequtils, parseopt, re

type cliArg = tuple[kind: CmdLineKind, key: TaintedString, val: TaintedString]

proc getKeys(argsSeq: seq[cliArg], targetGroup: CmdLineKind): seq[TaintedString] =
  argsSeq.filterIt(it.kind == targetGroup).mapIt(it.key)

proc parseGitIgnore(content: seq[string]): seq[string] =
  content.filterIt(not it.contains('#') and it.len > 0).map(proc(it: string): string =
    result = it
    result.removePrefix({'*'}))

proc listFiles(dir: string, searchTerm: seq[cliArg], ignored: seq[string], caseSensitive: bool) =
  let parsed = parseGitIgnore(ignored)

  for kind, path in walkDir(dir):
    var pathString: string = replace(path, dir)
    pathString.removePrefix({ '/', '\\' })

    if parsed.anyIt(it.contains(pathString)) or pathString.contains(".git"):
      continue

    if kind == pcFile:
      if len(searchTerm) == 0 or pathString.contains(re(searchTerm[0].key,
         {if caseSensitive: reStudy else: reIgnoreCase})):
         echo pathString
    else:
      listFiles(path, searchTerm, ignored, caseSensitive)

proc main =
  let
    currDir = getCurrentDir()
    argsSeq = toSeq(getopt())
    searchTerm = argsSeq.filterIt(it.kind == cmdArgument)

    flags = argsSeq.getKeys(cmdShortOption)
    opts = argsSeq.getKeys(cmdLongOption)

    caseSensitive = flags.anyIt(it.contains("s"))
    gitIgnore = not opts.anyIt(it.contains("no-ignore"))

  var f: File
  if open(f,".gitignore") and gitIgnore:
    let ignored: seq[string] = toSeq(lines(f))
    listFiles(currDir, searchTerm, ignored, caseSensitive)
    close(f)
  else:
      listFiles(currDir, searchTerm, @[], caseSensitive)

main()
