require ecs
require DagorSystem
require math.base
require DagorMath
require MotionMatching
require danetlibs/motion_matching/es/mm_events
require danetlibs/motion_matching/es/motion_matching_common

[es(on_appear)]
def init_anim_data_base_weights(evt : Event;
                                var dataBase : AnimationDataBase;
                                weightsPath : string;
                                rootMotionPath : string;
                                var main_database__root_node : das_string;
                                var main_database__direction_nodes : StringList;
                                var main_database__direction_weights : FloatList;
                                var main_database__center_of_mass_nodes : StringList;
                                var main_database__center_of_mass_params : Point4List;
                                var main_database__presetsTagsName : StringList)

  deserialize_presets(weightsPath, dataBase.tagsPresets, dataBase.nodesName, dataBase.predictionTimes, main_database__presetsTagsName)
  deserialize_root_motions(rootMotionPath, main_database__root_node, main_database__direction_nodes, main_database__direction_weights, main_database__center_of_mass_nodes, main_database__center_of_mass_params)

  dataBase.nodeCount = dataBase.nodesName |> length()
  dataBase.trajectorySize = dataBase.predictionTimes |> length()

  dataBase.featuresSize = get_features_sizes(dataBase.nodeCount, dataBase.trajectorySize)

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
    let len = length(motion_matching__linearVelocity)
    if len > 1f
      motion_matching__linearVelocity /= len
    motion_matching__linearVelocity *= input__keyAccelerationPressed ? motion_matching__runSpeed : motion_matching__walkSpeed;
    let PIXEL_TO_DEG = 40.f;
    if input__mouseLeftButtonPressed
      motion_matching__angularVelocity = float3(0.f, deg_to_rad(float(input__mouseDelta.x) * PIXEL_TO_DEG), 0.f)



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
                          var motion_matching__desiredPositions : Point3List;
                          var motion_matching__desiredDirections : Point3List;
                          var motion_matching__predictedPositions : Point3List;
                          var motion_matching__predictedDirections : Point3List)

  assume times = motion_matching__trajectoryTimes
  assume predPos = motion_matching__predictedPositions
  assume predDir = motion_matching__predictedDirections
  assume desPos = motion_matching__desiredPositions
  assume desDir = motion_matching__desiredDirections

  let N = length(times)
  if N == 0
    return
  motion_matching__linearVelocityAmortized = approach(motion_matching__linearVelocityAmortized, motion_matching__linearVelocity, info.dt, motion_matching__linearVelocityViscosity)
  motion_matching__angularVelocityAmortized = approach(motion_matching__angularVelocityAmortized, motion_matching__angularVelocity, info.dt, motion_matching__angularVelocityViscosity)

  assume goalLinVel = motion_matching__linearVelocityAmortized
  assume goalAngVel = motion_matching__angularVelocityAmortized

  let FORWARD_DIRECTION = float3(0f, 0f, -1f);

  var prevT = 0f
  var prevPos = float3(0)
  for pos, dir, t in desPos, desDir, times
    let dt = t - prevT
    let q = quat(float3(0, 1, 0), goalAngVel.y * t)
    pos = prevPos + q * goalLinVel * dt
    dir = q * FORWARD_DIRECTION
    prevT = t
    prevPos = pos


  let inertionFactor = motion_matching__trajectoryInertionFactor
  for pred_pos, pred_dir, des_pos, des_dir in predPos, predDir, desPos, desDir


    pred_pos = approach(pred_pos, des_pos, info.dt * inertionFactor, motion_matching__linearVelocityViscosity)
    pred_dir = approach(pred_dir, des_dir, info.dt * inertionFactor, motion_matching__angularVelocityViscosity)

