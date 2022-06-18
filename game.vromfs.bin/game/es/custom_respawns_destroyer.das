require enlisted.game.es.fortifications_build_common
require math.base
require ecs

def destroy_respawn_by_distance_restrictions()
  query() <| $ [es] (eid : EntityId;
                     disableCapturePointsRadius : float;
                     disableMissionRespawnPointsRadius : float;
                     transform : float3x4;
                     team : int;
                     dependsOnBuildingEid = INVALID_ENTITY_ID)
    let respawnPos = transform[3]
    let isCapZonesOrRespawnsNear = (!is_distance_to_capture_points_valid(respawnPos, disableCapturePointsRadius) ||
                                    is_human_respawn_selector_in_radius_for_team(respawnPos, disableMissionRespawnPointsRadius, team))
    if isCapZonesOrRespawnsNear
      destroyEntity(dependsOnBuildingEid)
      destroyEntity(eid)

[es(on_appear, track=active, tag=server, REQUIRE=capzone)]
def respawn_disabler_capture_zone_check(evt : Event; active : bool)
  if active
    destroy_respawn_by_distance_restrictions()

[es(on_appear, track=(respawn_icon__active, respawn_icon__position), tag=server, REQUIRE=respawn_icon__position)]
def respawn_disabler_respawn_base_check(evt : Event; respawn_icon__active : bool)
  if respawn_icon__active
    destroy_respawn_by_distance_restrictions()