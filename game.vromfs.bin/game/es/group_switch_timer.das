require ecs
require strings
require game.es.capzones_common

[es(tag=server, no_order)]
def group_switch_timer(info : UpdateStageInfoAct;
                       eid : EntityId;
                       group_switch_timer__time : float;
                       group_switch_timer__deactivateGroup : string;
                       group_switch_timer__activateGroup : string)
  query() <| $ [es] (firstPlayerConnectionTime : float)
    if firstPlayerConnectionTime >= 0. && info.curTime > firstPlayerConnectionTime + group_switch_timer__time
      if !empty(group_switch_timer__deactivateGroup)
        deactivate_group(group_switch_timer__deactivateGroup)
      if !empty(group_switch_timer__activateGroup)
        activate_group(group_switch_timer__activateGroup)
      destroyEntity(eid)
