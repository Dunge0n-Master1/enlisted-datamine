require ecs
require app
require game.es.events
require common_shooter.events_common_shooter
require game.events_game
require game.utils.team
require EnlistedNet

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
  sendEvent(eid, [[EventEntityDied
    victim=eid, offender=hitpoints__lastOffender,
    damageType=death_desc__damageType, gunPropsId=death_desc__gunPropsId, shellId=death_desc__shellId,
    collNodeId=death_desc__collNodeId, victimTeam=death_desc__victimTeam, offenderTeam=death_desc__offenderTeam]])
  broadcastEvent([[EventAnyEntityDied
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