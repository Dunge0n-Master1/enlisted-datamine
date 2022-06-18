require ecs
require ecs.common

[es(on_event=EventLevelLoaded)]
def poly_area_gen(evt : Event; poly_area_gen__polyName : string; poly_area_gen__template : string)
  find_query() <| $ [es] (level_spline__name : string; level_spline__points : Point3List)
    if level_spline__name != poly_area_gen__polyName
      return false
    createEntity(poly_area_gen__template) <| $(var init : ComponentsInitializer)
      push_to_initializer(init, "battleAreaPoints") <| $(var pts : Point2List#)
        for pt in level_spline__points
          push(pts, pt.xz)
    return true

