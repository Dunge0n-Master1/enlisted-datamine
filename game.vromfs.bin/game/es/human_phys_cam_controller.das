require ecs
require DngHuman
require HumanPhys
require math.base

[es(no_order, REQUIRE_NOT=beh_tree)]
def human_phys_cam_controller(info : UpdateStageInfoAct; bindedCamera : EntityId; human_net_phys : HumanActor; isAlive, isDowned, human_weap__blockAiming : bool)
  query(bindedCamera) <| $ [es] (var zoom : float&; var shooter_cam__alternative_settings : bool&)
    let wishZoomValue = !human_weap__blockAiming && is_control_bit_set(human_net_phys.phys.producedCT, (HumanPhysControlType HCT_AIM)) ? 1.0 : 0.0
    zoom = move_to_scalar(zoom, wishZoomValue, info.dt, human_net_phys.phys.aimSpeed)
    shooter_cam__alternative_settings = !isAlive || isDowned
