require ecs
require app
require math.base
require game.es.events
require enlisted.game.es.offender_cache_common
require common_shooter.events_common_shooter
require common_shooter.es.hitpoints_common
require game.es.vehicle.vehicle_seats_common
require game.events_game
require game.utils.team
require EnlistedDm
require EnlistedNet
require vehicle
require game.events_game

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
             victim_team : int;
             death_desc__offenderTeam : int;
             hitpoints__lastOffender : EntityId;
             hitpoints__lastOffenderPlayer : EntityId;
             hitpoints__lastVictimPlayer : EntityId)
  setOptional(eid, "killer", hitpoints__lastOffender)
  setOptional(eid, "lastDamageType", death_desc__damageType)
  send_net_event(eid, [[EventEntityDied
    victim=eid, offender=hitpoints__lastOffender,
    damageType=death_desc__damageType, gunPropsId=death_desc__gunPropsId, shellId=death_desc__shellId,
    collNodeId=death_desc__collNodeId, victimTeam=victim_team, offenderTeam=death_desc__offenderTeam]])
  broadcast_net_event([[EventAnyEntityDied
    victim=eid, offender=hitpoints__lastOffender, offenderPlayer=hitpoints__lastOffenderPlayer,
    victimPlayer=hitpoints__lastVictimPlayer, damageType=death_desc__damageType, gunPropsId=death_desc__gunPropsId, shellId=death_desc__shellId,
    collNodeId=death_desc__collNodeId, victimTeam=victim_team, offenderTeam=death_desc__offenderTeam]])


