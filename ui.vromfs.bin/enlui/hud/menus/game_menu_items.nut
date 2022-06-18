from "%enlSqGlob/ui_library.nut" import *

let { showSettingsMenu } = require("settings_menu.nut")
let { showControlsMenu } = require("controls_setup.nut")
let { exit_to_enlist } = require("app")
let { isSandboxEditor, quitSandboxEditor } = require("%ui/sandbox_editor.nut")
let msgbox = require("%ui/components/msgbox.nut")

let items = {
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
          { text=loc("Yes"), action=exit_to_enlist}
          { text=loc("No"), isCurrent=true}
        ]
      })
    }
  }
}

return items
