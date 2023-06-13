module gun_reload_common shared
require daslib/enum_trait

enum GunReloadState
  NONE
  PREPARE
  BULLET_MULTIPLE
  BULLET_SINGLE
  POST

let GUN_RELOAD_STATE_NAMES = typeinfo(enum_names type<GunReloadState>)
