import os, strutils, sequtils, parseopt, re
import docopt, threadpool, locks, osproc

include utils/argsBuilder, utils/streamBuilder

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

  buildStream(currDir,
    colors,
    searchTerm,
    caseSensitive,
    hidden,
    parsed,
    currDir
  )

main()
