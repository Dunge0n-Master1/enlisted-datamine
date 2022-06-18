options no_aot
require ecs
require DagorConsole

[console_cmd(name="volfog.force_change")]
def cmd_volfog__force_change()
  query() <| $ [es] (var volfog_snow__intensityNextChangeTimer : float&)
    volfog_snow__intensityNextChangeTimer = 0.f

[console_cmd(name="volfog.change")]
def cmd_volfog__change(val : float)
  query() <| $ [es] (var volfog_snow__maxIntensity : float&)
    volfog_snow__maxIntensity = val
