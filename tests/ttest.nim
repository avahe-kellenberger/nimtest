import nimtest

describe "A test without the default suffix":
  test "1 equals 1":
    doAssert 1 == 1

  test "2 is greater than 1":
    doAssert 2 > 1

