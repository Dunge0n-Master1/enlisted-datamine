from "%enlSqGlob/ui_library.nut" import *
from "roomMemberStatuses.nut" import *
let { logerr } = require("dagor.debug")
let { debounce } = require("%sqstd/timers.nut")
let { deep_clone } = require("%sqstd/underscore.nut")
let { appId } = require("%enlSqGlob/clientState.nut")
let {
  roomIsLobby, setMemberAttributes, room, isEventRoom, roomCampaigns, roomTeamArmies,
  roomMembers, doConnectToHostOnHostNotfy, canOperateRoom, isInRoom, lobbyStatus, LobbyStatus
} = require("enlRoomState.nut")
let { curArmy, mteam, setRoomArmy } = require("%enlist/soldiers/model/state.nut")
let { curCampaign, setRoomCampaign } = require("%enlist/meta/curCampaign.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { chosenPortrait, chosenNickFrame } = require("%enlist/profile/decoratorState.nut")
let { isInDebriefing } = require("%enlist/debriefing/debriefingStateInMenu.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let getMissionInfo = require("%enlist/gameModes/getMissionInfo.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")


let keysToDropReady = ["mode", "difficulty", "campaigns", "teamArmies", "scenes"]

let curTeam = mkWatched(persist, "curTeam", 0)
let myCampaign = mkWatched(persist, "myCampaign", null)
let myArmy = mkWatched(persist, "myArmy", "")
let hasBalanceCheckedByEntrance = Watched(false)
let isPrevCampaignNotAvailible = mkWatched(persist, "isPrevCampaignNotAvailible", false)
let lastPlayedSessionId = mkWatched(persist, "lastPlayedSessionId", -1)
let isReady = doConnectToHostOnHostNotfy //really it value need to be always the same atm. But need better name.
mteam.subscribe(@(v) isEventRoom.value ? null : curTeam(v))
myCampaign.subscribe(@(c) isInRoom.value ? setRoomCampaign(c) : null)
curCampaign.subscribe(@(c) !isInRoom.value ? myCampaign(c) : null)
myArmy.subscribe(@(a) isInRoom.value ? setRoomArmy(a) : null)
curArmy.subscribe(@(a) !isInRoom.value ? myArmy(a) : null)

let method = @(_) isReady(canOperateRoom.value)
foreach (v in [canOperateRoom, isInDebriefing])
  v.subscribe(method)

let myRoomPublic = Computed(@() !isEventRoom.value
  ? { appId = appId.value
      team = curTeam.value
    }
  : { appId = appId.value
      team = curTeam.value
      campaign = myCampaign.value
      army = myArmy.value
      isReady = isReady.value
      portrait = chosenPortrait.value?.guid
      nickFrame = chosenNickFrame.value?.guid
      status = isInBattleState.value ? IN_BATTLE.id
        : isInDebriefing.value ? IN_DEBRIEFING.id
        : isReady.value ? IN_LOBBY_READY.id
        : IN_LOBBY_NOT_READY.id
    })

let function updateMyPublic() {
  if (roomIsLobby.value)
    setMemberAttributes({ public = myRoomPublic.value })

  if (myRoomPublic.value?.status == IN_BATTLE.id && (room.value?.public.sessionId ?? 0) > 0)
    lastPlayedSessionId(room.value?.public.sessionId)
}
let updateMyPublicDebounced = debounce(updateMyPublic, 0.1)
myRoomPublic.subscribe(@(_) updateMyPublicDebounced())

isInRoom.subscribe(function(is) {
  isReady(canOperateRoom.value || !(roomIsLobby.value && isEventRoom.value))
  updateMyPublicDebounced()

  if (!is) {
    setRoomCampaign(null)
    setRoomArmy(null)
    myArmy(curArmy.value)
    myCampaign(curCampaign.value)
  }
})


local lastRoomPublic = deep_clone(room.value?.public)


let function setMyCampaign(campaign) {
  if (campaign == myCampaign.value || !roomCampaigns.value.contains(campaign))
    return
  local team = curTeam.value
  local armyId = (roomTeamArmies.value?[team] ?? [])
    .findvalue(@(a) gameProfile.value?.campaignByArmyId[a] == campaign)
  if (armyId == null) {
    team = 1 - team
    armyId = (roomTeamArmies.value?[team] ?? [])
      .findvalue(@(a) gameProfile.value?.campaignByArmyId[a] == campaign)
  }
  if (armyId == null) {
    log("Room team armies: ", roomTeamArmies.value)
    logerr($"Try to choose campaign {campaign} which is in the campaigns list, but no armies for such campaign.")
    return
  }
  curTeam(team)
  myCampaign(campaign)
  myArmy(armyId)
}

let function setMyArmy(armyId) {
  if (armyId == myArmy.value)
    return
  let campaign = gameProfile.value?.campaignByArmyId[armyId]
  if (!roomCampaigns.value.contains(campaign))
    return
  local team = curTeam.value
  if (!(roomTeamArmies.value?[team].contains(armyId) ?? false))
    team = (roomTeamArmies.value?[1 - team].contains(armyId) ?? false) ? 1 - team
      : null
  if (team == null)
    return
  curTeam(team)
  myCampaign(campaign)
  myArmy(armyId)
}

let function setReady(ready) {
  if (canOperateRoom.value) //always ready
    return
  if (!ready) {
    isReady(ready)
    return
  }

  let { campaigns = [] } = room.value?.public
  let lockedCampaign = campaigns.findvalue(@(c) !unlockedCampaigns.value.contains(c))
    ?? (room.value?.public.scenes ?? []).findvalue(@(s) !unlockedCampaigns.value.contains(getMissionInfo(s).campaign))
  if (lockedCampaign != null) {
    showMsgbox({ text = loc("msg/cantReadyHasLockedCampaign", { campaign = loc($"{lockedCampaign}/full") }) })
    return
  }

  //todo: disbalance messages here
  isReady(ready)
}

let function setMyTeam(team) {
  if (team == curTeam.value)
    return

  setReady(false)

  local armyId = myArmy.value
  if (roomTeamArmies.value?[team].contains(armyId) ?? false) {
    curTeam(team)
    return
  }

  let campaign = gameProfile.value?.campaignByArmyId[armyId]
  let { armies = [] } = gameProfile.value?.campaigns[campaign]
  armyId = armies.findvalue(@(a) roomTeamArmies.value?[team].contains(a.id))?.id
    ?? roomTeamArmies.value?[team][0]
  if (armyId == null)
    return
  curTeam(team)
  myArmy(armyId)
  myCampaign(gameProfile.value?.campaignByArmyId[armyId])
}

let hasPlayedCurSession = Computed(function(){
  let { GameInProgress, GameInProgressNoLaunched } = LobbyStatus
  return (room.value?.public.sessionId ?? 0) == lastPlayedSessionId.value
    && (lobbyStatus.value == GameInProgress || lobbyStatus.value == GameInProgressNoLaunched)
  })

isInBattleState.subscribe(function(v){
  if (!v && room.value?.public.sessionId != null && !canOperateRoom.value)
    isReady(false)
})

let canChangeTeam = Computed(function(){
  let maxPlayersByTeam = (room.value?.public.maxPlayers ?? 0) / 2
  let currentTeam = curTeam.value
  let teamToJoin = 1 - currentTeam
  let doesTeamToJoinExists = teamToJoin in roomTeamArmies.value
  let members = roomMembers.value ?? []
  let playersInTeam = members.filter(@(player) player.public?.team == teamToJoin)
  return doesTeamToJoinExists && playersInTeam.len() < maxPlayersByTeam && !hasPlayedCurSession.value
})

let function teamSelectAfterEntrance(){
  let members = roomMembers.value ?? []
  let playersInTeam0 = members.reduce(@(sum, player) sum + (player?.public.team == 0 ? 1 : 0), 0)
  let playersInTeam1 = members.reduce(@(sum, player) sum + (player?.public.team == 1 ? 1 : 0), 0)
  let teamToSelect = playersInTeam0 > playersInTeam1 ? 1 : 0
  setMyTeam(teamToSelect)
  hasBalanceCheckedByEntrance(true)
}

let function onRoomChanged() {
  let isFirstConnectToRoom = lastRoomPublic == null
  let needDropReady = null != keysToDropReady.findindex(@(key) !isEqual(lastRoomPublic?[key], room.value?.public[key]))
  lastRoomPublic = deep_clone(room.value?.public)
  if (!roomIsLobby.value || room.value == null)
    return
  if (!isEventRoom.value) {
    updateMyPublic()
    return
  }

  if (needDropReady)
    isReady(canOperateRoom.value)

  let isCampaignValidForCurRoom = roomCampaigns.value.contains(myCampaign.value)
  if (!isCampaignValidForCurRoom && (roomCampaigns.value.len() > 1 && isFirstConnectToRoom))
    isPrevCampaignNotAvailible(true)

  let campaign = isCampaignValidForCurRoom ? myCampaign.value : roomCampaigns.value?[0]
  let campArmies = gameProfile.value?.campaigns[campaign].armies
  if (campArmies == null)
    return //wait for valid params

  myCampaign(campaign)
  setRoomCampaign(campaign)

  local armyId = campArmies.findvalue(@(aData) aData.id == myArmy.value)?.id
  if (armyId != null)
    if (!(roomTeamArmies.value?[curTeam.value].contains(armyId) ?? false))
      if (roomTeamArmies.value?[1 - curTeam.value].contains(armyId) ?? false)
        curTeam(1- curTeam.value)
      else
        armyId = null

  myArmy(armyId ?? roomTeamArmies.value?[curTeam.value][0])
  setRoomArmy(myArmy.value)

  if (!hasBalanceCheckedByEntrance.value)
    teamSelectAfterEntrance()

  if (!isFirstConnectToRoom && !canOperateRoom.value && !isCampaignValidForCurRoom)
    showMsgbox({
      text = loc("lobbyMsg/playerCampaignHasChanged")
      buttons = [{ text = loc("Ok"), action = @() anim_start("campaign_blink") }]
    })
}

let onRoomChangedDebounced = debounce(onRoomChanged, 0.01)
foreach (w in [room, roomIsLobby, isEventRoom, roomCampaigns, roomTeamArmies])
  w.subscribe(@(_) onRoomChangedDebounced())

return {
  myRoomPublic
  curTeam
  myCampaign
  myArmy
  setMyArmy
  setMyTeam
  setMyCampaign
  canChangeTeam
  isReady = Computed(@() isReady.value)
  setReady
  hasBalanceCheckedByEntrance
  isPrevCampaignNotAvailible
  hasPlayedCurSession
}