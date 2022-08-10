from "daRg" import *
from "%enlSqGlob/ui_library.nut" import hdpx, Computed, watchElemState, kwarg, loc

let {body_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let {BtnBgHover, BtnBgActive, ControlBgOpaque, TextHighlight, TextDefault, Active} = require("%ui/style/colors.nut")
let {buttonSound} = require("%ui/style/sounds.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let {isTouch} = require("%ui/control/active_controls.nut")

let fillColor = @(sf, active)
  !active ? ControlBgOpaque
  : (sf & S_HOVER) ? BtnBgHover
  : BtnBgActive

let spinnerLeftLoc = loc("spinner/prevValue", "Previous value")
let spinnerRightLoc = loc("spinner/nextValue", "Next value")

let mkSpinnerLine = @(sf, indexWatch, total, setValue, allValues, group) @() {
  watch = indexWatch
  size = flex()
  gap = hdpx(4)
  padding = [hdpx(2), hdpx(4), hdpx(2), 0]
  margin = [0, 0, hdpx(4), 0]
  group
  flow = FLOW_HORIZONTAL
  children = sf & S_HOVER ? array(total).map(@(_, idx) {
    size = flex()
    valign = ALIGN_BOTTOM
    children = {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(4)]
      color = indexWatch.value != idx ? ControlBgOpaque
        : sf & S_HOVER ? TextHighlight
        : TextDefault
    }
    skipDirPadNav = true
    behavior = Behaviors.Button
    onClick = @() setValue(allValues[idx])
    }) : null
}

let mkSpinnerBtn = @(isEnabled, icon, action)
  watchElemState(@(sf){
    rendObj = ROBJ_BOX
    watch = isEnabled
    borderWidth = (sf & S_HOVER) && isEnabled.value ? hdpx(2) : 0
    sound = buttonSound
    borderColor = BtnBgHover
    borderRadius = hdpx(2)
    behavior = Behaviors.Button
    onClick = @() isEnabled.value ? action() : null
    padding = [0, hdpx(10)]
    vplace = ALIGN_CENTER
    skipDirPadNav = true
    children = {
      rendObj = ROBJ_INSCRIPTION
      text = icon
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      color = fillColor(sf, isEnabled.value)
     }.__update(fontawesome, {fontSize = hdpx(35)})
   }
  )

local spinner = kwarg(function(curValue, allValues, setValue = null,
  valToString = null, xmbNode= null, group = null, isEqual = null, stateFlags = null
) {
  setValue = setValue ?? @(v) curValue(v)
  valToString = valToString ?? @(v) v
  let valuesCount = max(allValues.len(), 1)
  let maxIdx = valuesCount - 1
  let curIdx = Computed(@() isEqual != null
    ? allValues.findindex(@(value) isEqual(value, curValue.value))
    : allValues.indexof(curValue.value))

  let isLeftBtnEnabled = Computed(@() curIdx.value != null && curIdx.value > 0)
  let isRightBtnEnabled = Computed(@() curIdx.value != null && curIdx.value < maxIdx)
  let function leftBtnAction() { if (isLeftBtnEnabled.value) setValue(allValues[curIdx.value - 1]) }
  let function rightBtnAction() { if (isRightBtnEnabled.value) setValue(allValues[curIdx.value + 1]) }

  let hotkeysElem = @(){
    watch = [isLeftBtnEnabled, isRightBtnEnabled]
    key = $"hotkeys{isLeftBtnEnabled.value}{isRightBtnEnabled.value}"
    hotkeys = [
      ["Left | J:D.Left",
        { action = leftBtnAction, sound = buttonSound,
          description = isLeftBtnEnabled.value ? spinnerLeftLoc : { skip = true }
        }
      ],
      ["Right | J:D.Right",
        { action = rightBtnAction, sound = buttonSound,
          description = isRightBtnEnabled.value ? spinnerRightLoc : { skip = true }
        }
      ]
    ]
  }

  let labelText = @() {
    watch = curValue
    behavior = Behaviors.Marquee
    rendObj = ROBJ_TEXT
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    text = valToString(curValue.value)
    color = Active
    size = flex()
    scrollOnHover = true
    clipChildren = true
    group
  }.__update(body_txt)

  let buttons = {
    flow = FLOW_HORIZONTAL
    size = SIZE_TO_CONTENT
    vplace = ALIGN_CENTER
    gap = hdpx(5)
    children = [
      mkSpinnerBtn(isLeftBtnEnabled, fa["angle-left"], leftBtnAction)
      mkSpinnerBtn(isRightBtnEnabled, fa["angle-right"], rightBtnAction)
    ]
  }

  return watchElemState(@(sf) {
      behavior = Behaviors.Button
      watch = curIdx
      xmbNode
      group
      eventPassThrough = isTouch.value
      size = flex()
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = flex()
          children = [
            labelText
            mkSpinnerLine(sf, curIdx, valuesCount, setValue, allValues,  group)
          ]
        }
        buttons
        sf & S_HOVER ? hotkeysElem : null
      ]
    }, {stateFlags})
})



return spinner