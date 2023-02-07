from "%enlSqGlob/ui_library.nut" import *

let { endswith } = require("string")
let colorize = require("%ui/components/colorize.nut")
let icon3dByGameTemplate = require("%enlSqGlob/ui/icon3dByGameTemplate.nut")
let { portraits, nickFrames } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { medalsPresentation } = require("%enlist/profile/medalsPresentation.nut")
let { accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")


let rewardBgSizePx = [170, 210]
let rewardWidthToHeight = rewardBgSizePx[0].tofloat() / rewardBgSizePx[1]

let mkSizeByParent = @(size) [pw(100.0 * size[0] / rewardBgSizePx[0]), ph(100.0 * size[1] / rewardBgSizePx[1])]
let mkImageParams = @(pxSize, pxOffset = [0, 12]) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  size = mkSizeByParent(pxSize)
  pos = mkSizeByParent(pxOffset)
}

let calcSize = @(pxSize, sizeBg) [
  (pxSize[0].tofloat() / rewardBgSizePx[0] * sizeBg[0]).tointeger(),
  (pxSize[1].tofloat() / rewardBgSizePx[1] * sizeBg[1]).tointeger()
]

let mkImageCtor = @(pxSize, pxOffset, image) function(sizeBg) {
  let size = calcSize(pxSize, sizeBg)
  let img = endswith(image,".svg")
    ? $"{image}:{size[0]}:{size[1]}:F"
    : image
  return {
    size
    pos = mkSizeByParent(pxOffset)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture(img)
  }
}

let mkTemplateImageCtor = @(pxSize, pxOffset, gametemplate, genOverride = {}) function(sizeBg) {
  let size = calcSize(pxSize, sizeBg)
  return icon3dByGameTemplate(gametemplate, {
    width = size[0]
    height = size[1]
    pos = mkSizeByParent(pxOffset)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    genOverride
  })
}


let function mkReward(reward, pName = "") {
  let { decorators = [] } = reward
  if (decorators.len() > 0) {
    let viewDecorator = decorators[0]
    let { guid, lifeTime = 0 } = viewDecorator
    let isTemporary = lifeTime > 0
    let lifeTimeText = !isTemporary ? ""
      : colorize(accentTitleTxtColor, loc("issuedFor", {
          timeTxt = secondsToHoursLoc(lifeTime)
        }))

    if (guid in portraits) {
      let { icon, name = null, bgimg = ""} = portraits[guid]
      return {
        bgImage = bgimg
        isTemporary
        name = loc(name ?? "portrait/baseName")
        description = "\n".join([ loc("decorator/baseDesc"), lifeTimeText ], true)
        stackImages = [
          {
            img = icon
            params = {
              size = mkSizeByParent([170, 210])
              hplace = ALIGN_CENTER
              vplace = ALIGN_CENTER
            }
          }
        ]
      }
    }
    if (guid in nickFrames){
      let cfg = nickFrames[guid]
      return {
        name = loc("nickFrames/baseName", { nick = cfg(pName) })
        isTemporary
        description = "\n".join([ loc("decorator/baseDesc"), lifeTimeText ], true)
        cardText = cfg("")
      }
    }
  }

  let { medals = [] } = reward
  if (medals.len() > 0) {
    let medal = medalsPresentation?[medals[0]]
    return medal == null ? null
      : {
          name = loc(medal.name)
          bgImage = medal.bgImage
          stackImages = medal.stackImages
        }
  }
  return null
}

let defRewardPresentation = {
  cardImage = "ui/skin#rewards/crate_small_1.png"
  cardImageParams = mkImageParams([240, 240])
}

