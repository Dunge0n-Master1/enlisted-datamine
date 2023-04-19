require ecs
require statBQ
require jsonwriter
require game.events_game
require game.es.stat_bq_common
require DngDm
require enlisted.game.es.offender_cache_common

[es(tag=server, REQUIRE=human)]
def send_to_bq_soldier_kills(evt : EventEntityDied; eid : EntityId; soldier__sClass : string; transform : float3x4; squad_member__playerEid : EntityId)
  let gunPropsId = evt.gunPropsId
  let victimOwnerPlayer = squad_member__playerEid
  let offenderOwnerPlayer = get_offender_from_cache(evt.offender).player

  var damageTypeEnum = DamageType DM_PROJECTILE
  for damageEnum in each_enum(DamageType DM_PROJECTILE)
    if evt.damageType == int(damageEnum)
      damageTypeEnum = damageEnum
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("soldier_kill") <| $(var jw : JsonWriter)
    jw_key_value(jw, "victim_class", soldier__sClass)
    jw_key_value(jw, "victim_pos", "{transform[3]}")

    query(evt.offender) <| $ [es] (soldier__sClass : string; transform : float3x4)
      jw_key_value(jw, "soldier_class", soldier__sClass)
      jw_key_value(jw, "offender_pos", "{transform[3]}")

    jw_key_value(jw, "weapon_type", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item__weapType") : "")
    jw_key_value(jw, "weapon_template", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item__weapTemplate") : "")
    jw_key_value(jw, "damage_type", "{damageTypeEnum}")

    add_entity_type(jw, evt.offender, "offender")
    add_entity_type(jw, eid, "victim")

    query(victimOwnerPlayer) <| $ [es] (userid : uint64)
      add_user_id(jw, userid, "victim_user_id")
    query(offenderOwnerPlayer) <| $ [es] (userid : uint64)
      add_user_id(jw, userid)
