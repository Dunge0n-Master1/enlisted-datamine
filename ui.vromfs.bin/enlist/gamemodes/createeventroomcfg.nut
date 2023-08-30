from "%enlSqGlob/ui_library.nut" import *
let eventbus = require("eventbus")
let matching_api = require("matching.api")
let { matchingCall } = require("%enlist/matchingClient.nut")
let { endswith } = require("string")
let { getPlatformId } = require("%enlSqGlob/httpPkg.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")


let allRoomCfg = nestWatched("allRoomCfg", [])
let isRoomCfgActual = nestWatched("isRoomCfgActual", false)
let isRoomCfgLoading = Watched(false)

const MODDED_CONFIG_POSTFIX = "_MODDED"

let createEventRoomCfg = Computed(function() {
  let cfg = {}
  foreach (tpl in allRoomCfg.value) {
    let id = tpl?["template-id"]
    if (id != null && ("rules" in tpl))
      cfg[id] <- tpl
  }
  return cfg
})

let isModsAvailable = Computed(function(){
  let roomCfg = createEventRoomCfg.value
  if (roomCfg.len() <= 0)
    return true
  let modsSettings = roomCfg.filter(@(settings)
    endswith(settings?["template-id"], MODDED_CONFIG_POSTFIX))
  let restrictedPlatforms = {}
  modsSettings.each(@(settings)
    restrictedPlatforms.__update(settings.rules?["public/restrictPlatforms"] ?? {}))
  return getPlatformId() not in restrictedPlatforms
})

let allModes = Computed(@()
  createEventRoomCfg.value.keys()
  .filter(@(key) createEventRoomCfg.value[key]?.defaults.public.mode == key)
  .sort(@(a, b) b <=> a))

