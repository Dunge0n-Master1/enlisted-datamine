options no_aot = true//we don't need aot ever for this script. Is basically called once in a program life-time, not to bother
require DagorSystem
require DagorConsole
//require DagorShaders

[init]
def platformInit
  if get_platform_string_id() == "iOS"
    console_command("render.subdivCellSize 0.32")//example of console variables set
    //DagorShaders::set_int(get_shader_variable_id("some_int", true), 1)//example of shader variables set
