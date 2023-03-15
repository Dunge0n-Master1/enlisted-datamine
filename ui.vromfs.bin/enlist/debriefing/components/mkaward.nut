from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let mkBattleHeroAwardIcon = require("%enlSqGlob/ui/battleHeroAwardIcon.nut")
let { BattleHeroesAward } = require("%enlSqGlob/ui/battleHeroesAwards.nut")

let COUNT_VALUE_DELAY = 0.05

let function awardText(award) {
  let text = award?.id
    ? loc($"debriefing/awards/{award.id}/short", "")
    : ""
  return text.len()
    ? {
        rendObj = ROBJ_TEXT
        size = [flex(), SIZE_TO_CONTENT]
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        text
      }.__update(sub_txt)
    : null
}

let awardValue = @(awardWatch) @(){
  watch = awardWatch
  rendObj = ROBJ_BOX
  fillColor = Color(50, 50, 50)
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  borderWidth = 0
  borderRadius = hdpx(50)
  pos = [hdpx(15), 0]
  children = awardWatch.value != ""
    ?{
      rendObj = ROBJ_BOX
      fillColor = Color(179, 178, 146)
      size = [hdpx(50), hdpx(25)]
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      valign = ALIGN_CENTER
      borderWidth = 0
      borderRadius = hdpx(50)
      pos = [hdpx(2), -hdpx(2)]
      children = {
        rendObj = ROBJ_TEXT
        text = awardWatch.value
        color = Color(51,51,51)
      }.__update(body_txt)
    }
    : null
}

let function mkCountTimersData(award, hasAnim) {
  let value = award?.value
  let canCount = hasAnim && (typeof value == "integer" || typeof value == "float")
  if (!canCount)
    return {
      curVal = Watched(value)
      countTimer = @() null
    }
  let curVal = Watched("")
  local current = 0.0
  let target = value.tointeger()
  let function countTimer() {
    let step = max((2 * target - current) / 30.0, target / 50.0)
    current = min(current + step, target)
    curVal(current.tointeger().tostring())
    if (current < target)
      gui_scene.setTimeout(COUNT_VALUE_DELAY, countTimer)
  }
  return {
    curVal = curVal
    countTimer = countTimer
  }
}

let mkBattleHeroAward = kwarg(function(award, size = flex(), pauseTooltip = Watched(false)) {
  return mkBattleHeroAwardIcon(award, size, true/*isActive*/, true/*isBig*/).__update({
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(on && !pauseTooltip.value
      ? loc($"debriefing/award_{award.id}")
      : null)
  })
})

let mkStdAward = @(imagesList) kwarg(function(
  award, size = flex(), pauseTooltip = Watched(false), hasAnim = true, countDelay = 0
) {
  let countTimersData = mkCountTimersData(award, hasAnim)
  local wrapCompleteFlag = false
  return {
    size = size
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(on && !pauseTooltip.value
      ? loc($"debriefing/awards/{award.id}")
      : null)
    onAttach = function() {
      if (!wrapCompleteFlag) {
        wrapCompleteFlag = true
        gui_scene.setTimeout(COUNT_VALUE_DELAY + countDelay, countTimersData.countTimer)
      }
    }
    children = imagesList.map(@(img) {
      rendObj = ROBJ_IMAGE
      size = flex()
      keepAspect = KEEP_ASPECT_FIT
      image = Picture(img)
    }).append(
      awardText(award)
      awardValue(countTimersData.curVal)
    )
  }
})

let mkDefaultAward = mkStdAward(["ui/skin#awards/capture.avif"])

