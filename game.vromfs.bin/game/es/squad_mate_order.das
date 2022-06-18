require ecs
require EnlistedWalkerai
require enlisted.events_enlisted
require enlisted.game.es.enlisted_squad_common

[es(tag=server)]
def on_cancel_squad_mate_order(squadMateOrder : RequestSquadMateOrder; eid : ecs::EntityId; squad__leader : ecs::EntityId)
  if squadMateOrder.orderType == SquadMateOrder ESMO_NO_ORDER
    reset_squad_mate_orders(eid, squad__leader)

[es(tag=server)]
def on_cancel_personal_squadmate_order(personalSquadMateOrder : RequestPersonalSquadMateOrder; eid : ecs::EntityId)
  if personalSquadMateOrder.orderType == int(SquadMateOrder ESMO_NO_ORDER)
    reset_personal_squadmate_orders(eid)

[es(tag=server, track=squad__leader)]
def reset_squad_mate_order_on_squad_leader_change(evt : Event; eid, squad__leader : ecs::EntityId)
  reset_squadmate_orders_exclude_personal(eid, squad__leader)
  reset_personal_squadmate_orders(squad__leader)

[es(tag=server, no_order)]
def sync_squad_mate_order_status(act : ecs::UpdateStageInfoAct; eid : ecs::EntityId; squad__leader : ecs::EntityId;
                                 squad__numAliveMembers : int; var squad__hasPersonalOrder : bool&)
  squad__hasPersonalOrder = squad__numAliveMembers > 1 && collect_squad(eid, squad__leader) <| $(member_eid : EntityId)
    return get_int(member_eid, "squad_member__orderType") ?? int(SquadMateOrder ESMO_NO_ORDER) != int(SquadMateOrder ESMO_NO_ORDER)
