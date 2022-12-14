from "%enlSqGlob/ui_library.nut" import *

let isNewbie = require("%enlist/unlocks/isNewbie.nut")
let { hasCampaignPromo } = require("%enlist/featureFlags.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { hasMsgBoxes } = require("%enlist/components/msgbox.nut")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let { hasArmyProgressOpened } = require("%enlist/mainMenu/sectionsState.nut")
let { hasSeenGetUnlockTutorial } = require("%enlist/tutorial/notReceivedUnlockTutorial.nut")
let { Transp } = require("%ui/components/textButton.nut")


const SEEN_ID = "seen/promoUrl"
const PROMO_NAME = "Enlisted_progression_short_LQ_v10"
const WND_UID = "promoView"


let suffixByLanguage = {
  Russian = "_RU"
}

let promoUrl = $"content/video/{PROMO_NAME}{suffixByLanguage?[gameLanguage] ?? ""}.ivf"

let seen = Computed(@() settings.value?[SEEN_ID])

let reqPromoView = keepref(Computed(function() {
  if (!isLoggedIn.value
    || !hasCampaignPromo.value
    || !onlineSettingUpdated.value
    || !hasSeenGetUnlockTutorial.value
    || !hasArmyProgressOpened.value
    || isNewbie.value
    || hasMsgBoxes.value)
    return false

  return seen.value != PROMO_NAME
}))

let function markPromoSeen() {
  settings.mutate(function(set) {
    set[SEEN_ID] <- PROMO_NAME
  })
}

let hasSkipButton = Watched(false)
let hasPromoFinished = Watched(false)

let bgObject = {
  size = flex()
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 1.5, play = true }]
}

let promoBlock = {
  key = WND_UID
  size = flex()
  valign = ALIGN_CENTER
  children = [
    bgObject
    {
      size = flex()
      rendObj = ROBJ_MOVIE
      keepAspect = KEEP_ASPECT_FIT
      movie = promoUrl
      behavior = Behaviors.Movie
      loop = false
      function onFinish() {
        hasPromoFinished(true)
      }
    }
    @() {
      watch = hasPromoFinished
      size = flex()
      children = !hasPromoFinished.value ? null : bgObject
    }
    @() {
      watch = hasSkipButton
      size = flex()
      children = !hasSkipButton.value ? null
        : Transp(loc("btn/skip"), markPromoSeen, {
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            margin = hdpx(60)
            animations = [
              { prop = AnimProp.opacity, from = 0, to = 1, duration = 2.5, play = true }
            ]
          })
    }
  ]
  onClick = @() null
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 1, playFadeOut = true }
  ]
}

hasPromoFinished.subscribe(function(hasFinished) {
  if (hasFinished)
    gui_scene.resetTimeout(2, markPromoSeen)
})

reqPromoView.subscribe(function(isVisible) {
  if (isVisible) {
    hasSkipButton(false)
    hasPromoFinished(false)
    addModalWindow(promoBlock)
    gui_scene.resetTimeout(5, @() hasSkipButton(true))
  }
  else
    removeModalWindow(WND_UID)
})

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      delete s[SEEN_ID]
  })
}, "meta.resetSeenPromo")
