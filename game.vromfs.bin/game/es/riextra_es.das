require ecs
require math.base
require danetlibs.native_dasevents.main.native_events
require RendInst
require RendInstPhys
require DagorMath
require DagorSystem
require Dacoll


[es(before=(rendinst_axis_state_es, rendinst_move_es), on_appear, on_event=EventRendinstsLoaded)]
def riextra_create_es(evt : Event;
                      eid : EntityId;
                      ri_extra : RiExtraComponent;
                      var initialTransform : float3x4;
                      var transform : float3x4)
  if riex_isRiGenExtraValid(ri_extra.handle)
    var m : mat44f
    getRIGenExtra44(ri_extra.handle, m)
    initialTransform = float3x4(m)
    transform = initialTransform
  elif get_DAECS_EXTENSIVE_CHECKS() != 0
    logwarn("Rendinst entity {eid}<{getEntityTemplateName(eid)}> has not valid ri handle {ri_extra.handle} on creation. Probably already destroyed.")


[es(tag=dev, track=rendinst_axis_rotation__targetAngle, before=rendinst_axis_state_es)]
def rendinst_axis_state_es_dev(evt : Event;
                               eid : EntityId;
                               transform : float3x4;
                               ri_extra : RiExtraComponent;
                               rendinst_axis_rotation__enabled : Tag const?;
                               rendinst_axis_rotation__targetAngle : float;
                               rendinst_axis_rotation__curAngle : float = 0.0)
  if get_DAECS_EXTENSIVE_CHECKS() != 0
    let enabled = !is_equal_float(rendinst_axis_rotation__curAngle, rendinst_axis_rotation__targetAngle)
    let axisRotationEnabled = rendinst_axis_rotation__enabled != null
    if enabled != axisRotationEnabled
      let pos = transform[3]
      var riTm : mat44f
      let isValid = riex_isRiGenExtraValid(ri_extra.handle)
      if isValid
        getRIGenExtra44(ri_extra.handle, riTm)
      else
        riTm.col3 = float4()
      print("rendinst_axis_state_es_dev {!isValid ? "invalid" : (enabled ? "enable" : "disable")}
            eid={eid} riex.handle={ri_extra.handle} curAngle={rendinst_axis_rotation__curAngle}
            targetAngle={rendinst_axis_rotation__targetAngle} pos={pos} handle_pos={riTm.col3}")


[es(REQUIRE=ri_extra, track=rendinst_axis_rotation__targetAngle, after=riextra_create_es)]
def rendinst_axis_state_es(evt : Event;
                           eid : EntityId;
                           rendinst_axis_rotation__enabled : Tag const?;
                           rendinst_axis_rotation__targetAngle : float;
                           rendinst_axis_rotation__curAngle : float = 0.0)
  let enabled = !is_equal_float(rendinst_axis_rotation__curAngle, rendinst_axis_rotation__targetAngle)
  let axisRotationEnabled = (rendinst_axis_rotation__enabled != null)
  if enabled != axisRotationEnabled
    if enabled
      addSubTemplate(eid, "rotating_rendinst")
    else
      removeSubTemplate(eid, "rotating_rendinst")


[es(before=rendinst_move_es, after=riextra_create_es, on_appear)]
def rendinst_axis_force_initial_rotation_es(evt : Event;
                                            rendinst_axis_rotation__targetAngle : float;
                                            rendinst_axis_rotation__axis : float3;
                                            initialTransform : float3x4;
                                            var transform : float3x4;
                                            var rendinst_axis_rotation__curAngle : float&)
  rendinst_axis_rotation__curAngle = rendinst_axis_rotation__targetAngle
  var tm : float3x4
  make_tm(rendinst_axis_rotation__axis, deg_to_rad(rendinst_axis_rotation__targetAngle), tm)
  transform = initialTransform * tm


[es(REQUIRE=rendinst_axis_rotation__enabled, before=rendinst_axis_rotation_applier_es)]
def rendinst_axis_rotation_es(info : UpdateStageInfoAct;
                              eid : EntityId;
                              rendinst_axis_rotation__targetAngle : float;
                              rendinst_axis_rotation__axis : float3;
                              rendinst_axis_rotation__rotSpeed : float;
                              initialTransform : float3x4;
                              ri_extra : RiExtraComponent;
                              var transform : float3x4;
                              var rendinst_axis_rotation__curAngle : float&)
  if !is_equal_float(rendinst_axis_rotation__curAngle, rendinst_axis_rotation__targetAngle)
    let newAngle = move_to(rendinst_axis_rotation__curAngle,
                             rendinst_axis_rotation__targetAngle, info.dt, rendinst_axis_rotation__rotSpeed);
    var rotTm : float3x4
    make_tm(rendinst_axis_rotation__axis, deg_to_rad(newAngle), rotTm)
    let newTrans = initialTransform * rotTm

    using(ri_extra.handle) <| $(var desc : RendInstDesc#)
      if check_ri_collision_filtered(desc, transform, newTrans, int(PhysLayer EPL_KINEMATIC))
        return

      rendinst_axis_rotation__curAngle = newAngle
      transform = newTrans
  if !is_equal_float(rendinst_axis_rotation__curAngle, rendinst_axis_rotation__targetAngle)
    return
  rendinst_axis_rotation__curAngle = rendinst_axis_rotation__targetAngle // make sure that floats are binary equal
  if riex_isRiGenExtraValid(ri_extra.handle)
    move_ri_extra_tm(ri_extra.handle, transform)

  if get_DAECS_EXTENSIVE_CHECKS() != 0
    print("rendinst_axis_rotation_es disable eid={eid} riex.handle={ri_extra.handle} curAngle={rendinst_axis_rotation__curAngle}
          targetAngle={rendinst_axis_rotation__targetAngle} pos={transform[3]}")

  removeSubTemplate(eid, "rotating_rendinst") // target angle reached - disable this ES


[es(REQUIRE=rendinst_phys_move__enabled, after=after_net_phys_sync)]
def rendinst_phys_move_es(evt : UpdateStageInfoAct;
                          ri_extra : RiExtraComponent;
                          transform : float3x4)
  if riex_isRiGenExtraValid(ri_extra.handle)
    move_ri_extra_tm(ri_extra.handle, transform)
