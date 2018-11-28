import os, strutils, sequtils, parseopt, re

type cliArg = tuple[kind: CmdLineKind, key: TaintedString, val: TaintedString]

let currDir: string = getCurrentDir()

let argsSeq: seq[cliArg] = toSeq(getopt())

proc getKeys(targetGroup: CmdLineKind): seq[TaintedString] =
  map(
    filter(argsSeq,
      proc(i: cliArg): bool = return i.kind == targetGroup),
        proc(i: cliArg): TaintedString = i.key)

let searchTerm = filter(argsSeq,
  proc(i: cliArg): bool = return i.kind == cmdArgument)

let flags = getKeys(cmdShortOption)
let opts = getKeys(cmdLongOption)

let searchTermIsNotEmpty = len(searchTerm) != 0 and searchTerm[0].key != ""
let searchIsCaseSensitive = any(flags,
  proc(i: string): bool = return contains(i, "s"))

let gitIgnoreIsNotUsed = any(opts,
proc(i: string): bool = return contains(i, "no-ignore"))


proc parseGitIgnore(openedFile: seq[string]): seq[string] =
  let parsedFiles = map(
    filter(openedFile,
      proc (i: string): bool =  return contains(i, "#") != true and i != ""),
        proc (i: string): string =
          var glob: string = i
          glob.removePrefix({ '*' })
          return glob
        )
  return parsedFiles

proc listFiles(dir: string, ignored: seq[string]) =
  let parsed = parseGitIgnore(ignored)
  for kind, path in walkDir(dir):
    var pathString: string = replace(path, currDir)
    pathString.removePrefix({ '/', '\\' })
    if any(parsed,
      proc (i: string): bool =
        return contains(pathString, i)) or contains(pathString, ".git"):
      continue

    elif kind == pcFile:
     if searchTermIsNotEmpty:
        if contains(pathString, re(searchTerm[0].key,
          {if searchIsCaseSensitive: reStudy else: reIgnoreCase})):
          echo pathString
        else:
          continue
     else:
        echo pathString
    else:
      listFiles(path, ignored)

var f: File

if open(f,".gitignore") and gitIgnoreIsNotUsed != true:
  let ignored: seq[string] = toSeq(lines(f))
  listFiles(currDir, ignored)
  close(f)
else:
  listFiles(currDir, newSeqWith(0, ""))

