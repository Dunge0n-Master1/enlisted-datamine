from "%enlSqGlob/ui_library.nut" import *

let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let { logerr } = require("dagor.debug")
let logAT = require("%enlSqGlob/library_logs.nut").with_prefix("[ARMY_LEVEL_TUTOR] ")
let { isGamepad } = require("%ui/control/active_controls.nut")
let {
  airSelectedBgColor, msgHighlightedTxtColor, bigPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { setTutorialConfig, finishTutorial, goToStep, isTutorialActive, nextStep, getTimeAfterStepStart
} = require("%enlist/tutorial/tutorialWndState.nut")
let { mkSizeTable, mkMessageCtorWithGamepadIcons, messageCtor, defMsgPadding
} = require("%enlist/tutorial/tutorialWndDefStyle.nut")
let { curArmyNextUnlockLevel, isArmyUnlocksStateVisible, readyToUnlockSquadId, unlockSquad,
  hasCampaignSection, levelWidth, squadGap
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let { isUnlockSquadSceneVisible, closeUnlockSquadScene, unlockSquadViewData
} = require("%enlist/soldiers/unlockSquadScene.nut")
let { armies } = require("%enlist/meta/profile.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { openChooseSquadsWnd, closeChooseSquadsWnd, applyAndClose, chosenSquads, reserveSquads,
  changeList, moveIndex, selectedSquadId, findLastIndexToTakeSquad
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let { mkHorizontalSlot } = require("%enlist/soldiers/chooseSquadsSlots.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { isInSquad } = require("%enlist/squad/squadManager.nut")
let { seenArmyProgress } = require("%enlist/soldiers/model/unseenArmyProgress.nut")


const LEVEL_TO_SHOW = 2

let needTutorial = Computed(function() {
  let hasOtherArmyLevel = null != armies.value.findvalue(@(armyData, armyId) armyId != curArmy.value
    && (armyData?.level ?? 0) >= LEVEL_TO_SHOW)
  return !hasOtherArmyLevel
    && curArmyNextUnlockLevel.value == LEVEL_TO_SHOW
    && readyToUnlockSquadId.value != null
    && !isInSquad.value
})

let canShowTutorialFromMainMenu = Computed(@() canDisplayOffers.value
  && hasCampaignSection.value
  && isCurCampaignProgressUnlocked.value
  && curArmy.value in seenArmyProgress.value?.unseen)

let showTutorial = keepref(Computed(@() needTutorial.value
  && (isArmyUnlocksStateVisible.value || canShowTutorialFromMainMenu.value)))

let newReceivedSquadId = Watched(null)

let function openSquadManage() {
  logAT("Open squad manage called")
  if (unlockSquadViewData.value == null) {
    logerr("Not opened unlockSquadScene on try to open squad manage")
    return
  }
  let { armyId, squadCfg } = unlockSquadViewData.value
  closeUnlockSquadScene()
  closeChooseSquadsWnd() //only for debug from the middle of tutorial. In the full tutorial it do nothing
  newReceivedSquadId(squadCfg.id)
  openChooseSquadsWnd(armyId, squadCfg.id, true)
}

let getSquadKey = @(squad, idx) squad == null ? $"empty_slot{idx}" : $"slot{squad.guid}{idx}"

let function moveReserveSquadToActive(idx) {
  let squadId = newReceivedSquadId.value ?? reserveSquads.value?[0].squadId
  if (chosenSquads.value?[idx] != null) {
    selectedSquadId(chosenSquads.value?[idx].squadId)
    changeList()
  }
  selectedSquadId(squadId)
  changeList()
}

let mkDropSquadSlot = @(box, idx, squad) mkSizeTable(box, {
  rendObj = ROBJ_SOLID,
  color = 0xF0000000
  children = squad == null ? null
    : [
        mkHorizontalSlot(squad.__merge({
          idx
          fixedSlots = chosenSquads.value.len()
          onClick = @() null
          onInfoCb = null
          onDropCb = @(_, __) null
        }), KWARG_NON_STRICT)
        {
          size = flex()
          rendObj = ROBJ_BOX
          borderWidth = hdpx(1)
        }
      ]
})

let mkDropTarget = @(box, onDrop) watchElemState(@(sf) mkSizeTable(box, {
  behavior = Behaviors.DragAndDrop
  onDrop

  rendObj = ROBJ_BOX
  fillColor = (sf & S_ACTIVE) != 0 ? airSelectedBgColor : 0
  borderWidth = hdpx(1)
}))

let function tryUnlockSquad() {
  if (readyToUnlockSquadId.value == null) {
    logerr($"Miss squad to unlock during tutorial.")
    finishTutorial()
    return false
  }
  unlockSquad(readyToUnlockSquadId.value)
  return true
}

let function startTutorial() {
  let chosenSquadsKeys = Computed(@() chosenSquads.value.map(getSquadKey))
  let reserveSquadsKeys = Computed(@() reserveSquads.value.map(
    @(s, idx) "guid" in s ? getSquadKey(s, idx + chosenSquads.value.len()) : null ))
  let newReceivedIdxInReserve = Computed(@() reserveSquads.value.findindex(@(s) s.squadId == newReceivedSquadId.value) ?? 0)
  let newReceivedKeyInReserve = Computed(@() reserveSquadsKeys.value?[newReceivedIdxInReserve.value])
  let newSquadIdx = Watched(-1)
  let newSquadKey = Computed(@() newSquadIdx.value < 0 ? null : getSquadKey(chosenSquads.value?[newSquadIdx.value], newSquadIdx.value))

  setTutorialConfig({
    id = "newSquadByArmyLevel"
    onStepStatus = @(stepId, status) logAT($"{stepId}: {status} (isUnlockSquadSceneOpened ? {unlockSquadViewData.value != null})")
    steps = [
      //*************************************************************
      //********************** Main menu window *********************
      //*************************************************************
      {
        id = "w0s1_check_campaign_rewards"
        nextStepAfter = isArmyUnlocksStateVisible
        text = loc("tutorial_open_rewards_window")
        objects = [{
          keys = ["section_SQUADS", "section_unseen_SQUADS"]
          sizeIncAdd = hdpx(5)
          onClick = jumpToArmyProgress
          needArrow = true
          hotkey = $"^{JB.A}"
        }]
      }
      {
        id = "w0s2_wait_rewards_opening"
        nextStepAfter = isArmyUnlocksStateVisible
        objects = []
      }


      //*************************************************************
      //******************** Army unlocks window ********************
      //*************************************************************
      {
        id = "w1s1_received_army_level"
        text = loc("tutorial_meta_start",
          { squadName  = colorize(msgHighlightedTxtColor,
              loc(squadsPresentation?[curArmy.value][readyToUnlockSquadId.value].titleLocId ?? "???"))
          })
        nextKeyDelay = -1
        textCtor = @(text, nextKeyAllowed, onNext) messageCtor(text, nextKeyAllowed, onNext,
          { size = [sw(95) - safeAreaBorders.value[3] - levelWidth - bigPadding
                      - squadGap - 2 * defMsgPadding[1], SIZE_TO_CONTENT] })
        objects = [
          { keys = ["squadReadyToUnlock" "squadReadyToUnlockButton"] }
          {
            keys = "squadReadyToUnlockButton"
            ctor = @(box) mkSizeTable(box, {
              behavior = Behaviors.Button
              function onClick() {
                if (tryUnlockSquad())
                  goToStep("w1s3_wait_for_get_squad")
                return true
              }
              hotkeys = [ ["^J:X", { description = { skip = true }, sound = "click"}] ]
            })
          }
        ]
      }
      {
        id = "w1s2_get_new_squad"
        text = loc("tutorial_meta_get_new_squad")
        objects = [{
          keys = "squadReadyToUnlockButton"
          onClick = @() !tryUnlockSquad()
          hotkey = "^J:X"
          needArrow = true
        }]
      }
      {
        id = "w1s3_wait_for_get_squad"
        nextStepAfter = isUnlockSquadSceneVisible
        text = loc("xbox/waitingMessage")
        function onSkip() {
          finishTutorial()
          return true
        }
        objects = [{ keys = "squadReadyToUnlock", onClick = @() true }]
      }

      //*******************************************************************
      //******************** new squad received window ********************
      //*******************************************************************

      {
        id = "w2s1_new_squad_received_window"
        objects = [
          { keys = "unlockSquadScene",
            function onClick() {
              if (getTimeAfterStepStart() > 3.0) //wait for animation finish.
                nextStep()
              return true
            }
          },
          {
            keys = "SquadManageBtnInSquadPromo"
            ctor = @(box) mkSizeTable(box, {
              behavior = Behaviors.Button
              function onClick() {
                openSquadManage()
                goToStep("w3s1_battle_squads_info")
                return true
              }
              hotkeys = [ ["^J:X", { description = { skip = true }, sound = "click"}] ]
            })
          }
        ]
      }
      {
        id = "w2s2_press_manage_squad_btn"
        text = loc("tutorial_meta_add_new_squad")
        objects = [{
          keys = "SquadManageBtnInSquadPromo"
          onClick = @() openSquadManage()
          hotkey = "^J:X"
          needArrow = true
        }]
      }


      //*************************************************************
      //******************** manage squad window ********************
      //*************************************************************
      {
        id = "w3s1_battle_squads_info"
        text = loc("tutorial_meta_squad_menu_intro_01")
        nextKeyDelay = -1
        objects = [{ keys = chosenSquadsKeys }]
      }
      {
        id = "w3s2_reserve_squads_info"
        text = loc("tutorial_meta_squad_menu_intro_02")
        nextKeyDelay = -1
        objects = [{ keys = reserveSquadsKeys }]
      }
      {
        id = "w3s3_change_squads_info"
        text = Computed(@() loc(isGamepad.value ? "tutorial_meta_squad_menu_how_to_change_gamepad"
          : "tutorial_meta_squad_menu_how_to_change_mouse"))
        textCtor = mkMessageCtorWithGamepadIcons(["J:LB", "J:RB"])
        nextKeyDelay = -1
        objects = [
          { keys = chosenSquadsKeys }
          { keys = Computed(@() ["dropToReserveSquad"].extend(reserveSquadsKeys.value)) }
          { keys = ["manageSquadsBtnUp", "manageSquadsBtnDown", "manageSquadsBtnLeft", "manageSquadsBtnRight"] }
        ]
      }
      {
        id = "w3s4_move_new_squad_to_active"
        text = Computed(@() loc("{0}/{1}".subst(
            isGamepad.value ? "tutorial_meta_squad_menu_choose_squad_by_gamepad" : "tutorial_meta_squad_menu_drag_squad",
            chosenSquads.value.findindex(@(s) s == null) == null ? "last" : "empty")))
        textCtor = mkMessageCtorWithGamepadIcons(["J:LB"])
        beforeStart = @() reserveSquads.value.len() == 0 ? null
          : newSquadIdx(findLastIndexToTakeSquad(reserveSquads.value[newReceivedIdxInReserve.value]))
        arrowLinks = [[0, 2], [1, 2]]
        objects = [
          //gamepad only
          { keys = Computed(@() isGamepad.value ? newReceivedKeyInReserve.value : null)
            hotkey = "^J:LB"
            function onClick() {
              moveReserveSquadToActive(newSquadIdx.value)
              defer(nextStep) //wait for scene update after change.
              return true
            }
          }
          //mouse only
          { keys = Computed(@() isGamepad.value ? null : newReceivedKeyInReserve.value)
            ctor = @(box) mkDropSquadSlot(box, chosenSquads.value.len(), reserveSquads.value?[newReceivedIdxInReserve.value])
          }
          //gamepad and mouse
          { keys = newSquadKey
            ctor = @(box) mkDropTarget(box,
              function onDrop(_) {
                moveReserveSquadToActive(newSquadIdx.value)
                gui_scene.setTimeout(0.1, nextStep) //wait for scene update after change.
              })
          }
        ]
      }
      {
        id = "w3s5_move_squad_to_first"
        text = loc("tutorial_meta_squad_menu_place_squad_1st")
        textCtor = mkMessageCtorWithGamepadIcons(["J:Y"])
        beforeStart = @() newSquadIdx.value > 0 ? null : defer(nextStep)
        arrowLinks = [[1, 2]]
        objects = [
          //gamepad only
          { keys = Computed(@() isGamepad.value ? newSquadKey.value : null)
            hotkey = "^J:Y"
            function onClick() {
              if (newSquadIdx.value > 0) {
                let idx = newSquadIdx.value
                newSquadIdx(idx - 1)
                chosenSquads(moveIndex(chosenSquads.value, idx, idx - 1))
              }
              return newSquadIdx.value > 0
            }
            needArrow = true
          }
          //mouse only
          { keys = Computed(@() isGamepad.value ? null : newSquadKey.value)
            ctor = @(box) mkDropSquadSlot(box, newSquadIdx.value, chosenSquads.value?[newSquadIdx.value])
          }
          {
            keys = Computed(@() isGamepad.value ? null : getSquadKey(chosenSquads.value?[0], 0))
            onClick = @() true
            ctor = @(box) mkDropTarget(box,
              function onDrop(_) {
                chosenSquads(moveIndex(chosenSquads.value, newSquadIdx.value, 0))
                nextStep()
              })
          }
        ]
        function onSkip() {
          if (newSquadIdx.value in chosenSquads.value) {
            chosenSquads(moveIndex(chosenSquads.value, newSquadIdx.value, 0))
            return false
          }
          finishTutorial()
          return true
        }
      }
      {
        id = "w3s6_show_result"
        beforeStart = @() gui_scene.setTimeout(1.0, nextStep)
        onFinish = @() gui_scene.clearTimer(nextStep)
        objects = [{ keys = Computed(@() getSquadKey(chosenSquads.value?[0], 0)) }]
      }
      {
        id = "w3s7_final"
        text = loc("tutorial_meta_squad_menu_leave")
        textCtor = mkMessageCtorWithGamepadIcons([JB.B])
        objects = [{ keys = "closeSquadsManage", hotkey = $"^{JB.B}", needArrow = true }]
        onFinish = applyAndClose
      }
    ]
  })
}

//wait for switch scene animation
let startTutorialDelayed = @()
  gui_scene.resetTimeout(0.3, function() {
    if (showTutorial.value && !isTutorialActive.value)
      startTutorial()
  })

startTutorialDelayed()
showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)

console_register_command(startTutorial, "tutorial.startArmyLevel")
