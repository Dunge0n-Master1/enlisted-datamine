require ecs
require DngWalkerai
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common
require game.es.squad_order_common

[es(tag=server)]
def on_cancel_squad_mate_order(squadMateOrder : RequestSquadMateOrder; eid : EntityId; squad__leader : EntityId)
  if squadMateOrder.orderType == SquadMateOrder ESMO_NO_ORDER
    reset_squad_mate_orders(eid, squad__leader)
    reset_squad_behaviour(eid)

[es(tag=server)]
def on_cancel_personal_squadmate_order(personalSquadMateOrder : RequestPersonalSquadMateOrder; eid : EntityId)
  if personalSquadMateOrder.orderType == int(SquadMateOrder ESMO_NO_ORDER)
    reset_personal_squadmate_orders(eid)
    reset_squad_mate_behaviour(eid)

[es(tag=server, track=squad__leader)]
def reset_squad_mate_order_on_squad_leader_change(evt : Event; eid, squad__leader, squad__ownerPlayer : EntityId)
  if has(squad__ownerPlayer, "botAiEnabler")
    return

  reset_squadmate_orders_exclude_personal(eid)
  reset_personal_squadmate_orders(squad__leader)
  reset_squad_behaviour_exclude_personal(eid)

[es(tag=server, no_order)]
def sync_squad_mate_order_status(act : UpdateStageInfoAct; eid : EntityId; squad__leader : EntityId;
                                 squad__numAliveMembers : int; var squad__hasPersonalOrder : bool&)
  squad__hasPersonalOrder = squad__numAliveMembers > 1 && collect_squad(eid, squad__leader) <| $(member_eid : EntityId)
    return get_int(member_eid, "squad_member__orderType") ?? int(SquadMateOrder ESMO_NO_ORDER) != int(SquadMateOrder ESMO_NO_ORDER)
