from "%enlSqGlob/ui_library.nut" import *

let { rand } = require("math")
let { chooseRandom } = require("%sqstd/rand.nut")
let { matchingCall } = require("%enlist/matchingClient.nut")
let baseRoomState = require("%enlist/state/roomState.nut")
let {
  room, startSessionWithLocalDedicated, canStartWithLocalDedicated,
  joinedRoomWithInvite, leaveRoom
} = baseRoomState
let roomMembersBase = baseRoomState.roomMembers
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { openEventModes } = require("%enlist/gameModes/eventModesState.nut")
let getMissionInfo = require("%enlist/gameModes/getMissionInfo.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { portraits, nickFrames } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { error_string, OK } = require("matching.errors")
let { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")
let memberStatuses = require("roomMemberStatuses.nut")
let { availableCampaigns } = require("%enlist/gameModes/sandbox/customMissionState.nut")


const IS_LOCAL_DEDICATED = "startWithLocalDedicated"

let roomScene = Computed(@() room.value?.public.scene)
let isEventRoom = Computed(@() room.value?.public.digestGroup == "events-lobby")
let debugMembers = mkWatched(persist, "debugMembers", [])
let roomMembers = Computed(@() (clone roomMembersBase.value).extend(debugMembers.value))
let isLocalDedicated = Watched(get_setting_by_blk_path(IS_LOCAL_DEDICATED) ?? false)
isLocalDedicated.subscribe(function(v) {
  set_setting_by_blk_path(IS_LOCAL_DEDICATED, v)
  save_settings()
})

let roomCampaigns = Computed(function() {
  let modsCampaigns = availableCampaigns.value
  if (modsCampaigns.len() > 0)
    return modsCampaigns

  let { scene = null, campaigns = [] } = room.value?.public
  if (campaigns.len() > 0 || scene == null)
    return campaigns

  local { campaign } = getMissionInfo(scene)
  if (!unlockedCampaigns.value.contains(campaign) && !isEventRoom.value)
    campaign = unlockedCampaigns.value?[0]
  return [campaign]
})

let roomTeamArmies = Computed(function() {
  let { teamArmies = "historical" } = room.value?.public
  let res = [[], []]
  foreach (campaign in roomCampaigns.value)
    foreach (teamIdx, army in gameProfile.value?.campaigns[campaign].armies ?? [])
      if (teamIdx in res)
        res[teamIdx].append(army.id)

  if (teamArmies != "historical")
    res[1] = res[0].extend(res[1])
  return res
})

let function onStartSessionResult(res) {
  if (res.error == 0)
    return

  log("Error on start session: ", res)
  showMsgbox({
    text = loc("msgbox/failedJoinRoom",
      { error = res?.accept == false ? loc(res?.reason ?? "") // server rejected invite
        : loc($"error/{error_string(res.error)}")
      })
  })
}

let function startSession() {
  if (isLocalDedicated.value && canStartWithLocalDedicated.value)
    startSessionWithLocalDedicated(onStartSessionResult)
  else
    matchingCall("mrooms.start_session",
      onStartSessionResult,
      { cluster = room.value?.public.cluster })
}

let function cancelSessionStart() {
  matchingCall("mrooms.cancel_session_start")
}

let mkDebugMembers = @(count) array(count).map(function(_, idx) {
  let campaign = chooseRandom((gameProfile.value?.campaigns ?? {}).keys())
  let rnd = rand()
  return {
    userId = rnd
    memberId = 1000 - idx
    name = $"WWWWWWWWWWWWWWW{rnd % 10}"
    nameText = $"WWWWWWWWWWWWWWW{rnd % 10}"
    squadNum = max(0, rnd % 10 - 4)
    public = {
      team = rnd % 2
      campaign
      army = chooseRandom(gameProfile.value?.campaigns[campaign].armies ?? [])?.id ?? ""
      isReady = (rnd % 2) == 1
      portrait = chooseRandom(portraits.keys())
      nickFrame = chooseRandom(nickFrames.keys())
      status = chooseRandom(memberStatuses.keys())
    }
  }
})

let function leaveRoomCb(response) {
  let err = response.error
  if (err != OK) {
    let errStr = error_string(err)
    showMsgbox({ text = loc("msgbox/failedLeaveRoom", {
      error = loc($"error/{errStr}", errStr)})
    })
  }}

let function doLeaveRoom() {
  leaveRoom(leaveRoomCb)
}


joinedRoomWithInvite.subscribe(function(v){
  if (!v)
    return

  local missingCampaign = null
  foreach (rCampaign in roomCampaigns.value)
    if (!unlockedCampaigns.value.contains(rCampaign))
      missingCampaign = rCampaign

  if (missingCampaign != null){
    doLeaveRoom()
    showMsgbox({ text = loc("msg/cantJoinHasLockedCampaign",
      { campaign = loc($"{missingCampaign}/full") }) })
    return
  }
  openEventModes()
})

console_register_command(
  @() debugMembers(debugMembers.value.len() > 0 ? [] : mkDebugMembers(rand() % 64)),
  "eventRooms.toggleDebugMembersMode")
console_register_command(@() debugMembers(mkDebugMembers(rand() % 64)),
  "eventRooms.regenerateDebugMembers")

return baseRoomState.__merge({
  roomScene
  roomCampaigns
  roomTeamArmies
  isEventRoom
  roomMembers
  isLocalDedicated

  startSession
  cancelSessionStart
})
