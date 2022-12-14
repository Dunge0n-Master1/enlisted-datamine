require ecs
require soundHash
require game.es.events
require game.es.sound_net.sound_net_events
require common_shooter.events_common_shooter
require DaWeaponProps
require strings

def request_human_speech(phrase : string; vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    if get_bool(seatEid, "seat__isPlayer") ?? false
      let seatOwnerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      sendEvent(seatOwnerEid, [[CmdRequestHumanSpeech phrase=phrase]])


[es(tag=server, REQUIRE=damage_model)]
def vehicle_net_speech_part_type_damaged(evt : EventOnVehiclePartTypeDamaged;
                                         isExploded : bool;
                                         vehicle_seats__seatEids : EidList)
  if evt.isDestroyed && !isExploded
    request_human_speech("vehiclePartDestroyed/{evt.partType}", vehicle_seats__seatEids)


[es(tag=server)]
def vehicle_net_speech_on_select_next_bullet_id(evt : EventOnSelectNextBulletId;
                                                vehicle_seats__seatEids : EidList;
                                                [[shared_comp]] vehicle_net_speech_switch_bullet__types : Object)

  query(evt.gunEid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds)
    if uint(evt.nextBulletId) < uint(length(gun__shell_prop_ids))
      let shellId = int(gun__shell_prop_ids[evt.nextBulletId].shellId)
      shell_entity_get_props(shellId) <| $(shellEntityProps : ShellEntityTypeProps)
        let bulletType = shellEntityProps.bulletType
        for it in vehicle_net_speech_switch_bullet__types
          let typeObj = it.value |> get_ecs_object()
          let prefixList = *typeObj |> get_ecs_StringList("prefix")
          for prefix in *prefixList
            if slice(bulletType, 0, length(prefix)) == prefix
              request_human_speech("vehicleSwitchBulletType/{it.key}", vehicle_seats__seatEids)
              return
        request_human_speech("vehicleSwitchBulletType/default", vehicle_seats__seatEids)
