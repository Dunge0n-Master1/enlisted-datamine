require ecs
require app
require game.es.events
require common_shooter.events_common_shooter
require game.es.vehicle.vehicle_seats_common
require game.events_game
require game.utils.team
require EnlistedDm
require EnlistedNet
require vehicle

let
  DEF_REVIVINGCOUNT = 0
  DEF_HPTHRESHOLD = 2.
  DEF_HPRECOVERYSPD = 1.
  DEF_RECOVERYTIMETHRESHOLD = 3.
  DEF_STOPPINGPOWERRECOVERYRATE = 1.
  DEF_DEATHHPTHRESHOLD = 0.
  DEF_DOWNEDTIMER = 15.
  DEF_DOWNEDTIMERADD = 1.

def on_death(eid : EntityId;
             death_desc__damageType : int;
             death_desc__gunPropsId : int;
             death_desc__shellId : int;
             death_desc__collNodeId : int;
             death_desc__victimTeam : int;
             death_desc__offenderTeam : int;
             var hitpoints__lastOffender : EntityId&;
             var hitpoints__lastOffenderPlayer : EntityId&;
             hitpoints__lastVictimPlayer : EntityId;
             lastCriticalOffender : EntityId)
  let criticalOffenderTeam = get_int(lastCriticalOffender, "team") ?? TEAM_UNASSIGNED
  let lastOffenderTeam = get_int(hitpoints__lastOffender, "team") ?? TEAM_UNASSIGNED
  if is_teams_friendly(criticalOffenderTeam, lastOffenderTeam)
    let criticalOffender = get_Eid(lastCriticalOffender, "possessed") ?? INVALID_ENTITY_ID
    if criticalOffender != INVALID_ENTITY_ID
      hitpoints__lastOffender = criticalOffender
      hitpoints__lastOffenderPlayer = lastCriticalOffender

  setOptional(eid, "killer", hitpoints__lastOffender)
  setOptional(eid, "lastDamageType", death_desc__damageType)
  send_net_event(eid, [[EventEntityDied
    victim=eid, offender=hitpoints__lastOffender,
    damageType=death_desc__damageType, gunPropsId=death_desc__gunPropsId, shellId=death_desc__shellId,
    collNodeId=death_desc__collNodeId, victimTeam=death_desc__victimTeam, offenderTeam=death_desc__offenderTeam]])
  broadcast_net_event([[EventAnyEntityDied
    victim=eid, offender=hitpoints__lastOffender, offenderPlayer=hitpoints__lastOffenderPlayer,
    victimPlayer=hitpoints__lastVictimPlayer, damageType=death_desc__damageType, gunPropsId=death_desc__gunPropsId, shellId=death_desc__shellId,
    collNodeId=death_desc__collNodeId, victimTeam=death_desc__victimTeam, offenderTeam=death_desc__offenderTeam]])


