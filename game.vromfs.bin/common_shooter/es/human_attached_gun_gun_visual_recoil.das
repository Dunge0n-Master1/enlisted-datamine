require ecs
require EnlistedWeapon
require DaWeapons
require DagorMath

[es(tag=gameClient, REQUIRE=hero, after=mounted_gun_es, before=clear_gun_launch_events_es)]
def human_attached_gun_gun_visual_recoil_es(info : UpdateStageInfoAct;
                                            human_attached_gun__attachedGunEid : EntityId;
                                            var human_weap__gunOffsAngles : float3&)
  query(human_attached_gun__attachedGunEid) <| $ [es] (gun_launch_events : GunLaunchEvents;
                                                       gun__visualRecoilPower : float;
                                                       gun__visualRecoilYaw : float;
                                                       gun__visualRecoilPitch : float;
                                                       gun__visualRecoilCameraOffset : float)
    if length(gun_launch_events.launchEvents) <= 0
      return

    let noiseYaw   = perlin_noise1(gun__visualRecoilPower * info.curTime + 1500.f)
    let noisePitch = perlin_noise1(gun__visualRecoilPower * info.curTime + 3000.f)
    human_weap__gunOffsAngles.x = gun__visualRecoilYaw * noiseYaw
    human_weap__gunOffsAngles.y = gun__visualRecoilPitch * noisePitch

    query() <| $ [es] (camera__active : bool; var shooter_cam__recoilOffset : float&)
      if camera__active
        shooter_cam__recoilOffset += gun__visualRecoilCameraOffset