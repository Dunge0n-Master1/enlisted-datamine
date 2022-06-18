require ecs
require game.es.events
require EnlistedPhysObj
require HumanPhys
require EnlistedHuman

[es(tag=server)]
def first_contact_dispatcher(evt : CmdPostPhysUpdate;
                             eid : EntityId;
                             phys_obj_net_phys : PhysObjActor;
                             var first_contact_listener__hadContact : bool&)
  if first_contact_listener__hadContact
    return
  if phys_obj_net_phys.phys.currentState.hadContact
    first_contact_listener__hadContact = true
    sendEvent(eid, [[EventFirstContact velocity=phys_obj_net_phys.phys.currentState.velocity]]) // note: recreate entity on first contact to reduce es usage

[es]
def human_first_contact_dispatcher(evt : CmdPostPhysUpdate;
                                   eid : EntityId;
                                   human_net_phys : HumanActor;
                                   var first_contact_listener__hadContact : bool&)
  if first_contact_listener__hadContact
    return
  let isSpdDiffExists = length_sq(human_net_phys.phys.currentState.spdSummaryDiff) > FLT_EPSILON
  let notInAir = (uint(human_net_phys.phys.currentState.isInAirHistory) & 1u) == 0u
  if isSpdDiffExists || notInAir || human_phys_state_get_is_swimming(human_net_phys.phys.currentState)
    first_contact_listener__hadContact = true
    sendEvent(eid, [[EventFirstContact velocity=human_net_phys.phys.currentState.velocity]])
