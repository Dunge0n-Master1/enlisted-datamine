module squad_order_common shared
require ecs.enum_macro

[export_enum]
enum SquadOrder
  ESO_FOLLOW_ME
  ESO_DEFEND_POINT
  ESO_USE_VEHICLE

[export_enum]
enum SquadMateOrder
  ESMO_NO_ORDER
  ESMO_BRING_AMMO
  ESMO_HEAL
  ESMO_ARTILLERY
  ESMO_BUILD
  ESMO_ATTACK_TARGET
  ESMO_DEFEND_POINT
  ESMO_USE_VEHICLE
  ESMO_DEFUSE_BOMB
  ESMO_PLANT_BOMB

[export_enum]
enum SquadFormationSpread
  ESFN_CLOSEST
  ESFN_STANDARD
  ESFN_WIDE
