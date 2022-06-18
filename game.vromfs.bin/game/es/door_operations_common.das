module door_operations_common shared
require ecs
require app
require game.es.events


def toggle_door(door_eid : EntityId; opener_pos : float3; is_server : bool)
  query(door_eid) <| $ [es] (var door_operations__reqState : bool&;
                             var door_operations__curState : bool&;
                             var rendinst_axis_rotation__targetAngle : float&;
                             var door_operations__serverTargetAngle : float&;
                             var door_operations__lastUseTime : float&;
                             door_operations__openedAngle : float;
                             door_operations__closedAngle : float;
                             rendinst_axis_rotation__curAngle : float;
                             transform : float3x4;
                             door_operations__omniRotate : bool = false;
                             door_operations__useCooldown : float)
    let curTime = get_sync_time()
    if curTime - door_operations__lastUseTime < door_operations__useCooldown
      return
    door_operations__curState = door_operations__closedAngle == rendinst_axis_rotation__curAngle
    door_operations__reqState = !door_operations__reqState
    var targetAngle = rendinst_axis_rotation__targetAngle
    if door_operations__reqState
      if door_operations__omniRotate
        let doorPos = transform[3]
        let doorDir = transform[2]
        let dirSign = dot(doorDir, (doorPos - opener_pos)) > 0f ? 1f : -1f
        let angleSign = (door_operations__openedAngle - door_operations__closedAngle) > 0f ? 1f : -1f
        let sign = dirSign * angleSign
        targetAngle = door_operations__closedAngle + (door_operations__closedAngle - door_operations__openedAngle) * sign
      else
        targetAngle = door_operations__openedAngle
    else
      targetAngle = door_operations__closedAngle

    rendinst_axis_rotation__targetAngle = targetAngle
    door_operations__lastUseTime = curTime

    if is_server
      door_operations__serverTargetAngle = targetAngle // set server angle only on server so client can check against it
    else // not server
      let alreadyPredicting = find_query() <| $ [es] (door_client_prediction__doorEid : EntityId; var door_client_prediction__atTime : float&)
        if door_client_prediction__doorEid == door_eid
          door_client_prediction__atTime = curTime
          return true
        return false

      if !alreadyPredicting
        createEntity("door_client_prediction_tracker") <| $(init)
          init |> set("door_client_prediction__doorEid", door_eid)
          init |> set("door_client_prediction__atTime", curTime)


def cmd_use_door(door_eid, opener_eid, pair_door__eid : EntityId; is_server : bool)
  query(opener_eid) <| $ [es] (transform : float3x4)
    let openerPos = transform[3]
    toggle_door(door_eid, openerPos, is_server)
    toggle_door(pair_door__eid, openerPos, is_server)
