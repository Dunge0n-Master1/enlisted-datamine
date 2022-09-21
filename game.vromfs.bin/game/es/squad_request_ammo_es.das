require ecs
require app
require strings
require HumanPhys
require game.es.events
require ecs.safe

[es(tag=server, REQUIRE=human, REQUIRE_NOT=deadEntity)]
def squad_request_ammo_es(evt : CmdUse;
                          squad_member__squad aka requestee_squad_member__squad : EntityId;
                          isDowned : bool)
  if isDowned
    return
  let slots = [[int[] int(HUWeaponSlots EWS_PRIMARY)]]
  let requesterEid = evt.requesterEid
  query(requesterEid) <| $ [es] (squad_member__squad aka requester_squad_member__squad : EntityId;
                                 itemContainer : EidList;
                                 ammoProtoToTemplateMap : Object;
                                 human_weap__weapInfo : Array;
                                 human_weap__gunEids : EidList;
                                 requestAmmoCooldown : float;
                                 var requestAmmoAllowTime : float&)
    if (requester_squad_member__squad != requestee_squad_member__squad ||
        requestAmmoAllowTime > get_sync_time() ||
        !(get_bool(requester_squad_member__squad, "squad__isLeaderNeedsAmmo") ?? true))
      return

    var ammoCount : table<string; int>
    for slot in slots
      let weap = human_weap__weapInfo[slot] as Object
      var ammo = weap?.numReserveAmmo ?? 0

      if (get_int(human_weap__gunEids[slot], "gun__ammo") ?? 0) > 0
        ammo -= 1
      let reserveAmmoTemplate = weap?.reserveAmmoTemplate ?? ""
      if !empty(reserveAmmoTemplate)
        ammoCount[reserveAmmoTemplate] = ammo

    for itemEid in itemContainer
      query(itemEid) <| $ [es] (item__proto : string)
        if ammoCount |> key_exists(item__proto)
          ammoCount[item__proto]--

    let putToContainer <- @ <| (eid : EntityId)
      query(requesterEid) <| $ [es] (var itemContainer : EidList&)
        itemContainer |> push(eid)

    for proto, ammo in keys(ammoCount), values(ammoCount)
      if ammo <= 0
        continue
      let ammoTemplate = (ammoProtoToTemplateMap[proto] ?as Object)?.template ?? ""
      if !empty(ammoTemplate)
        createEntity(ammoTemplate, putToContainer) <| $(var comps : ComponentsInitializer)
          comps |> set("item__lastOwner", evt.requesterEid)
        requestAmmoAllowTime = get_sync_time() + requestAmmoCooldown
        break
