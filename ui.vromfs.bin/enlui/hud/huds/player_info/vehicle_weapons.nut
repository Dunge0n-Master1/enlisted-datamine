import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let {body_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let {HUD_TIPS_HOTKEY_FG, FAIL_TEXT_COLOR, DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let heroVehicleState = require("%ui/hud/state/vehicle_hp.nut").hero
let {vehicleTurrets, turretsReload, turretsAmmo, showVehicleWeapons} = require("%ui/hud/state/vehicle_turret_state.nut")
let { generation } = require("%ui/hud/menus/controls_state.nut")
let vehicleWeaponWidget = require("vehicle_weapon_widget.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let mkBulletTypeIcon = require("mkBulletTypeIcon.nut")
let {get_sync_time} = require("net")
let fa = require("%ui/components/fontawesome.map.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")

let healthBar = require("mk_health_bar.nut")
let { textListFromAction, buildElems } = require("%ui/control/formatInputBinding.nut")
let { mkShortHudHintFromList } = require("%ui/components/controlHudHint.nut")

let barWidth = sw(7)
let barHeight = fsh(1)
let barBlockHeight = hdpx(22)
let gap = hdpx(5)
let vehicleWeaponWidth = hdpx(425)

let mkControlText = @(text) {
  text,
  color = HUD_TIPS_HOTKEY_FG,
  rendObj = ROBJ_TEXT padding = hdpx(4)
}.__update(body_txt)

const eventTypeToText = false
let makeTurretControlTip = @(hotkey) function(){
  if (hotkey == null)
    return null
  let textList = textListFromAction(hotkey, isGamepad.value ? 1 : 0, eventTypeToText)
  let controlElems = buildElems(textList, { textFunc = mkControlText, compact = true })
  return mkShortHudHintFromList(controlElems, [generation])
}

let reloadProgressSize = fsh(4.0)
let reloadImg = Picture("ui/skin#round_border.svg:{0}:{0}:K".subst(reloadProgressSize.tointeger()))
let reloadMoreOne = freeze({
  size = [fontH(100), SIZE_TO_CONTENT]
  rendObj = ROBJ_INSCRIPTION
  font = fontawesome.font
  color = Color(255, 86, 86)
  text = fa["arrow-down"]
  fontSize = hdpx(10)
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
})
let reloadLessOne = freeze({
  size = [fontH(100), SIZE_TO_CONTENT]
  rendObj = ROBJ_INSCRIPTION
  font = fontawesome.font
  color = Color(86, 255, 86)
  text = fa["arrow-up"]
  fontSize = hdpx(10)
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
})

let mkReloadProgress = @(from, to, duration, key, mult) {
  margin = [0, 0, 0, hdpx(10)]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = reloadImg
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  size = [reloadProgressSize, reloadProgressSize]
  fValue = 0
  key
  children = [
    mult > 1.
      ? reloadMoreOne
      : mult < 1. ? reloadLessOne : null
  ]
  animations = [
    { prop = AnimProp.fValue, from, to, duration, play = true}
  ]
}

let triggerGroupTurretControlTips = ["Vehicle.Shoot", "Vehicle.ShootSecondary", "Vehicle.ShootMachinegun", "Vehicle.ShootGrenadeLauncher"]
let defaultTurretControlTips = ["Vehicle.Shoot", "Vehicle.ShootSecondary", "Vehicle.ShootMachinegun", "Vehicle.ShootTurret03"]

let function turretControlTip(turret, index) {
  let hotkey = turret?.hotkey
  let triggerGroup = turret?.triggerGroup ?? -1
  let gunEid = turret?.gunEid ?? ecs.INVALID_ENTITY_ID
  let turretReloadState = Computed(@() turretsReload.value?[gunEid] ?? {})

  return function() {
    let { progressStopped = -1, totalTime = -1, endTime = -1, reloadTimeMult = 1. } = turretReloadState.value
    let reloadTimeLeft = max(0, endTime - get_sync_time())
    let isReloadStopped = progressStopped >= 0
    let startProgress = isReloadStopped ? progressStopped
      : totalTime > 0 ? max(0, 1 - reloadTimeLeft / totalTime)
      : 0
    let endProgress = isReloadStopped ? progressStopped : 1
    let isReloading = endTime > 0
    return {
      watch = turretReloadState
      valign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = [
        isReloading ? mkReloadProgress(startProgress, endProgress, reloadTimeLeft, turretReloadState.value, reloadTimeMult)
                    : makeTurretControlTip(hotkey ?? (triggerGroup != -1
                      ? triggerGroupTurretControlTips[triggerGroup]
                      : defaultTurretControlTips?[index]))
      ]
    }
  }
}

let triggerGroupNextBulletTips = ["Vehicle.NextBulletType", "Vehicle.SecondaryNextBulletType"]
let function turretNextBulletTip(triggerGroup) {
  return makeTurretControlTip(triggerGroupNextBulletTips?[triggerGroup] ?? triggerGroupNextBulletTips[0])
}

let iconBlockWidth = hdpxi(230)
let function turretIconCtor(weapon, _baseWidth, baseHeight) {
  let width = iconBlockWidth
  let height = (0.8 * baseHeight).tointeger()
  let size = [width, height]
  let bulletIcon = mkBulletTypeIcon(weapon, size)
  return {
    size = size
    rendObj = ROBJ_IMAGE
    imageHalign = ALIGN_RIGHT
    imageValign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    margin = [0, hdpx(80), 0, 0]
    image = bulletIcon.image
    color = bulletIcon.color
    keepAspect = KEEP_ASPECT_FIT
  }
}

let function vehicleTurretBlock(turret, idx) {
  if (!turret.isControlled && !isReplay.value)
    return null

  if (!turret.isWithSeveralShells)
    return vehicleWeaponWidget({
      width = vehicleWeaponWidth
      weapon = turret.__merge({ instant = !turret.isReloadable, showZeroAmmo = true })
      hint = turretControlTip(turret, idx)
      iconCtor = turretIconCtor
      turretsAmmo
    })

  return function() {
    let activeAmmoSets = turret.ammoSet
      .map(@(ammoSet, setId) ammoSet.__merge({setId}))
      .filter(@(ammoSet) (ammoSet?.maxAmmo ?? 0) > 0)
    let ammoSetsCount = activeAmmoSets.len()
    let nextAmmoSetIndex = activeAmmoSets.findindex(@(set) set.setId == turret.nextAmmoSetId) ?? 0
    let switchToBulletIdx = activeAmmoSets[(nextAmmoSetIndex + 1) % max(ammoSetsCount, 1)].setId
    let children = activeAmmoSets.map(function(bt) {
      let setId = bt.setId
      let isCurrent = turret.currentAmmoSetId == setId
      let weapon = turret.__merge({
        isCurrent = isCurrent
        isNext = turret.nextAmmoSetId == setId
        name = $"{bt.type}/name/short"
        bulletType = bt.type
        setId
        instant = !isCurrent || !turret.isReloadable
      })
      return vehicleWeaponWidget({
        width = vehicleWeaponWidth
        height = hdpx(60)
        weapon = weapon
        hint = !turret.isControlled ? null
          : isCurrent ? turretControlTip(turret, idx)
          : setId == switchToBulletIdx ? turretNextBulletTip(turret?.triggerGroup)
          : null
        iconCtor = turretIconCtor
        turretsAmmo
      })
    })
    return {
      watch = [isGamepad]
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      gap = gap
      children = children
    }
  }
}

let mkFaIcon = @(faId, color) faComp(faId, {color, minHeight = fontH(100)})

let isBurn = Computed(@() heroVehicleState.value.isBurn)
let function vehicleHpEffects() {
  let res = { watch = isBurn }
  if (!isBurn.value)
    return res
  return res.__update(mkFaIcon("fire", FAIL_TEXT_COLOR))
}

let hitAnimTrigger = "vehicle_hit"
local lastVehicleData = null
let function saveLastVehicleData() {
  lastVehicleData = {
    vehicle = heroVehicleState.value.vehicle
    hp = heroVehicleState.value.hp
  }
}
saveLastVehicleData()
heroVehicleState.subscribe(function(v) {
  if (v.vehicle == lastVehicleData.vehicle && v.hp == lastVehicleData.hp)
    return
  if (v.vehicle == lastVehicleData.vehicle)
    anim_start(hitAnimTrigger)
  saveLastVehicleData()
})

let function vehicleHp() {
  let res = { watch = heroVehicleState }
  let { vehicle, hp, maxHp } = heroVehicleState.value
  if (vehicle == ecs.INVALID_ENTITY_ID)
    return res

  return res.__update({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gap
    children = [
      hp >= maxHp ? null : mkFaIcon("gear", DEFAULT_TEXT_COLOR)
      {
        size = [barWidth, barHeight]
        children = healthBar({ hp = heroVehicleState.value.hp, maxHp = heroVehicleState.value.maxHp,
          hitTrigger = hitAnimTrigger, colorFg = DEFAULT_TEXT_COLOR })
      }
    ]
  })
}

return function() {
  let turrets = showVehicleWeapons.value ? {
    flow = FLOW_VERTICAL
    gap = gap
    children = vehicleTurrets.value.map(vehicleTurretBlock)
  } : null

  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    gap = hdpx(30)
    size = SIZE_TO_CONTENT
    watch = [vehicleTurrets, showVehicleWeapons]

    children = [
      turrets
      {
        size = [SIZE_TO_CONTENT, barBlockHeight]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = gap
        children = [
          vehicleHpEffects
          vehicleHp
        ]
      }
    ]
  }
}