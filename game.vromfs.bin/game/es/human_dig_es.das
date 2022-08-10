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
require DagorSystem
require RendInst

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

      var matId = -1
      let checkRadius = dig_tool__radius *  dig_tool__checkRadiusMul
      let canTerraformCheckResult = can_terraform_at_pos(terraform, evt.pos, checkRadius, human_net_phys.phys.traceHandle, dig_tool__allowedMaterials, matId)

      if canTerraformCheckResult == CanTerraformCheckResult Successful
        let digPos = evt.pos.xz
        terraform |> terraform_storeSphereAlt(digPos, dig_tool__radius, -dig_tool__depth, TerraformPrimMode DYN_ADDITIVE)

        broadcast_net_event([[CmdDig diggerEid=eid, pos=evt.pos, radius=dig_tool__radius, depth=-dig_tool__depth, matId=matId]])

      send_net_event(eid, [[EventOnDig canTerraformCheckResult=int(canTerraformCheckResult)]])

[es(tag=netClient)]
def apply_terraform_es(evt : CmdDig; var terraform : TerraformComponent)
  let digPos = evt.pos.xz
  terraform |> terraform_storeSphereAlt(digPos, evt.radius, evt.depth, TerraformPrimMode DYN_ADDITIVE)

[es(tag=server)]
def human_dig_clean_loot_after_dig(evt : CmdDig)
  clean_loot_in_radius(evt.pos, evt.radius)

[es]
def human_dig_ri_gen_damage(evt : CmdDig; digging_config__riGenDamageRadiusScale : float)
  let sphere = BSphere3(evt.pos, floor(evt.radius * digging_config__riGenDamageRadiusScale))
  let axis : float3
  if sphere.r > 0.0
    rendinst_doRIGenDamage(sphere, get_dagor_frame_no(), axis)
