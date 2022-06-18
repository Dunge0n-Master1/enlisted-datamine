require ecs
require game.es.events

[es(tag=server)]
def heal_applied(evt : EventOnLootItemUsed; item__restoreHpAmount : float)
  query(evt.target) <| $ [es] (var hitpoints_heal__restoreAmount : float&; hitpoints__hp, hitpoints__maxHp : float; hitpoints_heal__restoreReserveLimit : float = -1.0; entity_mods__healAmountMult : float = 1.0)
    hitpoints_heal__restoreAmount += item__restoreHpAmount * entity_mods__healAmountMult
    if hitpoints_heal__restoreReserveLimit >= 0.0
      hitpoints_heal__restoreAmount = min(hitpoints_heal__restoreAmount, hitpoints__maxHp - hitpoints__hp + hitpoints_heal__restoreReserveLimit)

[es(tag=server, no_order)]
def heal_restore_hp(info : UpdateStageInfoAct; var hitpoints__hp : float&; var hitpoints_heal__restoreAmount : float&;
                    hitpoints__maxHp : float;
                    hitpoints_heal__restoreSpeed : float)
  if hitpoints_heal__restoreAmount <= 0.0
    return
  let healAmount = min(hitpoints_heal__restoreAmount, hitpoints_heal__restoreSpeed * info.dt)
  hitpoints_heal__restoreAmount -= healAmount
  if hitpoints__hp <= 0.0 || hitpoints__hp >= hitpoints__maxHp
    return
  let leftToHeal = hitpoints__maxHp - hitpoints__hp
  hitpoints__hp += min(healAmount, leftToHeal)

