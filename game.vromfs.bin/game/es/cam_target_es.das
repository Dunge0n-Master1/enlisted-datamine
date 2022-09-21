require ecs

[es(on_appear, track=(camera__active, camera__target))]
def cam_target_switcher_es(evt : Event; camera__active : bool; camera__target : ecs::EntityId; var camera__prevTarget : ecs::EntityId&)
  if !camera__active
    return
  setOptional(camera__prevTarget, "isCameraTarget", false)
  setOptional(camera__target, "isCameraTarget", true)
  camera__prevTarget = camera__target

