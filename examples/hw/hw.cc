#include <iostream>

int main() {
#ifdef NDEBUG
  std::cout << "Hello, World, from an NDEBUG build!" << std::endl;
#else
  std::cout << "Hello, World, from a DEBUG build!" << std::endl;
#endif
}
