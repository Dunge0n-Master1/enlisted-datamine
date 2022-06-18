options no_aot
require ecs

[es(on_appear, REQUIRE=(animchar, attaches_list))]
def add_motion_matching(evt : Event; eid : EntityId)
  query() <| $ [es(REQUIRE=requireMotionMatchingComponents)] ()
    addSubTemplate(eid, "motion_matching_animchar_component")