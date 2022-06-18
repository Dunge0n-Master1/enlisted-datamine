require ecs
require app
require game.es.events
require EnlistedDm
require DagorSystem
require daslib/enum_trait

let DAMAGE_TYPES_COUNT = typeinfo(enum_length type<DamageType>)
let DAMAGE_TYPE_NAMES = [[string[DAMAGE_TYPES_COUNT]
  "projectile";
  "melee";
  "explosion";
  "zone";
  "collision";
  "hold_breath";
  "fire";
  "disconnected";
  "backstab";
  "barbwire";
  "unknown"]]

[es(on_appear)]
def dm_init_damage_type_es(evt : Event;
                           dm__damageType : string;
                           var dm__damageTypeId : int&)
  dm__damageTypeId = DAMAGE_TYPE_NAMES |> find_index(dm__damageType)
  if dm__damageTypeId == -1
    logerr("Unknown dm__damageType name '{dm__damageType}'")