require ecs
require AnimV20
require common_shooter.es.render.animation_common
require game.es.vehicle.vehicle_events


[es(tag=gameClient, before=human_anim_es, REQUIRE=paratroopersAircraft)]
def paratroopers_freefall_begin_on_plane_left(evt : EventEnterVehicle)
  if evt.enter
    return

  query(evt.incomer) <| $ [es] (human_freefall__gameEffect : EntityId;
                                animchar : AnimcharBaseComponent;
                                var human_freefall__isFreefall : bool&)
    let animGraph = animchar.animGraph
    if human_freefall__gameEffect == INVALID_ENTITY_ID || animGraph == null
      return
    human_freefall__isFreefall = true
    query(human_freefall__gameEffect) <| $ [es] (game_effect__forceAnimState : string;
                                                 var game_effect__attachedTo : EntityId&;
                                                 var game_effect__forceAnimStateId : int&)
      game_effect__attachedTo = evt.incomer
      game_effect__forceAnimStateId = anim_graph_getStateIdx(*animGraph, game_effect__forceAnimState)
      set_human_anim_state(evt.incomer, game_effect__forceAnimStateId)
