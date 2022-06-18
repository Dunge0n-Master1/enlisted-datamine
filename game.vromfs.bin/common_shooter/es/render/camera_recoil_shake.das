require ecs
require math.base

[es(tag=gameClient, after=shooter_cam_apply_offset_multiplier_es, before=after_camera_sync)]
def shooter_cam_apply_recoil_offset_es(info : UpdateStageInfoAct;
                                       camera__active : bool;
                                       shooter_cam__recoilOffsetTau : float;
                                       var shooter_cam__offset : float3&;
                                       var shooter_cam__recoilOffset : float&)
  if camera__active
    shooter_cam__recoilOffset = approach(shooter_cam__recoilOffset, 0., info.dt, shooter_cam__recoilOffsetTau)
    shooter_cam__offset.z += shooter_cam__recoilOffset