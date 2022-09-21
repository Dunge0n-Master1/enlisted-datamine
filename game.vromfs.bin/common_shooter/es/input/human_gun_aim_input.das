require ecs
require game.es.input.input_events
require game.es.events
require game.events_game
require DagorMathUtils
require Gun
require EnlistedHuman
require EnlistedActor
require HumanPhys

[es]
def human_input_attached_gun_es(evt : UpdateStageUpdateInput;
                                human_attached_gun__attachedGunEid : ecs::EntityId;
                                human_input__aimAngleOffset : float2&;
                                var human_net_phys : HumanActor&;
                                var human_input__aimAngle : float2&)
  if human_attached_gun__attachedGunEid != ecs::INVALID_ENTITY_ID
    let roleFlags = RoleFlags URF_AUTHORITY | RoleFlags URF_LOCAL_CONTROL
    if (uint(human_net_phys.role) & uint(roleFlags)) != 0u
      query(human_attached_gun__attachedGunEid) <| $ [es] (mounted_gun : MountedGun)
        let angle = human_input__aimAngle + human_input__aimAngleOffset
        let dir = angles_to_dir(angle)
        let initialDir = mounted_gun.initialDir
        let aimDir = mounted_gun |> mounted_gun_clampAimDir(dir, initialDir)
        let aimAngle = dir_to_angles(aimDir)
        human_input__aimAngle = aimAngle - human_input__aimAngleOffset
        human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(aimDir)

[es(tag=input)]
def human_input_action_triggered_es(evt : EventDaInputActionTriggered;
                                    human_input__sightNext : int;
                                    human_input__sightPrev : int;
                                    human_weap__gunEids : EidList;
                                    human_weap__currentGunSlot : int;
                                    input__enabled : bool)
  if !input__enabled
    return

  if human_weap__currentGunSlot >= 0
    let action = evt.action
    let weapEid = human_weap__gunEids[human_weap__currentGunSlot]

    if action == uint16(human_input__sightNext)
      sendEvent(weapEid, [[CmdWeapSwitchSight toNext=true]])
    elif action == uint16(human_input__sightPrev)
      sendEvent(weapEid, [[CmdWeapSwitchSight toNext=false]])
