require ecs
require common_shooter.events_common_shooter
require ProjectiveDecals

def is_blood_enabled()
  var isEnabled = true
  find_query <| $ [es] (isBloodEnabled : bool)
    isEnabled = isBloodEnabled
    return true
  return isEnabled

[es(tag=gameClient, REQUIRE=msg_sink)]
def shell_explode_create_blood_decals(shellExpl : CmdShellExplodeClient)
  if is_blood_enabled()
    createEntity("blood_decal_manager") <| $(var init : ComponentsInitializer)
      using() <| $(var list : EidList#)
        for i, eid in iter_range(shellExpl.explVictim), shellExpl.explVictim
          let isFatalHit = (int(shellExpl.explDamageAndFatal[i]) & 1) == 1
          if isFatalHit
            list |> push(eid)
        init |> set("blood_decal_manager__fromPos", shellExpl.pos)
        init |> set("blood_decal_manager__targets", list)

[es(tag=gameClient, no_order)]
def blood_decal_manager_update(info : UpdateStageInfoAct;
                               eid : EntityId;
                               blood_decal_manager__fromPos : float3;
                               blood_decal_manager__targets : EidList;
                               blood_decal_manager__decalPerUpdate : int;
                               blood_decal_manager__offset : float3;
                               var blood_decal_manager__currentIndex : int&)
  let lastTargetIndex = length(blood_decal_manager__targets)
  let endIndex = min(lastTargetIndex, blood_decal_manager__currentIndex + blood_decal_manager__decalPerUpdate)
  for i in range(blood_decal_manager__currentIndex, endIndex)
    query(blood_decal_manager__targets[i]) <| $ [es] (transform : float3x4)
      let pos = transform[3] + blood_decal_manager__offset
      blood_decals_add_decal(blood_decal_manager__fromPos, pos)
  blood_decal_manager__currentIndex = endIndex
  if endIndex == lastTargetIndex
    destroyEntity(eid)