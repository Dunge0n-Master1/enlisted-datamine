import "%dngscripts/ecs.nut" as ecs
let {kwarg} = require("%sqstd/functools.nut")
let math = require("math")
let {Point3, TMatrix} = require("dagor.math")
let {validateTm, validatePosition, getTeamUnitTemplateName, getTeamWeaponPresetTemplateName, initItemContainer} = require("%scripts/game/utils/spawn.nut")

let dasevents = require("dasevents")

const spawnZoneExtents = 3.0

return kwarg(function(team, squadLen, spawnParams, playerEid, squadEid = INVALID_ENTITY_ID, isBot = false) {
  let commonParams = {
    ["squad_member__squad"] = [squadEid, ecs.TYPE_EID]
  }

  let function spawnSquad() {
    let transform = spawnParams.transform

    let spawnTmIsValidated = spawnParams?.isValidated ?? false
    let tm = spawnTmIsValidated ? transform : validateTm(transform, spawnZoneExtents)
    let botCount = squadLen - 1

    let leaderParams =
      commonParams.
      __merge(spawnParams).
      __merge({
        ["transform"] = [tm, ecs.TYPE_MATRIX],
        ["squad_member__memberIdx"] = 0,
        ["human_net_phys__isSimplifiedPhys"] = isBot,
      })

    local templateName = "{0}+{1}".subst(getTeamUnitTemplateName(team, playerEid), getTeamWeaponPresetTemplateName(team))
    ecs.g_entity_mgr.createEntity(templateName, leaderParams, function(leaderEid) {
      ecs.g_entity_mgr.sendEvent(playerEid, dasevents.CmdPossessEntity({possessedEid=leaderEid}))
      ecs.obsolete_dbg_set_comp_val(squadEid, "squad__leader", leaderEid)
      initItemContainer(leaderEid)
    })

    let numRows = math.ceil(math.sqrt(botCount + 1)).tointeger()
    let spawnDist = 1.0
    for (local i = 0; i < botCount; ++i) {
      let memberIdx = i + 1

      let aiTm = TMatrix(tm)
      let row = ((i + 1) / numRows) * spawnDist
      let col = math.ceil(((i + 1) % numRows) * 0.5) * spawnDist * ((i % 2) * 2 - 1) // alternating -1 +1
      aiTm.setcol(3, aiTm * Point3(-row, 0.0, col));

      let botParams =
        commonParams.
        __merge(spawnParams).
        __merge({
          ["transform"] = spawnTmIsValidated ? [tm, ecs.TYPE_MATRIX] : [validatePosition(aiTm, tm.getcol(3), spawnZoneExtents), ecs.TYPE_MATRIX],
          ["squad_member__memberIdx"] = memberIdx,
          ["beh_tree__enabled"] = true,
          ["human_weap__infiniteAmmoHolders"] = true,
          ["human_net_phys__isSimplifiedPhys"] = true,
        })

      templateName = "{0}+{1}".subst(getTeamUnitTemplateName(team, playerEid), getTeamWeaponPresetTemplateName(team))
      ecs.g_entity_mgr.createEntity(templateName, botParams, @(squadmateEid) initItemContainer(squadmateEid))
    }
  }

  if (squadEid == INVALID_ENTITY_ID)
    ecs.g_entity_mgr.createEntity("squad", {}, function(eid) {
      commonParams["squad_member__squad"] <- [eid, ecs.TYPE_EID]
      spawnSquad()
    })
  else
    spawnSquad()
})