def update_hitpoints_impl(cur_time : float;
                          dt : float;
                          eid : EntityId;
                          death_desc__damageType : int;
                          death_desc__gunPropsId : int;
                          death_desc__shellId : int;
                          death_desc__collNodeId : int;
                          victim_team : int;
                          death_desc__offenderTeam : int;
                          var hitpoints__timeFromLastDamage : float&;
                          hitpoints__lastOffender : EntityId;
                          hitpoints__lastOffenderPlayer : EntityId;
                          hitpoints__lastVictimPlayer : EntityId;
                          var hitpoints__hp : float&;
                          var isAlive : bool&; // we should change isAlive, as if we're sending event immediately receiver will observe that this entity is not dead yet
                          var isDowned : bool&;
                          var hitpoints__stoppingPower : float&;
                          hitpoints__maxHp : float;
                          var hitpoints__downedEndTime : float&;
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
  var killedByDowned = false
  if wasDowned && isAlive && dt > 1e-6f && hitpoints__downedEndTime < cur_time
    hitpoints__hp = hitpoints__deathHpThreshold
    killedByDowned = true

  let wasAlive = isAlive
  let curAlive = hitpoints__hp > hitpoints__deathHpThreshold
  if wasAlive != curAlive
    isAlive = curAlive
    if curAlive
      send_net_event(eid, [[EventEntityResurrected]])
      broadcastEvent([[EventAnyEntityResurrected eid=eid]])
    else
      if !killedByDowned
        sendEvent(hitpoints__lastOffender, [[EventEntityKilledToPart collNodeId=death_desc__collNodeId, damageType=death_desc__damageType, killer=hitpoints__lastOffender]])
      on_death(eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId, victim_team,
               death_desc__offenderTeam, hitpoints__lastOffender, hitpoints__lastOffenderPlayer,
               hitpoints__lastVictimPlayer)
  if curAlive && wasDowned && (hitpoints__revivingCount != 0)
    hitpoints__downedEndTime += dt
  let curDowned = hitpoints__hp <= 0.f && isAlive
  if wasDowned != curDowned
    if !curDowned
      isDowned = false
      if isAlive
        send_net_event(eid, [[EventEntityRevived]])
        hitpoints__downedEndTime = -1.f
    else
      sendEventImmediate(eid, [[EventOnDownedThreshold]])
      if hitpoints__hp <= hitpoints__deathHpThreshold
        isAlive = false
        sendEvent(hitpoints__lastOffender, [[EventEntityKilledToPart collNodeId=death_desc__collNodeId, damageType=death_desc__damageType, killer=hitpoints__lastOffender]])
        on_death(eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId, victim_team,
                 death_desc__offenderTeam, hitpoints__lastOffender, hitpoints__lastOffenderPlayer,
                 hitpoints__lastVictimPlayer)
      elif hitpoints__hp <= 0.f
        isDowned = true
        hitpoints__downedEndTime = get_sync_time() + hitpoints__downedTimer + entity_mods__downedTimerAdd
        send_net_event(eid, [[EventEntityDowned offender=hitpoints__lastOffender]])
        broadcastEvent([[EventAnyEntityDowned victim=eid, offender=hitpoints__lastOffender]])


[es(tag=server)]
def hitpoints_es(info : UpdateStageInfoAct;
                 eid : EntityId;
                 death_desc__damageType : int;
                 death_desc__gunPropsId : int;
                 death_desc__shellId : int;
                 death_desc__collNodeId : int;
                 death_desc__offenderTeam : int;
                 var hitpoints__hp : float&;
                 hitpoints__lastOffender : EntityId;
                 hitpoints__lastOffenderPlayer : EntityId;
                 hitpoints__lastVictimPlayer : EntityId;
                 var hitpoints__timeFromLastDamage : float&;
                 var isAlive : bool&;
                 var isDowned : bool&;
                 var hitpoints__stoppingPower : float&;
                 hitpoints__maxHp : float;
                 var hitpoints__downedEndTime : float&;
                 team : int = TEAM_UNASSIGNED;
                 hitpoints__revivingCount : int = DEF_REVIVINGCOUNT;
                 hitpoints__hpThreshold : float = DEF_HPTHRESHOLD;
                 hitpoints__hpRecoverySpd : float = DEF_HPRECOVERYSPD;
                 hitpoints__recoveryTimeThreshold : float = DEF_RECOVERYTIMETHRESHOLD;
                 hitpoints__stoppingPowerRecoveryRate : float = DEF_STOPPINGPOWERRECOVERYRATE;
                 hitpoints__deathHpThreshold : float = DEF_DEATHHPTHRESHOLD;
                 hitpoints__downedTimer : float = DEF_DOWNEDTIMER;
                 entity_mods__downedTimerAdd : float = DEF_DOWNEDTIMERADD)
  update_hitpoints_impl(info.curTime, info.dt, eid, death_desc__damageType, death_desc__gunPropsId, death_desc__shellId, death_desc__collNodeId,
                        team, death_desc__offenderTeam, hitpoints__timeFromLastDamage, hitpoints__lastOffender,
                        hitpoints__lastOffenderPlayer, hitpoints__lastVictimPlayer, hitpoints__hp, isAlive, isDowned,
                        hitpoints__stoppingPower, hitpoints__maxHp, hitpoints__downedEndTime,
                        hitpoints__revivingCount, hitpoints__hpThreshold,
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
                           death_desc__offenderTeam : int;
                           var hitpoints__hp : float&;
                           hitpoints__lastOffender : EntityId;
                           hitpoints__lastOffenderPlayer : EntityId;
                           hitpoints__lastVictimPlayer : EntityId;
                           var hitpoints__timeFromLastDamage : float&;
                           var isAlive : bool&;
                           var isDowned : bool&;
                           var hitpoints__stoppingPower : float&;
                           hitpoints__maxHp : float;
                           var hitpoints__downedEndTime : float&;
                           team : int = TEAM_UNASSIGNED;
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
                        team, death_desc__offenderTeam, hitpoints__timeFromLastDamage, hitpoints__lastOffender,
                        hitpoints__lastOffenderPlayer, hitpoints__lastVictimPlayer, hitpoints__hp, isAlive, isDowned,
                        hitpoints__stoppingPower, hitpoints__maxHp, hitpoints__downedEndTime,
                        hitpoints__revivingCount, hitpoints__hpThreshold,
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
                           var death_desc__offenderTeam : int&;
                           var hitpoints__timeFromLastDamage : float&;
                           var hitpoints__lastOffender : EntityId&;
                           var hitpoints__lastOffenderPlayer : EntityId&;
                           var hitpoints__lastVictimPlayer : EntityId&;
                           var hitpoints__stoppingPower : float&;
                           var hitpoints__hp : float&;
                           var hitpoints__lastHitNodeId : int&;
                           var hitpoints__lastOffenderTime : float&;
                           var hitpoints__lastOffenderSquadPlayer : EntityId&;
                           beh_tree__enabled aka victim_beh_tree__enabled : bool = false;
                           possessedByPlr aka victim_possessedByPlr : EntityId = INVALID_ENTITY_ID;
                           hitpoints__clearOffenderTimer : float = 30.;
                           hitpoints__deathHpThreshold : float = 0.;
                           hitpoints__dmgMult : float = 1.;
                           hitpoints__stoppingPowerThreshold : float = 0.;
                           hitpoints__stoppingPowerToHpMult : float = 1.;
                           hitpoints__killDownedByMeleeHit : bool = false;
                           isDowned : bool = false;
                           team aka victim_team : int = TEAM_UNASSIGNED)
  if evt.deltaHp < 0.
    return

  let victim = eid
  var offender = evt.offender

  var offenderPossessedByPlayer = INVALID_ENTITY_ID
  var offenderTeam = TEAM_UNASSIGNED
  var offenderSquadPlayer = INVALID_ENTITY_ID

  let offenderExists = query(offender) <| $ [es] (possessedByPlr : EntityId = INVALID_ENTITY_ID;
                                                  squad_member__playerEid : EntityId = INVALID_ENTITY_ID;
                                                  team : int = TEAM_UNASSIGNED)
    offenderPossessedByPlayer = possessedByPlr
    offenderSquadPlayer = squad_member__playerEid
    offenderTeam = team
  if !offenderExists
    let cacheOffender = get_offender_from_cache(offender)
    offenderSquadPlayer = cacheOffender.player
    offenderTeam = get_int(offenderSquadPlayer, "team") ?? TEAM_UNASSIGNED

  if !offenderPossessedByPlayer
    let maxInertialKillTime = 4.
    let driver = get_last_vehicle_driver_possessed_by_player(offender, maxInertialKillTime)
    if !!driver
      offender = driver
      offenderPossessedByPlayer = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID

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
  let isCritDamage = hitr == HitResult HIT_RES_KILLED || hitr == HitResult HIT_RES_DOWNED

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
    armorMult = evt.armorMult,
    armorPenetration = evt.armorPenetration
  ]])

  hitpoints__timeFromLastDamage = 0.
  hitpoints__lastHitNodeId = int(evt.collNodeId)

  try_set_last_offender(offender,
                        offenderTeam,
                        offenderPossessedByPlayer,
                        offenderSquadPlayer,
                        int(evt.damageType),
                        int(evt.gunPropsId),
                        int(evt.shellId),
                        int(evt.collNodeId),
                        isCritDamage,
                        victim,
                        victim_team,
                        isDowned,
                        victim_possessedByPlr,
                        hitpoints__clearOffenderTimer,
                        hitpoints__lastOffenderTime,
                        hitpoints__lastOffender,
                        death_desc__offenderTeam,
                        hitpoints__lastOffenderPlayer,
                        death_desc__damageType,
                        death_desc__gunPropsId,
                        death_desc__shellId,
                        death_desc__collNodeId,
                        hitpoints__lastVictimPlayer,
                        hitpoints__lastOffenderSquadPlayer)

