import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let idleAnims = require("%enlSqGlob/menu_poses_for_weapons.nut")
let { templatesCombined } = require("%enlist/soldiers/model/all_items_templates.nut")
let faceGen = require("%enlist/faceGen.nut")
let { genFacesOverrides } = require("%enlist/faceGen/animTree_gen_faces.nut")
let faceGenBase = require("%enlist/faceGen/gen_faces.nut")

const EXPORT_TO_FILE = "gen_faces.nut"
const FACE_ID_COUNT = 51

let soldierOverrides = mkWatched(persist, "soldierOverrides", {})
let faceGenOverrides = mkWatched(persist, "faceGenOverrides", {})

let DB = ecs.g_entity_mgr.getTemplateDB()

let allIdleAnims = Computed(@() idleAnims.reduce(function(tbl, val) {
  val.each(@(id) tbl[id] <- true)
  return tbl
}, {}).keys().sort())

let animcharToHead = Computed(function() {
  let res = {}
  templatesCombined.value.each(@(armyTmpl) armyTmpl
    .filter(@(tmpl) tmpl?.itemtype == "head")
    .map(@(tmpl) tmpl.gametemplate)
    .each(function(key) {
      let animChar = DB.getTemplateByName(key)?.getCompValNullable("animchar__res")
      if (animChar != null && animChar not in res)
        res[animChar] <- key
    }))
  return res
})

let allSoldierHeads = Computed(@() animcharToHead.value.keys().sort())

let update = @(guid, data) guid == null ? null
  : soldierOverrides.mutate(@(tbl) tbl[guid] <- (tbl?[guid] ?? {}).__update(data))

let remove = @(guid, key)
  soldierOverrides.mutate(@(tbl) guid in tbl && key in tbl[guid] ? delete tbl[guid][key] : null)

let soldierReset = @(guid) guid in soldierOverrides.value
  ? soldierOverrides.mutate(@(v) delete v[guid])
  : null

let function soldierResetAll() {
  soldierOverrides({})
  faceGenOverrides({})
}

let isSoldierDisarmed = @(guid, data) data?[guid].isDisarmed ?? false

let setSoldierDisarmed = @(guid, isDisarmed)
  isSoldierDisarmed(guid, soldierOverrides.value) == isDisarmed ? null
    : isDisarmed ? update(guid, { isDisarmed = true })
    : remove(guid, "isDisarmed")

let isSoldierSlotsSwap = @(guid, data) data?[guid].isSlotsSwap ?? false

let setSoldierSlotsSwap = @(guid, isSlotsSwap)
  isSoldierSlotsSwap(guid, soldierOverrides.value) == isSlotsSwap ? null
    : isSlotsSwap ? update(guid, { isSlotsSwap = true })
    : remove(guid, "isSlotsSwap")

let getSoldierIdle = @(guid, data) data?[guid].idleAnim

let setSoldierIdle = @(guid, idleAnim)
  getSoldierIdle(guid, soldierOverrides.value) == idleAnim ? null
    : allIdleAnims.value.contains(idleAnim) ? update(guid, { idleAnim })
    : remove(guid, "idleAnim")

let function switchSoldierIdle(guid, dir) {
  let curAnim = getSoldierIdle(guid, soldierOverrides.value)
  let idx = allIdleAnims.value.indexof(curAnim)
  if (idx == null)
    return setSoldierIdle(guid, allIdleAnims.value[0])

  let length = allIdleAnims.value.len()
  setSoldierIdle(guid, allIdleAnims.value[(idx + dir + length) % length])
}

let getSoldierHead = @(guid, data) data?[guid].headId

let setSoldierHead = @(guid, headId)
  getSoldierHead(guid, soldierOverrides.value) == headId ? null
    : allSoldierHeads.value.contains(headId) ? update(guid, { headId })
    : remove(guid, "headId")

let function switchSoldierHead(guid, dir) {
  let headId = getSoldierHead(guid, soldierOverrides.value)
  let idx = allSoldierHeads.value.indexof(headId)
  if (idx == null)
    return setSoldierHead(guid, allSoldierHeads.value[0])

  let length = allSoldierHeads.value.len()
  setSoldierHead(guid, allSoldierHeads.value[(idx + dir + length) % length])
}

let getSoldierFace = @(guid, data) data?[guid].faceId

local function setSoldierFace(guid, faceId) {
  faceId = faceId.tointeger()
  if (getSoldierFace(guid, soldierOverrides.value) == faceId)
    return
  if (0 <= faceId && faceId < FACE_ID_COUNT)
    update(guid, { faceId })
  else
    remove(guid, "faceId")
}

