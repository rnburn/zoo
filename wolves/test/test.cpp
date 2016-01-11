#include <zoo/wolves/dependency.h>
#include <zoo/wolves/display.h>

int main() {
  auto display = zoo::make_wolf_display();
  std::cout << display.fence_.num_feet_ << "\n";
  return 0;
}
