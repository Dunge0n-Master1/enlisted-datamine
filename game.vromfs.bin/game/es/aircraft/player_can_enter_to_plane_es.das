require ecs
require DngPlane

[es(after=plane_phys_es, tag=server, REQUIRE=(airplane, dm_state), REQUIRE_NOT=deadEntity, track=dm_state)]
def player_can_enter_to_plane_es(info : Event;
                                 plane_net_phys : PlaneActor;
                                 var vehicle__isPlayerCanEnter : bool&)
  vehicle__isPlayerCanEnter = !plane_net_phys.phys.isTakenMortalDamage && !plane_net_phys.phys.isAnyInoperable && plane_net_phys.phys.isCapableOfTaxi
