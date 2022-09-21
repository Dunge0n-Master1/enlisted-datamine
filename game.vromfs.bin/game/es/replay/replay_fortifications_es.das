require ecs

[es(tag=playingReplay, on_appear, REQUIRE=builder_preview)]
def hide_replay_fortification_ri_preview_es(evt : Event; var preview_render__enabled : bool&)
  preview_render__enabled = false
