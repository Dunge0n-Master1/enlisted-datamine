require ecs
require ecs.common
require EnlistedHumanAnim

[es(tag=render, REQUIRE_NOT=animchar__actOnDemand, before=(animchar_es, net_phys_update_es))]
def update_animchar_dtThreshold_es(info : UpdateStageInfoAct;
                                   animchar__visible : bool;
                                   var animchar__dtThreshold : float&;
                                   animchar__invisDtThreshold : float = 0.4;
                                   animchar__minDtThreshold : float = 0.0)
  animchar__dtThreshold = animchar__visible ? animchar__minDtThreshold : max(animchar__invisDtThreshold, animchar__minDtThreshold);


[es(tag=render, before=(animchar_es, net_phys_update_es, update_animchar_dtThreshold_es))]
def update_animchar_visibility_es(info : UpdateStageInfoAct;
                                  var animchar__visible : bool&;
                                  animchar_visbits : uint8;
                                  animchar__considerAsVisible : Tag const?;
                                  animchar_render__enabled : bool = true)
  if animchar__considerAsVisible != null // need for some entites such as hero skeleton (no skip animchar update by threshold etc)
    animchar__visible = true
    return

  if !animchar_render__enabled
    animchar__visible = false
    return

  animchar__visible = (int(animchar_visbits) & (int(AnimcharVisbits VISFLG_MAIN_CAMERA_RENDERED) |
                       int(AnimcharVisbits VISFLG_CSM_SHADOW_RENDERED) | int(AnimcharVisbits VISFLG_COCKPIT_VISIBLE) |
                       int(AnimcharVisbits VISFLG_SEMI_TRANS_RENDERED) | int(AnimcharVisbits VISFLG_OUTLINE_RENDERED))) != 0