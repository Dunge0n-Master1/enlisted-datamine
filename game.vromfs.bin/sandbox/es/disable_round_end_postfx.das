require ecs

[es(tag=render, on_appear, REQUIRE=postfxRoundctrlTag)]
def disable_round_end_postfx_sandbox(evt : Event; eid : EntityId)
  reCreateEntityFrom(eid, add_sub_template_name(eid, "disable_round_end_postfx"))
