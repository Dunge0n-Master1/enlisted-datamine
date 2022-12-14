from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { friendsOnlineUids, requestsToMeUids } = require("%enlist/contacts/contactsWatchLists.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { fastAccessIconHeight, defTxtColor, hoverTxtColor, accentColor
} = require("%enlSqGlob/ui/designConst.nut")

let accentStyle = { color = accentColor }.__update(fontSmall)
let advancedIconPos = [fastAccessIconHeight / 3, fastAccessIconHeight / 2]


let counterText = @(counterWatch, overrride = {}) function() {
  let number = counterWatch.value.len()
  return {
    watch = counterWatch
    rendObj = ROBJ_TEXT
    text = number <= 0 ? null : number
  }.__update(accentStyle, overrride)}


let onlineFriendsCounter = counterText(friendsOnlineUids, { pos = advancedIconPos })
let invitationsCounter = counterText(requestsToMeUids, {
  pos = advancedIconPos
  vplace = ALIGN_BOTTOM
})

let contactsButton = @(onClick) {
  size = [fastAccessIconHeight, fastAccessIconHeight]
  halign = ALIGN_RIGHT
  children = [
    watchElemState(@(sf) {
      rendObj = ROBJ_IMAGE
      size = [fastAccessIconHeight, fastAccessIconHeight]
      image = Picture("ui/skin#fastAccessIcons/team_icon.svg:{0}:{0}:K"
        .subst(fastAccessIconHeight))
      color = sf & S_HOVER ? hoverTxtColor : defTxtColor
      behavior = Behaviors.Button
      onClick
      onHover = @(on) setTooltip(on ? loc("tooltips/contactsButton") : null)
    })
    onlineFriendsCounter
    invitationsCounter
  ]
}

return contactsButton
