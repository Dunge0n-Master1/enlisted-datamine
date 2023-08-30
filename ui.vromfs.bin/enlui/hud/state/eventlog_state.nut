from "%enlSqGlob/ui_library.nut" import *


let {sound_play} = require("%dngscripts/sound_system.nut")
let getByPath = require("%sqstd/table.nut").getValInTblPath
let {get_time_msec} = require("dagor.time")
const MAX_EVENTS_DEFAULT = 10

let equalIgnore = { ttl = true, key = true, num = true }
let countNotIgnoreKeys = @(event) event.keys().reduce(@(res, key) equalIgnore?[key] ? res + 1 : res, 0)

let function isEventSame(event1, event2) {
  if (countNotIgnoreKeys(event1) != countNotIgnoreKeys(event2))
    return false
  foreach (key, value in event1)
    if (!equalIgnore?[key] && event2?[key] != value)
      return false
  return true
}

let function speedUpRemoveSame(eventList, event, maxTime) {
  for (local i = eventList.len() - 1; i >= 0; i--) {
    let eventToRemove = eventList[i]
    if (isEventSame(eventToRemove, event)) {
      eventToRemove.ttl = min(eventToRemove.ttl, maxTime)
      break;
    }
  }
}

let function playEventSound(event){
  if ("sound" in event)
    sound_play(event?.sound ?? "", event?.volume ?? 1)
}

local EventLogState = class {
  data = null
  events = null
  clearTime = -1
  defTtl = null
  maxEvents = MAX_EVENTS_DEFAULT
  checkCollapseByFunc = null

  constructor(persistId, clearSameTime = -1, maxActiveEvents = MAX_EVENTS_DEFAULT, ttl = 5.0, collapseByFunc=null) {
    if (type(persistId)=="table"){
      clearSameTime = persistId?.clearSameTime ?? clearSameTime
      maxActiveEvents = persistId?.maxActiveEvents ?? maxActiveEvents
      ttl = persistId?.ttl ?? ttl
      collapseByFunc = persistId?.collapseByFunc ?? collapseByFunc
      persistId = persistId.id
    }
    this.data = persist(persistId, @() { events = Watched([]), idCounter = 0 })
    this.events = this.data.events
    this.clearTime = clearSameTime
    this.maxEvents = maxActiveEvents
    this.defTtl = ttl
    this.checkCollapseByFunc = collapseByFunc
  }

  function pushEvent(eventExt, collapseBy=null) {
    let key = ++this.data.idCounter
    let ev = this.events?.value ?? []
    let lastev  = ev?[ev.len()-1]
    let event = clone eventExt
    local funcCollapseBy = null
    if (type(collapseBy)=="array"){
      funcCollapseBy = @(lastevt, evt) getByPath(lastevt,collapseBy) == getByPath(evt,collapseBy)
    }
    let funcToCheck = funcCollapseBy ?? this.checkCollapseByFunc
    this.events.mutate(function(_) {
      let unique = event?.unique
      if (unique != null)
        for (local idx = ev.len() - 1; idx >= 0; --idx) {
          if (ev[idx]?.unique == unique)
            ev.remove(idx)
        }
      event.ttl <- (event?.ttl != null && event.ttl >= 0) ? event.ttl : this.defTtl
      event.ctime <- get_time_msec()
      if (funcToCheck == null || !funcToCheck(lastev, event) || ev.len() == 0) {
        event.key <- key
        if (this.clearTime >= 0)
          speedUpRemoveSame(ev, event, this.clearTime)
        ev.append(event)
        playEventSound(event)
      }
      else {
        let num = (lastev?.num != null) ? lastev.num+1 : 2
        event.num <- num
        event.key <- lastev?.key ?? key
        ev[ev.len()-1] = event
      }
      if (ev.len() > this.maxEvents)
        ev.remove(0)
    }.bindenv(this))
  }

  function update(dt) {
    foreach (e in this.events.value)
      e.ttl -= dt
    let newEvents = this.events.value.filter(@(e) e.ttl > 0)
    if (newEvents.len() != this.events.value.len())
      this.events(newEvents)
  }
}

return EventLogState
