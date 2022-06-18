module sound_desc_common shared
require ecs
require ecs.common
require soundHash

def find_desc_idx(desc_id : string; descs : Array) : int
  var idx : int = 0
  for it in descs
    if get_ecs_object(it) |> get_string("id", "") == desc_id
      return idx
    ++idx
  return -1

def find_desc_idx_by_hash(desc_id_hash : uint; descs : Array) : int
  var idx : int = 0
  for it in descs
    if sound_hash(get_ecs_object(it) |> get_string("id", "")) == desc_id_hash
      return idx
    ++idx
  return -1

def get_desc(idx : int; descs : Array)
  return idx >= 0 && idx < length(descs) ? get_ecs_object(descs[idx]) : null

def find_desc_by_hash(hash : uint; descs : Object)
  for it in descs
    if sound_hash(it.key) == hash
      return get_ecs_object(it.value)
  return null
