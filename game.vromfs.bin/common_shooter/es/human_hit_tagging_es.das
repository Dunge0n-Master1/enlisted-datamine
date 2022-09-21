require ecs
require game.es.events
require app
require EnlistedHuman
require HumanPhys
require DagorMath
require EnlistedDm
require common_shooter.events_common_shooter

[es(before=human_phys_es, after=(human_in_spawn_speed_es, after_entity_mods_apply_sync_point))]
def human_hit_tagging_applier_es(info : ecs::UpdateStageInfoAct;
                                 var human_net_phys : HumanActor;
                                 human_hit_tagging__tagStart : float;
                                 human_hit_tagging__tagEnd : float;
                                 human_hit_tagging__currentTagPower : float)
  if info.curTime < human_hit_tagging__tagStart || info.curTime > human_hit_tagging__tagEnd
    return

  human_net_phys.phys.currentState.moveSpeedMult *= cvt(info.curTime, human_hit_tagging__tagStart,
                                                        human_hit_tagging__tagEnd,
                                                        human_hit_tagging__currentTagPower,
                                                        1.f)

[es(REQUIRE=human_hit_tagging__tagEnd)]
def human_hit_tagging(evt : EventOnEntityHit; eid : EntityId)
  let damageType = evt.damageType
  if eid != evt.victim || damageType == int(DamageType DM_ZONE)
    return

  sendEventImmediate(eid, [[CmdHumanHitTagging powerMult=1.f]])

[es(tag=server)]
def cmd_hit_tagging(evt : CmdHumanHitTagging;
                    var human_hit_tagging__tagStart : float&;
                    var human_hit_tagging__tagEnd : float&;
                    var human_hit_tagging__currentTagPower : float&;
                    human_hit_tagging__tagPower : float  = 0.4f;
                    human_hit_tagging__tagTime : float  = 1.f;
                    human_hit_tagging__maxTime : float  = 1.5f;
                    human_hit_tagging__timeOffset : float  = 0.1f;
                    human_hit_tagging__mult : float  = 1.f)
  let powerMult = evt.powerMult
  let curTime = get_sync_time()
  let alreadyTagged = human_hit_tagging__tagEnd > curTime
  if !alreadyTagged
    human_hit_tagging__tagStart = curTime + human_hit_tagging__timeOffset
  else
    human_hit_tagging__tagStart = curTime
  human_hit_tagging__tagEnd := (alreadyTagged ? min(curTime + human_hit_tagging__maxTime, human_hit_tagging__tagEnd)
                                                : curTime) + human_hit_tagging__tagTime
  human_hit_tagging__currentTagPower = max(0.f, 1.f - ((1.f - human_hit_tagging__tagPower * powerMult) * human_hit_tagging__mult))
