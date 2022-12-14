from "%enlSqGlob/ui_library.nut" import *

let { isMainMenuVisible } = require("%enlist/mainMenu/sectionsState.nut")
let { isProfileOpened } = require("profileState.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { showMessageWithContent } = require("%enlist/components/msgbox.nut")
let { decorators, medals, wallposters, vehDecorators } = require("%enlist/meta/profile.nut")
let { mkMedalCard } = require("medalsPkg.nut")
let { medalsCfg } = require("medalsState.nut")
let { mkPortraitIcon, mkNickFrame, PORTRAIT_SIZE
} = require("decoratorPkg.nut")
let { decoratorsCfgByType } = require("decoratorState.nut")
let { bigPadding, titleTxtColor, tinyOffset, idleBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  mark_decorators_as_seen, mark_medals_as_seen, mark_wallposters_as_seen,
  mark_veh_decorators_as_seen
} = require("%enlist/meta/clientApi.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { specialUnlockToReceive } = require("%enlist/unlocks/dailyRewardsState.nut")
let { activeUnlocks } = require("%enlSqGlob/userstats/unlocksState.nut")
let { wallpostersCfg } = require("wallpostersState.nut")
let { mkWallposter } = require("wallpostersPkg.nut")
let { mkDecalImage, mkDecorImage } = require("%enlist/vehicles/customizePkg.nut")


let unseenSize = [fsh(80), fsh(50)]

let unseenProfileStuffs = Computed(function() {
  let medalsConfig = medalsCfg.value
  let decoratorsList = decorators.value.filter(@(d) !(d?.wasSeen ?? false))
  let { portrait = {}, nickFrame = {} } = decoratorsCfgByType.value

  let portraits = decoratorsList
    .filter(@(d) d.guid in portrait)
    .map(@(p) p.__merge(portrait?[p.guid] ?? {}))
    .values()
  let nickFrames = decoratorsList
    .filter(@(d) d.guid in nickFrame)
    .map(@(n) n.__merge(nickFrame?[n.guid] ?? {}))
    .values()

  if (portraits.len() > 0 || nickFrames.len() > 0)
    return { portraits, nickFrames }

  let unseenMedals = medals.value
    .filter(@(d) !(d?.wasSeen ?? false))
    .map(@(m) m.__merge(medalsConfig?[m.id] ?? {}))
    .values()
    .sort(@(a,b) (b?.weight ?? 0) <=> (a?.weight ?? 0))

  if (unseenMedals.len() > 0)
    return { unseenMedals }

  let unseenWallposters = wallposters.value
    .filter(@(w) !(w?.wasSeen ?? false))
    .values()

  if (unseenWallposters.len() > 0)
    return { unseenWallposters }

  let vehDecors = vehDecorators.value
    .filter(@(d) !(d?.wasSeen ?? false) && d?.cType != "vehCamouflage")
    .values()

  return vehDecors.len() > 0 ? { vehDecors } : null
})

let unseenTitles = {
  portraits = "unseenPortraitsTitle"
  nickFrames = "unseenNickFramesTitle"
  vehDecors = "unseenVehDecorsTitle"
  medals = "unseenMedalsTitle"
  wallposters = "unseenWallpostersTitle"
}

let function mkUnseenBlock(uType, children = null) {
  let specialUnlockHeader =
    activeUnlocks.value?[specialUnlockToReceive.value].meta.congratulationLangId ?? ""
  return @(){
    watch = [activeUnlocks, specialUnlockToReceive]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = tinyOffset
    halign = ALIGN_CENTER
    children = [
      specialUnlockHeader == "" ? null : {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(specialUnlockHeader)
        halign = ALIGN_CENTER
        color = titleTxtColor
        onDetach = @() specialUnlockToReceive(null)
      }.__update(body_txt)
      txt({
        text = loc(unseenTitles?[uType] ?? "")
        color = titleTxtColor
      }).__update(body_txt)
    ].append(children)
  }
}

let wrapParams = {
  width = unseenSize[0]
  halign = ALIGN_CENTER
  hGap = bigPadding
  vGap = bigPadding
}

let withWrap = @(children) wrap(children, wrapParams)

let vehDecorOverride = { iconSize = PORTRAIT_SIZE - 2 * bigPadding }

let mkVehDecors = @(vehDecors)
  vehDecors.map(function(vehDecor) {
    let { cType, id } = vehDecor
    let iconCtor = cType == "vehDecorator" ? mkDecorImage : mkDecalImage
    return {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = [PORTRAIT_SIZE, PORTRAIT_SIZE]
      padding = bigPadding
      borderColor = idleBgColor
      children = iconCtor({ guid = id }, vehDecorOverride)
    }
  })

let mkPortraits = @(portraits) portraits.map(@(portraitCfg) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  size = [PORTRAIT_SIZE, PORTRAIT_SIZE]
  borderColor = idleBgColor
  children = mkPortraitIcon(portraitCfg)
})

let mkNickFrames = @(nickFrames) nickFrames.map(@(nickFrameCfg)
  mkNickFrame(nickFrameCfg))

let mkMedals = @(unseenMedals) unseenMedals.map(function(medal) {
  let { bgImage = null, stackImages = [] } = medal
  return mkMedalCard(bgImage, stackImages, PORTRAIT_SIZE)
})

let mkWallposters = @(unseenWallposters, wpCfgs) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = unseenWallposters.map(function(wallposter) {
    let wpCfg = wpCfgs.findvalue(@(wp) wp.id == wallposter.tpl)
    return wpCfg == null ? null : mkWallposter(wpCfg)
  })
}

