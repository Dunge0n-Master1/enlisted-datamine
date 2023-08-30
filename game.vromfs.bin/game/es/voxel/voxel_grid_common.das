module voxel_grid_common shared
require ecs
require DagorMath

def get_voxel_index(pos : int3; resolution : int)
  return pos.x + (pos.y + pos.z * resolution) * resolution

def get_voxel_index(tm : float3x4; pos : float3; resolution : int; side : float)
  let localPos = floori(((pos - tm[3]) + float3(float(resolution) * side * 0.5)) * safeinv(side))
  if localPos.x < 0 || localPos.x >= resolution || localPos.y < 0 || localPos.y >= resolution || localPos.z < 0 || localPos.z >= resolution
    return -1
  return get_voxel_index(localPos, resolution)

def get_voxel_pos(index : int; resolution : int)
  return int3(index % resolution,
              (index / resolution) % resolution,
              (index / resolution) / resolution)

def get_voxel_pos(tm : float3x4; index : int; resolution : int; side : float)
  let voxel = get_voxel_pos(index, resolution)
  let pos = float3(voxel) * side - float3(float(resolution) * side * 0.5)
  return tm[3] + pos

def get_voxel_box(tm : float3x4; index : int; dimension : int; side : float)
  let pos = get_voxel_pos(tm, index, dimension, side)
  let side3 = float3(side)
  return BBox3(pos, pos + side3)
