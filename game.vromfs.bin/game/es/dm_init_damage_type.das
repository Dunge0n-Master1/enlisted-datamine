require ecs
require app
require game.es.events
require DagorSystem
require game.es.damage_type_common

[es(on_appear)]
def dm_init_damage_type_es(evt : Event;
                           dm__damageType : string;
                           var dm__damageTypeId : int&)
  dm__damageTypeId = DAMAGE_TYPE_NAMES |> find_index(dm__damageType)
  if dm__damageTypeId == -1
    logerr("Unknown dm__damageType name '{dm__damageType}'")