let awardsCfg = {
  kill = mkStdAward(["ui/skin#awards/debriefing_awards_kill.avif"])
  tankKill = mkStdAward(["ui/skin#awards/debriefing_awards_tankKill.avif"])
  planeKill = mkStdAward(["ui/skin#awards/debriefing_awards_planeKill.avif"])
  assists = mkStdAward(["ui/skin#awards/debriefing_awards_assists.avif"])
  headshot = mkStdAward(["ui/skin#awards/debriefing_awards_headshot.avif"])
  grenade_kill = mkStdAward(["ui/skin#awards/debriefing_awards_grenade_kills.avif"])
  melee_kill = mkStdAward(["ui/skin#awards/debriefing_awards_melee_kill.avif"])
  machinegunner_kill = mkStdAward(["ui/skin#awards/debriefing_awards_machinegunner_kill.avif"])
  long_range_kill = mkStdAward(["ui/skin#awards/debriefing_awards_long_range_kill.avif"])
  capture = mkStdAward(["ui/skin#awards/debriefing_awards_capture.avif"])
  double_kill = mkStdAward(["ui/skin#awards/debriefing_awards_double_kill.avif"])
  triple_kill = mkStdAward(["ui/skin#awards/debriefing_awards_triple_kill.avif"])
  multi_kill = mkStdAward(["ui/skin#awards/debriefing_awards_multi_kill.avif"])
  rifle_kills = mkStdAward(["ui/skin#awards/debriefing_awards_rifle_kills.avif"])
  machine_gun_kills = mkStdAward(["ui/skin#awards/debriefing_awards_machine_gun_kills.avif"])
  submachine_gun_kills = mkStdAward(["ui/skin#awards/debriefing_awards_submachine_gun_kills.avif"])
  assault_rifle_kills = mkStdAward(["ui/skin#awards/debriefing_awards_assault_rifle_kills.avif"])
  pistol_kills = mkStdAward(["ui/skin#awards/debriefing_awards_pistol_kills.avif"])
  semiauto_kills = mkStdAward(["ui/skin#awards/debriefing_awards_semiauto_kills.avif"])
  shotgun_kills = mkStdAward(["ui/skin#awards/debriefing_awards_shotgun_kills.avif"])
  launcher_kills = mkStdAward(["ui/skin#awards/debriefing_awards_launcher_kills.avif"])
  flamethrower_kills = mkStdAward(["ui/skin#awards/debriefing_awards_flamethrower_kills.avif"])
  car_driver_kills = mkStdAward(["ui/skin#awards/debriefing_awards_car_driver_kills.avif"])
  cannon_kills = mkStdAward(["ui/skin#awards/debriefing_awards_cannon_kills.avif"])
  mortar_kills = mkStdAward(["ui/skin#awards/debriefing_awards_mortar_kills.avif"])
  vehicle_mine_kills = mkStdAward(["ui/skin#awards/debriefing_awards_vehicle_mine_kills.avif"])
  infantry_mine_kills = mkStdAward(["ui/skin#awards/debriefing_awards_infantry_mine_kills.avif"])
  lunge_mine_kills = mkStdAward(["ui/skin#awards/debriefing_awards_infantry_lunge_mine_kills.avif"])
  ampulomet_kills = mkStdAward(["ui/skin#awards/debriefing_awards_ampulomet_kills.avif"])
  infantry_tnt_kills = mkStdAward(["ui/skin#awards/debriefing_awards_tnt_kills.avif"])
  artillery_kills = mkStdAward(["ui/skin#awards/debriefing_awards_artillery_kills.avif"])
  engineer_ammo_box_usage = mkStdAward(["ui/skin#awards/debriefing_awards_ammo_crate.avif"])
  infantry_bomb_kills = mkStdAward(["ui/skin#awards/debriefing_awards_bomb_kills.avif"])
  engineer_rally_point_usage = mkStdAward(["ui/skin#awards/debriefing_awards_spawn_1.avif"])
  infantry_antitank_mine_kills = mkStdAward(["ui/skin#awards/debriefing_awards_antipersonnel_mine_kill.avif"])
  first_blood = mkStdAward(["ui/skin#awards/debriefing_awards_first_blood.avif"])
  infantry_rocket_kills = mkStdAward(["ui/skin#awards/debriefing_awards_missile_kills.avif"])
  tank_commander_kills = mkStdAward(["ui/skin#awards/debriefing_awards_tank_commander_kills.avif"])
}
foreach (name in BattleHeroesAward)
  awardsCfg[name] <- mkBattleHeroAward

let function mkAward(options) {
  let ctor = awardsCfg?[options?.award.id] ?? mkDefaultAward
  return ctor(options, KWARG_NON_STRICT)
}

return {
  make = mkAward
  awardsCfg = awardsCfg
}
