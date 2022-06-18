require ecs
require app
require game.es.events
require EnlistedPhysObj
require PhysObj

[es]
def phys_obj_thrust_es(evt : CmdPostPhysUpdate;
                       var phys_obj_net_phys : PhysObjActor&;
                       phys_obj_thrust__direction : float3&;
                       phys_obj_thrust__offset : float3&;
                       phys_obj_thrust__thrust : float;
                       phys_obj_thrust__endTime : float = 0.f)
  if phys_obj_thrust__endTime == 0.f || phys_obj_thrust__endTime > get_sync_time()
    let direction = phys_obj_thrust__direction * phys_obj_thrust__thrust
    phys_obj_addForce(phys_obj_net_phys.phys, phys_obj_thrust__offset, direction)

[es(on_appear)]
def phys_obj_thrust_created_es(evt : Event;
                               phys_obj_thrust__duration : float;
                               var phys_obj_thrust__endTime : float&)
  phys_obj_thrust__endTime = get_sync_time() + phys_obj_thrust__duration