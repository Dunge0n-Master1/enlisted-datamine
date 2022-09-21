import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let warningsCompsTrack = [
  ["ui_perf_stats__server_tick_warn", 0],
  ["ui_perf_stats__low_fps_warn", 0],
  ["ui_perf_stats__latency_warn", 0],
  ["ui_perf_stats__latency_variation_warn", 0],
  ["ui_perf_stats__packet_loss_warn", 0],
  ["ui_perf_stats__low_tickrate_warn", 0],
]

let warnings = Watched(warningsCompsTrack.totable())

ecs.register_es("script_perf_stats_es",
  {
    [["onChange", "onInit"]] = @(_eid, comp) warnings(clone comp)
  },
  {comps_track=warningsCompsTrack.map(@(v) [v[0], ecs.TYPE_INT])}
)

return {
  warnings
}
