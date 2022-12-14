require ecs
require game.es.events
require DaWeaponProps
require DagorMath
require math.curve
require common_shooter.events_common_shooter
require enlisted.events_enlisted

[es(tag=gameClient, on_appear)]
def explosion_flash_created(evt : Event;
                            flash__startBrightness : float;
                            var light__brightness : float&)
  light__brightness = flash__startBrightness


[es(tag=gameClient, no_order)]
def explosion_flash_update_client(act : ParallelUpdateFrameDelayed;
                                  flash__intensityCurve : Array;
                                  game_effect__timeToDestroy : float;
                                  flash__startBrightness : float;
                                  game_effect__destroyAt : float;
                                  var light__brightness : float&)
  let t = clamp((game_effect__destroyAt - act.curTime) / game_effect__timeToDestroy, 0.0, 1.0)
  light__brightness = flash__startBrightness * get_value_on_2d_pl_curve(t, flash__intensityCurve)


[es(tag=server)]
def explosion_flash_initiate(evt : CmdShellExplode; transform : float3x4; explosion_flash__template : string)
  createEntity(explosion_flash__template) <| $(var init : ComponentsInitializer)
    init |> set("transform", transform)
