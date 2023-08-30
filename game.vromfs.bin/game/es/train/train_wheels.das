require ecs
require AnimV20
require GeomNodeTree
require DagorSystem
require DagorMath
require GamePhys
require DngPhysObj
require enlisted.events_enlisted

[es(on_appear)]
def init_train_wheels(evt : Event;
                      eid : EntityId;
                      train__wheels : StringList;
                      var train__wheelNodeIds : IntList;
                      var train__wheelRotations : FloatList;
                      animchar : AnimcharBaseComponent)
  train__wheelNodeIds |> resize(length(train__wheels))
  train__wheelRotations |> resize(length(train__wheels))

  var isFail = false
  for wheel, i in train__wheels, range(length(train__wheels))
    let nodeId = *animchar.nodeTree |> geomtree_findNodeIndex(string(wheel))
    isFail ||= nodeId < 0
    if nodeId < 0
      logerr("Wheel node '{wheel}' is not found for a train '{getEntityTemplateName(eid)}' in the component 'train__wheels'")

    train__wheelNodeIds[i]   = nodeId
    train__wheelRotations[i] = 0.

  if isFail
    train__wheelNodeIds |> clear()
    train__wheelRotations |> clear()

[es(REQUIRE=train, no_order)]
def rotate_train_wheels_es(info : ParallelUpdateFrameDelayed;
                           var animchar : AnimcharBaseComponent;
                           phys_obj_net_phys : PhysObjActor;
                           train__wheelNodeIds : IntList)
  let vel = phys_obj_net_phys.phys.currentState.velocity
  let fwd = quat_get_forward(phys_obj_net_phys.phys.currentState.location.O.quat)
  let invWheelRadius = 1. / 0.55

  let rotation = invWheelRadius * sign(-dot(fwd, vel)) * length(vel) * info.dt

  var rotTm : float3x4
  rotyTM(rotation, rotTm)

  for nodeId in train__wheelNodeIds
    var nodeTm : float3x4
    *animchar.nodeTree |> geomtree_getNodeTmScalar(nodeId, nodeTm)

    let tm = nodeTm * rotTm
    *animchar.nodeTree |> geomtree_setNodeTmScalar(nodeId, tm)