def update_hitpoints_impl(cur_time : float;
                          dt : float;
                          eid : EntityId;
                          death_desc__damageType : int;
                          death_desc__gunPropsId : int;
                          death_desc__shellId : int;
                          death_desc__collNodeId : int;
                          death_desc__victimTeam : int;
                          death_desc__offenderTeam : int;
                          var hitpoints__timeFromLastDamage : float&;
                          var hitpoints__lastOffender : EntityId&;
                          var hitpoints__lastOffenderPlayer : EntityId&;
                          hitpoints__lastVictimPlayer : EntityId;
                          var hitpoints__hp : float&;
                          var isAlive : bool&; // we should change isAlive, as if we're sending event immediately receiver will observe that this entity is not dead yet
                          var isDowned : bool&;
                          var hitpoints__stoppingPower : float&;
                          hitpoints__maxHp : float;
                          var hitpoints__downedEndTime : float&;
                          var lastCriticalOffender : EntityId&;
                          hitpoints__revivingCount : int;
                          hitpoints__hpThreshold : float;
                          hitpoints__hpRecoverySpd : float;
                          hitpoints__recoveryTimeThreshold : float;
                          hitpoints__stoppingPowerRecoveryRate : float;
                          hitpoints__deathHpThreshold : float;
                          hitpoints__downedTimer : float;
                          entity_mods__downedTimerAdd : float)
  hitpoints__timeFromLastDamage += dt
  if (hitpoints__hp < hitpoints__hpThreshold && hitpoints__hp > 0.f &&
      (hitpoints__timeFromLastDamage < 0.f || hitpoints__timeFromLastDamage > hitpoints__recoveryTimeThreshold))
    hitpoints__hp = min(hitpoints__hp + hitpoints__hpRecoverySpd * dt, min(hitpoints__hpThreshold, hitpoints__maxHp))
  hitpoints__stoppingPower = max(hitpoints__stoppingPower - dt * hitpoints__stoppingPowerRecoveryRate, 0.f)

  let wasDowned = isDowned
  if wasDowned && isAlive && dt > 1e-6f && hitpoints__downedEndTime < cur_time
    hitpoints__hp = hitpoints__deathHpThreshold

  let wasAlive = isAlive
  let curAlive = hitpoints__hp > hitpoints__deathHpThreshold
  if wasAlive != curAlive
    isAlive = curAlive
    if curAlive
      send_net_event(eid, [[EventEntityResurrected]])
      broadcastEvent([[EventAnyEntityResurrected eid=eid]])
    else
      on_death(eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId, death_desc__victimTeam,
               death_desc__offenderTeam, hitpoints__lastOffender, hitpoints__lastOffenderPlayer,
               hitpoints__lastVictimPlayer, lastCriticalOffender)
  if curAlive && wasDowned && (hitpoints__revivingCount != 0)
    hitpoints__downedEndTime += dt
  let curDowned = hitpoints__hp <= 0.f && isAlive
  if wasDowned != curDowned
    if !curDowned
      isDowned = false
      if isAlive
        send_net_event(eid, [[EventEntityRevived]])
        lastCriticalOffender = INVALID_ENTITY_ID
        hitpoints__downedEndTime = -1.f
    else
      sendEventImmediate(eid, [[EventOnDownedThreshold]])
      if hitpoints__hp <= hitpoints__deathHpThreshold
        isAlive = false
        on_death(eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId, death_desc__victimTeam,
                 death_desc__offenderTeam, hitpoints__lastOffender, hitpoints__lastOffenderPlayer,
                 hitpoints__lastVictimPlayer, lastCriticalOffender)
      elif hitpoints__hp <= 0.f
        isDowned = true
        hitpoints__downedEndTime = get_sync_time() + hitpoints__downedTimer + entity_mods__downedTimerAdd
        send_net_event(eid, [[EventEntityDowned offender=hitpoints__lastOffender]])
        broadcastEvent([[EventAnyEntityDowned victim=eid, offender=hitpoints__lastOffender]])
        lastCriticalOffender = hitpoints__lastOffenderPlayer


[es(tag=server)]
def hitpoints_es(info : UpdateStageInfoAct;
                 eid : EntityId;
                 death_desc__damageType : int;
                 death_desc__gunPropsId : int;
                 death_desc__shellId : int;
                 death_desc__collNodeId : int;
                 death_desc__victimTeam : int;
                 death_desc__offenderTeam : int;
                 var hitpoints__hp : float&;
                 var hitpoints__lastOffender : EntityId&;
                 var hitpoints__lastOffenderPlayer : EntityId&;
                 hitpoints__lastVictimPlayer : EntityId;
                 var hitpoints__timeFromLastDamage : float&;
                 var isAlive : bool&;
                 var isDowned : bool&;
                 var hitpoints__stoppingPower : float&;
                 hitpoints__maxHp : float;
                 var hitpoints__downedEndTime : float&;
                 var lastCriticalOffender : EntityId&;
                 hitpoints__revivingCount : int = DEF_REVIVINGCOUNT;
                 hitpoints__hpThreshold : float = DEF_HPTHRESHOLD;
                 hitpoints__hpRecoverySpd : float = DEF_HPRECOVERYSPD;
                 hitpoints__recoveryTimeThreshold : float = DEF_RECOVERYTIMETHRESHOLD;
                 hitpoints__stoppingPowerRecoveryRate : float = DEF_STOPPINGPOWERRECOVERYRATE;
                 hitpoints__deathHpThreshold : float = DEF_DEATHHPTHRESHOLD;
                 hitpoints__downedTimer : float = DEF_DOWNEDTIMER;
                 entity_mods__downedTimerAdd : float = DEF_DOWNEDTIMERADD)
  update_hitpoints_impl(info.curTime, info.dt, eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId,
                        death_desc__victimTeam, death_desc__offenderTeam, hitpoints__timeFromLastDamage, hitpoints__lastOffender,
                        hitpoints__lastOffenderPlayer, hitpoints__lastVictimPlayer, hitpoints__hp, isAlive, isDowned,
                        hitpoints__stoppingPower, hitpoints__maxHp, hitpoints__downedEndTime,
                        lastCriticalOffender, hitpoints__revivingCount, hitpoints__hpThreshold,
                        hitpoints__hpRecoverySpd, hitpoints__recoveryTimeThreshold,
                        hitpoints__stoppingPowerRecoveryRate, hitpoints__deathHpThreshold,
                        hitpoints__downedTimer, entity_mods__downedTimerAdd)

