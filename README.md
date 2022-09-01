# nimtest

A simple testing framework for Nim.

This is used mostly for my personal projects.
If you're looking for something more "official",
take a look at [Testament](https://nim-lang.org/docs/testament.html).

## Examples

See the `tests` directory for more comprehensive tests.

```nim
describe "assertEquals":

  type Foo = ref object
    x: int

  it "works properly with nillable objects":
    var f: Foo = nil
    assertEquals(f, nil)

    f = Foo(x: 5)
    assertRaises:
      assertEquals(f, nil)

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

```

