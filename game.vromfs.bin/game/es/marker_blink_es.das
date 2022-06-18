require ecs
require app
require enlisted.events_enlisted

[es(tag=server)]
def marker_blink_es(evt : CmdBlinkMarker; possessedByPlr : EntityId; marker__blinkTime : float; var marker__blink : bool&; var marker__blinkTimer : float&)
  if !possessedByPlr
    return

  marker__blink = true
  marker__blinkTimer = get_sync_time() + marker__blinkTime

[es(tag=server, no_order)]
def marker_blink_timer_es(evt : UpdateStageInfoAct; possessedByPlr : EntityId; var marker__blink : bool&; var marker__blinkTimer : float&)
  if !possessedByPlr || !marker__blink || marker__blinkTimer > get_sync_time()
    return
  marker__blinkTimer = -1f
  marker__blink = false

[es(tag=server, track=possessedByPlr)]
def marker_blink_reset_on_possessed_es(evt : Event; possessedByPlr : EntityId; var marker__blink : bool&; var marker__blinkTimer : float&)
  if !!possessedByPlr || !marker__blink
    return

  let blink = marker__blink
  let blinkTimer = marker__blinkTimer
  query(possessedByPlr) <| $ [es] (possessed : EntityId)
    query(possessed) <| $ [es] (var marker__blink : bool&; var marker__blinkTimer : float&)
      marker__blink = blink
      marker__blinkTimer = blinkTimer

  marker__blinkTimer = -1f
  marker__blink = false
