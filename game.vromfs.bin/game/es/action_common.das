module action_common shared
require ecs
require net
require Action
require EnlistedNet
require game.events_game
require game.utils.net_utils

let DEF_ACTION_RANGE = 200.

def run_action_by_id(eid : EntityId; action_id : int; override_props_id : int; interp_delay_ticks : int;
                     override_time : float; override_at : float; action_period : float)
  if action_id < 0
    return
  if is_server()
    send_net_event(eid, [[RunActionCmd id=action_id, overridePropsId=override_props_id,
      overrideTime=override_time, overrideAt=override_at, actionPeriod=action_period]],
      target_entity_pos_range_except_hero(eid, DEF_ACTION_RANGE, /*is_player_relative*/ true))
  run_action_impl(eid, action_id, override_props_id, interp_delay_ticks, override_time, override_at, action_period)

def run_action(eid : EntityId; action : string;
               override_props_id : int = -1;
               interp_delay_ticks : int = -1;
               override_time : float = -1.0;
               override_at : float = -1.0;
               action_period : float = -1.0)
  let actionId = get_action_id(eid, action)
  run_action_by_id(eid, actionId, override_props_id, interp_delay_ticks, override_time, override_at, action_period)
