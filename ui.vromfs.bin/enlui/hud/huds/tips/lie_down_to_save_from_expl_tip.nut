import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {EventEntityDied} = require("dasevents")
let {get_shell_template_by_shell_id, DM_EXPLOSION} = require("dm")

let showTip = Watched(false)

const TIP_SHOW_TIME = 5

let hideTip = @() showTip(false)

ecs.register_es(
  "show_bomb_tip_es",
  {
    [EventEntityDied] = function(evt, _eid, _comp) {
      let { shellId, damageType } = evt

      let shellTemplateName = get_shell_template_by_shell_id(shellId) ?? ""
      if (shellTemplateName == "")
        return

      let shellTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(shellTemplateName)
      let isBomb = shellTemplate?.getCompValNullable("projectile__isBomb") != null

      if (damageType != DM_EXPLOSION || !isBomb)
        return

      if (!showTip.value) {
        showTip(true)
        gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
      }
    }
  },
  {
    comps_rq = ["watchedByPlr"]
  }
)

let explTip = tipCmp({
  text = loc("hint/lieDownToSaveFromExplosion")
  style = {onAttach = @() gui_scene.setTimeout(TIP_SHOW_TIME, @() showTip(false))
           onDetach = @() showTip(false)}
}.__update(body_txt))

let lie_down_to_save_from_expl_tip = @() {
  watch = showTip
  children = showTip.value ? explTip : null
}

return lie_down_to_save_from_expl_tip