require ecs
require math
require DagorMath
require common_shooter.events_common_shooter
require enlisted.events_enlisted

[es(before=gun_human_recoil_es)]
def human_weap_move_recoil_mult_es(act : ParallelUpdateFrameDelayed; var human_weap__recoilMult : float&; human_weap__gunAngleSpeed : float2;
                                   human_weap__angleSpeedRecoilParams : float4)
  let len = length(human_weap__gunAngleSpeed)
  human_weap__recoilMult = cvt(len, human_weap__angleSpeedRecoilParams.x, human_weap__angleSpeedRecoilParams.y, human_weap__angleSpeedRecoilParams.z, human_weap__angleSpeedRecoilParams.w)
  //visual_log("{human_weap__recoilMult} : {len}", E3DCOLOR(0xffffffff), 0)
