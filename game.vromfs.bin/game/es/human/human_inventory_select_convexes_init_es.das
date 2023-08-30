require ecs
require game.es.events
require GameMath
require math.base

[es(on_appear, on_event=EventOnModsChanged)]
def human_inventory_select_convexes_init_es(evt : Event;
                                            var human_inventory__selectConvex : Point4List&;
                                            var human_inventory__selectTpsConvex : Point4List&;
                                            human_inventory__pickupDistance = 2.5f;
                                            entity_mods__pickupDistanceAdd = 0.f;
                                            human_inventory__pickupFrustum__znear = 0.1f;
                                            human_inventory__pickupFrustum__zfar = -1.f;
                                            human_inventory__pickupFrustum__fovx = 50.f;
                                            human_inventory__pickupFrustum__fovy = 50.f;
                                            human_inventory__pickupTpsFrustum__znear = -1.f;
                                            human_inventory__pickupTpsFrustum__zfar = -1.f;
                                            human_inventory__pickupTpsFrustum__cameraOffset = 1.8f;
                                            human_inventory__pickupTpsFrustum__fovx = 50.f;
                                            human_inventory__pickupTpsFrustum__fovy = 50.f)
  let zfar = human_inventory__pickupFrustum__zfar > 0. ? human_inventory__pickupFrustum__zfar : human_inventory__pickupDistance + entity_mods__pickupDistanceAdd
  let fovx = deg_to_rad(human_inventory__pickupFrustum__fovx) * 0.5f
  let fovy = deg_to_rad(human_inventory__pickupFrustum__fovy) * 0.5f
  construct_convex_from_frustum(human_inventory__selectConvex,
                                human_inventory__pickupFrustum__znear,
                                zfar,
                                fovx,
                                fovy,
                                IDENT_TM)
  let znearTps = human_inventory__pickupTpsFrustum__znear > 0. ? human_inventory__pickupTpsFrustum__znear : human_inventory__pickupTpsFrustum__cameraOffset + 0.1f
  let zfarTps = human_inventory__pickupTpsFrustum__zfar > 0. ? human_inventory__pickupTpsFrustum__zfar : human_inventory__pickupTpsFrustum__cameraOffset + human_inventory__pickupDistance + entity_mods__pickupDistanceAdd
  let fovxTps = deg_to_rad(human_inventory__pickupTpsFrustum__fovx) * 0.5f
  let fovyTps = deg_to_rad(human_inventory__pickupTpsFrustum__fovy) * 0.5f
  construct_convex_from_frustum(human_inventory__selectTpsConvex,
                                znearTps,
                                zfarTps,
                                fovxTps,
                                fovyTps,
                                IDENT_TM)
