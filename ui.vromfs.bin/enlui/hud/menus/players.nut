from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let sessions_players = require("%ui/hud/state/sessions_players.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let JB = require("%ui/control/gui_buttons.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let cursors = require("%ui/style/cursors.nut")

let showPlayersMenu = mkWatched(persist, "showPlayersMenu", false)

let function close(){
  showPlayersMenu(false)
}

let closebutton = fontIconButton("close", {
  onClick = close
  margin = hdpx(8)
  hplace = ALIGN_RIGHT
  hotkeys = [["^{0}".subst(JB.B), {description={skip=true}}]]
  padding = 0
})

let mkPlayer = @(text) { rendObj = ROBJ_TEXT, text }.__update(body_txt)

let header = {
  rendObj = ROBJ_TEXT
  text = loc("Players in session")
  margin = hdpx(8)
  color = Color(120,120,120,120)
}.__update(body_txt)

let function menu(){
  return {
    watch = [sessions_players]
    size = [sw(20), sh(60)]
    pos = [sw(10),sh(10)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = Color(0,0,0,80)
    hotkeys = [["^Esc", close]]
    flow = FLOW_VERTICAL
    children = [
      {children = [header, closebutton] size = [flex(), SIZE_TO_CONTENT]}
      scrollbar.makeVertScroll(
        {
          size = SIZE_TO_CONTENT
          flow = FLOW_VERTICAL
          padding = [fsh(1), fsh(1)]
          children = sessions_players.value.map(mkPlayer)
        },
        {
          needReservePlace = false
          wheelStep = hdpx(30)
        }
      )
    ]
  }
}

return {
  showPlayersMenu
  playersMenuUi = @(){
    size = flex()
    watch = [showPlayersMenu]
    cursor = showPlayersMenu.value ? cursors.normal : null
    children = showPlayersMenu.value ? menu : null
    behavior = Behaviors.ActivateActionSet
    actionSet = "StopInput"
  }
}