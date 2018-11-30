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
  let alwaysIgnored: seq[string] = @["node_modules", "target"]
  var f: File
  if open(f,".gitignore") and gitIgnore:
    let ignored = toSeq(lines(f))
    let parsed = parseGitIgnore(ignored)
    result = concat(parsed, alwaysIgnored)
  else:
    for kind, path in walkDir("../"):
      if path.contains(".gitignore") and open(f, path):
        let ignored = toSeq(lines(f))
        let parsed = parseGitIgnore(ignored)
        result = concat(parsed, alwaysIgnored)
      else:
        result = alwaysIgnored



proc listFiles(dir: string, searchTerm: seq[cliArg],
  caseSensitive: bool, parsed: seq[string], rootDir: string) =

  for path in walkDirRec(dir):
    var pathString: string = replace(path, rootDir)

    pathString.removePrefix({ '/', '\\' })
    if parsed.anyIt(contains(pathString, it)) or pathString.contains(".git") or startsWith(pathString, "."):
      continue

    if len(searchTerm) == 0 or pathString.contains(re(searchTerm[0].key,
      {if caseSensitive: reStudy else: reIgnoreCase})):
        echo pathString
    # for path in walkDirRec(dir, yieldFilter = {pcDir})

    # if kind == pcDir:
    #   spawnX listFiles(path, searchTerm, caseSensitive, parsed, rootDir)

proc main =
  let
    argsSeq = toSeq(getopt())
    searchTerm = argsSeq.filterIt(it.kind == cmdArgument)

    currDir = getCurrentDir()
    flags = argsSeq.getKeys(cmdShortOption)
    opts = argsSeq.getKeys(cmdLongOption)

    caseSensitive = flags.anyIt(it.contains("s"))
    gitIgnore = not opts.anyIt(it.contains("no-ignore"))
    parsed = openGitIgnore(gitIgnore)

  listFiles(currDir, searchTerm, caseSensitive, parsed, currDir)

main()
