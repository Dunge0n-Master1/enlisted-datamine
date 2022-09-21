require ecs
require enlisted.events_enlisted
require enlisted.game.es.stat_bq.send_squad_cmd_stat_bq_common
require game.es.squad_order_common

[es]
def send_new_player_order_bq(evt : RequestSquadOrder; squad__leader : EntityId)
  new_player_order_bq(squad__leader, "{evt.orderType}")

[es]
def send_new_player_mate_order_bq(evt : RequestSquadMateOrder; squad__leader : EntityId)
  new_player_order_bq(squad__leader, "{evt.orderType}")