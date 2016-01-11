#pragma once

namespace zoo {
struct wolf_display {
  fence fence_;
};

inline wolf_display make_wolf_display() { return {make_fence(50)}; }
}  // namespace zoo
