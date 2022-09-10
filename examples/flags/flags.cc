#include <iostream>

#include "bricks/dflags/dflags.h"

DEFINE_int32(a, 2, "The `A` in `A+B`.");
DEFINE_int32(b, 2, "The `B` in `A+B`.");

int main() {
  std::cout << "A+B=" << FLAGS_a << '+' << FLAGS_b << '=' << FLAGS_a + FLAGS_b << std::endl;
}
