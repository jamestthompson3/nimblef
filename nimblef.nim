import os, strutils, sequtils, parseopt, re, glob

type cliArg = tuple[kind: CmdLineKind, key: TaintedString, val: TaintedString]

proc getKeys(argsSeq: seq[cliArg], targetGroup: CmdLineKind): seq[TaintedString] =
  argsSeq.filterIt(it.kind == targetGroup).mapIt(it.key)

proc parseGitIgnore(content: seq[string]): seq[string] =
  content.filterIt(not it.contains('#') and it.len > 0).map(
    proc(it: string): string =
      result = it
      result.removePrefix({'*'})
      result.removeSuffix({ '/', '\\' })
    )

proc openGitIgnore(gitIgnore: bool): seq[string] =
  var f: File
  if open(f,".gitignore") and gitIgnore:
    let ignored = toSeq(lines(f))
    let parsed = parseGitIgnore(ignored)
    result = parsed
  else:
    for kind, path in walkDir("../"):
      if path.contains(".gitignore") and open(f, path):
        let ignored = toSeq(lines(f))
        let parsed = parseGitIgnore(ignored)
        result = parsed
      else:
        result = @[]


let currDir = getCurrentDir()

proc listFiles(dir: string, searchTerm: seq[cliArg],
  caseSensitive: bool, parsed: seq[string]) =

  for kind, path in walkDir(dir):
    var pathString: string = replace(path, currDir)
    pathString.removePrefix({ '/', '\\' })

    if parsed.anyIt(contains(pathString, it)) or pathString.contains(".git"):
      continue

    if kind == pcFile:
      if len(searchTerm) == 0 or pathString.contains(re(searchTerm[0].key,
         {if caseSensitive: reStudy else: reIgnoreCase})):
         echo pathString
    else:
      listFiles(path, searchTerm, caseSensitive, parsed)

proc main =
  let
    argsSeq = toSeq(getopt())
    searchTerm = argsSeq.filterIt(it.kind == cmdArgument)

    flags = argsSeq.getKeys(cmdShortOption)
    opts = argsSeq.getKeys(cmdLongOption)

    caseSensitive = flags.anyIt(it.contains("s"))
    gitIgnore = not opts.anyIt(it.contains("no-ignore"))
    parsed = openGitIgnore(gitIgnore)

  listFiles(currDir, searchTerm, caseSensitive, parsed)

main()
