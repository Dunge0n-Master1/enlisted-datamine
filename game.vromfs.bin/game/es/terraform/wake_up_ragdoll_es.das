require ecs
require math.base
require PhysDecl
require Dacoll
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
    static_if typeinfo(builtin_function_exists @@ < (var arg0 : PhysDecl::PhysRagdoll implicit; arg1 : int const; arg2 : int const; arg3 : GeomNodeTree::GeomNodeTree const ? const implicit) : void > _::ragdoll_startRagdoll)
      if ! ragdoll |> ragdoll_wakeUp()
        ragdoll |> ragdoll_startRagdoll(int(PhysLayer EPL_CHARACTER),
                                        int(PhysLayer EPL_ALL & (~(PhysLayer EPL_KINEMATIC | PhysLayer EPL_CHARACTER))),
                                        animchar.nodeTree)
    else
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
