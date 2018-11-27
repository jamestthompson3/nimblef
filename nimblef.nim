import os, strutils, sequtils, parseopt, re

type cliArg = tuple[kind: CmdLineKind, key: TaintedString, val: TaintedString]

let searchTerm = filter(toSeq(getopt()), proc(i: cliArg): bool = return i.kind == cmdArgument)

let flags = map(filter(toSeq(getopt()), proc(i:cliArg): bool = return i.kind == cmdShortOption), proc(i: cliArg): TaintedString = i.key)

proc parseGitIgnore(openedFile: seq[string]): seq[string] =
  let parsedFiles = filter(openedFile, proc (i: string): bool =  return contains(i, "#") != true and i != "")
  return parsedFiles

let currDir: string = getCurrentDir()
proc listFiles(dir: string, ignored: seq[string]) =
  let parsed = parseGitIgnore(ignored)
  for kind, path in walkDir(dir):
    var pathString: string = replace(path, currDir)
    pathString.removePrefix({ '/', '\\' })
    if any(parsed, proc (i: string): bool = return contains(pathString, i)) or contains(pathString, ".git"):
      continue
    elif kind == pcFile:
     if len(searchTerm) != 0 and searchTerm[0].key != "":
        if contains(pathString, re(searchTerm[0].key,
          if any(flags, proc(i: string): bool = return contains(i, "i")): {reIgnoreCase} else: {reStudy})): echo pathString
        else: continue
     else:
        echo pathString
    else:
      listFiles(path, ignored)

var f: File
if open(f,".gitignore"):
  let ignored: seq[string] = toSeq(lines(f))
  listFiles(currDir, ignored)
else:
  listFiles(currDir, newSeqWith(0, ""))

