# Package

version       = "0.1.2"
author        = "Avahe Kellenberger"
description   = "Simple testing framework for Nim"
license       = "GPL-2.0-only"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nimtest"]


# Dependencies

requires "nim >= 1.6.6"

# Tasks

task release, "Creates a release build":
  exec "nim c --outDir:./bin -d:release src/nimtest.nim"

task debug, "Creates a debug build":
  exec "nim c --outDir:./bin -d:debug src/nimtest.nim"

