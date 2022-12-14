require ecs
require ecs.safe
require EnlistedDm
require game.utils.team
require game.events_game
require enlisted.events_enlisted
require enlisted.game.es.offender_cache_common
require EnlistedNet
require strings

def get_name(player_eid : EntityId; eid : EntityId; is_vehicle : bool)
  return get_string(player_eid, "name", is_vehicle ? get_string(eid, "item__name", "") : get_string(eid, "killLogName", ""))

def get_weapon_name_for_report(gun_props_id : int; shell_id : int)
  let gunTemplateName = get_gun_template_by_props_id(gun_props_id)
  let shellTemplateName = get_shell_template_by_shell_id(shell_id)
  let gunTemplate = getTemplateByName(gunTemplateName)
  if gunTemplate != null
    let name = getTemplateComponent(*gunTemplate, "item__name") ?? ""
    if !empty(name)
      return name
  let shellTemplate = getTemplateByName(shellTemplateName)
  if shellTemplate != null
    let name = getTemplateComponent(*shellTemplate, "item__name") ?? ""
    if !empty(name)
      return name
  return ""

def get_score_id(victim_plane : Tag const?; victim_tank : Tag const?)
  return (victim_plane != null ? "planeKills"
        : victim_tank != null ? "tankKills"
        : "kills")

[es(tag=server)]
def report_kill_es(evt : EventAnyEntityDied) // broadcast
  let victimEid = evt.victim
  let killerEid = evt.offender
  let damageType = evt.damageType
  let gunPropsId = evt.gunPropsId
  let shellId = evt.shellId
  let collNodeId = evt.collNodeId

  query(victimEid) <| $ [es] (team aka victim_team : int const?;
                              reportKill : bool = true;
                              vehicle aka victim_vehicle : Tag const?;
                              airplane aka victim_airplane : Tag const?;
                              isTank aka victim_isTank : Tag const?;
                              dm_parts__type : StringList const?;
                              transform aka victim_transform : float3x4 const?)
    if !reportKill
      return
    let isVictimVehicle = victim_vehicle != null
    let victimPlayerEid = get_offender_from_cache(victimEid).player
    var killerPos : float3
    var isKillerVehicle = false
    query(killerEid) <| $ [es] (vehicle aka killer_vehicle : Tag const?; transform aka killer_transform : float3x4 const?)
      killerPos = killer_transform != null ? (*killer_transform)[3] : killerPos
      isKillerVehicle = killer_vehicle != null
    let killerPlayerEid = get_offender_from_cache(killerEid).player
    let victimTeam = victim_team ?? get_int(victimPlayerEid, "team") ?? TEAM_UNASSIGNED
    let killerTeam = get_int(killerPlayerEid, "team") ?? TEAM_UNASSIGNED

    if victimTeam == TEAM_UNASSIGNED
      return

    let victimRank = get_int(victimPlayerEid, "player_info__military_rank") ?? 0
    let killerRank = get_int(killerPlayerEid, "player_info__military_rank") ?? 0
    let isPartIndexValid = dm_parts__type != null && uint(collNodeId) < uint(length(*dm_parts__type))
    let nodeType = isPartIndexValid ? string((*dm_parts__type)[collNodeId]) : "null"
    let isHeadshot = nodeType == "head" && damageType == int(DamageType DM_PROJECTILE)
    let gunName = get_weapon_name_for_report(gunPropsId, shellId)
    let killerName = get_name(killerPlayerEid, killerEid, isKillerVehicle)
    let victimName = get_name(victimPlayerEid, victimEid, isVictimVehicle)
    let scoreId = get_score_id(victim_airplane, victim_isTank)

    broadcast_net_event([[EventKillReport
      victim = victimEid,
      victimTeam = victimTeam,
      victimPlayer = victimPlayerEid,
      victimName = victimName,
      victimRank = victimRank,
      isVictimVehicle = isVictimVehicle,
      scoreId = scoreId,
      killer = killerEid,
      killerTeam = killerTeam,
      killerPlayer = killerPlayerEid,
      killerName = killerName,
      killerRank = killerRank,
      isKillerVehicle = isKillerVehicle,
      isHeadshot = isHeadshot,
      damageType = damageType,
      gunName = gunName
    ]])


    let victimPos = victim_transform != null ? (*victim_transform)[3] : float3()
    print("player {killerName} ({killerPos}) kills {victimName} ({victimPos}) by {damageType} with {gunName} hit to {nodeType}")
