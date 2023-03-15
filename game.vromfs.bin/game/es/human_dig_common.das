module human_dig_common shared

require math
require math.base


def pack_digging_radius(radius : float; limits : float2)
  let packRangeLen = limits.y - limits.x
  let clampedRadius = clamp(radius, limits.x, limits.y)
  let normalizedRadius = (clampedRadius - limits.x) / packRangeLen
  return uint8(roundi(normalizedRadius * 255.0))


def unpack_digging_radius(radius : uint8; limits : float2)
  let packRangeLen = limits.y - limits.x
  return (float(radius) / 255.0) * packRangeLen + limits.x
