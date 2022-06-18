module medic_common shared
require ecs.enum_macro

[export_enum]
enum MedicHealState
  MHS_NONE = 0
  MHS_NEED_HEAL = 1
  MHS_NEED_REVIVE = 2