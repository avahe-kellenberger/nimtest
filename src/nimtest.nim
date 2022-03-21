import
  os,
  osproc,
  parseopt,
  strutils,
  strformat,
  locks,
  sets

import nimtestpkg/tester
export tester

# TODO: Make this an option, perhaps with regex.
const
  testFileSuffix = "_test.nim"
  defaultTestDir = "./tests"

var
  cmdlineArgs = "--hints:off"
  lock: Lock
  globalExitCode = 0

proc testFile(a: tuple[file: string, args: string]) {.thread.} =
  let (output, exitcode) = execCmdEx(
    command = fmt"nim {a.args} r {a.file}"
  )

  acquire(lock)
  echo output
  if exitcode != 0 or output.contains("[Failed]: "):
    globalExitCode = 1
  release(lock)

when isMainModule:
  var
    optParser = initOptParser()
    testFiles: OrderedSet[string]
    testDirs: HashSet[string]

  for opt in optParser.getopt():
    case opt.kind:
    of cmdArgument:
      if opt.key.endsWith(".nim"):
        testFiles.incl(opt.key)
      else:
        testDirs.incl(opt.key)
    of cmdShortOption:
      cmdlineArgs &= fmt" -{opt.key}:{opt.val}"
    of cmdLongOption:
      cmdlineArgs &= fmt" --{opt.key}:{opt.val}"
    of cmdEnd:
      break

  # Check the default test dir if no test files or dirs were provided.
  if testFiles.len == 0 and testDirs.len == 0:
    testDirs.incl(defaultTestDir)

  for dir in testDirs:
    for file in walkDirRec(dir):
      if file.endsWith(testFileSuffix):
        testFiles.incl(file)

  if testFiles.len > 1:
    echo fmt"Found {testFiles.len} tests..."
    initLock(lock)

    var threads = newSeq[Thread[tuple[file: string, args: string]]](testFiles.len)
    for (i, file) in testFiles.pairs:
      createThread(threads[i], testFile, (file, cmdlineArgs))
    joinThreads(threads)
    
    deinitLock(lock)

  elif testFiles.len == 1:
    echo "Found 1 test..."
    var test: string
    for file in testFiles:
      test = file

    testFile((test, cmdlineArgs))
  else:
    echo "No tests found."

  quit globalExitCode