let function markSeen() {
  let {
    portraits = [], nickFrames = [], vehDecors = [], unseenMedals = [],
    unseenWallposters = []
  } = unseenProfileStuffs.value

  let decoratorsList = portraits.map(@(v) v.guid)
    .extend(nickFrames.map(@(v) v.guid))
  if (decoratorsList.len() > 0)
    mark_decorators_as_seen(decoratorsList)

  let vehDecorsList = vehDecors.map(@(v) v.guid)
  if (vehDecorsList.len() > 0)
    mark_veh_decorators_as_seen(vehDecorsList)

  let medalsList = unseenMedals.map(@(v) v.guid)
  if (medalsList.len() > 0)
    mark_medals_as_seen(medalsList)

  let wallpostersList = unseenWallposters.map(@(wp) wp.guid)
  if (wallpostersList.len() > 0)
    mark_wallposters_as_seen(wallpostersList)
}

let mkUnseenContent = @(portraits, nickFrames, vehDecors, unseenMedals, unseenWallposters, vplace = ALIGN_TOP) {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = tinyOffset
  vplace
  children = [
    portraits.len() == 0 ? null
      : mkUnseenBlock("portraits", withWrap(mkPortraits(portraits)))
    nickFrames.len() == 0 ? null
      : mkUnseenBlock("nickFrames", withWrap(mkNickFrames(nickFrames)))
    vehDecors.len() == 0 ? null
      : mkUnseenBlock("vehDecors", withWrap(mkVehDecors(vehDecors)))
    unseenMedals.len() == 0 ? null
      : mkUnseenBlock("medals", withWrap(mkMedals(unseenMedals)))
    unseenWallposters.len() == 0 ? null
      : function() {
          let wpCfgs = wallpostersCfg.value
          return {
            watch = wallpostersCfg
            size = [flex(), SIZE_TO_CONTENT]
            children = mkUnseenBlock("wallposters", mkWallposters(unseenWallposters, wpCfgs))
          }
        }
  ]
}

let canShowUnseenStuffs = keepref(Computed(@()
  isMainMenuVisible.value || isProfileOpened.value
))

let function checkShowUnseenStuffs(_ = null) {
  let canShow = canShowUnseenStuffs.value
  let unseen = unseenProfileStuffs.value
  if (!canShow || unseen == null)
    return

  showMessageWithContent({
    uid = "unseenProfileMsgbox"
    content = function() {
      let {
        portraits = [], nickFrames = [], vehDecors = [], unseenMedals = [],
        unseenWallposters = []
      } = unseen
      let total = portraits.len() + nickFrames.len() + unseenMedals.len() + vehDecors.len()
      let hasScroll = total > (unseenSize[0] / PORTRAIT_SIZE) * 2
        || (unseenWallposters.len() > 2)
      return {
        watch = unseenProfileStuffs
        size = hasScroll ? unseenSize : [unseenSize[0], SIZE_TO_CONTENT]
        children = hasScroll
          ? makeVertScroll(mkUnseenContent(portraits, nickFrames, vehDecors, unseenMedals, unseenWallposters),
              { styling = thinStyle })
          : mkUnseenContent(portraits, nickFrames, vehDecors, unseenMedals, unseenWallposters, ALIGN_CENTER)
      }
    }
    buttons = [{
      text = loc("Ok"), isCurrent = true, isCancel = true, action = markSeen
    }]
  })
}

foreach (v in [canShowUnseenStuffs, unseenProfileStuffs])
  v.subscribe(checkShowUnseenStuffs)

checkShowUnseenStuffs()
