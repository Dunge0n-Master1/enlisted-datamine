require ecs
require DngDm
require math
require app

[es(tag=server, track=burning__isBurning)]
def fire_damage_track_burning(evt : Event;
                              burning__isBurning : bool;
                              var burning__nextDamageAtTime : float&;
                              burning__updateInterval : float)
  burning__nextDamageAtTime = burning__isBurning ? get_sync_time() + burning__updateInterval : -1.0

[es(tag=server, before=hitpoints_es)]
def fire_damage(info : ecs::UpdateStageInfoAct;
                eid : EntityId;
                transform : float3x4;
                var burning__isBurning : bool&;
                var burning__force : float&;
                var burning__tickIncrement : float&;
                var burning__nextDamageAtTime : float&;
                burning__decrease : float;
                burning__damagePerSecond : float;
                burning__maxForce : float;
                burning__isPuttingOut : bool;
                burning__putOutDamageMult : float;
                burning__updateInterval : float;
                entity_mods__fireDamageMult : float = 1.0;
                burning__offender : EntityId = ecs::INVALID_ENTITY_ID;
                burning__offenderGunPropsId : int = -1;
                burning__offenderShellId : int = -1)
  if burning__nextDamageAtTime < 0.f || info.curTime < burning__nextDamageAtTime
    return

  burning__nextDamageAtTime += burning__updateInterval
  let dt = burning__updateInterval

  let increment = burning__tickIncrement
  burning__tickIncrement = 0.0

  let pos = transform[3]
  var damagePerSecond = burning__damagePerSecond
  if burning__isPuttingOut
    damagePerSecond *= burning__putOutDamageMult
  let offender = burning__offender != ecs::INVALID_ENTITY_ID ? burning__offender : eid
  let damage = dt * damagePerSecond * entity_mods__fireDamageMult
  if damage > 0f
    var dmDesc : DamageDesc = DamageDesc(DamageType DM_FIRE, damage, pos)
    dmDesc.gunPropsId = int16(burning__offenderGunPropsId)
    dmDesc.shellId = int16(burning__offenderShellId)
    damage_entity(eid, offender, dmDesc)

  let burningForce = burning__force + increment - dt * burning__decrease
  burning__force = min(burning__maxForce, burningForce)
  if burning__force <= 0.0
    burning__force = 0.0
    burning__isBurning = false