[es(tag=server)]
def force_update_hitpoints(evt : CmdUpdateHitpoints;
                           eid : EntityId;
                           death_desc__damageType : int;
                           death_desc__gunPropsId : int;
                           death_desc__shellId : int;
                           death_desc__collNodeId : int;
                           death_desc__victimTeam : int;
                           death_desc__offenderTeam : int;
                           var hitpoints__hp : float&;
                           var hitpoints__lastOffender : EntityId&;
                           var hitpoints__lastOffenderPlayer : EntityId&;
                           hitpoints__lastVictimPlayer : EntityId;
                           var hitpoints__timeFromLastDamage : float&;
                           var isAlive : bool&;
                           var isDowned : bool&;
                           var hitpoints__stoppingPower : float&;
                           hitpoints__maxHp : float;
                           var hitpoints__downedEndTime : float&;
                           var lastCriticalOffender : EntityId&;
                           hitpoints__revivingCount : int = DEF_REVIVINGCOUNT;
                           hitpoints__hpThreshold : float = DEF_HPTHRESHOLD;
                           hitpoints__hpRecoverySpd : float = DEF_HPRECOVERYSPD;
                           hitpoints__recoveryTimeThreshold : float = DEF_RECOVERYTIMETHRESHOLD;
                           hitpoints__stoppingPowerRecoveryRate : float = DEF_STOPPINGPOWERRECOVERYRATE;
                           hitpoints__deathHpThreshold : float = DEF_DEATHHPTHRESHOLD;
                           hitpoints__downedTimer : float = DEF_DOWNEDTIMER;
                           entity_mods__downedTimerAdd : float = DEF_DOWNEDTIMERADD)
  let dt = 0.f
  update_hitpoints_impl(evt.time, dt, eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId,
                        death_desc__victimTeam, death_desc__offenderTeam, hitpoints__timeFromLastDamage, hitpoints__lastOffender,
                        hitpoints__lastOffenderPlayer, hitpoints__lastVictimPlayer, hitpoints__hp, isAlive, isDowned,
                        hitpoints__stoppingPower, hitpoints__maxHp, hitpoints__downedEndTime,
                        lastCriticalOffender, hitpoints__revivingCount, hitpoints__hpThreshold,
                        hitpoints__hpRecoverySpd, hitpoints__recoveryTimeThreshold,
                        hitpoints__stoppingPowerRecoveryRate, hitpoints__deathHpThreshold,
                        hitpoints__downedTimer, entity_mods__downedTimerAdd)


