from "%enlSqGlob/ui_library.nut" import *

let { warnings } = require("%ui/hud/state/perf_stats_es.nut")
let {horPadding, verPadding} = require("%enlSqGlob/safeArea.nut")
let cursors = require("%ui/style/cursors.nut")
let picSz = fsh(3.3)
let {hudIsInteractive} = require("%ui/hud/state/interactive_state.nut")

let function pic(name) {
  return Picture("ui/skin#qos/{0}.svg:{1}:{1}:K".subst(name, picSz.tointeger()))
}

let icons = {
  ["ui_perf_stats__server_tick_warn"] = {pic = pic("server_perfomance"), loc="hud/server_tick_warn_tip"},
  ["ui_perf_stats__low_fps_warn"] = {pic = pic("low_fps"), loc="hud/low_fps_warn_tip"},
  ["ui_perf_stats__latency_warn"] = {pic = pic("high_latency"), loc="hud/latency_warn_tip"},
  ["ui_perf_stats__latency_variation_warn"] = {pic = pic("latency_variation"), loc ="hud/latency_variation_warn_tip"},
  ["ui_perf_stats__packet_loss_warn"] = {pic = pic("packet_loss"), loc="hud/packet_loss_warn_tip"},
  ["ui_perf_stats__low_tickrate_warn"] = {pic = pic("low_tickrate"), loc="hud/low_tickrate_warn_tip"},
}

let colorMedium = Color(160, 120, 0, 160)
let colorHigh = Color(200, 50, 0, 160)
let debugWarnings = Watched(false)
let function mkidx() {
  local i = 0
  return @() i++
}
let cWarnings = Computed(function() {
  let idx = mkidx()
  return debugWarnings.value ? icons.map(@(_v, _i) 1+(idx()%2)) : warnings.value
})
console_register_command(@() debugWarnings(!debugWarnings.value),"ui.debug_perf_stats")

let function root() {
  let children = []

  foreach (key, val in cWarnings.value) {
    if (val > 0) {
      let hint = loc(icons[key]["loc"], "")
      let onHover = @(on) cursors.setTooltip(on ? hint : null)
      children.append({
        key = key
        size = [picSz, picSz]
        image = icons[key]["pic"]
        behavior = hudIsInteractive.value ? Behaviors.Button : null
        skipDirPadNav = true
        onHover = onHover
        rendObj = ROBJ_IMAGE
        color = (val==2) ? colorHigh : colorMedium
      })
    }
  }

  return {
    watch = [cWarnings, verPadding, horPadding, hudIsInteractive]
    size = SIZE_TO_CONTENT
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    flow = FLOW_HORIZONTAL
    children = children
    margin = [max(verPadding.value/2.0,fsh(0.4)), max(horPadding.value/1.2,fsh(0.4))]
  }
}

return root
