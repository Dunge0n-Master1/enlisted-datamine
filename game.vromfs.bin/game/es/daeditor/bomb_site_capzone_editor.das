require ecs
require DagorEditor

[es(tag=(gameClient), track=transform, REQUIRE=daeditor__selected)]
def track_transform_for_editor(evt : Event; transform aka bomb_transform : float3x4; bomb_site__capzoneEid : EntityId)
  query(bomb_site__capzoneEid) <| $ [es] (transform : float3x4; var capzone__bombTransformLocalPos : float3x4)
    capzone__bombTransformLocalPos = bomb_transform
    capzone__bombTransformLocalPos[3] -= transform[3]
    entity_obj_editor_saveComponent(bomb_site__capzoneEid, "capzone__bombTransformLocalPos")
