require ecs
require DngHuman
require DngPhysObj
require game.es.events
require GamePhys


[es]
def apply_local_human_gravity(evt : CmdPostPhysUpdate;
                              local_gravity : float;
                              var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.velocity += float3(0.0, (gravity() - local_gravity) * evt.dt, 0.0)

[es]
def apply_local_physobj_gravity(evt : CmdPostPhysUpdate;
                                local_gravity : float;
                                local_gravity_enabled : bool;
                                var phys_obj_net_phys : PhysObjActor)
  if local_gravity_enabled
    let velDiff = float3(0.0, (gravity() - local_gravity) * evt.dt * phys_obj_net_phys.phys.gravityMult, 0.0)
    phys_obj_net_phys.phys.currentState.velocity += velDiff

[es(tag=server, on_appear)]
def set_default_gravity(evt : Event;
                        var local_gravity : float&)
  local_gravity = gravity()

[es(tag=server, on_appear)]
def enable_local_gravity(evt : Event;
                         var local_gravity_enabled : bool&)
  local_gravity_enabled = find_query() <| $ [es(REQUIRE=enableGravityZones)] () => true