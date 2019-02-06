import terminal, strutils, re, os, queues, times, sequtils

template colorEcho*(s: string, fg: ForegroundColor) =
  setForeGroundColor(fg, true)
  s.writeStyled({})

type StreamStatus = enum
  Streaming
  Buffering

const MAX_BUFFER_SIZE = 256

proc echoColor(msg: string) =
  let pathStrings = split(msg, re"\/|\\")
  for index, pathStr in pathStrings:
    if match(pathStr, re"[a-zA-Z]*\.[a-zA-Z]+"):
      colorEcho(replace(msg, pathStr), fgBlue)
      colorEcho(pathStr, fgWhite)
      echo ""
    elif index == pathStrings.len:
        colorEcho(replace(msg, pathStr), fgBlue)
        colorEcho(pathStr, fgWhite)
        echo ""

proc buildStream*(dir: string, colors: bool, searchTerm: string,
  caseSensitive: bool, hidden: bool, parsed: seq[string],
  rootDir: string
  ) =
  var fileQueue = initQueue[string]()
  var mode: StreamStatus = Buffering
  var time = cpuTime()

  proc echoFiles(msg: string) =
    if mode == Buffering:
      if fileQueue.len > MAX_BUFFER_SIZE or msg == "flush":
        while fileQueue.len > 0:
          mode = Streaming
          if colors:
            echoColor(fileQueue.pop())
          else:
            echo fileQueue.pop()
      else:
        fileQueue.add(msg)
    else:
      if colors:
        echoColor(msg)
      else:
        echo msg
      mode = Buffering

  proc searchFiles(dir: string, searchTerm: string,
    caseSensitive: bool, hidden: bool, parsed: seq[string],
    rootDir: string
    ) =

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
          echoFiles(pathString)

      else:
        searchFiles(
          pathString,
          searchTerm,
          caseSensitive,
          hidden,
          parsed,
          rootDir
          )

  searchFiles(
    dir,
    searchTerm,
    caseSensitive,
    hidden,
    parsed,
    rootDir,
    )
  echoFiles("flush")

