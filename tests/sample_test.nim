import
  nimtest,
  std/locks

test "top level test":
  doAssert 10 > 9

describe "Sample test":

  test "nest 1 level deep":
    doAssert 2 > 1

  describe "Nested describe":
    var a = 1

    beforeEach:
      a = 5

    test "test one":
      doAssert a == 5

    test "test two":
      doAssert 2 == 2

    it "foo":
      doAssert 23 > 0


describe "Test with hooks":
  var
    lock: Lock
    a: int

  beforeAll:
    initLock(lock)

  beforeEach:
    a = 5
    acquire(lock)

  afterEach:
    release(lock)

  afterAll:
    deinitLock(lock)

  it "tests something":
    doAssert(a == 5)


describe "assertEquals":

  type Foo = ref object
    x: int

  it "works properly with nillable objects":
    var f: Foo = nil
    assertEquals(f, nil)

    f = Foo(x: 5)
    assertRaises:
      assertEquals(f, nil)

