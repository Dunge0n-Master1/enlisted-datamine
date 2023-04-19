require ecs
require DngNet
require game.es.input.input_events
require common_shooter.events_common_shooter


[es(tag=input, after=human_common_input_action_triggered_es)]
def open_parachute_manual(evt : EventDaInputActionTriggered;
                          eid : EntityId;
                          human_input__jump : int;
                          human_parachute__eid : EntityId;
                          human_parachute__canDeployManually : bool;
                          human_parachute__canDeploy : bool;
                          input__enabled : bool)
  if (human_parachute__eid == INVALID_ENTITY_ID || !input__enabled ||
      int(evt.action) != human_input__jump || !human_parachute__canDeployManually)
    return

  if human_parachute__canDeploy
    send_net_event(eid, [[HumanRequestParachuteOpen]])


[es(tag=input, on_appear, REQUIRE=parachuteDeployed)]
def human_parachute_input_disable_mouse_movement(evt : Event;
                                                 var human_input__forceLookMode : bool&;
                                                 var human_input__aimAngle : float2&;
                                                 var human_input__lookAngle : float2&)
  human_input__lookAngle = float2(human_input__lookAngle.x, human_input__aimAngle.y)
  human_input__aimAngle = float2(human_input__aimAngle.x, 0.0)
  human_input__forceLookMode = true

[es(tag=input, on_disappear, REQUIRE=parachuteDeployed)]
def human_parachute_input_enable_mouse_movement(evt : Event;
                                                var human_input__forceLookMode : bool&)
  human_input__forceLookMode = false