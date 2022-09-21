from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { decorators } = require("%enlist/meta/profile.nut")
let {
  decoratorsPresentation
} = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let {
  add_decorator, add_all_decorators, choose_decorator,
  buy_decorator
} = require("%enlist/meta/clientApi.nut")


const EXPIRED_TEXT_TIME = 3

let decoratorInPurchase = Watched(null)

let ownDecorators = Watched({})
let decoratorsCfg = Computed(@() configs.value?.decoratorsCfg ?? {})

let nextExpireTime = Computed(function() {
  local time = 0
  foreach (decorator in ownDecorators.value) {
    let { expireTime = 0 } = decorator
    if (expireTime > 0)
      time = time == 0 ? expireTime : min(time, expireTime)
  }
  return time
})

let function recalcActiveDecorators() {
  let time = serverTime.value
  let res = decorators.value.filter(@(d) d.expireTime == 0 || (d.expireTime - time) > 0)
  ownDecorators(freeze(res))
}

nextExpireTime.subscribe(function(v) {
  let timeLeft = v - serverTime.value
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft + EXPIRED_TEXT_TIME, recalcActiveDecorators)
})

decorators.subscribe(@(_) recalcActiveDecorators())
recalcActiveDecorators()

let decoratorsCfgByType = Computed(function() {
  let res = {}
  foreach (guid, decoratorCfg in decoratorsCfg.value) {
    let {
      cType, weight = 0, isNotOwnedHidden = false, buyData = null
    } = decoratorCfg
    if (cType not in res)
      res[cType] <- {}
    let presentation = decoratorsPresentation?[cType][guid] ?? {}
    res[cType][guid] <- { guid, weight, isNotOwnedHidden, buyData }
      .__update(presentation)
  }
  return res
})

let decoratorsListByType = Computed(@()
  decoratorsCfgByType.value.map(@(v) v.values()))

let availDecoratorsByType = Computed(function() {
  let decorsCfg = decoratorsCfg.value
  let res = {}
  foreach (guid, decorator in ownDecorators.value) {
    let cType = decorsCfg?[guid].cType
    if (cType == null)
      continue

    if (cType not in res)
      res[cType] <- {}

    res[cType][guid] <- decorator
  }
  return res
})

let portraitsConfig = Computed(@() decoratorsListByType.value?.portrait ?? [])
let nickFramesConfig = Computed(@() decoratorsListByType.value?.nickFrame ?? [])

let availPortraits = Computed(@() availDecoratorsByType.value?.portrait ?? {})
let availNickFrames = Computed(@() availDecoratorsByType.value?.nickFrame ?? {})

let sortDecorators = @(a, b, avail)
  b.guid in avail <=> a.guid in avail
    || a.weight <=> b.weight
    || b.guid <=> a.guid

let portraitCfgAvailable = Computed(function() {
  let avail = availPortraits.value
  return portraitsConfig.value
    .filter(@(p) !p.isNotOwnedHidden || p.guid in avail)
    .sort(@(a, b) sortDecorators(a, b, avail))
})

let nickFramesCfgAvailable = Computed(function() {
  let avail = availNickFrames.value
  return nickFramesConfig.value
    .filter(@(p) !p.isNotOwnedHidden || p.guid in avail)
    .sort(@(a, b) sortDecorators(a, b, avail))
})

let chosenPortrait = Computed(@() availPortraits.value.findvalue(@(v) v.hasChosen))
let chosenNickFrame = Computed(@() availNickFrames.value.findvalue(@(v) v.hasChosen))

let function chooseDecorator(cType, guid) {
  choose_decorator(cType, guid)
}

let function buyDecorator(guid, cost) {
  if (decoratorInPurchase.value != null)
    return

  decoratorInPurchase(guid)
  buy_decorator(guid, cost, function(_) {
    decoratorInPurchase(null)
  })
}

console_register_command(@(guid) add_decorator(guid), "meta.addDecorator")
console_register_command(@() add_all_decorators(), "meta.addAllDecorators")

return {
  decoratorsCfgByType
  portraitsConfig
  nickFramesConfig
  availPortraits
  availNickFrames
  portraitCfgAvailable
  nickFramesCfgAvailable
  chosenPortrait
  chosenNickFrame
  chooseDecorator
  buyDecorator
  decoratorInPurchase
  nextExpireTime
}
