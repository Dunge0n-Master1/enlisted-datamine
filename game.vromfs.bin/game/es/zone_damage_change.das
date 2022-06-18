require ecs
require math

[es(on_event=EventOnMovingZoneStarted)]
def zone_damage_change_es(evt : Event; var dmgzone__damage : float&; dmgzone__damageIncrease : float; dmgzone__damageCap : float)
  dmgzone__damage = min(dmgzone__damage * dmgzone__damageIncrease, dmgzone__damageCap)
