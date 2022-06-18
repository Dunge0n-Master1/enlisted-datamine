require ecs
require PhysMat

[es(on_appear)]
def human_phys_init_collision_material_es(evt : Event;
                                          human_net_phys__playerCollisionMaterial : string;
                                          human_net_phys__botCollisionMaterial : string;
                                          var human_net_phys__playerCollisionMaterialId : int&;
                                          var human_net_phys__botCollisionMaterialId : int&)
  human_net_phys__playerCollisionMaterialId = get_material_id(human_net_phys__playerCollisionMaterial)
  human_net_phys__botCollisionMaterialId    = get_material_id(human_net_phys__botCollisionMaterial)

[es(track=beh_tree__enabled, on_appear)]
def human_phys_update_collision_material_es(evt : Event;
                                            beh_tree__enabled : bool;
                                            human_net_phys__playerCollisionMaterialId : int;
                                            human_net_phys__botCollisionMaterialId : int;
                                            var net_phys__collisionMaterialId : int&;
                                            var net_phys__ignoreMaterialId : int&)
  if human_net_phys__playerCollisionMaterialId != PHYSMAT_INVALID && human_net_phys__botCollisionMaterialId != PHYSMAT_INVALID
    let matId = beh_tree__enabled ? human_net_phys__botCollisionMaterialId : human_net_phys__playerCollisionMaterialId
    net_phys__collisionMaterialId = matId
    net_phys__ignoreMaterialId    = human_net_phys__botCollisionMaterialId