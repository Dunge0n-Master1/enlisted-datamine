require ecs
require DagorMath

[es(tag=gameClient, before=human_anim_disable_nodes_client_update_es)]
def optimize_animchar_camera_update(info : UpdateStageInfoAct;
                                    transform : float3x4;
                                    camera__animcharMaxDtThreshold = 0.f;
                                    camera__animcharDtThresholdMinDistance = 15.f;
                                    camera__animcharDtThresholdMaxDistance = 60.f;
                                    camera__active : bool)
  if !camera__active
    return
  let cameraPos = transform[3]
  query() <| $ [es(REQUIRE_NOT=watchedByPlr)] (var human_anim__minDtThreshold : float&;
                                               transform : float3x4)
    if camera__animcharMaxDtThreshold == 0.f
      human_anim__minDtThreshold = 0.f
      return
    let entityPos = transform[3]
    let distanceToCam = length(cameraPos - entityPos)
    human_anim__minDtThreshold = cvt(distanceToCam, camera__animcharDtThresholdMinDistance, camera__animcharDtThresholdMaxDistance,
                                        0.f, camera__animcharMaxDtThreshold)