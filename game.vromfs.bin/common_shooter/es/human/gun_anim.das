require ecs
require PhysVars


[es(on_appear)]
def grenade_anim_init(evt : Event;
                      var grenade__throwProgressVarId : int&;
                      var phys_vars : PhysVars)
  grenade__throwProgressVarId = phys_vars |> registerVar("throw_progress", 0.0)


[es(no_order)]
def grenade_thrower_anim_update(info : UpdateStageInfoAct;
                                grenade_thrower__projectileEntity : EntityId;
                                grenade_thrower__throwProgress : float)
  query(grenade_thrower__projectileEntity) <| $ [es] (grenade__throwProgressVarId : int; var phys_vars : PhysVars)
    if grenade__throwProgressVarId >= 0
      phys_vars |> setVar(grenade__throwProgressVarId, grenade_thrower__throwProgress)
