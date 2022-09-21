from "%enlSqGlob/ui_library.nut" import *

let { h1_txt, h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")
let {showBriefingForTime, showBriefing, briefingState} = require("%ui/hud/state/briefingState.nut")
let {localPlayerTeamInfo, localPlayerTeamIcon} = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let mkTeamIcon = require("%ui/hud/components/teamIcon.nut")
let {tokenizeTextWithShortcuts, makeHintsRows, controlView} = require("%ui/components/templateControls.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")
let textarea = require("%ui/components/textarea.nut").smallTextarea
let {dtext} = require("%ui/components/text.nut")
let {isAlive} = require("%ui/hud/state/health_state.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { strokeStyle } = require("%enlSqGlob/ui/viewConst.nut")

let teamIcon = mkTeamIcon(localPlayerTeamIcon)
let showGoalAuto = Watched(false)
let showGoal = showBriefing

let function hideGoalAfterTime() {
  if ((showBriefingForTime.value ?? 0) > 0){
    showBriefingForTime(null)
    showGoalAuto(false)
    showGoal(false)
  }
}

showGoal.subscribe(function(v){
  if (v)
    return
  showGoalAuto(false)
  showBriefingForTime(null)
})

let function briefingText(briefing, teamInfo) {
  local team_briefing = teamInfo?["team__briefing"]
  if (team_briefing==null || team_briefing == "")
    team_briefing = briefing?["briefing_common"]
  return team_briefing
}

let function isBriefingEmpty(briefing, teamInfo){
  let team_briefing = briefingText(briefing, teamInfo)
  return ((team_briefing==null || team_briefing=="") && (briefing?.common == null || briefing?.common == ""))
}

let function setShow() {
  showGoalAuto(true)
  showGoal(true)
}

let hasGoals = Computed(@() !isBriefingEmpty(briefingState.value, localPlayerTeamInfo.value))

showBriefingForTime.subscribe(function(value){
  if (value==null || value <=0)
    return
  if (!hasGoals.value || !isTutorial.value)
    return
  gui_scene.clearTimer(setShow)
  gui_scene.clearTimer(hideGoalAfterTime)
  gui_scene.setTimeout(0.5, setShow)
  gui_scene.setTimeout(value+0.5, hideGoalAfterTime)
})

let showBrief = Computed(@() showGoal.value || showGoalAuto.value)

isAlive.subscribe(function(live){
  if (live)
    showGoal(false)
})
let lightgray = Color(180,180,180,180)

let hintSrcState = Computed(@() loc(briefingState.value?.hints ?? ""))
let hintsTokensState = Computed(@() tokenizeTextWithShortcuts(hintSrcState.value))


let kbCloseKey = "Esc"
let gpCloseKey = JB.B
let closeMenuKey ="^{0} | {1}".subst(gpCloseKey, kbCloseKey)

let function closeHint() {
  let closeKey = controlView([isGamepad.value ? gpCloseKey : kbCloseKey])
  return closeKey!=null ? {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      closeKey
      dtext(loc("briefing/close"))
    ]
  } : null
}

let hintsBlock = @(hintsHeader, hintsTokens) @() {
  watch = isGamepad
  size = flex()
  color = lightgray
  flow = FLOW_VERTICAL
  gap = hdpx(2)
  children = [
    hintsHeader!=null ? dtext(loc(hintsHeader), { halign = ALIGN_CENTER, margin = [0, 0, fsh(2), 0] }) : null
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(2)
      children = makeHintsRows(hintsTokens)
    }
  ]
}

let isEmpty = Computed(@() !hasGoals.value && !hintsTokensState.value.len())

let emptyBriefing = {
  size = flex()
  flow = FLOW_VERTICAL
  children = { size=flex() halign=ALIGN_CENTER valign=ALIGN_CENTER children=dtext(loc("No briefing available")) }
}

let function goalsBriefing(){
  let briefing = briefingState.value
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = fsh(2)
    watch = [localPlayerTeamInfo, briefingState]
    children = [
      {size = [flex(), SIZE_TO_CONTENT] flow=FLOW_HORIZONTAL valign=ALIGN_CENTER gap=fsh(1)
        children = [
          teamIcon
          {size=flex() maxWidth=hdpx(10)}
          dtext(loc(briefing?.header), { size = [flex(), SIZE_TO_CONTENT] }.__update(h2_txt))
          {size=flex()}
        ]
      },
      textarea(loc(briefingText(briefing, localPlayerTeamInfo.value)), {color=lightgray}.__update(body_txt)),
      dtext(loc(briefing?.common_header), {halign=ALIGN_CENTER}.__update(body_txt)),
      type(briefing?.common) == "string" ? textarea( loc(briefing.common), { size=[flex(),fsh(10)], halign=ALIGN_LEFT color=lightgray}.__update(sub_txt)) : null
    ]
  }
}
let mainBlock = @() {
  watch = [isEmpty, hasGoals]
  size = flex()
  children = isEmpty.value
    ? emptyBriefing
    : hasGoals.value
      ? goalsBriefing
      : null
}

let function briefingComp() {
  let briefing = briefingState.value
  let hints = hintsTokensState.value.len() ? hintsBlock(briefing?.hints_header, hintsTokensState.value) : null

  return {
    size = [fsh(hasGoals.value ? 110 : 80), fsh(72)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color (120,120,120,255)
    flow = FLOW_VERTICAL
    padding = [fsh(2), fsh(4)]
    gap = fsh(2)
    hotkeys = [[closeMenuKey, @() showGoal.update(false)]]
    watch = [ hintsTokensState, hasGoals, briefingState]
    halign = ALIGN_CENTER
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = fsh(7)
        children = [
          mainBlock
          hints
        ]
      }
      closeHint
    ]
  }
}

let missionTitle = @() {
  watch = [missionName, missionType]
  rendObj = ROBJ_TEXT
  text = loc(missionName.value, { mission_type = loc($"missionType/{missionType.value}") })
}.__update(h1_txt, strokeStyle)

let titledBriefing = {
  flow = FLOW_VERTICAL
  gap = fsh(2)
  children = [
    missionTitle
    briefingComp
  ]
}

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true, easing = OutQuintic }
  { prop = AnimProp.scale, from =[0.5, 0.5], play = true, to = [1, 1], duration = 0.15, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.15, playFadeOut = true, easing = InQuintic }
  { prop = AnimProp.scale, from =[1, 1], playFadeOut = true, to = [1.2, 1.2], duration = 0.15, easing = InQuad }
]

let function briefingUi() {
  return {
    key = "briefing"
    size = flex()
    halign = ALIGN_CENTER
    transform = {}
    animations = animations
    valign = ALIGN_CENTER
    children = showBrief.value ? titledBriefing : null
    watch = [localPlayerTeam, showBrief, briefingState, localPlayerTeamInfo]
    hotkeys = [[closeMenuKey, {
        action = @() showGoal(false)
        description =loc("Close")
        inputPassive = true
      }]]
  }
}

return briefingUi