[es(REQUIRE=hitpoints__hp)] // Note: client doesn't have 'hitpoints' component (only attribute)
def hp_death_es(evt : EventEntityDied; var isAlive : bool&)
  isAlive = false // This is important on client (where replication is in different channel then net messages)

[es(tag=server, after=hitpoints_restore_es)]
def clear_last_offender_on_hp_restore(evt : CmdRestoreEntityHp;
                                      hitpoints__hp : float;
                                      hitpoints__resetOffenderAfterHealThreshold : float;
                                      var hitpoints__lastOffenderTime : float&;
                                      var hitpoints__lastOffender : EntityId&;
                                      var death_desc__offenderTeam : int&;
                                      var hitpoints__lastOffenderPlayer : EntityId&;
                                      var death_desc__damageType : int&;
                                      var death_desc__gunPropsId : int&;
                                      var death_desc__shellId : int&;
                                      var death_desc__collNodeId : int&;
                                      var hitpoints__lastVictimPlayer : EntityId&;
                                      var hitpoints__lastOffenderSquadPlayer : EntityId&)
  if hitpoints__hp >= hitpoints__resetOffenderAfterHealThreshold
    reset_last_offender(hitpoints__lastOffenderTime,
                        hitpoints__lastOffender,
                        death_desc__offenderTeam,
                        hitpoints__lastOffenderPlayer,
                        death_desc__damageType,
                        death_desc__gunPropsId,
                        death_desc__shellId,
                        death_desc__collNodeId,
                        hitpoints__lastVictimPlayer,
                        hitpoints__lastOffenderSquadPlayer)

[es(tag=server, REQUIRE=hitpoints)]
def hitpoints_kill_es(evt : CmdKill; eid : EntityId; transform : float3x4; hitpoints__hp : float; hitpoints__deathHpThreshold : float = 0.0)
  let deltaHp = hitpoints__hp + abs(hitpoints__deathHpThreshold)
  var damageDesc = DamageDesc(DamageType(int(evt.damageType)), deltaHp, transform[3])
  damageDesc.gunPropsId = int16(evt.gunPropsId)
  damageDesc.shellId = int16(evt.shellId)
  apply_damage(eid, evt.offender, damageDesc)
