from "%enlSqGlob/ui_library.nut" import *

let {configs} = require("%enlSqGlob/configs/configs.nut")

return Computed(@() configs.value?.transferConfig ?? [])
