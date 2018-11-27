import os, strutils, sequtils

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
      echo pathString
    else:
      listFiles(path, ignored)

var f: File
if open(f,".gitignore"):
  let ignored: seq[string] = toSeq(lines(f))
  listFiles(currDir, ignored)
else:
  listFiles(currDir, newSeqWith(0, ""))

