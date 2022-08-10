from "%enlSqGlob/ui_library.nut" import *


const INV_ITEMS_COUNT = 9

let viewTemplates = mkWatched(persist, "viewTemplates", array(INV_ITEMS_COUNT, ""))

console_register_command(function(tpl, slot) {
  if (slot >= 0 && slot < viewTemplates.value.len())
    viewTemplates.mutate(@(tpls) tpls[slot] = tpl)
}, "itemview.addTpl")

console_register_command(function() {
  viewTemplates.mutate(function(tpls) {
    for (local i = 0; i < tpls.len(); i++)
      tpls[i] = ""
  })
}, "itemview.clear")

return {
  viewTemplates
}
