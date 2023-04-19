require ecs
require app
require DngDm
require DagorMath
require DngHuman
require DaWeaponProps
require game.es.events
require common_shooter.es.confusion_common
require game.utils.hero
require common_shooter.events_common_shooter


[es(tag=server, no_order)]
def confusion_timer(info : UpdateStageInfoAct;
                    eid : EntityId;
                    confusion__startedAtTime : float;
                    confusion__duration : float)
  if info.curTime > confusion__startedAtTime + confusion__duration
    destroyEntity(eid)

[es(tag=server, REQUIRE=human)]
def on_zone_damage_apply_concussion(evt : EventOnEntityHit; eid : EntityId; isAlive : bool)
  if evt.victim == eid && evt.damageType == int(DamageType DM_ZONE) && isAlive
    enable_confusion_affect(eid)

[es(tag=server, track=isAlive)]
def on_death_disable_confusion(evt : Event; eid : EntityId; isAlive : bool)
  if !isAlive
    disable_confusion_affect(eid)


[es(tag=server, REQUIRE=human)]
def on_hit_confusion(evt : EventOnEntityHit; eid : EntityId; isAlive : bool)
  if evt.victim != eid || !isAlive
    return
  if evt.damageType == int(DamageType DM_MELEE) || evt.damageType == int(DamageType DM_BACKSTAB)
    let actionPropId = evt.actionPropsId
    if actionPropId >= 0
      melee_get_props(actionPropId) <| $(meleeProps : MeleeProps)
        if meleeProps.confusion
          enable_confusion_affect(eid)