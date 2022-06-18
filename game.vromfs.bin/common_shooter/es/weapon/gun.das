require ecs
require PhysMat


[es(on_appear)]
def gun_init_proj_ray_mat_es(evt : Event;
                             gun__projectileRayMat : string;
                             var gun__projectileRayMatId : int&)
  gun__projectileRayMatId = get_material_id(gun__projectileRayMat)