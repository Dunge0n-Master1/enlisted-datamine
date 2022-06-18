module context_command_common shared
require ecs.enum_macro

[export_enum]
enum ContextCommand
  ECC_DISABLED // no squad mates for example
  ECC_NONE
  ECC_CANCEL
  ECC_REVIVE
  ECC_BRING_AMMO
  ECC_DEFEND_POINT
  ECC_ATTACK_TARGET
  ECC_BUILD
  ECC_PLANT_BOMB
  ECC_DEFUSE_BOMB
