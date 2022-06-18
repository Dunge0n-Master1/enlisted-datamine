require ecs
require EnlistedNet
require HumanPhys
require EnlistedHuman
require Dacoll
require terraform
require DagorConsole
require game.events_game
require enlisted.events_enlisted
require DagorMath
require PhysMat
require GridCollision
require enlisted.game.es.terraform.terraform_common
require math.base

def check_material_valid_to_dig(matId : int;
                                [[shared_comp]] dig_tool__allowedMaterials : Object)
  return matId >= 0 && get_bool(dig_tool__allowedMaterials, get_material_name(get_material(matId))) ?? false

def check_dig_materials_at_radius(pos : float3;
                                  check_radius : float;
                                  [[shared_comp]] dig_tool__allowedMaterials : Object)
  let forwardDir = float2(check_radius, 0.)
  let rightDir = float2(0., check_radius)
  let digPos = pos.xz;

  let checkPositions = [[float2[5]
                         digPos;
                         digPos + forwardDir;
                         digPos - forwardDir;
                         digPos + rightDir;
                         digPos - rightDir]]
  for p in checkPositions
    if !check_material_valid_to_dig(dacoll_get_lmesh_mat_id_at_point(p), dig_tool__allowedMaterials)
      return false
  return true

[es(tag=gameClient, REQUIRE=hero)]
def human_dig_client_es(evt : EventMeleeAttackHit;
                        human_weap__currentGunEid : EntityId;
                        eid : EntityId)
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=canDig)] ()
    send_net_event(eid, [[EventDigRequest pos=evt.pos]])

[es(tag=server)]
def human_dig_es(evt : EventDigRequest;
                 eid : EntityId;
                 human__aimTm : float3x4;
                 human_weap__currentGunEid : EntityId;
                 human_net_phys : HumanActor)
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=canDig)] (dig_tool__distance : float;
                                                              dig_tool__radius : float;
                                                              dig_tool__depth : float;
                                                              dig_tool__checkDistanceMul : float = 1.5;
                                                              dig_tool__checkRadiusMul : float = 1.25;
                                                              [[shared_comp]] dig_tool__allowedMaterials : Object)
    query() <| $ [es] (var terraform : TerraformComponent)
      let traceFrom = human__aimTm[3]
      if length_sq(traceFrom - evt.pos) > square(dig_tool__distance * dig_tool__checkDistanceMul)
        return
      let checkMatRadius = dig_tool__radius *  dig_tool__checkRadiusMul
      let canDig = (can_terraform_at_pos(terraform, evt.pos, checkMatRadius, human_net_phys.phys.traceHandle) &&
                    check_dig_materials_at_radius(evt.pos, checkMatRadius, dig_tool__allowedMaterials))
      if canDig
        let digPos = evt.pos.xz
        terraform |> terraform_storeSphereAlt(digPos, dig_tool__radius, -dig_tool__depth, TerraformPrimMode DYN_ADDITIVE)

        broadcast_net_event([[CmdTerraform pos=evt.pos, radius=dig_tool__radius, depth=-dig_tool__depth]])
      send_net_event(eid, [[EventOnDig isSuccessful=canDig]])

[es(tag=netClient)]
def apply_terraform_es(evt : CmdTerraform; var terraform : TerraformComponent)
  let digPos = evt.pos.xz
  terraform |> terraform_storeSphereAlt(digPos, evt.radius, evt.depth, TerraformPrimMode DYN_ADDITIVE)
