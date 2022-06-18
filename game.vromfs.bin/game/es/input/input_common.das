module input_common shared

require ecs
require game.es.events
require DagorInput
require HumanPhys
require TouchInput
require DagorSystem

enum InputMode
  MODE_UNKNOWN            = 0
  MODE_KEYBOARD_AND_MOUSE = 1
  MODE_GAMEPAD            = 2

def InputMode(v : int)
  for mode in each_enum(InputMode MODE_UNKNOWN)
    if int(mode) == v
      return mode
  return InputMode MODE_UNKNOWN

def get_input_mode()
  var mode = InputMode MODE_UNKNOWN
  find_query() <| $ [es] (glob_input__inputMode : int)
    mode = InputMode(glob_input__inputMode)
    return true
  return mode

def is_gamepad_input()
  return get_input_mode() == InputMode MODE_GAMEPAD

def is_keyboard_and_mouse_input()
  return get_input_mode() == InputMode MODE_KEYBOARD_AND_MOUSE

def set_controlbit_touch(bit : HumanPhysControlType; button : uint16; var ct : HumanControlState&)
  if is_action_active(button)
    let actionState = get_digital_action_state(button).bState || is_button_pressed(button)
    ct |> human_control_state_set_control_bit(bit, actionState)

def set_controlbit(bit : HumanPhysControlType; button : uint16; var ct : HumanControlState&) : bool
  if is_action_active(button)
    let state = get_digital_action_state(button).bState
    ct |> human_control_state_set_control_bit(bit, state)
    return true
  return false
