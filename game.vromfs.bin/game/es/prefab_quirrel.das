require ecs.ecs_quirrel
require daslib/quirrel_boost
require game.es.prefab_common

[quirrel_bind(module_name="das.prefab")]
def is_prefab_name_valid(name : string) : bool
  return prefab_common::is_prefab_name_valid(name)


[quirrel_bind(module_name="das.prefab")]
def make_prefab_path(name : string) : string
  return prefab_common::make_prefab_path(name)
