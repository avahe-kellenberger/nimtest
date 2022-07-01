import
  macros,
  terminal,
  strutils,
  strformat

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

macro describe*(description: string, body: untyped): untyped =
  result = newStmtList()
  result.add quote do:
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

  result.add quote do:
    testOutputIndentation += NUM_INDENTATION_SPACES

  var
    # outsideTestBlocks is used when there are "it.only" conditions.
    # The code outside of test blocks is typically used _in_ tests.
    outsideTestBlocks: seq[NimNode]
    testBlocks: seq[NimNode]

  for node in body:
    var addedTestBlock = false
    if node.kind == nnkCommand:
      let testDecl = node[0]
      if testDecl.kind == nnkDotExpr and testDecl[0].kind == nnkIdent:
        if eqIdent("test", testDecl[0].strVal) or eqIdent("it", testDecl[0].strVal):
          if testDecl[1].kind == nnkIdent and eqIdent("only", testDecl[1].strVal):
            node[0] = newIdentNode("test")
            testBlocks.add node
            addedTestBlock = true

    if not addedTestBlock:
      outsideTestBlocks.add node

  if testBlocks.len > 0:
    if outsideTestBlocks.len > 0:
      result.add outsideTestBlocks
    result.add testBlocks
  else:
    # No exclusive tests, add everything under the describe block.
    result.add body

  result.add quote do:
    testOutputIndentation -= NUM_INDENTATION_SPACES

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
      raiseAssert("$1 was raised instead of $2: $3" % [$e.name, astToStr(exception), strip(astToStr(code))])

  if codeDidNotRaiseException:
    raiseAssert("$1 was not raised by: $2" % [astToStr(exception), strip(astToStr(code))])

when isMainModule:
  describe "testing":
    test "test one":
      doAssert 1 == 1

    test.only "only this test will run":
      doAssert 2 == 2

