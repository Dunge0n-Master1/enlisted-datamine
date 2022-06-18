import "%dngscripts/ecs.nut" as ecs
let noBotsModeQuery = ecs.SqQuery("noBotsModeQuery", {comps_rq=["noBotsMode"]})
let isNoBotsMode = @() noBotsModeQuery.perform(@(...) true) ?? false

let friendlyFireModeQuery = ecs.SqQuery("friendlyFireModeQuery", {comps_rq=["gamemodeFriendlyFire"]})
let isFriendlyFireMode = @() friendlyFireModeQuery.perform(@(...) true) ?? false

let missionTypeQuery = ecs.SqQuery("missionTypeQuery", {comps_ro=[["mission_type", ecs.TYPE_STRING]]})
let getMissionType = @() missionTypeQuery.perform(@(_, comp) comp.mission_type)

return {
  isNoBotsMode
  isFriendlyFireMode
  getMissionType
}