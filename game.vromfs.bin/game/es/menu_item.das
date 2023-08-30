require ecs
require game.es.events
require CollRes
require DagorMath
require GeomNodeTree
require AnimV20
require enlisted.events_enlisted

[es(on_appear)]
def menu_item_entity_created_es(evt : Event;
                                collres : CollisionResource;
                                var menu_item__boundingBoxCenter : float3&)
  var box = BBox3()
  bbox3f_to_scalar_bbox3(box, collres.vFullBBox)
  menu_item__boundingBoxCenter = box.center

  let t = menu_item__boundingBoxCenter.x
  menu_item__boundingBoxCenter.x = menu_item__boundingBoxCenter.z
  menu_item__boundingBoxCenter.z = t

  menu_item__boundingBoxCenter.x = -menu_item__boundingBoxCenter.x


// menu animchar updates it's position and camera fov for zoom effect on input
// because of this we need to update menu animchar and it's attachments
// on update and not in parallel, before rendering. Otherwise we get one frame
// of new camera fov and old animchar position which looks jittery
// this also fixes item in BP being rendered in a wqrong pos for one frame
[es(tag=server, tag=gameClient, after=menu_rotate_target_cam_es, REQUIRE=menuItemObject)]
def menu_item_animchar_act(info : UpdateStageInfoAct;
                           transform : float3x4;
                           var animchar : AnimcharBaseComponent;
                           var animchar_node_wtm : AnimcharNodesMat44;
                           var animchar_render__root_pos : vec4f&;
                           animchar__turnDir = false)
  var resultTm = transform
  if animchar__turnDir
    resultTm[0] = transform[2]
    resultTm[2] = -transform[0]

  animchar_set_tm(animchar, resultTm, true)
  animchar |> animchar_recalc_wtm()

  animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

// separate system so slot attach update is called only once
// and only if there is a menuItemObject in the scene
[es(tag=server, tag=gameClient, after=menu_item_animchar_act)]
def menu_item_animchar_slot_attaches_act(info : UpdateStageInfoAct)
  find_query() <| $ [es(REQUIRE=menuItemObject)] ()
    broadcastEventImmediate([[SlotAttachUpdateEvent dt=info.dt]])
    return true