/*****  config example ******
local createEventRoomCfg = Watched({
  SQUADS = {
    rules = {
      ["public/isPrivate"] = { type = "bool" },
      ["public/cluster"] = { type = "string" },
      ["public/writeReplay"] = { type = "bool" },
      ["public/appId"] = { type = "integer" },
      ["public/chatId"] = {},
      ["public/maxPlayers"] = {
        oneOf = [1, 2, 4, 8, 16, 20],
        override = [{
          applyIf = { ["public/isPrivate"] = false },
          oneOf = [20]
        }]
      },
      ["public/chatKey"] = {},
      ["public/scenes"] = {
        anyOf = [
          "content/enlisted/gamedata/scenes/normandy_beach_inv.blk",
          "content/enlisted/gamedata/scenes/volokolamsk_city_dom_large_zones.blk",
          "content/enlisted/gamedata/scenes/berlin_chancellery_dom.blk",
          "content/enlisted/gamedata/scenes/berlin_goering_dom.blk",
          "content/enlisted/gamedata/scenes/berlin_garden_inv.blk",
          "content/enlisted/gamedata/scenes/berlin_goering_inv.blk",
          "content/enlisted/gamedata/scenes/berlin_opera_inv.blk",
          "content/enlisted/gamedata/scenes/tunisia_city_invasion.blk"
        ]
      },
      ["public/botpop"] = {
        oneOf = [0, 1, 2, 4, 8, 12, 16, 20],
        override = [{
          applyIf = { ["public/isPrivate"] = false },
          oneOf = [1, 2, 4, 8, 12, 16, 20]
        }]
      },
      ["public/difficulty"] = { oneOf = ["standard", "hardcore"] },
      ["public/campaigns"] = { anyOf = ["normandy", "moscow", "berlin", "tunisia"] },
      ["public/teamArmies"] = { oneOf = ["historical", "any_army"] },
      ["public/voteToKick"] = {
        type = "bool",
        override = [{
          applyIf = { ["public/isPrivate"] = false },
          oneOf = [true]
        }]
      },
      ["public/crossplay"] = { oneOf = ["off", "consoles", "all"] },
      password = {}
    },

    digest = {
      group = "events-lobby",
      keys = [
        "appId",
        "gameName",
        "membersCnt",
        "creator",
        "sessionState",
        "hasPassword",
        "maxPlayers"
      ]
    },
    defaults = {
      public = {
        gameName = "enlisted",
        isPrivate = false,
        writeReplay = false,
        cluster = "EU",
        difficulty = "standard",
        botpop = 20,
        maxPlayers = 20,
        campaigns = ["tunisia"],
        teamArmies = "historical",
        voteToKick = true,
        crossplay = "all"
      }
    },
    template_id = "SQUADS"
  }

  LONE_FIGHTERS = {
    rules = {
     ["public/isPrivate"] = { type = "bool" },
     ["public/cluster"] = { type = "string" },
     ["public/writeReplay"] = { type = "bool" },
     ["public/appId"] = { type = "integer" },
     ["public/chatId"] = {},
     ["public/maxPlayers"] = {
       oneOf = [1, 2, 4, 8, 16, 20, 30, 40, 50],
       override = [{
         applyIf = { ["public/isPrivate"] = false },
         oneOf = [50]
       }]
     },
     ["public/chatKey"] = {},
     ["public/scenes"] = {
       anyOf = [
         "content/enlisted/gamedata/scenes/normandy_beach_inv_solo.blk",
         "content/enlisted/gamedata/scenes/volokolamsk_city_dom_solo.blk",
         "content/enlisted/gamedata/scenes/berlin_chancellery_dom_solo.blk",
         "content/enlisted/gamedata/scenes/berlin_goering_dom_solo.blk",
         "content/enlisted/gamedata/scenes/berlin_garden_inv_solo.blk",
         "content/enlisted/gamedata/scenes/berlin_goering_inv_solo.blk",
         "content/enlisted/gamedata/scenes/berlin_opera_inv_solo.blk"
       ]
     },
     ["public/botpop"] = {
       oneOf = [0, 1, 2, 4, 8, 12, 16, 20],
       override = [{
         applyIf = { ["public/isPrivate"] = false },
         oneOf = [1, 2, 4, 8, 12, 16, 20, 30, 40, 50]
       }]
     },
     ["public/difficulty"] = { oneOf = ["standard", "hardcore" ] },
     ["public/campaigns"] = { anyOf = ["normandy", "moscow", "berlin"] },
     ["public/teamArmies"] = { oneOf = ["historical", "any_army"] },
     ["public/voteToKick"] = {
       type = "bool",
       override = [{
         applyIf = { ["public/isPrivate"] = false },
         oneOf = [true]
       }]
     },
     ["public/crossplay"] = { oneOf = ["off", "consoles", "all"] },
     "password": {}
    },

    digest = {
      group = "events-lobby",
      keys = [
        "appId",
        "gameName",
        "membersCnt",
        "creator",
        "sessionState",
        "hasPassword",
        "maxPlayers"
      ]
    },

    defaults = {
      public = {
        gameName = "enlisted",
        isPrivate = false,
        writeReplay = false,
        cluster = "EU",
        difficulty = "standard",
        botpop = 50,
        maxPlayers = 50,
        campaigns = ["berlin"],
        teamArmies = "historical",
        voteToKick = true,
        crossplay = "all"
      }
    },
    template_id = "LONE_FIGHTERS"
  }
})
/* */

let function getValuesFromRule(rule) {
  local values = []
  local isMultival = false
  if ("oneOf" in rule)
    values = rule.oneOf
  else if ("anyOf" in rule) {
    values = rule.anyOf
    isMultival = true
  }
  else if ("range" in rule) {
    if ((rule.range?.len() ?? 0) >= 2)
      for(local i = rule.range[0]; i <= rule.range[1]; i++)
        values.append(i)
  }
  else if (rule?.type == "bool")
    values = [true, false]
  return { values, isMultival }
}

let function mSubscribe(id, cb) {
  matching_api.listen_notify(id)
  eventbus.subscribe(id, cb)
}

let function onRoomCfgResult(resp) {
  isRoomCfgLoading(false)
  if (resp.error != 0)
    return
  allRoomCfg.update(resp?.result ?? [])
  isRoomCfgActual.update(true)
}

let function actualizeRoomCfg() {
  if (isRoomCfgActual.value || isRoomCfgLoading.value)
    return

  isRoomCfgLoading(true)
  matchingCall("mrooms.fetch_lobby_templates", onRoomCfgResult)
}
mSubscribe("mrooms.lobby_templates_changed", @(_notify) isRoomCfgActual.update(false))

return {
  createEventRoomCfg
  isRoomCfgActual
  actualizeRoomCfg
  allModes
  getValuesFromRule
  isModsAvailable
}