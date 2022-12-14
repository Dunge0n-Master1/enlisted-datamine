require ecs
require app
require dm
require DmFire
require DagorMath
require game.es.events
require game.es.vehicle.vehicle_events
require EnlistedDm
require EnlistedNet
require enlisted.events_enlisted

def explosion_impl(offender : EntityId;
                   gun_props_id : int;
                   shell_id : int;
                   eid : EntityId;
                   var damage_model : DamageModel&;
                   var lastOffender : EntityId&;
                   var isAlive : bool&;
                   var isExploded : bool&)
  isAlive = false
  isExploded = true

  let explosionDamageTypeId = find_damage_type_id_by_name("explosion")
  for i in iter_range(damage_model.dmData.parts)
    let damage = get_max_hp(damage_model.dmData, i)
    lastOffender = offender
    using <| $(var hitData : HitData#)
      hitData.offender = offender
      hitData.gunPropsId = int16(gun_props_id)
      hitData.shellId = int16(shell_id)
      deal_damage_to_part(damage_model, eid, i, explosionDamageTypeId, int(DamageEffectsMask DM_EFFECTS_MASK_ALL), damage, hitData)

[es(tag=server)]
def kill_vehicle_es(evt : CmdKillVehicle;
                    eid : EntityId;
                    last_offender__gunPropsId : int;
                    last_offender__shellId : int;
                    var damage_model : DamageModel&;
                    var lastOffender : EntityId&;
                    var isAlive : bool&;
                    var isExploded : bool&)
  explosion_impl(evt.offender, last_offender__gunPropsId, last_offender__shellId, eid, damage_model, lastOffender, isAlive, isExploded)

[es(tag=server)]
def explosion_es(evt : CmdExplosionFatal;
                 eid : EntityId;
                 var damage_model : DamageModel&;
                 var lastOffender : EntityId&;
                 var last_offender__gunPropsId : int&;
                 var last_offender__shellId : int&;
                 var isAlive : bool&;
                 var isExploded : bool&)
  if !isExploded
    last_offender__gunPropsId = evt.gunPropsId
    last_offender__shellId = evt.shellId
    explosion_impl(evt.offender, last_offender__gunPropsId, last_offender__shellId, eid, damage_model, lastOffender, isAlive, isExploded)
    sendEvent(eid, [[EventExplosionFatal offender=evt.offender, gunPropsId=evt.gunPropsId, shellId=evt.shellId]])

[es(tag=server)]
def explosion_crash_es(evt : CmdCrashExplosionFatal;
                       eid : EntityId;
                       last_offender__gunPropsId : int;
                       last_offender__shellId : int;
                       var damage_model : DamageModel&;
                       var lastOffender : EntityId&;
                       var isAlive : bool&;
                       var isExploded : bool&)
  if !isExploded
    explosion_impl(evt.offender, last_offender__gunPropsId, last_offender__shellId, eid, damage_model, lastOffender, isAlive, isExploded)
    sendEvent(eid, [[EventCrashExplosionFatal offender=evt.offender, crashType=evt.crashType]])


def explosion_fire_damage_impl(offender : EntityId;
                               gun_props_id : int;
                               shell_id : int;
                               eid : EntityId;
                               var fire_damage : FireDamageComponent&;
                               var fire_damage__isBurn : bool&;
                               var fire_damage__gunPropsId : int&;
                               var fire_damage__shellId : int&;
                               fire_damage__fireParamsPreset : string)
  var haveFire = false
  for fireData in fire_damage.data
    if fireData.startTime > double(0.0)
      haveFire = true
      break

  fire_damage__isBurn = true
  fire_damage__gunPropsId = gun_props_id
  fire_damage__shellId = shell_id
  if !haveFire
    // We've exploded and we're probably gonna burn (visually), but if this explosion is due to
    // no crew left in vehicle then there's no burning currently, so surrounding fire damage
    // is not going to be applied, fix that by starting at least one dummy fire (related to vehicle_crew_dead_es).
    using <| $(var desc : StartBurnDesc#)
      desc.offender = offender
      desc.fireParamsId = get_fire_params_id(fire_damage__fireParamsPreset)
      if desc.fireParamsId < 0
        desc.fireParamsId = 0
      desc.atTime = double(get_sync_time())
      let center = float3(0.f, 0.f, 0.f)
      dm_calcRadius(desc, BSphere3(center, 0.5f), 0.5f)
      fire_component_startBurn(fire_damage, eid, desc)

[es(before=explosion_es)]
def explosion_fire_damage_es(evt : EventExplosionFatal;
                             eid : EntityId;
                             var fire_damage : FireDamageComponent&;
                             var fire_damage__isBurn : bool&;
                             var fire_damage__gunPropsId : int&;
                             var fire_damage__shellId : int&;
                             fire_damage__fireParamsPreset : string = "";
                             isExploded : bool&)
  if !isExploded
    explosion_fire_damage_impl(evt.offender, evt.gunPropsId, evt.shellId, eid, fire_damage,
                               fire_damage__isBurn, fire_damage__gunPropsId, fire_damage__shellId, fire_damage__fireParamsPreset)

[es(before=explosion_es)]
def explosion_fire_damage_crash_es(evt : EventCrashExplosionFatal;
                                   eid : EntityId;
                                   var fire_damage : FireDamageComponent&;
                                   var fire_damage__isBurn : bool&;
                                   var fire_damage__gunPropsId : int&;
                                   var fire_damage__shellId : int&;
                                   fire_damage__fireParamsPreset : string = "";
                                   isExploded : bool&)
  if !isExploded
    explosion_fire_damage_impl(evt.offender, fire_damage__gunPropsId, fire_damage__shellId, eid, fire_damage,
                               fire_damage__isBurn, fire_damage__gunPropsId, fire_damage__shellId, fire_damage__fireParamsPreset)


def seats_explosion_impl(offender : EntityId; gun_props_id : int; shell_id : int; vehicle_seats__seatEids : EidList&)
  for seatEid in vehicle_seats__seatEids
    let sitter = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    sendEvent(sitter, [[CmdKill offender=offender, damageType=uint16(int(DamageType DM_EXPLOSION)), gunPropsId=gun_props_id, shellId=shell_id]])

[es]
def explosion_seats_es(evt : EventExplosionFatal;
                       vehicle_seats__seatEids : EidList&)
  seats_explosion_impl(evt.offender, evt.gunPropsId, evt.shellId, vehicle_seats__seatEids)

[es]
def explosion_seats_crash_es(evt : EventCrashExplosionFatal;
                             lastOffender : EntityId;
                             last_offender__gunPropsId : int;
                             last_offender__shellId : int;
                             vehicle_seats__seatEids : EidList&)
  seats_explosion_impl(lastOffender, last_offender__gunPropsId, last_offender__shellId, vehicle_seats__seatEids)

[es(tag=server, after=fire_damage_updater_es)]
def fire_damage_total_time_reset_es(info : UpdateStageInfoAct;
                                    var fire_damage__totalTime : float&;
                                    fire_damage__isBurn : bool)
  if !fire_damage__isBurn
    fire_damage__totalTime = 0.f

[es(tag=server, after=fire_damage_updater_es)]
def fire_damage_total_time_es(info : UpdateStageInfoAct;
                              var fire_damage__totalTime : float&;
                              extinguishable__inProgress : bool  = false;
                              fire_damage__isBurn : bool)
  if fire_damage__isBurn && !extinguishable__inProgress
    fire_damage__totalTime += info.dt

[es(tag=server)]
def explosion_by_fire_es(info : UpdateStageInfoAct;
                         eid : EntityId;
                         fire_damage : FireDamageComponent;
                         fire_damage__totalTime : float;
                         fire_damage__timeToExplosion : float;
                         fire_damage__gunPropsId : int;
                         fire_damage__shellId : int;
                         isExploded : bool)
  if !isExploded && fire_damage__totalTime >= fire_damage__timeToExplosion
    sendEvent(eid, [[CmdExplosionFatal offender=fire_damage.offender, gunPropsId=fire_damage__gunPropsId, shellId=fire_damage__shellId]])

[es(tag=server)]
def fatal_fire_es(evt : CmdFireFatal;
                  eid : EntityId;
                  fatal_fire__timeToExplosion : float;
                  fire_damage__timeToExplosion : float;
                  var fire_damage__isFatal : bool&;
                  var isAlive : bool&;
                  var lastOffender : EntityId&;
                  var last_offender__gunPropsId : int&;
                  var last_offender__shellId : int&;
                  var fire_damage__totalTime : float&;
                  isExploded : bool)
  if !isExploded && !fire_damage__isFatal
    fire_damage__totalTime = max(fire_damage__totalTime, fire_damage__timeToExplosion - fatal_fire__timeToExplosion)
    fire_damage__isFatal = true
    lastOffender = evt.offender
    last_offender__gunPropsId = evt.gunPropsId
    last_offender__shellId = evt.shellId
    isAlive = false
    send_net_event(eid, [[EventFireFatal offender=evt.offender, gunPropsId=evt.gunPropsId, shellId=evt.shellId]])

[es]
def fatal_explosion_fire_check_es(info : ParallelUpdateFrameDelayed;
                                  eid : EntityId;
                                  fatal_explosion_fire__ttl : float;
                                  var fatal_explosion_fire__endTime : float&;
                                  isExploded : bool)
  if isExploded
    if fatal_explosion_fire__ttl > 0.f && fatal_explosion_fire__endTime <= 0.f
      fatal_explosion_fire__endTime = info.curTime + fatal_explosion_fire__ttl
    if info.curTime >= fatal_explosion_fire__endTime && fatal_explosion_fire__endTime > 0.f
      sendEvent(eid, [[CmdStopBurn]])