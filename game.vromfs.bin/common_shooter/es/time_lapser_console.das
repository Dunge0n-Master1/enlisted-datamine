options no_aot
require ecs
require ecs.common
require DagorConsole

[console_cmd(name="timelapser.record")]
def timelapser_cmd(curTime, toTime : float; timeStep : float?; deltaPosX : float?; deltaPosY : float?; deltaPosZ : float?)
  createEntity("timelapse_screener") <| $(var init : ComponentsInitializer)
    set(init, "timelapse_screener__curTime", curTime)
    set(init, "timelapse_screener__toTime", toTime)
    if timeStep != null
      set(init, "timelapse_screener__timeStep", *timeStep)
    if deltaPosX != null && deltaPosY != null && deltaPosZ != null
      set(init, "timelapse_screener__deltaPos", float3(*deltaPosX, *deltaPosY, *deltaPosZ))
