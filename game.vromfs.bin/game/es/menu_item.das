require ecs
require game.es.events
require CollRes
require DagorMath

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