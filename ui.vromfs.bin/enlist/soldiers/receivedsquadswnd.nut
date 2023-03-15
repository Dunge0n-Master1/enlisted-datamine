from "%enlSqGlob/ui_library.nut" import *

let closeBtnBase = require("%ui/components/closeBtn.nut")
let colorize = require("%ui/components/colorize.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { openUnlockSquadScene } = require("%enlist/soldiers/unlockSquadScene.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { bigPadding, smallPadding, tinyOffset, smallOffset, blurBgColor,
  defBgColor, activeTxtColor, accentTitleTxtColor, disabledTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")


const WND_UID = "received_squads"
const SQUADS_PER_LINE = 2

let receivedData = Watched(null)
let hasSquadsPromoOpened = Watched(false)

let squadSlotWidth = hdpx(500)
let squadImageSize = [hdpx(160), hdpx(120)]

let closeButton = closeBtnBase({ onClick = @() receivedData(null) })

let mkImage = @(img, override = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  keepAspect = KEEP_ASPECT_FIT
  image = Picture(img)
}.__update(override)

let function mkSquad(squadCfg) {
  let { image, nameLocId, titleLocId } = squadCfg
  let title = "{0}\n{1}".subst(loc(nameLocId),
    colorize(accentTitleTxtColor, loc(titleLocId)))
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    padding = smallPadding
    color = defBgColor
    children = [
      mkImage(image, { size = squadImageSize })
      noteTextArea(title)
        .__update({
          padding = smallPadding
          color = activeTxtColor
        }, sub_txt)
    ]
  }
}

let squadViewStyle = {
  unlockInfo = null
  isNewSquad = true
}

let curSquadStyle = {
  rendObj = ROBJ_SOLID
  color = Color(20,20,20,20)
}

let function receivedSquadsUi() {
  let res = { watch = [gameProfile, receivedData, curCampaign] }
  let squadsByArmy = receivedData.value
  if (squadsByArmy == null)
    return res

  let curCampId = curCampaign.value
  let campaigns = (gameProfile.value?.campaigns ?? {})
    .map(@(campaignData, id) {
      id
      title = campaignData.title
      armies = campaignData.armies
    })
    .values()
    .sort(@(a,b) (b.id == curCampId) <=> (a.id == curCampId) || a.id <=> b.id)

  let squadsBlock = []
  foreach (campaign in campaigns) {
    let isCurrent = campaign.id == curCampId
    local campaignSquads = []
    foreach (army in campaign.armies)
      if (army.id in squadsByArmy) {
        let squadsList = squadsByArmy[army.id]
        foreach (squad in squadsList) {
          let squadData = squad.__merge(squadViewStyle)
          let squadCfg = squadData.squadCfg
          let onClick = isCurrent
            ? function() {
                openUnlockSquadScene(squadData, KWARG_NON_STRICT)
                receivedData(null)
              }
            : null
          campaignSquads.append(watchElemState(@(sf) {
            size = [squadSlotWidth, SIZE_TO_CONTENT]
            behavior = isCurrent ? Behaviors.Button : null
            onClick
            children = [
              mkSquad(squadCfg)
              {
                rendObj = ROBJ_BOX
                size = flex()
                borderWidth = sf & S_HOVER ? hdpx(1) : 0
                borderColor = disabledTxtColor
              }
              sf & S_HOVER ? txt({
                text = utf8ToUpper(loc("btn/view"))
                padding = bigPadding
                hplace = ALIGN_RIGHT
                vplace = ALIGN_BOTTOM
                color = activeTxtColor
              }) : null
            ]
          }))
        }
      }

    if (campaignSquads.len() > 0) {
      let headerTxt = "{0} {1}".subst(loc(campaign.title),
        isCurrent ? colorize(accentTitleTxtColor, loc("currentCampaign")) : "")
      campaignSquads = arrayByRows(campaignSquads, SQUADS_PER_LINE)
        .map(@(list) {
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = list
        })
      squadsBlock.append({
        flow = FLOW_VERTICAL
        gap = smallPadding
        padding = bigPadding
        children = [
          noteTextArea(headerTxt).__update({ color = activeTxtColor }, body_txt)
          campaignSquads.len() == 1
            ? campaignSquads[0]
            : {
                flow = FLOW_VERTICAL
                gap = bigPadding
                children = campaignSquads
              }
        ]
      }.__update(isCurrent ? curSquadStyle : {}))
    }
  }

  return res.__update({
    flow = FLOW_VERTICAL
    gap = smallOffset
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          txt({
            text = utf8ToUpper(loc("squad/gotNewSquads"))
            hplace = ALIGN_CENTER
            color = activeTxtColor
          }).__update(body_txt)
          closeButton
        ]
      }
      {
        flow = FLOW_VERTICAL
        gap = tinyOffset
        children = squadsBlock
      }
    ]
  })
}

let close = @() removeModalWindow(WND_UID)

let open = @() addModalWindow({
  rendObj = ROBJ_WORLD_BLUR_PANEL
  key = WND_UID
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = blurBgColor
  onClick = @() null
  onAttach = @() hasSquadsPromoOpened(true)
  onDetach = @() hasSquadsPromoOpened(false)
  children = receivedSquadsUi
})

receivedData.subscribe(function(v) {
  if (v != null)
    open()
  else
    close()
})

return {
  openSquadsPromo = @(data) receivedData(data)
  hasSquadsPromoOpened
}
