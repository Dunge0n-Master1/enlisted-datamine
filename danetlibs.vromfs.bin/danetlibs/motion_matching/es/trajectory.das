require ecs
require DagorSystem
require math.base
require DagorMath
require MotionMatching
require danetlibs/motion_matching/es/mm_events
require danetlibs/motion_matching/es/motion_matching_common

[es(on_appear)]
def init_anim_data_base_weights(evt : Event; var dataBase : AnimationDataBase; weightsPath : string)
  deserialize_weights(weightsPath, dataBase.weights, dataBase.nodesName, dataBase.predictionTimes)

  dataBase.featureCount = dataBase.weights.position |> length()

  dataBase.pathSampleCount = dataBase.weights.positionWeight |> length()

[es(before=trajectory_prediction, tag=tools)]
def tool_input(info : UpdateStageInfoAct;
               motion_matching__walkSpeed : float;
               motion_matching__runSpeed : float;
               var motion_matching__linearVelocity : float3&;
               var motion_matching__angularVelocity : float3&)

  query() <| $ [es] (input__verticalAxis : float;
                     input__horizontalAxis : float;
                     input__mouseDelta : int2;
                     input__mouseLeftButtonPressed : bool;
                     input__keyAccelerationPressed : bool)
    motion_matching__linearVelocity = -float3(input__horizontalAxis, 0.f, input__verticalAxis)
    motion_matching__linearVelocity *= input__keyAccelerationPressed ? motion_matching__runSpeed : motion_matching__walkSpeed;
    let PIXEL_TO_DEG = 40.f;
    if input__mouseLeftButtonPressed
      motion_matching__angularVelocity = float3(0.f, deg_to_rad(float(input__mouseDelta.x) * PIXEL_TO_DEG), 0.f)

[es(before=trajectory_prediction, tag=tools)]
def tool_tm_update(info : UpdateStageInfoAct;
                   var transform : float3x4&;
                   motion_matching__predictedVelocity : Point3List;
                   motion_matching__predictedRotation : Point3List)

  transform[3] += rotate(transform, motion_matching__predictedVelocity[0]) * info.dt;
  var rotationTm : float3x4
  make_tm(quat(motion_matching__predictedRotation[0], length(motion_matching__predictedRotation[0]) * info.dt), rotationTm)
  transform = transform * rotationTm

[es(before=trajectory_prediction)]
def mm_lod_selector(info : ParallelUpdateFrameDelayed;
                    var motion_matching__distanceFactor : float&;
                    transform aka character_transform : float3x4)
  motion_matching__distanceFactor = 1.f
  find_query() <| $ [es] (camera__active : bool; transform aka camera_transform : float3x4)
    if !camera__active
      return false
    let distance = length(camera_transform[3] - character_transform[3])
    motion_matching__distanceFactor += 0.2f * sqrt(distance)
    return true

[es(before=update_matched_nodes_es)]
def trajectory_prediction(info : ParallelUpdateFrameDelayed;
                          motion_matching__linearVelocity : float3;
                          motion_matching__angularVelocity : float3;
                          motion_matching__trajectoryInertionFactor : float;
                          motion_matching__linearVelocityViscosity : float;
                          motion_matching__angularVelocityViscosity : float;
                          var motion_matching__linearVelocityAmortized : float3&;
                          var motion_matching__angularVelocityAmortized : float3&;
                          motion_matching__trajectoryTimes : FloatList;
                          var motion_matching__predictedPositions : Point3List;
                          var motion_matching__predictedVelocity : Point3List;
                          var motion_matching__predictedRotation : Point3List)

  let q = quat(float3(0, 1, 0), clamp(motion_matching__angularVelocityAmortized.y, -deg_to_rad(90.f), deg_to_rad(90.f)))
  motion_matching__linearVelocityAmortized = approach(motion_matching__linearVelocityAmortized, q * motion_matching__linearVelocity, info.dt, motion_matching__linearVelocityViscosity)
  motion_matching__angularVelocityAmortized = approach(motion_matching__angularVelocityAmortized, motion_matching__angularVelocity, info.dt, motion_matching__angularVelocityViscosity)

  var goalLinVelocity = motion_matching__linearVelocityAmortized
  var goalAngVelocity = motion_matching__angularVelocityAmortized

  let N = length(motion_matching__trajectoryTimes)
  if N == 0
    return
  let T = motion_matching__trajectoryTimes[N - 1]
  for j in range(N)
    let i = N - j - 1
    let inertionFactor = saturate(motion_matching__trajectoryTimes[i] / T * motion_matching__trajectoryInertionFactor)

    var linVelocity = motion_matching__predictedVelocity[i]
    linVelocity = approach(linVelocity, goalLinVelocity, info.dt * inertionFactor, motion_matching__linearVelocityViscosity)
    goalLinVelocity = linVelocity
    motion_matching__predictedVelocity[i] = linVelocity

    var angVelocity = motion_matching__predictedRotation[i]
    angVelocity = approach(angVelocity, goalAngVelocity, info.dt * inertionFactor, motion_matching__angularVelocityViscosity)
    goalAngVelocity = angVelocity
    motion_matching__predictedRotation[i] = angVelocity


  var p = float3(0.0)
  var prevT = 0.f
  for position, velocity, time in motion_matching__predictedPositions, motion_matching__predictedVelocity, motion_matching__trajectoryTimes
    let dt = time - prevT
    p += velocity * dt
    position = p
    prevT = time