#pragma once

namespace zoo {
struct fence {
  double num_feet_;
};

inline fence make_fence(double num_feet) { return {num_feet+1}; }
} // namespace zoo
