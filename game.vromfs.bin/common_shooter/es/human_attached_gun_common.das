module human_attached_gun_common shared
require ecs
require game.utils.team
require Gun
require common_shooter.events_common_shooter
require HumanPhys
require EnlistedActor
require EnlistedHuman
require EnlistedNet
require EffectorData


def reset_attached_gun(gun_eid : EntityId)
  query(gun_eid) <| $ [es] (dependsOnBuildingEid : EntityId = INVALID_ENTITY_ID;
                            var mounted_gun : MountedGun;
                            var gun : Gun;
                            var gun__owner : EntityId&;
                            var animchar__updatable : bool&;
                            var interactable : bool&;
                            var mounted_gun__active : bool&;
                            var team : int?)
    gun.appliedControls.shoot = false

    gun__owner = INVALID_ENTITY_ID

    animchar__updatable = false
    interactable = true

    mounted_gun__active = false
    mounted_gun.wishShoot = false
    mounted_gun.locked = false
    if team != null
      *team = TEAM_UNASSIGNED
    query(dependsOnBuildingEid) <| $ [es] (var team : int&)
      team = TEAM_UNASSIGNED


def detach_from_gun(eid : EntityId;
                    var human_attached_gun__attachedGunEid : EntityId&)
  reset_attached_gun(human_attached_gun__attachedGunEid)
  human_attached_gun__attachedGunEid = INVALID_ENTITY_ID
  query(eid) <| $ [es] (var human_net_phys : HumanActor;
                        var animchar_effectors__effectorsState : Object;
                        var human_attached_gun__lhandNodeIdx : int&;
                        var human_attached_gun__rhandNodeIdx : int&)

    var rightHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "r.hand")
    if rightHandEffector != null
      rightHandEffector.weight = 0.0
    var leftHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "l.hand")
    if leftHandEffector != null
      leftHandEffector.weight = 0.0

    human_attached_gun__lhandNodeIdx = -1
    human_attached_gun__rhandNodeIdx = -1

    if is_server()
      human_net_phys.phys.currentState.weapEquipState.progress = 0.0
      human_net_phys.phys.currentState.weapEquipState.curState = HUWeaponEquipState EES_EQUIPING
      sendEvent(eid, [[HumanDetachFromGunResponse]])

    sendEventImmediate(eid, [[HumanDetachFromGunComplete]])

    human_net_phys.phys.currentState |> human_phys_state_set_isAttached(false)