import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { pieMenuItems } = require("%ui/hud/state/pie_menu_state.nut")
let { wallPosters } = require("%ui/hud/state/wallposter.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { CmdWallposterPreview } = require("dasevents")
let mkPieItemCtor = require("%ui/hud/components/wallposter_menu_item_ctor.nut")

let elemSize = Computed(@() array(2, (hdpx(390) * 0.35).tointeger()))

let svg = memoize(function(img) {
  return "!ui/uiskin/{0}.svg:{1}:{1}:K".subst(img, elemSize.value[1])
})
let wallPosterPreview = @(index)
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdWallposterPreview({enable=true, wallPosterId=index}))

wallPosters.subscribe(function(posters) {
  pieMenuItems.value[0] = posters.map(function(poster, index) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(poster)
    let text = template?.getCompValNullable?("wallposter_menu__text") ?? ""
    let imageName = template?.getCompValNullable?("wallposter_menu__image")
    let image = imageName ? svg(imageName) : null
    let hintText = loc(text)
    return {
      action = @() wallPosterPreview(index)
      text = hintText
      ctor = mkPieItemCtor(index, image, hintText)
    }
  })
})