let rewardsPresentation = {
  ["9"] = {
    name = loc("items/weapon_order")
    description = loc("items/weapon_order/battlepass_desc")
    icon = "ui/skin#/currency/weapon_order.svg"
    gametemplate = "weapons_supply_ticket_bronze"
    worth = 0.5
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/silver_weapons.png"
    cardImageParams = mkImageParams([142, 170], [0, 17])
  },
  ["10"] = {
    name = loc("items/soldier_order")
    description = loc("items/soldier_order/battlepass_desc")
    icon = "ui/skin#/currency/soldier_order.svg"
    gametemplate = "soldiers_supply_ticket_bronze"
    worth = 0.5
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/silver_soldier.png"
    cardImageParams = mkImageParams([160, 178])
  },
  ["11"] = {
    name = loc("items/weapon_order_silver")
    description = loc("items/weapon_order_silver/battlepass_desc")
    icon = "ui/skin#/currency/weapon_order_silver.svg"
    gametemplate = "weapons_supply_ticket_silver"
    worth = 1
    bgImage = "ui/skin#/battlepass/bg_silver.png"
    cardImage = "ui/skin#/battlepass/silver_weapons.png"
    cardImageParams = mkImageParams([142, 170], [0, 17])
  },
  ["12"] = {
    name = loc("items/soldier_order_silver")
    description = loc("items/soldier_order_silver/battlepass_desc")
    icon = "ui/skin#/currency/soldier_order_silver.svg"
    gametemplate = "soldiers_supply_ticket_silver"
    worth = 1
    bgImage = "ui/skin#/battlepass/bg_silver.png"
    cardImage = "ui/skin#/battlepass/silver_soldier.png"
    cardImageParams = mkImageParams([160, 178])
  },
  ["13"] = {
    name = loc("items/weapon_order_gold")
    description = loc("items/weapon_order_gold/battlepass_desc")
    icon = "ui/skin#/currency/weapon_order_gold.svg"
    gametemplate = "weapons_supply_ticket_gold"
    worth = 3
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/gold_weapons.png"
    cardImageParams = mkImageParams([144, 170], [0, 17])
    specialRewards = {
      [9] = {
        normandy_allies = "lanchester_model_1"
        normandy_axis = "coenders_mp"
        berlin_allies = "lad_mg"
        berlin_axis = "coenders_mp"
        moscow_allies = "ppsh_40"
        moscow_axis = "mkb_42_w"
        tunisia_allies = "lanchester_model_1"
        tunisia_axis = "scotti_model_x"
        stalingrad_allies = "ppsh_40"
        stalingrad_axis = "mkb_42_w"
        pacific_allies = "lanchester_model_1"
        pacific_axis = "nambu_type_1_early_smg"
      }
    }
  },
  ["14"] = {
    name = loc("items/soldier_order_gold")
    description = loc("items/soldier_order_gold/battlepass_desc")
    icon = "ui/skin#/currency/soldier_order_gold.svg"
    gametemplate = "soldiers_supply_ticket_gold"
    worth = 3
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/gold_soldier.png"
    cardImageParams = mkImageParams([162, 178], [0, 12])
  },
  ["23"] = {
    name = loc("items/random_battlepass_order_crate")
    description = loc("items/random_battlepass_order_crate/desc")
    icon = "ui/skin#/currency/random_battlepass_order.svg"
    gametemplate = "random_battlepass_order"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/random.png"
    cardImageParams = mkImageParams([144, 122])
  },
  ["30"] = {
    name = loc("items/soldier_reward")
    icon = "ui/skin#/events/soldier_reward_icon.svg"
    worth = 3
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/gold_soldier.png"
    cardImageParams = mkImageParams([162, 178])
  },
  ["EnlistedGold"] = {
    name = loc("currency/code/EnlistedGold")
    icon = "ui/skin#currency/enlisted_gold.svg"
    gametemplate = "item_ecoin"
    worth = 10
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/gold_coins.png"
    cardImageParams = mkImageParams([166, 136], [0, -4])
  },
  ["31"] = {
    name = loc("items/vehicle_with_skin_order_gold")
    description = loc("items/vehicle_with_skin_order_gold/desc")
    icon = "ui/skin#/currency/vehicle_with_skin.svg"
    gametemplate = "vehicle_with_skin_supply_ticket_gold"
    worth = 3
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/gold_vehicles.png"
    cardImageParams = mkImageParams([170, 174], [0, -2])
  },
  ["33"] = {
    name = loc("items/research_change_order")
    description = loc("items/research_change_order/desc")
    icon = "ui/skin#/currency/squad_respec.svg"
    gametemplate = "research_change_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/reset_xp.png"
    cardImageParams = mkImageParams([146, 148])
  },
  ["34"] = {
    name = loc("items/item_upgrade_order")
    description = loc("items/item_upgrade_order/desc")
    icon = "ui/skin#/currency/item_upgrade.svg"
    gametemplate = "item_upgrade_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/up_weapons.png"
    cardImageParams = mkImageParams([180, 131], [0, 1])
  },
  ["35"] = {
    name = loc("items/soldier_levelup_order")
    description = loc("items/soldier_levelup_order/desc")
    icon = "!ui/uiskin/currency/soldier_levelup.svg"
    gametemplate = "soldier_level_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/up_soldier.png"
    cardImageParams = mkImageParams([172, 142], [-2, 4])
  },
  ["36"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["37"] = {
    name = loc("items/callname_change_order")
    description = loc("items/callname_change_order/desc")
    icon = "ui/skin#/currency/soldier_name_change.svg"
    gametemplate = "callname_change_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/rename.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["38"] = {
    name = loc("items/appearance_change_order")
    description = loc("items/appearance_change_order/desc")
    icon = "ui/skin#/currency/soldier_appearance.svg"
    gametemplate = "appearance_change_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/makeup.png"
    cardImageParams = mkImageParams([162, 148], [0, 18])
  },
  ["40"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg") //432 * 600
  },
  ["41"] = {
    name = loc("vehicleDetails/fw_189a_1")
    description = loc("items/fw_189a_1/desc")
    icon = "ui/skin#/aircraft_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkTemplateImageCtor([190, 190], [0, 18], "fw_189a1", { iconRoll = 50, iconYaw = -35 })
  },
  ["42"] = {
    name = loc("vehicleDetails/us_m5a1_stuart_rhino_event_premium")
    description = loc("items/us_m5a1_stuart_rhino_event_premium/desc")
    icon = "ui/skin#/tank_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkTemplateImageCtor([170, 150], [0, 12], "us_m5a1_stuart_rhino_event_premium")
  },
  ["43"] = {
    name = loc("squad/ussr_berlin_event_assault_1")
    description = loc("squadannounce/ussr_berlin_event_assault_1")
    icon = "ui/skin#/research/squad_points_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([120, 111], [-4, 28], "!ui/soldiers/ussr/ussr_berlin_event_assault_1_icon.svg") //600 * 555
  },
  ["45"] = defRewardPresentation.__merge({
    name = loc("smallTrophyTitle_1")
  }),
  ["49"] = {
    name = loc("items/battlepass_buster_1")
    description = loc("items/battlepass_buster_1/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_1_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["50"] = {
    name = loc("items/battlepass_buster_3")
    description = loc("items/battlepass_buster_3/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_3_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["186"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["187"] = {
    name = loc("items/battlepass_buster_soldier_3")
    description = loc("items/battlepass_buster_soldier_3/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_soldier_3_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_soldier.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["188"] = {
    name = loc("items/battlepass_buster_squad_5")
    description = loc("items/battlepass_buster_squad_5/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_squad_5_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_squad.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["179"] = {
    name = loc("squad/allies_tunisia_event_mgun_1")
    description = loc("squadannounce/allies_tunisia_event_mgun_1")
    icon = "ui/skin#/research/squad_points_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([120, 111], [-4, 28], "!ui/soldiers/usa/allies_tunisia_event_mgun_1_icon.svg") //600 * 555
  },
  ["180"] = {
    name = loc("items/tunisia_axis_hero_marathon_2021_autumn")
    description = loc("items/tunisia_axis_hero_marathon_2021_autumn/desc")
    icon = "ui/squads/germany/italy_hero_medal_1_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/squads/germany/italy_hero_medal_1_icon.svg")
  },
  ["181"] = {
    name = loc("items/p_47d_22_re")
    description = loc("items/p_47d_22_re/desc")
    icon = "ui/skin#/aircraft_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkTemplateImageCtor([190, 190], [0, 18], "p_47d_22_re_joan_premium", { iconRoll = 50, iconYaw = -35 })
  },
  ["182"] = {
    name = loc("items/germ_jgdpz_iv_l48")
    description = loc("items/germ_jgdpz_iv_l48/desc")
    icon = "ui/skin#/tank_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkTemplateImageCtor([170, 150], [0, 12], "germ_panzerjager_IV_L_48_berlin_premium")
  },
  ["189"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["190"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["191"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["192"] = {
    name = loc("items/marathon_2021_summer_order")
    description = loc("items/marathon_2021_summer_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["209"] = {
    name = loc("wp/agit_poster_china_a_preview/name")
    description = loc("wp/agit_poster_china_a_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["210"] = {
    name = loc("items/battlepass_buster_50_3")
    description = loc("items/battlepass_buster_50_3/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_50_3_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["211"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_5"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["212"] = {
    name = loc("items/booster_30_battle_1")
    description = loc("items/booster_30_battle_1/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_1_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["213"] = {
    name = loc("items/engineer_event_reward_moscow_allies")
    description = loc("items/engineer_event_reward_moscow_allies/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["214"] = {
    name = loc("items/engineer_event_reward_moscow_axis")
    description = loc("items/engineer_event_reward_moscow_axis/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["215"] = {
    name = loc("items/engineer_event_reward_normandy_allies")
    description = loc("items/engineer_event_reward_normandy_allies/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["216"] = {
    name = loc("items/engineer_event_reward_normandy_axis")
    description = loc("items/engineer_event_reward_normandy_axis/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["217"] = {
    name = loc("items/engineer_event_reward_berlin_allies")
    description = loc("items/engineer_event_reward_berlin_allies/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["218"] = {
    name = loc("items/engineer_event_reward_berlin_axis")
    description = loc("items/engineer_event_reward_berlin_axis/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["219"] = {
    name = loc("items/engineer_event_reward_tunisia_allies")
    description = loc("items/engineer_event_reward_tunisia_allies/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["220"] = {
    name = loc("items/engineer_event_reward_tunisia_axis")
    description = loc("items/engineer_event_reward_tunisia_axis/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["241"] = {
    name = loc("items/booster_global_300_battle_2")
    description = loc("items/booster_global_300_battle_2/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_1_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["242"] = {
    name = loc("items/victory_day_event_order")
    description = loc("items/victory_day_event_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["243"] = {
    name = loc("items/soldier_exclusive")
    description = loc("items/soldier_exclusive/desc")
    icon = "ui/skin#/currency/soldier_order_gold.svg"
    gametemplate = "soldiers_supply_ticket_gold"
    worth = 3
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/gold_soldier.png"
    cardImageParams = mkImageParams([162, 178], [0, 12])
  },
  ["244"] = {
    name = loc("items/booster_global_battlepass_50_battle_12")
    description = loc("items/booster_global_battlepass_50_battle_12/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "booster_global_battlepass_50_battle_12_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["245"] = {
    name = loc("items/booster_global_battlepass_100_battle_12")
    description = loc("items/booster_global_battlepass_100_battle_12/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "booster_global_battlepass_100_battle_12_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["246"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_6"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["247"] = {
    name = loc("items/booster_global_battlepass_100_battle_6")
    description = loc("items/booster_global_battlepass_100_battle_6/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "booster_global_battlepass_100_battle_6_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["248"] = {
    name = loc("items/booster_global_battlepass_100_battle_24")
    description = loc("items/booster_global_battlepass_100_battle_24/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "booster_global_battlepass_100_battle_24_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["249"] = {
    name = loc("items/vehicle_upgrade_order")
    description = loc("items/vehicle_upgrade_order/desc")
    icon = "ui/skin#/currency/vehicle_upgrade.svg"
    gametemplate = "vehicle_upgrade_ticket"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = "ui/skin#/battlepass/up_vehicles.png"
    cardImageParams = mkImageParams([180, 131], [0, 1])
  },
  ["250"] = {
    name = loc("squad/allies_tunisia_event_assault_1")
    description = loc("squadannounce/allies_tunisia_event_assault_1")
    icon = "ui/skin#/research/squad_points_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([120, 111], [-4, 28], "!ui/soldiers/usa/allies_tunisia_event_assault_1_icon.svg") //600 * 555
  },
  ["251"] = {
    name = loc("squad/ger_normandy_event_assault_1")
    description = loc("squadannounce/ger_normandy_event_assault_1")
    icon = "ui/skin#/research/squad_points_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([120, 111], [-4, 28], "!ui/soldiers/germany/ger_normandy_event_assault_1_icon.svg") //600 * 555
  },
  ["252"] = {
    name = loc("items/ussr_bt_7a_f32")
    description = loc("items/ussr_bt_7a_f32/desc")
    icon = "ui/skin#/tank_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkTemplateImageCtor([170, 150], [0, 12], "ussr_bt_7a_f32_stalingrad_premium")
  },
  ["253"] = {
    name = loc("items/moscow_allies_hero_marathon_2022_summer")
    description = loc("items/moscow_allies_hero_marathon_2022_summer/desc")
    icon = "ui/squads/ussr/ussr_hero_medal_1_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/squads/ussr/ussr_hero_medal_1_icon.svg")
  },
  ["254"] = {
    name = loc("items/normandy_axis_event_marathon_summer_2022_portrait")
    description = loc("items/normandy_axis_event_marathon_summer_2022_portrait/desc")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["255"] = {
    name = loc("items/tunisia_allies_event_marathon_summer_2022_portrait")
    description = loc("items/tunisia_allies_event_marathon_summer_2022_portrait/desc")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["256"] = {
    name = loc("items/marathon_2022_summer_event_order")
    description = loc("items/marathon_2022_summer_event_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["257"] = {
    name = loc("items/booster_global_100_battle_2")
    description = loc("items/booster_global_100_battle_2/desc")
    icon = "ui/skin#/battlepass/base_booster_icon.svg"
    gametemplate = "battlepass_buster_1_template"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_boost.png"
    cardImage = "ui/skin#/battlepass/boost_global.png"
    cardImageParams = mkImageParams([154, 144], [0, 15])
  },
  ["259"] = {
    name = loc("wp/agit_poster_china_b_preview/name")
    description = loc("wp/agit_poster_china_b_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["260"] = {
    name = loc("wp/agit_poster_china_c_preview/name")
    description = loc("wp/agit_poster_china_c_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["261"] = {
    name = loc("wp/agit_poster_china_d_preview/name")
    description = loc("wp/agit_poster_china_d_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["262"] = {
    name = loc("wp/agit_poster_china_e_preview/name")
    description = loc("wp/agit_poster_china_e_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["263"] = {
    name = loc("wp/agit_poster_china_f_preview/name")
    description = loc("wp/agit_poster_china_f_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["265"] = {
    name = loc("items/normandy_allies_hero_airborne_day_2022")
    description = loc("items/normandy_allies_hero_airborne_day_2022/desc")
    icon = "ui/squads/usa/usa_hero_medal_1_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/squads/usa/usa_hero_medal_1_icon.svg")
  },
  ["324"] = {
    name = loc("items/nickFrame")
    description = loc("items/nickFrame/desc")
    icon = "ui/skin#/currency/nickframe_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/nickframe_bp.png"
    cardImageParams = mkImageParams([160, 178])
  },
  ["344"] = {
    name = loc("items/pacific_event_2022_order")
    description = loc("items/pacific_event_2022_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["348"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_7"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["353"] = {
    name = loc("wp/agit_poster_china_g_preview/name")
    description = loc("wp/agit_poster_china_g_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["354"] = {
    name = loc("wp/agit_poster_china_h_preview/name")
    description = loc("wp/agit_poster_china_h_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["356"] = {
    name = loc("items/sea_predator_reward_order")
    description = loc("items/sea_predator_reward_order/desc")
    icon = "ui/skin#/currency/random_reward_order.svg"
    bgImage = "ui/skin#/battlepass/bg_other.png"
    cardImage = "ui/skin#/battlepass/random_reward.png"
    cardImageParams = mkImageParams([102, 146], [0, -10])
  },
  ["357"] = {
    name = loc("items/sea_predator_decal_order")
    description = loc("items/sea_predator_decal_order/desc")
    icon = "ui/skin#/currency/decal_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/decal_order_event.svg")
  },
  ["359"] = {
    name = loc("items/armory_event_crate")
    description = loc("items/armory_event_crate/desc")
    icon = "ui/skin#/currency/random_reward_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/random_reward_order.svg") //432 * 600
  },
  ["360"] = {
    name = loc("items/armory_event_portrait_usa")
    description = loc("decorator/armory_event_portrait_usa/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["361"] = {
    name = loc("items/armory_event_portrait_ger")
    description = loc("decorator/armory_event_portrait_ger/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["364"] = {
    name = loc("wp/agit_poster_china_i_preview/name")
    description = loc("wp/agit_poster_china_i_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["365"] = {
    name = loc("wp/agit_poster_china_j_preview/name")
    description = loc("wp/agit_poster_china_j_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["368"] = {
    name = loc("items/enlisted2years_portrait_ussr")
    description = loc("decorator/enlisted2years_portrait/tip")
    icon = "ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["369"] = {
    name = loc("items/enlisted2years_portrait_britain")
    description = loc("decorator/enlisted2years_portrait/tip")
    icon = "ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["370"] = {
    name = loc("items/enlisted2years_portrait_usa")
    description = loc("decorator/enlisted2years_portrait/tip")
    icon = "ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["371"] = {
    name = loc("decals/su_ulan_ude_bear")
    description = loc("decals/su_ulan_ude_bear/desc")
    icon = "ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([144, 170], [0, 17], "!ui/skin#/battlepass/silver_weapons.png")
  },
  ["372"] = {
    name = loc("decals/uk_britannia_defiant")
    description = loc("decals/uk_britannia_defiant/desc")
    icon = "ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([144, 170], [0, 17], "!ui/skin#/battlepass/silver_weapons.png")
  },
  ["373"] = {
    name = loc("decals/su_guards_emblem")
    description = loc("decals/su_guards_emblem/desc")
    icon = "ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([144, 170], [0, 17], "!ui/skin#/battlepass/silver_weapons.png")
  },
  ["374"] = {
    name = loc("decals/us_836_bmb_sqn_liberty_belle")
    description = loc("decals/us_836_bmb_sqn_liberty_belle/desc")
    icon = "ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([144, 170], [0, 17], "!ui/skin#/battlepass/silver_weapons.png")
  },
  ["375"] = {
    name = loc("decals/de_jg26_sqn_4_who_tiger")
    description = loc("decals/de_jg26_sqn_4_who_tiger/desc")
    icon = "ui/uiskin/currency/decal_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([144, 170], [0, 17], "!ui/skin#/battlepass/silver_weapons.png")
  },
  ["377"] = {
    name = loc("wp/agit_poster_china_k_preview/name")
    description = loc("wp/agit_poster_china_k_preview/desc")
    gametemplate = "poster_ticket_4"
    worth = 2
    icon = "ui/skin#/currency/poster_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["378"] = {
    name = loc("items/xmas_event_order")
    description = loc("items/xmas_event_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["379"] = {
    name = loc("items/xmas_event_ussr_portrait")
    description = loc("decorator/xmas_event_portrait/tip")
    icon = "ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["380"] = {
    name = loc("items/xmas_event_ger_portrait")
    description = loc("decorator/xmas_event_portrait/tip")
    icon = "ui/uiskin/currency/portrait_order_event.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["382"] = {
    name = loc("items/wallposter_battlepass_order")
    description = loc("items/wallposter_battlepass_order/desc")
    gametemplate = "poster_ticket_8"
    worth = 2
    bgImage = "ui/skin#/battlepass/bg_poster.png"
    cardImage = "ui/skin#/battlepass/posters.png"
    cardImageParams = mkImageParams([154, 174], [0, 13])
  },
  ["384"] = {
    name = loc("items/stalingrad_event_portrait_ussr")
    description = loc("decorator/stalingrad_event_portrait_ussr/tip")
    icon = "ui/portraits/default_portrait.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/portraits/default_portrait.svg")
  },
  ["385"] = {
    name = loc("items/heavy_weapons_event_order")
    description = loc("items/heavy_weapons_event_order/desc")
    icon = "ui/skin#/currency/event_order.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkImageCtor([72, 100], [0, 12], "!ui/skin#/currency/event_order.svg")
  },
  ["386"] = {
    name = loc("vehicleDetails/jp_type_97_kai")
    description = loc("items/jp_type_97_kai/desc")
    icon = "ui/skin#/tank_icon.svg"
    bgImage = "ui/skin#/battlepass/bg_gold.png"
    cardImage = mkTemplateImageCtor([170, 150], [0, 12], "jp_type_97_kai_pacific_premium")
  },


  // boosters presentation
  ["every_day_award_small_pack"] = defRewardPresentation.__merge({
    name = loc("smallTrophyTitle_2")
    cardImage = "ui/skin#rewards/crate_small_2.png"
  }),
  ["every_day_award_medium_pack"] = defRewardPresentation.__merge({
    name = loc("mediumTrophyTitle_1")
    cardImage = "ui/skin#rewards/crate_medium_1.png"
  }),
  ["every_day_award_big_pack"] = defRewardPresentation.__merge({
    name = loc("bigTrophyTitle_1")
    cardImage = "ui/skin#rewards/crate_big_1.png"
  })
}

return freeze({
  rewardWidthToHeight
  rewardsPresentation
  rewardBgSizePx
  mkImageCtor
  mkReward
})
