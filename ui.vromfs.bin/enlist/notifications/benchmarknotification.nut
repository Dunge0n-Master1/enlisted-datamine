from "%enlSqGlob/ui_library.nut" import *

let { debounce } = require("%sqstd/timers.nut")
let { gpuBenchmarkWnd, benchmarkWindowSeen } = require("%enlSqGlob/ui/benchmarkWnd.nut")
let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let { is_pc } = require("%dngscripts/platform.nut")

let needShowBenchmarkWindow = keepref(Computed(@() is_pc && !benchmarkWindowSeen.value && canDisplayOffers.value))

let openBenchmarkWindowDelayed = debounce(function(v) {
  if (v)
    gpuBenchmarkWnd()
}, 0.01)

needShowBenchmarkWindow.subscribe(openBenchmarkWindowDelayed)