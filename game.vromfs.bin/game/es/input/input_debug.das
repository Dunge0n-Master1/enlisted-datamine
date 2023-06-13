options no_aot
require ecs
require DagorInput
require DagorSystem
require DagorConsole


[console_cmd(name="input.set_stick_smooth_value", hint="Change the smoothValue of a specified action")]
def input_set_stick_smooth_value_debug_cmd(action_name : string; smooth_value : float)
  let actionHandle = get_action_handle(action_name, TYPEGRP_STICK)
  if actionHandle != BAD_ACTION_HANDLE
    set_analog_stick_action_smooth_value(actionHandle, smooth_value)
  else
    logerr("failed to set the smoothValue of the '{action_name}': invalid action name")


[console_cmd(name="input.get_stick_smooth_value", hint="Show the smoothValue of a specified action")]
def input_get_stick_smooth_value_debug_cmd(action_name : string)
  let actionHandle = get_action_handle(action_name, TYPEGRP_STICK)
  if actionHandle != BAD_ACTION_HANDLE
    let smoothValue = get_analog_stick_action_smooth_value(actionHandle)
    console_print("'{action_name}' smoothValue is '{smoothValue}'")
  else
    logerr("failed to get the smoothValue of the '{action_name}': invalid action name")
