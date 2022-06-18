require ecs
require app
require math
require GamePhys
require EnlistedPhysObj
require game.es.events

[es(tag=server, REQUIRE=shell, REQUIRE=shell__orientationByVelocity)]
def shell_orientation_by_velocity(evt : CmdPostPhysUpdate; var phys_obj_net_phys : PhysObjActor)
  assume orient = phys_obj_net_phys.phys.currentState.location.O
  assume vel = phys_obj_net_phys.phys.currentState.velocity
  let dir = float3(vel.x, -vel.y, -vel.z)
  orient_setYP0(orient, dir)