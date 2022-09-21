require ecs

[es(track=(camera__target, camera__active), REQUIRE=camera__target)]
def camera_set_tps_view_es(evt : Event; camera__active : bool; isTpsView aka camera__isTpsView : bool = false)
  if camera__active
    query() <| $ [es(REQUIRE=watchedByPlr)] (var isTpsView : bool&)
      isTpsView = camera__isTpsView

[es(on_appear, REQUIRE=watchedByPlr)]
def human_set_tps_view_es(evt : Event; var isTpsView aka human__isTpsView : bool&)
  find_query() <| $ [es] (camera__active : bool; isTpsView : bool = false)
    if camera__active
      human__isTpsView = isTpsView
    return camera__active
