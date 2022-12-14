module gun_sound_common shared
require ecs
require DagorMath


def get_gun_sound_pos(animchar_bbox : bbox3f)
  return (animchar_bbox.bmin.xyz + animchar_bbox.bmax.xyz) * 0.5


def is_watched_gun_sound(gun__owner : EntityId) : bool
  var isWatched = false
  query(gun__owner) <| $ [es] (is_watched_sound : bool; human_anim__vehicleSelected = INVALID_ENTITY_ID)
    isWatched = is_watched_sound
    query(human_anim__vehicleSelected) <| $ [es] (is_watched_sound : bool)
      isWatched ||= is_watched_sound
  return isWatched
