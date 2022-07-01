import
  osproc,
  strutils,
  strformat,
  sugar

import nimtestpkg/tester
export tester

# TODO: Make this an option, perhaps with regex.
const
  testFileSuffix = "_test.nim"
  defaultTestDir = "./tests"

var
  cmdlineArgs = "--hints:off"
  globalExitCode = 0

proc testFile(a: tuple[file: string, args: string]) {.thread.} =
  let (output, exitcode) = execCmdEx(
    command = fmt"nim {a.args} r {a.file}"
  )

  echo output
  if exitcode != 0 or output.contains("[Failed]: "):
    globalExitCode = 1

when isMainModule:
  import
    os,
    sets,
    parseopt

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

  if testFiles.len >= 1:
    echo fmt"Tests found: {testFiles.len}"

    let processes = collect:
      for file in testFiles:
        fmt"nim {cmdlineArgs} r {file}"
    globalExitCode = execProcesses(processes)

  else:
    echo "No tests found."

  quit globalExitCode

