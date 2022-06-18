require ecs
require DagorInput
require game.es.input.input_common

[es(tag=input, no_order)]
def detect_input_mode(info : UpdateStageInfoAct; var glob_input__inputMode : int&)
  let mask = get_last_used_device_mask()
  if mask == 0u
    return

  if (mask & (DEV_USED_mouse | DEV_USED_kbd)) != 0u
    glob_input__inputMode = int(InputMode MODE_KEYBOARD_AND_MOUSE)
  elif (mask & DEV_USED_gamepad) != 0u
    glob_input__inputMode = int(InputMode MODE_GAMEPAD)
  else
    glob_input__inputMode = int(InputMode MODE_UNKNOWN)