[es(REQUIRE=hitpoints__maxHp)]
def hitpoints_apply_damage(evt : CmdApplyDamage;
                           eid : EntityId;
                           var death_desc__damageType : int&;
                           var death_desc__gunPropsId : int&;
                           var death_desc__shellId : int&;
                           var death_desc__collNodeId : int&;
                           var death_desc__victimTeam : int&;
                           var death_desc__offenderTeam : int&;
                           var hitpoints__timeFromLastDamage : float&;
                           var hitpoints__lastOffender : EntityId&;
                           var hitpoints__lastOffenderPlayer : EntityId&;
                           var hitpoints__lastVictimPlayer : EntityId&;
                           var hitpoints__stoppingPower : float&;
                           var hitpoints__hp : float&;
                           var hitpoints__lastHitNodeId : int&;
                           var hitpoints__lastOffenderTime : float&;
                           beh_tree__enabled aka victim_beh_tree__enabled : bool = false;
                           possessedByPlr aka victim_possessedByPlr : EntityId = INVALID_ENTITY_ID;
                           hitpoints__clearOffenderTimer : float = 30.;
                           hitpoints__deathHpThreshold : float = 0.;
                           hitpoints__dmgMult : float = 1.;
                           hitpoints__stoppingPowerThreshold : float = 0.;
                           hitpoints__stoppingPowerToHpMult : float = 1.;
                           hitpoints__killDownedByMeleeHit : bool = false;
                           team : int = TEAM_UNASSIGNED)
  if evt.deltaHp < 0.
    return

  let victim = eid
  var offender = evt.offender

  let offenderPossessedByPlayer = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
  var offenderPlayer = offenderPossessedByPlayer
  var lastOffenderTeam = death_desc__offenderTeam
  let offenderTeam = get_int(offender, "team") ?? get_int(offenderPlayer, "team") ?? TEAM_UNASSIGNED
  if !offenderPlayer
    let maxInertialKillTime = 4.
    let driver = get_last_vehicle_driver_possessed_by_player(offender, maxInertialKillTime)
    if !!driver
      offender = driver
      offenderPlayer = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID

  var deltaHp = evt.deltaHp

  let curStoppingPower = hitpoints__stoppingPower
  let stopPowerThres = hitpoints__stoppingPowerThreshold
  if curStoppingPower + evt.stoppingPower > stopPowerThres
    let deltaStopPower = clamp(curStoppingPower + evt.stoppingPower - stopPowerThres, 0., evt.stoppingPower)
    deltaHp += hitpoints__stoppingPowerToHpMult * deltaStopPower
  hitpoints__stoppingPower = hitpoints__stoppingPower + evt.stoppingPower

  if victim != offender // ignore spawn immunity in case of suicide
    deltaHp *= hitpoints__dmgMult
    let isOffenderBehTreeEnabled = (get_bool(offender, "beh_tree__enabled") ?? false)
    if !isOffenderBehTreeEnabled && victim_beh_tree__enabled
      query(offenderPossessedByPlayer) <| $ [es] (player__damageToBotsScale : float)
        deltaHp *= player__damageToBotsScale
    if isOffenderBehTreeEnabled && !victim_beh_tree__enabled
      query(victim_possessedByPlr) <| $ [es] (player__damageFromBotsScale : float)
        deltaHp *= player__damageFromBotsScale
  let deathHp = hitpoints__deathHpThreshold
  let wasDowned = hitpoints__hp <= 0.f
  let wasDead = hitpoints__hp <= deathHp

  if (hitpoints__killDownedByMeleeHit && wasDowned &&
      (evt.damageType == int(DamageType DM_MELEE) || evt.damageType == int(DamageType DM_BACKSTAB)))
    hitpoints__hp = hitpoints__deathHpThreshold
  else
    hitpoints__hp = max(hitpoints__hp - deltaHp, deathHp)

  var hitr : HitResult
  if wasDead
    hitr = HitResult HIT_RES_NONE
  elif hitpoints__hp > 0.
    hitr = HitResult HIT_RES_NORMAL
  elif hitpoints__hp > deathHp
    hitr = wasDowned ? HitResult HIT_RES_NORMAL : HitResult HIT_RES_DOWNED
  else
    hitr = HitResult HIT_RES_KILLED

  broadcastEvent([[EventOnEntityHit
    victim = victim,
    offender = offender,
    hitResult = int(hitr),
    damageType = evt.damageType,
    shellId = evt.shellId,
    gunPropsId = evt.gunPropsId,
    actionPropsId = evt.actionPropsId,
    collNodeId = evt.collNodeId,
    deltaHp = evt.deltaHp,
    blockingDeltaHp = evt.blockingDeltaHp,
    stoppingPower = evt.stoppingPower,
    hitPos = evt.hitPos,
    hitDir = evt.hitDir,
    hitNorm = evt.hitNorm,
    dmgMult = evt.dmgMult,
    armorMult = evt.armorMult
  ]])

  let isLastOffenderPlayer = hitpoints__lastOffenderPlayer != INVALID_ENTITY_ID && hitpoints__lastOffender != victim
  let isNewOffenderPlayer = !!offenderPlayer && offender != victim
  let isLastOffenderTimeIsUp = (hitpoints__lastOffenderTime < 0. ||
                                get_sync_time() - hitpoints__lastOffenderTime > hitpoints__clearOffenderTimer)

  hitpoints__timeFromLastDamage = 0.
  if !isLastOffenderPlayer || isNewOffenderPlayer || isLastOffenderTimeIsUp
    hitpoints__lastOffenderTime = get_sync_time()
    hitpoints__lastOffender = offender
    lastOffenderTeam = offenderTeam

    let victimPlayerEid = get_Eid(victim, "possessedByPlr") ?? INVALID_ENTITY_ID
    if !!victimPlayerEid
      hitpoints__lastVictimPlayer = victimPlayerEid

    hitpoints__lastOffenderPlayer = offenderPlayer
  hitpoints__lastHitNodeId = int(evt.collNodeId)

  death_desc__damageType = int(evt.damageType)
  death_desc__gunPropsId = int(evt.gunPropsId)
  death_desc__shellId = int(evt.shellId)
  death_desc__collNodeId = int(evt.collNodeId)
  death_desc__victimTeam = team
  death_desc__offenderTeam = lastOffenderTeam

[es(REQUIRE=hitpoints__hp)] // Note: client doesn't have 'hitpoints' component (only attribute)
def hp_death_es(evt : EventEntityDied; var isAlive : bool&)
  isAlive = false // This is important on client (where replication is in different channel then net messages)
