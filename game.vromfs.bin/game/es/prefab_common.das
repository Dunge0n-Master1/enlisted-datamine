module prefab_common shared
require strings

def is_prefab_name_valid(name : string) : bool
  var len = 0
  for ch in name
    if !is_alpha(ch) && !is_number(ch) && ch != '_'
      return false
    ++len
  return len > 0

def make_prefab_path(name : string) : string
  return "userPrefabs/{name}.blk"
