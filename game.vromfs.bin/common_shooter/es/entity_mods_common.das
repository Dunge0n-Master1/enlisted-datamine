module entity_mods_common shared
require ecs
require ecs.safe

def is_mod_allowed(allowed : StringList?; mod : string)
  if allowed == null || length(*allowed) == 0
    return true
  for modName in *allowed
    if string(modName) == mod
      return true
  return false

def calc_change_mult_attr(map : Object; allowed : StringList?)
  var mult = 1.0
  for mod in map
    if is_mod_allowed(allowed, mod.key)
      mult *= get_float(mod.value) ?? 1.0
  return mult

def calc_diminishing_change_mult_attr(map : Object; allowed : StringList?)
  var mods : array<float>
  for mod in map
    if is_mod_allowed(allowed, mod.key)
      mods |> push(get_float(mod.value) ?? 1.0)
  if length(mods) == 0
    return 1.0
  sort(mods) <| $(lhs, rhs : float)
    return lhs > rhs
  var mult = 1.0
  for i in iter_range(mods)
    mult *= pow(mods[i], 1.0 / float(i + 1))
  return mult

def calc_change_add_attr(map : Object; allowed : StringList?)
  var add = 0f
  for mod in map
    if is_mod_allowed(allowed, mod.key)
      add += mod.value ?? 0.
  return add
