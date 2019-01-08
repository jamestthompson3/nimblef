import os, strutils, sequtils, parseopt, re, docopt, terminal, threadpool

{.experimental.}

const doc = """
Usage: nf [<searchterm>] [options]

Options:
  --help          show this help message and exit
  --no-ignore     do not ignore files and folders specified in .gitignore
  --hidden        search hidden files
  -s              case sensitive search
  --colors        color search results

Try: nf
     nf mydocument.txt
     nf --no-ignore
     nf controller -s --colors
"""

template colorEcho*(s: string, fg: ForegroundColor) =
  setForeGroundColor(fg, true)
  s.writeStyled({})
  resetAttributes()

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

proc echoFiles(channel: ptr Channel[string], colors: bool = false) {.thread.} =
  while true:
    let (dataAvailable, msg ) = channel[].tryRecv()
    if dataAvailable and msg != "":
      if colors:
        for i in split(msg, re"\/|\\"):
          if match(i, re"[a-zA-Z]*\.[a-zA-Z]+"):
            colorEcho(replace(msg, i), fgBlue)
            colorEcho(i, fgWhite)
            echo ""
      else:
        echo msg

proc searchFiles(dir: string, searchTerm: string,
  caseSensitive: bool, hidden: bool, parsed: seq[string],
  rootDir: string, channel: ptr Channel[string]
  ) {.thread.} =

  for kind, path in walkDir(dir):
    if parsed.anyIt(contains(path, it)) or path.contains(".git"):
      continue

    var pathString: string = replace(path, rootDir)
    pathString.removePrefix({ '/', '\\' })
    if not hidden and startsWith(pathString, "."):
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
        hidden,
        parsed,
        rootDir,
        channel
        )




proc main =
  let
    argsSeq = toSeq(getopt())
    args = docopt(doc)
    searchTerm = if args["<searchterm>"]: $args["<searchterm>"] else: ""
    currDir = getCurrentDir()
    caseSensitive = args["-s"]
    noIgnore = args["--no-ignore"]
    hidden = args["--hidden"]
    colors = args["--colors"]
    parsed = buildIgnored(noIgnore)

  var channel: Channel[string]

  channel.open()

  spawn echoFiles(addr(channel), colors)
  searchFiles(
    currDir,
    searchTerm,
    caseSensitive,
    hidden,
    parsed,
    currDir,
    addr(channel)
    )

main()