let function switchSoldierFace(guid, dir) {
  let faceId = getSoldierFace(guid, soldierOverrides.value)
  setSoldierFace(guid, faceId == null ? 0 : (faceId + dir + FACE_ID_COUNT) % FACE_ID_COUNT)
}

let getSoldierFaceGen = @(animChar, faceId) faceGenOverrides.value?[animChar][faceId?.tostring()]

let function faceGenClear(animChar) {
  if (animChar in faceGenOverrides.value)
    faceGenOverrides.mutate(@(v) delete v[animChar])
}

local function faceGenRandomize(animChar, fromId, toId = -1) {
  toId = max(toId, fromId)
  if (!animChar || fromId < 0 || toId >= FACE_ID_COUNT)
    return

  faceGenOverrides.mutate(function(tbl) {
    let data = tbl?[animChar] ?? {}
    let config = genFacesOverrides?[animChar]
    for (local idx = fromId; idx <= toId; ++idx)
      data[idx.tostring()] <- faceGen(config)
    tbl[animChar] <- data
  })
}

let function faceGenSave() {
  let facesNew = faceGenOverrides.value.keys()
  let facesSaved = faceGenBase.keys()
  let facesUsed = allSoldierHeads.value
  let facesAll = [].extend(facesNew, facesSaved, facesUsed)
    .filter(@(key, idx, arr) arr.indexof(key) == idx)
    .sort()
  let lines = ["return {"]
  foreach (faceId in facesAll) {
    let dataNew = faceGenOverrides.value?[faceId]
    let dataSaved = faceGenBase?[faceId]
    if (!facesUsed.contains(faceId))
      lines.append("  // DEPRECATED")
    else if (facesNew.contains(faceId))
      lines.append($"  // updated: {", ".join(dataNew?.keys().sort())}")
    lines.append($"  {faceId} = \{")
    for (local idx = 0; idx < FACE_ID_COUNT; ++idx) {
      let data = dataNew?[idx.tostring()] ?? dataSaved?[idx.tostring()]
      lines.append($"    [\"{idx}\"] = \{")
      if (data == null)
        lines.append("      // FIXME")
      else
        data.keys().sort().each(@(key) lines.append($"      {key} = {data[key]}"))
      lines.append("    },")
    }
    lines.append("  }")
  }
  lines.append("}")

  let fileName = EXPORT_TO_FILE
  let io = require("io")
  let file = io.file(fileName, "wt+")
  file.writestring("\n".join(lines))
  file.close()
  log($"Soldier face properties are saved to: {fileName}")
  return fileName
}

return {
  soldierOverrides
  soldierReset
  soldierResetAll

  isSoldierDisarmed = @(guid) isSoldierDisarmed(guid, soldierOverrides.value)
  mkSoldierDisarmed = @(guid) Computed(@() isSoldierDisarmed(guid, soldierOverrides.value))
  setSoldierDisarmed

  isSoldierSlotsSwap = @(guid) isSoldierSlotsSwap(guid, soldierOverrides.value)
  mkSoldierSlotsSwap = @(guid) Computed(@() isSoldierSlotsSwap(guid, soldierOverrides.value))
  setSoldierSlotsSwap

  allIdleAnims
  getSoldierIdle = @(guid) getSoldierIdle(guid, soldierOverrides.value)
  mkSoldierIdle = @(guid) Computed(@() getSoldierIdle(guid, soldierOverrides.value))
  setSoldierIdle
  switchSoldierIdle

  allSoldierHeads
  getSoldierHead = @(guid) getSoldierHead(guid, soldierOverrides.value)
  getSoldierHeadTemplate = @(guid) animcharToHead.value?[getSoldierHead(guid, soldierOverrides.value)]
  mkSoldierHead = @(guid) Computed(@() getSoldierHead(guid, soldierOverrides.value))
  setSoldierHead
  switchSoldierHead

  FACE_ID_COUNT
  getSoldierFace = @(guid) getSoldierFace(guid, soldierOverrides.value)
  mkSoldierFace = @(guid) Computed(@() getSoldierFace(guid, soldierOverrides.value))
  setSoldierFace
  switchSoldierFace

  faceGenOverrides
  getSoldierFaceGen
  faceGenClear
  faceGenRandomize
  faceGenAll = @(animChar) faceGenRandomize(animChar, 0, FACE_ID_COUNT - 1)
  faceGenSave
}