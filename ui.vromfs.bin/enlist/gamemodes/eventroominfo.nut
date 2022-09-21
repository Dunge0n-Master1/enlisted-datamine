from "%enlSqGlob/ui_library.nut" import *

let { format } = require("string")
let { unixtime_to_local_timetbl } = require("dagor.time")
let { txt, textArea, smallCampaignIcon, lockIcon, iconInBattle, iconPreparingBattle } = require("roomsPkg.nut")
let getPlayersCountInRoomText = require("getPlayersCountInRoomText.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  defTxtColor, titleTxtColor, smallPadding, bigPadding, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { clusterLoc } = require("%enlist/clusterState.nut")
let { selRoom } = require("eventRoomsListState.nut")
let getMissionInfo = require("getMissionInfo.nut")
let { isInRoom } = require("%enlist/mpRoom/enlRoomState.nut")
let {
  crossnetworkPlay, isCrossplayOptionNeeded, CrossplayState
} = require("%enlSqGlob/crossnetwork_state.nut")
let colorize = require("%ui/components/colorize.nut")


let textAreaOffset = hdpx(10)
let infoRowHeight = hdpx(40)
let headerTxtColor = 0xFF808080

let defTxtStyle = {
  color = defTxtColor
}.__update(sub_txt)

let headerTxtStyle = {
  color = headerTxtColor
}.__update(sub_txt)

let accentTxtStyle = {
  color = accentTitleTxtColor
}.__update(sub_txt)

const SHOW_MISSIONS_WHEN_HIDDEN = 3
const MAX_LENGTH_SHOW_ALL_MISSION = 5

let optLoc = @(v) v == null ? null : loc($"options/{v}", v)
let selRoomId = Computed(@() selRoom.value?.roomId)
let hTxt = @(text) {
    rendObj = ROBJ_TEXT
    text
  }.__update(headerTxtStyle)

let mkInfoTextRow = @(header, text) {
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = infoRowHeight
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      hTxt($"{header}:")
      txt(text).__update({ halign = ALIGN_RIGHT })
    ]
  }

let statusRow = @(icon, text){
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    icon
    {
      rendObj = ROBJ_TEXT
      text
    }.__update(defTxtStyle)
  ]
}

let mkRoomStatusRow = @(status) {
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = infoRowHeight
  valign = ALIGN_CENTER
  children = [
    hTxt($"{loc("options/roomStatus")}:")
    status == "launching" || status == "launched"
      ? statusRow(iconInBattle, loc("memberStatus/inBattle"))
      : statusRow(iconPreparingBattle, loc("lobby/preparationBattle"))
  ]
}

let mkShowMoreButton = @(count, cb) count <= 0 ? null
  : watchElemState(@(sf){
      rendObj = ROBJ_FRAME
      border = [0, 0, hdpx(1), 0]
      padding = [hdpx(2), 0, hdpx(2), 0]
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      flow = FLOW_HORIZONTAL
      margin = [ hdpx(10), 0]
      onClick = cb
      children = txt(loc("options/showMore", { count })).__update({
        halign = ALIGN_CENTER,
        color = sf & S_HOVER ? titleTxtColor : defTxtColor
      })
  })

let getBoolText = @(value) value ? loc("quickchat/yes") : loc("quickchat/no")

let mkMissionText = function(v) {
  let mCfg = getMissionInfo(v)
  let mName = loc(mCfg.locId)
  let mTypeLocId = mCfg.typeLocId
  let mLabel = mTypeLocId == null ? mName
    : loc("missionNameWithType", { mName, mType = loc(mTypeLocId) })
  return txt(mLabel).__update({ halign = ALIGN_RIGHT,
                                behavior = Behaviors.Marquee,
                                delay = 3.0
                                speed = 30 })
}

let isMissionsExpanded = Watched(false)
let toggleMissionsExpand = @() isMissionsExpanded(!isMissionsExpanded.value)

selRoomId.subscribe(@(_) isMissionsExpanded(false))

let function mkExpandedMissions(missions){
  if (missions.len() <= 0)
    return null
  let isOverflow = missions.len() >= MAX_LENGTH_SHOW_ALL_MISSION
  return function(){
    let sliceNumber = isMissionsExpanded.value && isOverflow
      ? missions.len()
      : SHOW_MISSIONS_WHEN_HIDDEN
    return {
      watch = isMissionsExpanded
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      padding = [bigPadding , 0]
      minHeight = infoRowHeight
      children = [hTxt($"{loc("options/missions")}:")]
        .extend(missions.slice(0, sliceNumber).map(mkMissionText)
        .append(mkShowMoreButton(missions.len() - sliceNumber, toggleMissionsExpand)))
    }
  }
}

