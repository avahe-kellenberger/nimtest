import nimtest

test "top level test":
  doAssert 10 > 9

describe "Sample test":

  test "nest 1 level deep":
    doAssert 2 > 1

  describe "Nested describe":

    test "test one":
      doAssert 1 == 1

    test "test two":
      doAssert 2 == 2

    it "foo":
      doAssert 23 > 0

