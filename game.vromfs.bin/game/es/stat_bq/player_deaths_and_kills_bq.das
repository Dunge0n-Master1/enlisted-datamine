require ecs
require statBQ
require jsonwriter
require game.events_game
require game.es.stat_bq_common
require DngDm
require matching

def add_type_and_pos(var jw; eid; prefix)
  ecs::query(eid) <| $ [es] (transform : float3x4)
    jw_key_value(jw, "{prefix}_pos", "{transform[3]}")
    add_entity_type(jw, eid, prefix)

def get_event_type(evt; eid)
  if eid == evt.offenderPlayer
    return "player_kill"
  elif eid == evt.victimPlayer
    return "player_death"
  return ""

[es(tag=server, REQUIRE=player)]
def player_kills_and_deaths_es(evt : EventAnyEntityDied; eid : ecs::EntityId; userid : uint64)
  let eventType = get_event_type(evt, eid)
  if eventType == "" || userid == INVALID_USER_ID
    return

  let victimUserId = get_uint64(evt.victimPlayer, "userid") ?? INVALID_USER_ID
  let offenderUserId = get_uint64(evt.offenderPlayer, "userid") ?? INVALID_USER_ID

  if victimUserId == INVALID_USER_ID || offenderUserId == INVALID_USER_ID
    return

  let gunPropsId = evt.gunPropsId
  var damageTypeEnum = DamageType DM_PROJECTILE
  for damageEnum in each_enum(DamageType DM_PROJECTILE)
    if evt.damageType == int(damageEnum)
      damageTypeEnum = damageEnum
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header(eventType) <| $(var jw : JsonWriter)
    add_user_id(jw, offenderUserId)
    jw_key_value(jw, "weapon_type", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item__weapType") : "")
    jw_key_value(jw, "weapon_template", gunPropsId >= 0 ? get_gun_component_by_props_id(gunPropsId, "item__weapTemplate") : "")
    jw_key_value(jw, "damage_type", "{damageTypeEnum}")
    add_user_id(jw, victimUserId, "victim_user_id")

    add_type_and_pos(jw, evt.offender, "offender")
    add_type_and_pos(jw, evt.victim, "victim")
