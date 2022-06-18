import "%dngscripts/ecs.nut" as ecs
let {CmdUse} = require("gameevents")
let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let { get_sync_time } = require("net")

const REQUEST_AMMO_CD = 10.0

let function onRequestAmmo(evt, _eid, comp) {
  if (!comp["isAlive"] || comp["isDowned"])
    return
  let slots = [weaponSlots.EWS_PRIMARY]
  let requesterEid = evt[0]
  let squadEid = ecs.obsolete_dbg_get_comp_val(requesterEid, "squad_member__squad", INVALID_ENTITY_ID)
  if (squadEid != comp["squad_member__squad"])
    return
  let requestAmmoAllowTime = ecs.obsolete_dbg_get_comp_val(requesterEid, "requestAmmoAllowTime") ?? 0.0
  if (requestAmmoAllowTime > get_sync_time())
    return
  if (!ecs.obsolete_dbg_get_comp_val(squadEid, "squad__isLeaderNeedsAmmo", true))
    return

  let itemContainer = ecs.obsolete_dbg_get_comp_val(requesterEid, "itemContainer")
  let ammoProtoToTemplateMap = ecs.obsolete_dbg_get_comp_val(requesterEid, "ammoProtoToTemplateMap")
  let weapInfo = ecs.obsolete_dbg_get_comp_val(requesterEid, "human_weap__weapInfo")
  let gunEids = ecs.obsolete_dbg_get_comp_val(requesterEid, "human_weap__gunEids").getAll()

  let items = itemContainer.getAll().map(@(itemEid) {
      eid = itemEid,
      template = ecs.g_entity_mgr.getEntityTemplateName(itemEid),
      proto = ecs.obsolete_dbg_get_comp_val(itemEid, "item__proto")
    })

  local ammoCount = {}
  foreach (slot in slots) {
    let weap = weapInfo[slot]
    local ammo = weap?["numReserveAmmo"] ?? 0
    if (ecs.obsolete_dbg_get_comp_val(gunEids[slot], "gun__ammo", 0) > 0)
      ammo -= 1
    let reserveAmmoTemplate = weap?["reserveAmmoTemplate"]
    if (reserveAmmoTemplate != null)
      ammoCount[reserveAmmoTemplate] <- ammo
  }

  foreach (item in items) {
    if (ammoCount?[item.proto] != null)
      ammoCount[item.proto]--
  }

  ammoCount = ammoCount.filter(@(ammo) ammo > 0)

  foreach (proto, _ in ammoCount) {
    let item = ammoProtoToTemplateMap?[proto]
    if (item) {
      ecs.g_entity_mgr.createEntity("{0}".subst(item.template), { ["item__lastOwner"] = ecs.EntityId(requesterEid) },
        function(ammoEid) {
          ecs.obsolete_dbg_get_comp_val(requesterEid, "itemContainer").append(ecs.EntityId(ammoEid))
        })
      ecs.obsolete_dbg_set_comp_val(requesterEid, "requestAmmoAllowTime", get_sync_time() + REQUEST_AMMO_CD)
      break
    }
  }
}

ecs.register_es("squad_request_ammo_es",
  {
    [CmdUse] = onRequestAmmo
  },
  {
    comps_ro = [
      ["squad_member__squad", ecs.TYPE_EID],
      ["isAlive", ecs.TYPE_BOOL],
      ["isDowned", ecs.TYPE_BOOL],
    ]
    comps_rq = ["human"]
  },
  {tags="server"}
)
