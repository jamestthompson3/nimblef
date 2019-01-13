import os, strutils, sequtils, re

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

proc buildIgnored*(noIgnore: bool): seq[string] =
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
