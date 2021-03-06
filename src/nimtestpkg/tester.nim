import std/[macros, genasts, terminal, strutils, strformat]

export
  macros,
  terminal,
  strutils,
  strformat

# TODO: Make configurable
const NUM_INDENTATION_SPACES = 2

var testOutputIndentation = 0

template echoSuccess(args: varargs[untyped]) =
  styledWriteLine(
    stdout,
    fgGreen,
    indent("[Success]: ", testOutputIndentation),
    fgDefault,
    args
  )

template echoError(args: varargs[untyped]) =
  styledWriteLine(
    stdout,
    fgRed,
    indent("[Failed]: ", testOutputIndentation),
    fgDefault,
    args
  )

template beforeAll(body: typed) =
  proc beforeAllProc() = body

template beforeEach(body: typed) =
  proc beforeEachProc() = body

template afterEach(body: typed) =
  proc afterEachProc() = body

template afterAll(body: typed) =
  proc afterAllProc() = body

template test*(description: string, body: untyped) =
  try:
    testOutputIndentation += NUM_INDENTATION_SPACES
    body
    testOutputIndentation -= NUM_INDENTATION_SPACES
    echoSuccess(description)
  except:
    echoError(description, "\n\t", getCurrentExceptionMsg())

template it*(description: string, body: untyped) =
  test(description, body)

template assertEquals*(a, b: untyped): untyped =
  if a != b:
    raise newException(
      Exception,
      "Expected " & (repr a) & " to equal " & (repr b) &
      "\n\tassertEquals(" & astToStr(a) & ", " & astToStr(b) & ")"
    )

template assertAlmostEquals*(a, b: float): untyped =
  if not almostEquals(a, b):
    raise newException(
      Exception,
      "Expected " & (repr a) & " to equal " & (repr b) &
      "\n\tassertAlmostEquals(" & astToStr(a) & ", " & astToStr(b) & ")"
    )

template assertRaises*(exception: typedesc[Exception], errorMessage: string, code: untyped) =
  ## Raises ``AssertionDefect`` if specified ``code`` does not raise the
  ## specified exception. Example:
  ##
  ## .. code-block:: nim
  ##  doAssertRaisesSpecific(ValueError, "wrong value!"):
  ##    raise newException(ValueError, "Hello World")
  var codeDidNotRaiseException = false
  try:
    code
    codeDidNotRaiseException = true
  except Exception as e:
    if e.msg != errorMessage:
      raiseAssert("Wrong exception was raised: " & e.msg)

    if not (e of exception):
      raiseAssert(
        "$1 was raised instead of $2: $3" % [$e.name, astToStr(exception), strip(astToStr(code))]
      )

  if codeDidNotRaiseException:
    raiseAssert("$1 was not raised by: $2" % [astToStr(exception), strip(astToStr(code))])

macro describe*(description: static string, body: untyped): untyped =
  result = newStmtList()

  var blockBody = newStmtList()

  blockBody.add quote do:
    writeStyled(repeat(' ', testOutputIndentation))
    styledWrite(
      stdout,
      fgYellow,
      styleUnderscore,
      `description`
    )
    styledWriteLine(
      stdout,
      fgYellow,
      ":"
    )
    testOutputIndentation += NUM_INDENTATION_SPACES

  for x in body:
    if x.kind in {nnkCall, nnkCommand}:
      let name = x[0]
      var added = false
      template specialCalls(s: static string) =
        if not added and name.eqIdent s:
          x[0] = bindSym(s)
          blockBody.add x
          if name.eqIdent "beforeAll":
            blockBody.add newCall("beforeAllProc")
          added = true

      specialCalls("beforeAll")
      specialCalls("beforeEach")
      specialCalls("afterEach")
      specialCalls("afterAll")

      if not added:
        blockBody.add:
          genast(code = x):
            when compiles(beforeEachProc()):
              beforeEachProc()
            code
            when compiles(afterEachProc()):
              afterEachProc()
    else:
      blockBody.add x
  blockBody.add:
    genast():
      when compiles(afterAllProc()):
        afterAllProc()

  blockBody.add quote do:
    testOutputIndentation -= NUM_INDENTATION_SPACES

  result.add newBlockStmt(blockBody)

