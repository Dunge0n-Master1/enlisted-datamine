require ecs
require game.utils.net_utils
require game.events_game
require EnlistedNet

[es(tag=server, no_order)]
def afk_server_es(info : UpdateStageInfoAct;
                  eid : EntityId;
                  afk__time : float;
                  afk__showWarningTimeout : int;
                  afk__showDisconnectWarningTimeout : int)
  let afkTime = int(afk__time)
  let prevAfkSec = int(afk__time - info.dt)
  if afkTime == prevAfkSec
    return
  if afkTime == afk__showWarningTimeout
    send_net_event(eid, [[AFKShowWarning]], target_entity_conn(eid))
  if afkTime == afk__showDisconnectWarningTimeout
    send_net_event(eid, [[AFKShowDisconnectWarning]], target_entity_conn(eid))
