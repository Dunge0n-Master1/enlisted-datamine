require ecs
require app

[es(tag=gameClient, track=ai_enabled__inSandbox, on_event=CmdEditorInvalidateAI, on_appear, before=switch_ai_on_possess_unpossess)]
def sandbox_toggle_ai_es(evt : Event; ai_enabled__inSandbox : bool; var ai_enabled : bool&)
  if get_app_offline_mode()
    ai_enabled = ai_enabled__inSandbox
