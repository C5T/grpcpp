#include <iostream>

#include "current/bricks/dflags/dflags.h"
#include "current/bricks/file/file.h"

// This "input" file is available right away, as the code is run with `grpcpp examples/dirs`.
DEFINE_string(inner, "foo.txt", "The path to the 'inner' file, from the source dir.");

// This "input" file is available only when run as `grpcpp examples/dirs 'examples/subdir/with spaces'`.
DEFINE_string(outer, "/extra/with spaces/foo.txt", "The path to the 'outer' file, from the other \"source\" dir.");

using namespace current;
using namespace current::strings;

int main(int argc, char** argv) {
  ParseDFlags(&argc, &argv);
  std::cout << FLAGS_inner << " : " << std::flush << Trim(FileSystem::ReadFileAsString(FLAGS_inner)) << std::endl;
  try {
    std::cout << FLAGS_outer << " : " << std::flush << Trim(FileSystem::ReadFileAsString(FLAGS_outer)) << std::endl;
  } catch (CannotReadFileException const&) {
    std::cout << "File not found, did you run `grpcpp examples/dirs 'examples/subdir/with spaces'`?" << std::endl;
  }
}
