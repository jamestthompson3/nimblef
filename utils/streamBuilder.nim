import terminal, strutils, re, os, queues, coro

template colorEcho*(s: string, fg: ForegroundColor) =
  setForeGroundColor(fg, true)
  s.writeStyled({})
  resetAttributes()

proc echoColor(msg: string) =
  for i in split(msg, re"\/|\\"):
    if match(i, re"[a-zA-Z]*\.[a-zA-Z]+"):
      colorEcho(replace(msg, i), fgBlue)
      colorEcho(i, fgWhite)
      echo ""

# proc echoFiles(fileQueue: Queue[string], colors: bool = false) {.thread.} =
 # while fileQueue.len > 0:
 #   echo fileQueue.pop()
 # for message in items(fileQueue):
 #   if message != "":
 #     if colors:
 #       echoColor(pop(fileQueue))
 #     else:
 #       echo pop(fileQueue)

proc buildStream*(dir: string, colors: bool, searchTerm: string,
  caseSensitive: bool, hidden: bool, parsed: seq[string],
  rootDir: string
  ) =
  var coro1: CoroutineRef
  var fileQueue = initQueue[string]()

  proc searchFiles(dir: string, searchTerm: string,
    caseSensitive: bool, hidden: bool, parsed: seq[string],
    rootDir: string
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
            fileQueue.add(pathString)

      else:
        coro.wait(coro.start(
          proc() =
            while fileQueue.len > 0:
              if colors:
                echoColor(fileQueue.pop())
              else:
                echo fileQueue.pop()
          ))
        searchFiles(
          pathString,
          searchTerm,
          caseSensitive,
          hidden,
          parsed,
          rootDir
          )

  coro.start(proc() = searchFiles(
    dir,
    searchTerm,
    caseSensitive,
    hidden,
    parsed,
    rootDir,
    ))
  coro.run()

