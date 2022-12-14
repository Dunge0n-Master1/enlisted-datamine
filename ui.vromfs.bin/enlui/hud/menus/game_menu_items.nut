from "%enlSqGlob/ui_library.nut" import *

let { showSettingsMenu } = require("settings_menu.nut")
let { showControlsMenu } = require("controls_setup.nut")
let { switch_to_menu_scene } = require("app")
let { isSandboxEditor, quitSandboxEditor } = require("%ui/sandbox_editor.nut")
let { isNewDesign, setDesign } = require("%enlSqGlob/designState.nut")
let msgbox = require("%ui/components/msgbox.nut")

return {
  btnResume = {
    text = loc("gamemenu/btnResume")
    action = @() true
  }
  btnOptions = {
    text = loc("gamemenu/btnOptions")
    action = @() showSettingsMenu.update(true)
  }
  btnBindKeys = {
    text = loc("gamemenu/btnBindKeys")
    action = @() showControlsMenu.update(true)
  }
  btnToggleDesign = {
    text = isNewDesign.value ? loc("gamemenu/btnLegacyDesign") : loc("gamemenu/btnNewDesign")
    action = function() {
      if (isNewDesign.value)
        setDesign(false)
      else {
        msgbox.show({
          text = loc("gamemenu/hintNewDesign")
          buttons = [
            { text = loc("Cancel"), isCurrent = true }
            { text = loc("Ok"), action = @() setDesign(true) }
          ]
        })
      }
    }
  }
  btnExitGame = {
    text = !isSandboxEditor() ? loc("gamemenu/btnExitGame")
                              : loc("sandboxeditor/exitSandbox", "Exit Sandbox")
    action = function() {
      if (isSandboxEditor()) {
        quitSandboxEditor()
        return
      }
      msgbox.show({
        text = loc("exit_game_confirmation")
        buttons = [
          { text=loc("Yes"), action=switch_to_menu_scene}
          { text=loc("No"), isCurrent=true}
        ]
      })
    }
  }
}
