require ecs
require app
require game.es.events
require enlisted.events_enlisted
require game.events_game
require common_shooter.events_common_shooter


def update_offender_mark(var offender_marks : Array; offender : EntityId; showTimeEnd : float)
  var arrayPos = -1
  for offenderMark, i in offender_marks, iter_range(offender_marks)
    let offenderMarkObj = offenderMark |> get_ecs_object()
    if offenderMarkObj == null
      continue
    let offenderEid = offenderMarkObj |> get_Eid("offender") ?? INVALID_ENTITY_ID
    if offender == offenderEid
      arrayPos = i
      break

  query(offender) <| $ [es] (transform : float3x4)
    using <| $(var obj : Object#)
      obj |> set("offender", offender)
      obj |> set("offenderPos", transform[3])
      obj |> set("showTimeEnd", showTimeEnd)
      if arrayPos == -1
        offender_marks |> push(obj)
      else
        var offenderMarkObj = offender_marks[arrayPos] |> getRW_ecs_object()
        if offenderMarkObj != null
          *offenderMarkObj := obj

def is_minimalist_hud()
  var isMinimalistHud = false
  find_query() <| $ [es] (minimalistHud : bool)
    isMinimalistHud = minimalistHud
    return true
  return isMinimalistHud

[es(tag=gameClient, REQUIRE_NOT=deadEntity)]
def offender_mark_on_hit(evt : EventOnEntityHit;
                         eid : EntityId;
                         offender_marks__enabled : bool;
                         offender_marks__showOnlyLast : bool;
                         offender_marks__showTime : float;
                         var offender_marks : Array)
  let isSelfHit = evt.offender == evt.victim
  if evt.victim != eid || !offender_marks__enabled || isSelfHit || is_minimalist_hud()
    return

  if offender_marks__showOnlyLast
    offender_marks |> clear()
  update_offender_mark(offender_marks, evt.offender, offender_marks__showTime + get_sync_time())


[es(tag=gameClient)]
def offender_mark_on_died(evt : EventEntityDied;
                          var offender_marks : Array)
  offender_marks |> clear()


[es(tag=gameClient)]
def offender_mark_update_time(act : ParallelUpdateFrameDelayed;
                              var offender_marks : Array)
  var reverceIdx = offender_marks |> length() - 1
  while reverceIdx >= 0
    let offenderMarkObj = offender_marks[reverceIdx] |> get_ecs_object()
    if offenderMarkObj == null
      continue
    let showTimeEnd = offenderMarkObj |> get_float("showTimeEnd") ?? 0.0
    if act.curTime >= showTimeEnd
      offender_marks |> erase(reverceIdx)
    reverceIdx -= 1


[es(tag=gameClient, after=offender_mark_update_time)]
def offender_mark_update_pos(act : ParallelUpdateFrameDelayed;
                             offender_marks__updateOffenderPos : bool;
                             var offender_marks : Array)
  if !offender_marks__updateOffenderPos
    return

  for mark in offender_marks
    let markObj = mark |> getRW_ecs_object()
    if markObj != null
      let offenderEid = markObj |> get_Eid("offender") ?? INVALID_ENTITY_ID
      var pos = markObj |> getRW_Point3("offenderPos")
      if pos != null
        query(offenderEid) <| $ [es] (transform : float3x4)
          *pos = transform[3]
