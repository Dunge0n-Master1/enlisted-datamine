import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let components = {
  briefing = [ecs.TYPE_BOOL],
  header = [ecs.TYPE_STRING, "briefing/header"],
  common_header = [ecs.TYPE_STRING, ""],
  briefing_common = [ecs.TYPE_STRING, ""],
  common = [ecs.TYPE_STRING, ""],
  hints_header = [ecs.TYPE_STRING, "briefing/common_hints_header"],
  hints = [ecs.TYPE_STRING, "common/controls"],
  showtime = [ecs.TYPE_FLOAT, 10.0],
  /*todo: replace image_team1, image_team2, team1, team_default, etc to
    briefing = {def={text="" image=null} [0]={text="" image=""} [1]={text="" image=""}} and use default if not specified
  */
}

let mkDefState = @() components.map(@(v) v?[1])
let briefingState = Watched(mkDefState())
let setState = @(_, comp) briefingState.update(components.map(@(defVal, name) comp?[name] ?? defVal?[1]))

let comps_track = []
foreach (name, defVal in components)
  comps_track.append([name].extend(defVal))

ecs.register_es("es_ui_briefing", {
    [["onInit", "onChange"]] = setState,
    onDestroy = @() setState(null, {})
  },
  {comps_track}
)
let showBriefingOnSquadChange = Watched(false)
ecs.register_es("es_ui_briefing_show_on_squad_change", {
    onInit =  @(_eid, _comp) showBriefingOnSquadChange(true)
    onDestroy =  @(_eid, _comp) showBriefingOnSquadChange(false)
  }, {comps_rq = ["show_briefing_on_squad_change"]}
)

let showBriefingOnHeroChange = Watched(false)
ecs.register_es("es_ui_briefing_show_on_hero_change", {
    onInit =  @(_eid, _comp) showBriefingOnHeroChange(true)
    onDestroy =  @(_eid, _comp) showBriefingOnHeroChange(false)
  }, {comps_rq = ["show_briefing_on_hero_change"]}
)

let showBriefing = mkWatched(persist, "showBriefing", false)

return {
  briefingState
  showBriefingOnHeroChange
  showBriefingOnSquadChange
  showBriefingForTime = Watched(null)
  showBriefing
}
