require ecs
require DngCamera
require AnimV20
require math.base
require enlisted.events_enlisted

[es(no_order)]
def animated_visible_attachments_act_animchar_es(info : ParallelUpdateFrameDelayed)
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTm == null
    return
  let camPos = (*camTm)[3]
  query() <| $ [es(REQUIRE=animchar_attaches__animated, REQUIRE_NOT=(transform, animchar__actOnDemand))] (animchar__visible : bool;
                                                                                                          animchar__updatable : bool;
                                                                                                          animchar_render__root_pos : vec4f;
                                                                                                          animchar_attaches__disableAnimDistance = 5.f;
                                                                                                          var animchar : AnimcharBaseComponent)
    if !animchar__visible || !animchar__updatable
      return
    let attachRenderPos = animchar_render__root_pos.xyz
    if length_sq(attachRenderPos - camPos) < square(animchar_attaches__disableAnimDistance)
      animchar_act(animchar, info.dt, true)


[es(tag=(server, gameClient), REQUIRE=animchar_attaches__animated, on_appear, track=slot_attach__attachedTo)]
def menu_attach_update_tag(evt : Event;
                           slot_attach__attachedTo : EntityId;
                           eid : EntityId;
                           animchar__menuDisableUpdateDistance = 1000.f;
                           var animchar_attaches__disableAnimDistance : float?)
  let parentInMenu = get_bool(slot_attach__attachedTo, "menuChar") ?? false
  if !parentInMenu
    return

  if animchar_attaches__disableAnimDistance != null
    *animchar_attaches__disableAnimDistance = animchar__menuDisableUpdateDistance
  else
    addSubTemplate(eid, "animated_attaches_update_disabler") <| $(var init)
      set(init, "animchar_attaches__disableAnimDistance", animchar__menuDisableUpdateDistance)
