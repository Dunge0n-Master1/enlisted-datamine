require ecs
require DngNet
require game.events_game
require Dacoll
require DngCamera
require enlisted.events_enlisted
require math.base
require game.es.battle_area_common


[es(tag=gameClient)]
def check_troopers_spawn_point(evt : CmdPickParatroopersPoint;
                               eid : EntityId;
                               team : int;
                               respawner__paratroopersPointPickHeightMult : float;
                               respawner__paratroopersChooserOn : bool;
                               var paratroopersIconEid : EntityId&)
  if !respawner__paratroopersChooserOn
    return
  var worldPoint : float3
  var worldDir : float3
  let point = float2(evt.coordX, evt.coordY)
  screen_to_world(point, worldPoint, worldDir)
  worldDir = normalize(worldDir)
  var norm : float3
  var rayDist = worldPoint.y * respawner__paratroopersPointPickHeightMult
  if traceray_normalized(worldPoint, worldDir, rayDist, norm, ETF_LMESH)
    let respawnPoint = worldPoint + worldDir * rayDist
    var tm = IDENT_TM
    tm[3] = respawnPoint
    let hasAreas = (find_query() <| $ [es(REQUIRE=battleAreaPoints)] () => true)
    if is_tm_outside_battle_area(tm, team) && hasAreas
      return
    send_net_event(eid, [[CmdParatroopersSpawnConfirm spawnPos=respawnPoint]])
    paratroopersIconEid = createEntity("paratroopers_respawn_point_selector") <| $(var init : ComponentsInitializer)
      set(init, "respawn_icon__active", true)
      set(init, "transform", tm)
      set(init, "respawn_icon__position", tm[3])
      set(init, "selectedGroup", 0)
      set(init, "respawnIconType", "paratroopers")
      set(init, "team", team)
    query() <| $ [es(REQUIRE=paratroopersIcon)] (eid aka icons_eid : EntityId)
      if paratroopersIconEid != icons_eid
        destroyEntity(icons_eid)

[es(tag=gameClient, REQUIRE=respawner__paratroopersSquad)]
def delete_paratroopers_icon_es(evt : CmdParatroopersPointDeleted)
  query() <| $ [es(REQUIRE=paratroopersIcon)] (eid : EntityId)
    destroyEntity(eid)
