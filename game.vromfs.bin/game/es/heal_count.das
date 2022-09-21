require ecs


[es(track=itemContainer, on_event=(EventOnLootUse, EventUpdatedItemContainer), on_appear, tag=server)]
def calculate_heal_items_count(evt : Event;
                               itemContainer : EidList;
                               var total_kits__selfHeal : int&;
                               var total_kits__targetHeal : int&;
                               var total_kits__targetOnlyHeal : int&;
                               var total_kits__selfRevive : int&;
                               var total_kits__targetRevive : int&)
  total_kits__selfHeal = 0
  total_kits__targetHeal = 0
  total_kits__targetOnlyHeal = 0
  total_kits__selfRevive = 0
  total_kits__targetRevive = 0
  for itemEid in itemContainer
    query(itemEid) <| $ [es] (item__healAmount : float?;
                              item__reviveAmount : float?;
                              item__useTime : float?;
                              item__useTimeToTarget : float?;
                              item__useCount : int?;
                              item__targetUseOnly : Tag?)
      let heal = item__healAmount != null
      let revive = item__reviveAmount != null
      let targetOnly = item__targetUseOnly != null
      let self = item__useTime != null && !targetOnly
      let target = item__useTimeToTarget != null

      let uses = item__useCount ?? 1

      total_kits__selfHeal += heal && self ? uses : 0
      total_kits__targetHeal += heal && target ? uses : 0
      total_kits__targetOnlyHeal += heal && target && targetOnly ? uses : 0
      total_kits__selfRevive += revive && self ? uses : 0
      total_kits__targetRevive += revive && target ? uses : 0
