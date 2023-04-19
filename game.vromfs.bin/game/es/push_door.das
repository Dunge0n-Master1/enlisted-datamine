require ecs
require DngNet
require game.es.events
require HumanPhys
require DngHuman
require RendInst
require DagorMath
require CollRes
require enlisted.events_enlisted


[es(tag=gameClient, after=hero_human_use_door_object_es, REQUIRE=hero)]
def push_door_es(info : ParallelUpdateFrameDelayed;
                 eid : EntityId;
                 isAlive : bool;
                 human_use_object__selectedObject : EntityId;
                 human_net_phys : HumanActor;
                 collres : CollisionResource;
                 transform : float3x4;
                 human_push_door__minAngleDot : float = 0.525;
                 human_push_door__extrapolatePosTime : float = 0.2)
  let isSprinting = (int(human_net_phys.phys.currentState.states) & int(StateFlag ST_SPRINT)) != 0
  if !isAlive || !isSprinting
    return

  let humanEid = eid
  let humanBox = BBox3(collres.vFullBBox)
  var humanTm := transform

  ecs::query(human_use_object__selectedObject) <| $ [es(REQUIRE=isDoor)] (eid : EntityId;
                                                                          rendinst_axis_rotation__targetAngle : float;
                                                                          door_operations__openedAngle : float;
                                                                          door_operations__closedAngle : float;
                                                                          door_operations__omniRotate : bool = false;
                                                                          ri_extra : RiExtraComponent;
                                                                          transform : float3x4)
    let isDoorClosed = rendinst_axis_rotation__targetAngle == door_operations__closedAngle
    if !isDoorClosed
      return
    let doorDir = transform[2]
    let openerDir = humanTm[0]
    let angleDot = dot(doorDir, openerDir)
    if abs(angleDot) < human_push_door__minAngleDot
      return
    if !door_operations__omniRotate && angleDot * (door_operations__openedAngle - door_operations__closedAngle) > 0.0
      return
    let riType = handle_to_ri_type(ri_extra.handle)
    let doorCollres = get_ri_gen_extra_collres(int(riType))
    if doorCollres == null
      return

    humanTm[3] += human_net_phys.phys.currentState.velocity * max(info.dt, human_push_door__extrapolatePosTime)
    let doorBox = BBox3(doorCollres.vFullBBox)
    if check_bbox3_intersection(humanBox, humanTm, doorBox, transform)
      sendEvent(humanEid, [[HumanUseObjectRequest objectEid=eid]])
