from "%enlSqGlob/ui_library.nut" import *

let dbgData = Watched(null)
let dbgShow = Watched(false)
dbgShow.subscribe(function(v) {
  if (!v)
    dbgData(null)
})

return {
  dbgData = dbgData
  dbgShow = dbgShow
}