require ecs
require ecs.common
require statBQ
require jsonwriter
require DagorSystem
require game.es.events
require game.es.stat_bq_common
require enlisted.game.utils.armies_common
require matching


def get_squad_object(squad__id; squads) : Object const?
  if squad__id < 0 || squad__id >= length(squads)
    logerr("[BQ]: Squad with id {squad__id} does not exist.")
    return null
  return get_ecs_object(squads[squad__id])

def get_squad(squad__id; team_army; armies) : Object const?
  let squads = get_army_squads(armies, team_army)
  return squads != null ? get_squad_object(squad__id, *squads) : null

def get_squad_name(squad__id; team_army; armies) : string
  let squad = get_squad(squad__id, team_army, armies)
  return squad != null ? get_string(*squad, "squadId", "") : ""

def get_squad_vehicle(squad__id; team_army; armies) : string
  let squad = get_squad(squad__id, team_army, armies)
  return squad != null ? get_squad_vehicle(squad) : ""

[es(tag=server, on_appear)]
def squad_spawn_es(evt : Event; squad__id : int; squad__ownerPlayer : ecs::EntityId)
  ecs::query(squad__ownerPlayer) <| $ [es] (userid : uint64; team : int; army : string; armies : ecs::Object)
    if userid == INVALID_USER_ID
      return
    // CHANGES TO THIS SCHEME SHALL BE REFLECTED IN BQ TABLE (ask devops for this if you don't know what it mean)
    send_event_bq_with_header("squad_spawn") <| $(var jw : JsonWriter)
      add_user_id(jw, userid)
      jw_key_value(jw, "team", team)
      jw_key_value(jw, "army", army)
      jw_key_value(jw, "squad_id", get_squad_name(squad__id, army, armies))
      jw_key_value(jw, "squad_vehicle", get_squad_vehicle(squad__id, army, armies))
