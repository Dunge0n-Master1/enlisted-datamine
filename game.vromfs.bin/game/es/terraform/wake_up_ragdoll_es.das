require ecs
require math.base
require PhysDecl
require AnimV20
require GeomNodeTree
require enlisted.events_enlisted

def private wake_up_ragdoll_on_terraform_impl(terraformPos : float3;
                                              terraformRadius : float;
                                              animchar : AnimcharBaseComponent;
                                              var ragdoll : PhysRagdoll;
                                              var animchar__updatable : bool&)
  let rootPos = geomtree_getNodeWpos(*animchar.nodeTree, 0)
  if length_sq(terraformPos - rootPos) < square(2. * terraformRadius)
    animchar__updatable = true
    ragdoll |> ragdoll_wakeUp()

[es(tag=gameClient, REQUIRE=deadEntity, REQUIRE_NOT=animchar__actOnDemand, after=apply_terraform_es)]
def wake_up_ragdoll_on_terraform(evt : CmdDig;
                                 animchar : AnimcharBaseComponent;
                                 var ragdoll : PhysRagdoll;
                                 var animchar__updatable : bool&)
  wake_up_ragdoll_on_terraform_impl(evt.pos, evt.radius, animchar, ragdoll, animchar__updatable)

[es(tag=gameClient, REQUIRE=deadEntity, REQUIRE_NOT=animchar__actOnDemand)]
def wake_up_ragdoll_on_terraform_bomb_crater(evt : EventBombCraterTerraformed;
                                             animchar : AnimcharBaseComponent;
                                             var ragdoll : PhysRagdoll;
                                             var animchar__updatable : bool&)
  wake_up_ragdoll_on_terraform_impl(evt.pos, evt.outerRadius, animchar, ragdoll, animchar__updatable)