let mkCampaignListItem = @(campaign) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  gap = hdpx(2)
  children = [
    smallCampaignIcon(campaign)
    txt(loc($"{campaign}/full"), SIZE_TO_CONTENT)
  ]
}

let mkCampaignList = @(campaigns) {
  size = [flex(), SIZE_TO_CONTENT]
  minHeight = infoRowHeight
  padding = [textAreaOffset, 0, 0, 0]
  children = [
    hTxt(loc("options/armyOfCampaign"))
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = campaigns.map(mkCampaignListItem)
    }
  ]
}

let function mkRoomCreateTime(room) {
  let tm = unixtime_to_local_timetbl(room?.cTime ?? 0)
  return {
    size = [flex(), SIZE_TO_CONTENT]
    minHeight = infoRowHeight
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      hTxt($"{loc("options/createTime")}:")
      !room?.isPrivate ? null
        : lockIcon.__merge({
            halign = ALIGN_RIGHT
          })
      txt(format("%02d:%02d", tm.hour, tm.min)).__update({ halign = ALIGN_RIGHT })
    ]
  }
}

let reducedXpWarning = textArea(loc("rooms/reducedXpNotEnoughPlayersWarning"),
  { color = titleTxtColor })
let modsXpWarning = textArea(loc("mods/econRules"), { color = titleTxtColor })
let modDescription = @(description) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [0,0, hdpx(20), 0]
  children = textArea(
    loc("mods/modDescription", { description = colorize(defTxtColor, description) }),
    { color = headerTxtColor }
  )
}

let mkModHeader = @(name, mode) {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = name
    }.__update(accentTxtStyle)
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = mode
    }.__update(defTxtStyle)
  ]
}

let function mkRoomInfo(room){
  let isMod = room?.scene == null
  return @(){
    watch = [crossnetworkPlay, isInRoom, isCrossplayOptionNeeded]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = [0, smallPadding]
    children = [
      isMod ? mkModHeader(room?.modName,  loc(room?.mode ?? "")) : null
      mkRoomCreateTime(room)
      isInRoom.value ? null : mkRoomStatusRow(room?.launcherState ?? "")
      mkInfoTextRow(loc("rooms/Creator"), room?.creatorText ?? "")
      mkInfoTextRow(loc("current_mode"), loc(room?.mode ?? ""))
      mkInfoTextRow(loc("options/difficulty"), optLoc(room?.difficulty))
      mkCampaignList(room?.campaigns ?? [])
      mkInfoTextRow(loc("options/teamArmies"), optLoc(room?.teamArmies))
      mkInfoTextRow(loc("rooms/PlayersInRoom"), getPlayersCountInRoomText(room))
      mkInfoTextRow(loc("options/botCount"), room?.botpop ?? 0)
      room?.crossplay != null && isCrossplayOptionNeeded.value && crossnetworkPlay.value != CrossplayState.OFF
        ? mkInfoTextRow(loc("options/crossplay"), loc($"option/crossplay/{room.crossplay}"))
        : null
      room?.voteToKick == null ? null
        : mkInfoTextRow(loc("options/voteToKick"), getBoolText(room?.voteToKick))
      mkInfoTextRow(loc("quickMatch/Server"), clusterLoc(room?.cluster ?? ""))
      isMod ? modDescription(room?.modDescription ?? "") : null
      mkExpandedMissions(room?.scenes ?? [])
      isMod ? modsXpWarning : reducedXpWarning
    ]
  }
}

let mkEventRoomInfo = @(room) makeVertScroll(mkRoomInfo(room), { styling = thinStyle })

let curEventRoomInfo = @(){
  watch = selRoomId
  size = flex()
  children = selRoomId.value == null
    ? txt(loc("noRoomSelected"))
      .__update({ halign = ALIGN_CENTER, vplace = ALIGN_CENTER })
    : @() {
        watch = selRoom
        size = flex()
        children = mkEventRoomInfo(selRoom.value)
      }
}

return {
  mkEventRoomInfo
  curEventRoomInfo
}