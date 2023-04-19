require ecs
require app
require game.es.events
require game.es.door_operations_common
require DagorSystem


[es]
def door_operations(evt : CmdUse; eid : EntityId; pair_door__eid : EntityId)
  cmd_use_door(eid, evt.requesterEid, pair_door__eid, true)

[es(tag=netClient)]
def door_client_operations(evt : HumanUseObjectRequest; eid : EntityId)
  query(evt.objectEid) <| $ [es] (pair_door__eid : EntityId)
    cmd_use_door(evt.objectEid, eid, pair_door__eid, false)

[es(tag=netClient, no_order)]
def door_client_prediction(info : UpdateStageInfoAct; eid : EntityId; door_client_prediction__doorEid : EntityId;
                           door_client_prediction__atTime, door_client_prediction__timeout : float)
  if info.curTime >= door_client_prediction__atTime + door_client_prediction__timeout
    query(door_client_prediction__doorEid) <| $ [es] (var rendinst_axis_rotation__targetAngle : float&; door_operations__serverTargetAngle : float)
      rendinst_axis_rotation__targetAngle = door_operations__serverTargetAngle
    destroyEntity(eid)

[es(track=door_operations__serverTargetAngle)]
def door_operations_apply_server(evt : Event; var rendinst_axis_rotation__targetAngle : float&; door_operations__serverTargetAngle : float)
  rendinst_axis_rotation__targetAngle = door_operations__serverTargetAngle

[es(tag=server, on_appear)]
def door_operations_verify_server(evt : Event;
                                  rendinst_axis_rotation__targetAngle : float;
                                  var door_operations__serverTargetAngle : float&;
                                  eid : EntityId)
  if door_operations__serverTargetAngle == rendinst_axis_rotation__targetAngle
    return
  logerr("{getEntityTemplateName(eid)} door angle uninited in blk {door_operations__serverTargetAngle} != {rendinst_axis_rotation__targetAngle}")
  // The line below will trigger serverTargetAngle replication to the client. This can be easily avoided by fixing it in the door template in blk
  door_operations__serverTargetAngle = rendinst_axis_rotation__targetAngle

