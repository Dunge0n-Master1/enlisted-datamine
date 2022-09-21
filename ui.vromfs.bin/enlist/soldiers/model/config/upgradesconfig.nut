from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")

return Computed(@() configs.value?.upgrades ?? {})