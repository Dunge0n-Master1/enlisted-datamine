require ecs
require DngHuman
require game.es.events


def apply_limit(var old_limit : float2&; new_limit : float2)
  old_limit.x = max(old_limit.x, new_limit.x)
  old_limit.y = min(old_limit.y, new_limit.y)


def apply_clamp(var old_clamp : float2&; new_clamp : float2)
  old_clamp.x = min(old_clamp.x, new_clamp.x)
  old_clamp.y = min(old_clamp.y, new_clamp.y)


[es(tag=input, before=human_input_es)]
def reset_look_angle_limit(evt : UpdateStageUpdateInput;
                           human_input__defaultVertLookAngleLimit : float2;
                           var human_input__currentVertLookAngleLimit : float2&;
                           var human_input__prevVertLookAngleLimit : float2&)
  human_input__prevVertLookAngleLimit = human_input__currentVertLookAngleLimit
  human_input__currentVertLookAngleLimit = human_input__defaultVertLookAngleLimit


[es(tag=input, before=human_input_es)]
def reset_look_dir_clamp(evt : UpdateStageUpdateInput;
                         human_input__defaultLookDirClamp : float2;
                         var human_input__currentLookDirClamp : float2&;
                         var human_input__prevLookDirClamp : float2&)
  human_input__prevLookDirClamp = human_input__currentLookDirClamp
  human_input__currentLookDirClamp = human_input__defaultLookDirClamp


[es(tag=input, before=human_input_es, after=reset_look_angle_limit)]
def apply_ladder_look_angle_limit(evt : UpdateStageUpdateInput;
                                  human_net_phys : HumanActor;
                                  human_input__vertLookAngleLimitOnLadder : float2;
                                  var human_input__currentVertLookAngleLimit : float2&)
  if human_net_phys.phys.currentState.isAttachedToLadder
    human_input__currentVertLookAngleLimit |> apply_limit(human_input__vertLookAngleLimitOnLadder)


[es(tag=input, before=human_input_es, after=reset_look_angle_limit)]
def apply_freefall_look_angle_limit(evt : UpdateStageUpdateInput;
                                    human_freefall__isFreefall : bool;
                                    human_freefall__vertLookAngleLimit : float2;
                                    var human_input__currentVertLookAngleLimit : float2&)
  if human_freefall__isFreefall
    human_input__currentVertLookAngleLimit |> apply_limit(human_freefall__vertLookAngleLimit)


[es(tag=input, before=human_input_es, after=reset_look_dir_clamp)]
def apply_parachute_look_dir_clamp(evt : UpdateStageUpdateInput;
                                   human_parachute__isDeployed : bool;
                                   human_parachute__lookDirClamp : float2;
                                   var human_input__currentLookDirClamp : float2&)
  if human_parachute__isDeployed
    human_input__currentLookDirClamp |> apply_clamp(human_parachute__lookDirClamp)


[es(tag=input, before=human_input_es, after=reset_look_angle_limit)]
def apply_item_use_look_angle_limit(evt : UpdateStageUpdateInput;
                                    human_inventory__entityToUse : EntityId;
                                    human_inventory__entityUseEnd : float;
                                    var human_input__currentVertLookAngleLimit : float2&)
  if human_inventory__entityToUse != INVALID_ENTITY_ID && human_inventory__entityUseEnd > evt.curTime
    query(human_inventory__entityToUse) <| $ [es] (item__limitLookAnglesInUse : float2)
      human_input__currentVertLookAngleLimit |> apply_limit(item__limitLookAnglesInUse)

[es(tag=input, before=human_input_es, after=reset_look_angle_limit)]
def apply_binocular_look_angle_limit(evt : UpdateStageUpdateInput;
                                     human_binocular__mode : bool;
                                     human_binocular__vertLookAngleLimit : float2;
                                     var human_input__currentVertLookAngleLimit : float2&)
  if human_binocular__mode
    human_input__currentVertLookAngleLimit |> apply_limit(human_binocular__vertLookAngleLimit)

[es(tag=input, before=human_input_es, after=reset_look_angle_limit)]
def apply_hold_gun_mode_look_angle_limit(evt : UpdateStageUpdateInput;
                                         human_vehicle__isHoldingGunPassenger : bool;
                                         human_vehicle__occupiedSeatEid : EntityId;
                                         var human_input__currentVertLookAngleLimit : float2&)
  if human_vehicle__isHoldingGunPassenger
    query(human_vehicle__occupiedSeatEid) <| $ [es] (seat__holdingGunPassengerVertLookLimit : float2)
      human_input__currentVertLookAngleLimit |> apply_limit(seat__holdingGunPassengerVertLookLimit)
