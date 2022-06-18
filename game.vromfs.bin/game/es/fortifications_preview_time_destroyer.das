require enlisted.game.es.fortifications_build_common
require ecs

[es(tag=server, after=building_fortification_building_object)]
def building_preview_inactive_destroyes_es(info : UpdateStageInfoAct;
                                           eid : EntityId;
                                           destroyByInactiveShredderAtTime : float)
  if destroyByInactiveShredderAtTime > 0.0 && destroyByInactiveShredderAtTime < info.curTime
    let canDestroyed = !get_player_eid_interacting_building(eid)
    if canDestroyed
      destroyEntity(eid)
