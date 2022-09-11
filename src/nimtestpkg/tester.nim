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
  block:
    try:
      testOutputIndentation += NUM_INDENTATION_SPACES
      body
      echoSuccess(description)
    except:
      echoError(description, "\n\t", getCurrentExceptionMsg())
    finally:
      testOutputIndentation -= NUM_INDENTATION_SPACES

template it*(description: string, body: untyped) =
  test(description, body)

template assertEquals*(a, b: untyped): untyped =
  when compiles(isNil(a)) and compiles(isNil(b)):
    if a != b:
      let aRepr = if isNil(a):
        "nil"
      else:
        repr a

      let bRepr = if isNil(b):
        "nil"
      else:
        repr b

      raise newException(
        Exception,
        "assertEquals(" & astToStr(a) & ", " & astToStr(b) & ")\n\t" &
        "Expected:\n\t" & aRepr & "\n\tto equal:\n\t" & bRepr
      )
  else:
    if a != b:
      raise newException(
        Exception,
        "Expected:\n\t" & (repr a) & "\n\tto equal:\n\t" & (repr b) &
        "\n\tassertEquals(" & astToStr(a) & ", " & astToStr(b) & ")"
      )

template assertAlmostEquals*(a, b: float): untyped =
  if not almostEquals(a, b):
    raise newException(
      Exception,
      "Expected:\n\t" & (repr a) & "\n\tto equal:\n\t" & (repr b) &
      "\n\tassertAlmostEquals(" & astToStr(a) & ", " & astToStr(b) & ")"
    )

template assertRaises*(exception: typedesc[Exception], errorMessage: string, code: untyped) =
  ## Raises ``AssertionDefect`` if specified ``code`` does not raise the
  ## specified exception. Example:
  ##
  ## .. code-block:: nim
  ##  AssertRaises(ValueError, "wrong value!"):
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

template assertRaises*(code: untyped) =
  ## Raises ``AssertionDefect``
  ## if ``code`` does not raise an exception.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##  assertRaises:
  ##    raise newException(ValueError, "Hello World")
  try:
    code
    raiseAssert("$1 was not raised by: $2" % [astToStr(exception), strip(astToStr(code))])
  except Exception as e:
    discard

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

