require ecs
require AnimV20
require enlisted.events_enlisted
require common_shooter.es.render.animation_common
require game.es.events

[es(tag=gameClient, on_appear)]
def init_vehicle_exit_animator(evt : Event;
                               human_vehicle__exitAnim : string;
                               var human_vehicle__exitAnimId : int&;
                               animchar : AnimcharBaseComponent)
  assume animGraph = animchar.animGraph
  if animGraph != null
    human_vehicle__exitAnimId = anim_graph_getStateIdx(*animGraph, human_vehicle__exitAnim)

[es(tag=gameClient, after=human_anim_es, REQUIRE=human_vehicle__exitAnimator)]
def human_vehicle_custom_animator(info : ParallelUpdateFrameDelayed;
                                  eid : EntityId;
                                  human_vehicle__exitAtTime : float;
                                  human_vehicle__exitAnimId : int;
                                  human_anim__vehicleSelected : EntityId)
  if !has(human_anim__vehicleSelected, "customExitPos")
    removeSubTemplate(eid, "human_vehicle_custom_exit_animator")
  if human_vehicle__exitAtTime > info.curTime
    set_human_anim_state(eid, human_vehicle__exitAnimId)
