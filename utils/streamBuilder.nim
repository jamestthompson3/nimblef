import terminal, strutils, re, os, threadpool

{.experimental.}

type
  StreamStatus {.pure.} = enum
    Buffering, Streaming

const MAX_BUFFER_TIME = 50

template colorEcho*(s: string, fg: ForegroundColor) =
  setForeGroundColor(fg, true)
  s.writeStyled({})
  resetAttributes()

proc echoColor(msg: string) {.thread.} =
  for i in split(msg, re"\/|\\"):
    if match(i, re"[a-zA-Z]*\.[a-zA-Z]+"):
      colorEcho(replace(msg, i), fgBlue)
      colorEcho(i, fgWhite)
      echo ""

proc echoFiles(channel: ptr Channel[string], colors: bool = false) {.thread.} =
  var mode = StreamStatus.Buffering
  while true:
    if mode == StreamStatus.Buffering:
      let messages = channel[].peek()
      for message in 0..messages:
        let (_, msg) = channel[].tryRecv()
        if msg != "":
          mode = StreamStatus.Streaming
          if colors:
            echoColor(msg)
          else:
            echo msg
      mode = StreamStatus.Buffering

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


proc buildStream*(dir: string, colors: bool, searchTerm: string,
  caseSensitive: bool, hidden: bool, parsed: seq[string],
  rootDir: string
  ) =
  var channel: Channel[string]

  channel.open()

  spawn echoFiles(addr(channel), colors)
  searchFiles(
    dir,
    searchTerm,
    caseSensitive,
    hidden,
    parsed,
    rootDir,
    addr(channel)
    )

