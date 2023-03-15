module game_object_sound_common shared

require soundHash
require math.base
require math


def place_game_object_sound(listener : float3; extent_maxRadiusSq : float4; shape : uint; tm : float3x4) : float3

  if distance_sq(listener.xyz, tm[3]) >= extent_maxRadiusSq.w
    return tm[3]

  var localListener = listener - tm[3]
  localListener = float3(dot(localListener, tm[0]), dot(localListener, tm[1]), dot(localListener, tm[2]))

  if shape == sound_hash("sphere")
    if length_sq(localListener) < square(extent_maxRadiusSq.x)
      return listener
    return tm * (normalize(localListener) * extent_maxRadiusSq.x)

  if shape == sound_hash("capsule")
    let pos = float3(0., clamp(localListener.y, -extent_maxRadiusSq.y, extent_maxRadiusSq.y), 0.)
    if distance_sq(pos, localListener) < square(extent_maxRadiusSq.x)
      return listener
    return tm * (pos + normalize(localListener - pos) * extent_maxRadiusSq.x)

  // box
  let pos = clamp(localListener, -extent_maxRadiusSq.xyz, extent_maxRadiusSq.xyz)
  if pos == localListener
    return listener // dist_sq(listener, pos) should be zero if pos is inside volume
  return tm * pos
