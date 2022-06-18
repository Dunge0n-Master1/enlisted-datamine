require ecs
require ecs.common
require soundEvent
require soundProps
require game.es.sound.sound_events
require sound_utils.modules.sound_player_common
require common_shooter.events_common_shooter
require EnlistedDm
require DagorSystem
require strings

def is_armored(parts_armor : FloatList const?; node_id : int; sound_tags : Object)
  if parts_armor != null
    return node_id >= 0 && node_id < length(*parts_armor) && (*parts_armor)[node_id] != 0.
  return read_sound_tag("armored", sound_tags)


def damage_type_to_sound_path(damage_type : DamageType)
  if damage_type == DamageType DM_PROJECTILE
    return "hit_dmgProjectile"
  if damage_type == DamageType DM_MELEE || damage_type == DamageType DM_BACKSTAB
    return "hit_dmgMelee"
  if damage_type == DamageType DM_EXPLOSION
    return "hit_dmgExplosion"
  if damage_type == DamageType DM_HOLD_BREATH
    return "hit_dmgAsphyxiation"
  return ""


[es(tag=sound, REQUIRE=humanSound)]
def human_hit_sound(evt : EventOnEntityHit; eid : EntityId;
                    [[shared_comp]] human_hit_sound__paths : Object;
                    is_watched_sound : bool;
                    sound_tags : Object;
                    dm_parts__type : StringList const?;
                    dm_parts__partsArmor : FloatList const?;
                    isAlive : bool)
  if eid != evt.victim
    return

  var name = ""
  var path = ""

  let actionSoundProps = action_sound_try_get_props(int(evt.damageDesc.actionPropsId))
  if actionSoundProps != null
    name = (*actionSoundProps).humanHitSoundName
    path = (*actionSoundProps).humanHitSoundPath

  if empty(path)
    path = damage_type_to_sound_path(evt.damageDesc.damageType)

  var pathObj = path != "" ? get_ecs_object(human_hit_sound__paths, path) : null
  if pathObj == null
    return

  let collNodeId = int(evt.damageDesc.collNodeId)
  if dm_parts__type != null && uint(collNodeId) < uint(length(*dm_parts__type))
    let part = get_desc(*pathObj, "part_{(*dm_parts__type)[collNodeId]}")
    pathObj = part != null ? part : pathObj

  if !get_option_path(pathObj, sound_tags, is_watched_sound, path)
    return

  if empty(name)
    name = get_string(*pathObj, "name", "")

  var handle = play_name_path_impl(name, path, evt.damageDesc.hitPos, false/*is_abandon*/)

  //logerr("{path} / {name} handle={handle}")

  if evt.damageDesc.damageType == DamageType DM_PROJECTILE || evt.damageDesc.damageType == DamageType DM_MELEE || evt.damageDesc.damageType == DamageType DM_BACKSTAB
    let isArmored = isAlive && is_armored(dm_parts__partsArmor, collNodeId, sound_tags)
    set_var_optional(handle, "armored", isArmored ? 1. : 0.)

  abandon(handle)
