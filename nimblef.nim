import os, strutils, sequtils, parseopt, re, docopt

let doc = """
Usage: nf
       nf --help
       nf --no-ignore
       nf <searchterm>
       nf -s
       nf <searchterm> -s
       nf <searchterm> --no-ignore

Options:
  --help          show this help message and exit
  --no-ignore     do not ignore files and folders specified in .gitignore
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

proc listFiles(dir: string, searchTerm: string,
  caseSensitive: bool, parsed: seq[string], rootDir: string) =

  for path in walkDirRec(dir):
    var pathString: string = replace(path, rootDir)

    pathString.removePrefix({ '/', '\\' })
    if parsed.anyIt(contains(pathString, it)) or pathString.contains(".git") or startsWith(pathString, "."):
      continue

    if len(searchTerm) == 0 or pathString.contains(re(searchTerm,
      {if caseSensitive: reStudy else: reIgnoreCase})):
          echo pathString

proc main =
  let
    argsSeq = toSeq(getopt())
    args = docopt(doc)
    searchTerm = if args["<searchterm>"]: $args["<searchterm>"] else: ""
    currDir = getCurrentDir()
    caseSensitive = args["-s"]
    noIgnore = args["--no-ignore"]
    parsed = buildIgnored(noIgnore)

  listFiles(currDir, searchTerm, caseSensitive, parsed, currDir)

main()
