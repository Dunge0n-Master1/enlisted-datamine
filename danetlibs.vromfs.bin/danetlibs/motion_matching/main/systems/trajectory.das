require ecs
require DagorSystem
require DagorMath

[es(no_order)]
def update_trajectory(info : UpdateStageInfoAct;
                      input_linear_velocity : float3;
                      input_angular_velocity : float3;
                      var input_amort_linear_velocity : float3&;
                      var input_amort_angular_velocity : float3&;
                      var input_linear_acceleration : float3&;
                      var input_angular_acceleration : float3&)
  let t = float3(info.dt * 5.0)//float3(exp(-info.dt*100.01))
  let prev_v = input_amort_linear_velocity
  let prev_w = input_amort_angular_velocity
  input_amort_linear_velocity = lerp(input_amort_linear_velocity, input_linear_velocity, t)
  input_amort_angular_velocity = lerp(input_amort_angular_velocity, input_angular_velocity, t)
  input_linear_acceleration = (input_amort_linear_velocity - prev_v)
  input_angular_acceleration = (input_amort_angular_velocity - prev_w)



[es(after=update_trajectory)]
def trajectory_prediction(info : UpdateStageInfoAct;
                          input_amort_linear_velocity : float3;
                          input_amort_angular_velocity : float3;
                          input_linear_acceleration : float3;
                          input_angular_acceleration : float3;
                          trajectory_times : FloatList&;
                          var transform : float3x4&;
                          var predicted_positions : Point3List&;
                          var predicted_velocity : Point3List&;
                          var predicted_rotation : Point3List&)
  let localSpeed = input_amort_linear_velocity;
  let speed = transform[0] * localSpeed.x + transform[1] * localSpeed.y + transform[2] * localSpeed.z;
  transform[3] = transform[3] + speed * info.dt;
  var rotationTm : float3x4
  make_tm(quat(input_amort_angular_velocity, length(input_amort_angular_velocity) * info.dt), rotationTm)
  transform = transform * rotationTm
  var p = float3(0.0)
  var v = input_amort_linear_velocity
  var w = input_amort_angular_velocity

  for position, velocity, rotation, dt in predicted_positions, predicted_velocity, predicted_rotation, trajectory_times
    p += v * dt
    w += input_angular_acceleration * dt
    let q = quat(float3(0, 1, 0), input_amort_angular_velocity.y * dt)

    v += input_linear_acceleration * dt
    v = q * v
    position = p
    velocity = v
    rotation = w