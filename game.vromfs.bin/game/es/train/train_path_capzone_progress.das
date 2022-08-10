require ecs
require math.base
require DagorMath
require enlisted.events_enlisted
require game.utils.team
require enlisted.game.es.train.train_capzone_common

[es(tag=server, on_appear, track=(active, capzone__owningTeam, capzone__capTeam, ui_order), REQUIRE=(active, capzone__capTeam, capzone__owningTeam, ui_order, trainTriggerable))]
def set_next_escort_point_on_capzone_change(evt : Event; eid : EntityId; capzone__alwaysShow : bool; capzone__alwaysHide : bool)
  if capzone__alwaysShow && !capzone__alwaysHide
    query() <| $ [es] (var train_progress__nextCapzoneEid : EntityId&)
      if !train_progress__nextCapzoneEid || train_progress__nextCapzoneEid == eid
        train_progress__nextCapzoneEid = get_next_train_checkpoint()

[es(tag=server, on_appear)]
def set_next_escort_point_on_train_init(evt : Event; var train_progress__nextCapzoneEid : EntityId&)
  train_progress__nextCapzoneEid = get_next_train_checkpoint()

[es(tag=server, track=train_progress__nextCapzoneEid)]
def escort_capzone_init_train_path_length(evt : Event;
                                          train_progress__nextCapzoneEid : EntityId;
                                          transform aka train_transform : float3x4)
  query(train_progress__nextCapzoneEid) <| $ [es] (transform aka capzone_transform : float3x4; var capzone__trainPathLength : float&)
    capzone__trainPathLength = length(train_transform[3] - capzone_transform[3])

[es(tag=ui, no_order)]
def escort_capzone_progress(info : ParallelUpdateFrameDelayed;
                            transform aka train_transform : float3x4;
                            train_progress__nextCapzoneEid : EntityId;
                            train_progress__updateInterval : float;
                            var train_progress__nextUpdate : float&)
  if info.curTime < train_progress__nextUpdate
    return
  train_progress__nextUpdate = info.curTime + train_progress__updateInterval
  query(train_progress__nextCapzoneEid) <| $ [es] (transform aka checkpoint_transform : float3x4;
                                                   capzone__trainPathLength : float;
                                                   var capzone__trainProgress : float&)
    let distanceToCheckpoint = length(train_transform[3] - checkpoint_transform[3])
    capzone__trainProgress = clamp(1. - safediv(distanceToCheckpoint, capzone__trainPathLength), 0., 1.)
