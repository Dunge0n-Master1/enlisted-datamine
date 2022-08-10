require ecs
require app
require DagorMath
require enlisted.events_enlisted
require game.events_game

[es(tag=render, REQUIRE=(hero, deadEntity), on_appear, track=death_cam__killer)]
def killer_outline(evt : Event; death_cam__killer : EntityId)
  query(death_cam__killer) <| $ [es] (human_anim__vehicleSelected : EntityId)
    let outline_target = !!human_anim__vehicleSelected ? human_anim__vehicleSelected : death_cam__killer
    query(outline_target) <| $ [es] (var outline__enabled : bool&;
                                     var outline__color : E3DCOLOR&;
                                     var outline__disableAtTime : float&;
                                     var outline__always_visible : bool&;
                                     var killer_outline__enabled : bool&;
                                     killer_outline__color : E3DCOLOR;
                                     killer_outline__timeout : float = 5.0)
      outline__enabled = true
      outline__color = killer_outline__color
      outline__disableAtTime = get_sync_time() + killer_outline__timeout
      killer_outline__enabled = true
      outline__always_visible = true


[es(tag=render)]
def outline_disabler(info : ParallelUpdateFrameDelayed;
                     var killer_outline__enabled : bool&;
                     var outline__enabled : bool&;
                     var outline__always_visible : bool&;
                     var outline__disableAtTime : float&)
  if killer_outline__enabled && outline__disableAtTime < info.curTime && outline__disableAtTime >= 0.0
    outline__disableAtTime = -1.0
    outline__enabled = false
    killer_outline__enabled = false
    outline__always_visible = false

[es(tag=render, on_event=EventHeroChanged)]
def outline_disabler_hero_changed(evt : Event;
                                  var killer_outline__enabled : bool&;
                                  var outline__enabled : bool&;
                                  var outline__always_visible : bool&;
                                  var outline__disableAtTime : float&)
  if killer_outline__enabled
    outline__disableAtTime = -1.0
    outline__enabled = false
    killer_outline__enabled = false
    outline__always_visible = false

