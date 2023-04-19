module damage_type_common shared public
require ecs
require DngDm
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
  "gas";
  "unknown"]]
