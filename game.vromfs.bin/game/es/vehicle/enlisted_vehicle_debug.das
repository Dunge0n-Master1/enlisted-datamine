options no_aot
require ecs
require DngNet
require player
require DagorConsole
require DagorMath
require Plane

require game.utils.hero
require game.es.vehicle.vehicle_events
require game.es.server_debug_common
require game.es.vehicle.vehicle_seats_common
require game.es.net_console_macro
require enlisted.events_enlisted
require danetlibs.console_commands.main.console_common
require daslib/strings_boost

[console_cmd(name="vehicle.explosion")]
def vehicle_explosion()
  let vehicleEid = get_Eid(get_controlled_hero(), "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  sendEvent(vehicleEid, [[CmdExplosionFatal offender=INVALID_ENTITY_ID, gunPropsId=-1, shellId=-1]])

[console_cmd(name="vehicle.explosion_crash")]
def vehicle_explosion_crash()
  let vehicleEid = get_Eid(get_controlled_hero(), "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  sendEvent(vehicleEid, [[CmdCrashExplosionFatal offender=INVALID_ENTITY_ID, crashType=int(CrashType CRASH_TYPE_LAND)]])

[net_console_cmd(name="vehicle.spawnInVehicle")]
def vehicle_spawn_debug(vehicleTempl : string; [[net_hero]] hero_eid : EntityId; [[net_player]] player_eid : EntityId)
  query(hero_eid) <| $ [es] (eid : EntityId;
                             transform : float3x4;
                             squad_member__squad : EntityId;
                             human_anim__vehicleSelected : EntityId)
    query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
      kick_from_vehicle(hero_eid, human_anim__vehicleSelected, vehicle_seats__seatEids)

    let finalizeCreation <- @ <| (vehicleEid : EntityId)
      sendEventImmediate(player_eid, [[CmdUseVehicleOnSpawn possessed=eid, squad=squad_member__squad, vehicle=vehicleEid, seatOrderNo=0]])

    createEntity("{vehicleTempl}", finalizeCreation) <| $(var init : ComponentsInitializer)
      var tm = transform
      tm[3] += float3(0., 1., 0.)
      set(init, "transform", tm)

[net_console_cmd(name="vehicle.resupply")]
def debug_plane_resupply([[net_hero]] eid : EntityId)
  query(eid) <| $ [es] (human_anim__vehicleSelected : EntityId)
    send_net_event(human_anim__vehicleSelected, [[CmdResupplyVehicle]])


[console_processor]
def vehicle_spawn_debug_cmd_processor(args : array<string>;
                                      collect : bool;
                                      var hints : ConsoleProcessorHints)
  let cmd = "vehicle.spawnInVehicle"
  if collect
    let inputs <- args[0] |> split(" ")
    if length(inputs) >= 2
      add_hints([[auto[] [[CommandArgDesc name="vehicleTempl", hintType=CommandArgHintType TemplateName]] ]],
                cmd, inputs, /*hints_count*/ 20, /*threshold_cam_distance_sq*/ 2500.0, hints)
  return false