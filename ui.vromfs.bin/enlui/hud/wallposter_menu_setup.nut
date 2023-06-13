import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { pieMenuItems } = require("%ui/hud/state/pie_menu_state.nut")
let { wallPosters } = require("%ui/hud/state/wallposter.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { CmdWallposterPreview } = require("dasevents")
let texNameConvertor = require("%enlSqGlob/ui/texNameConvertor.nut")
let mkPieItemCtor = require("%ui/hud/components/wallposter_menu_item_ctor.nut")

let wallPosterPreview = @(index)
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdWallposterPreview({enable=true, wallPosterId=index}))

wallPosters.subscribe(function(posters) {
  pieMenuItems.mutate(@(arr) arr[0] = posters.map(function(poster, index) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(poster)
    let text = template?.getCompValNullable?("wallposter_menu__text") ?? ""
    local imageName = template?.getCompValNullable?("wallposter_menu__image")
    if (imageName != null)
      imageName = texNameConvertor(imageName)
    let hintText = loc(text)
    return {
      action = @() wallPosterPreview(index)
      text = hintText
      ctor = mkPieItemCtor(index, imageName, hintText)
    }
  }))
})
