require ecs
require PhysVars

[es(on_appear, tag=render, before=anim_phys_init_es)]
def human_anim_fpv_init(evt : Event; var human_anim__isFpvVarId : int&; var phys_vars : PhysVars)
  human_anim__isFpvVarId = registerVar(phys_vars, "is_fpv", 0.0)

[es(before=human_anim_es, tag=render)]
def human_anim_fpv(info : UpdateStageInfoAct; isCockpitCam : bool; camera__active : bool)
  if !camera__active
    return
  ecs::query() <| $ [es(REQUIRE=cockpitEntity)] (var phys_vars : PhysVars; human_anim__isFpvVarId : int)
    setVar(phys_vars, human_anim__isFpvVarId, isCockpitCam ? 1.0 : 0.0)

