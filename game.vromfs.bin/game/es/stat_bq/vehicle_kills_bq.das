require ecs
require statBQ
require jsonwriter
require game.events_game
require game.es.stat_bq_common
require EnlistedDm
require enlisted.game.es.offender_cache_common

def get_vehicle_type(eid : EntityId; is_empty : bool)
  if has(eid, "isTank")
    return is_empty ? "empty_tank" : "tank"
  elif has(eid, "airplane")
    return is_empty ? "empty_airplane" : "airplane"
  return ""

[es(tag=server, REQUIRE=vehicle)]
def send_to_bq_vehicle_destroyed(evt : EventEntityDied;
                                 eid : EntityId;
                                 transform : float3x4;
                                 ownedBySquad : EntityId;
                                 killLogName : string = "";
                                 vehicle__isDestroyedWithoutCrew : bool = false)
  let gunPropsId = evt.gunPropsId
  let offenderOwnerPlayer = get_offender_from_cache(evt.offender).player

  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  let victimType = get_vehicle_type(eid, vehicle__isDestroyedWithoutCrew)
  if victimType == ""
    return
  var victimOwnerPlayer = INVALID_ENTITY_ID
  query(ownedBySquad) <| $ [es] (squad__ownerPlayer : EntityId)
    victimOwnerPlayer = squad__ownerPlayer
  if !victimOwnerPlayer
    return

  var damageTypeEnum = DamageType DM_PROJECTILE
  for damageEnum in each_enum(DamageType DM_PROJECTILE)
    if evt.damageType == int(damageEnum)
      damageTypeEnum = damageEnum

  send_event_bq_with_header("vehicle_kill") <| $(var jw : JsonWriter)
    jw_key_value(jw, "victim_pos", "{transform[3]}")

    add_entity_type(jw, evt.offender, "offender")
    query(evt.offender) <| $ [es] (soldier__sClass : string; transform : float3x4)
      jw_key_value(jw, "soldier_class", soldier__sClass)
      jw_key_value(jw, "offender_pos", "{transform[3]}")

    jw_key_value(jw, "weapon_type", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item__weapType") : "")
    jw_key_value(jw, "weapon_template", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item__weapTemplate") : "")
    jw_key_value(jw, "damage_type", "{damageTypeEnum}")

    jw_key_value(jw, "victim_type", victimType)
    jw_key_value(jw, "victim_class", killLogName)

    query(victimOwnerPlayer) <| $ [es] (userid : uint64)
      add_user_id(jw, userid, "victim_user_id")
    query(offenderOwnerPlayer) <| $ [es] (userid : uint64)
      add_user_id(jw, userid)
