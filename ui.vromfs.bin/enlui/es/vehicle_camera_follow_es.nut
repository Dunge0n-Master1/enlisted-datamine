import "%dngscripts/ecs.nut" as ecs

let {get_setting_by_blk_path} = require("settings")
let { vehicleCameraFollow } = require("%ui/hud/state/vehicleCameraFollowState.nut")

let setFollowVehicleRotationQuery = ecs.SqQuery("setFollowVehicleRotationQuery", {
  comps_rw = [["human_input__followVehicleRotationInFirstPerson", ecs.TYPE_BOOL]]
})
vehicleCameraFollow.subscribe(function(follow) {
  setFollowVehicleRotationQuery.perform(function(_eid, comp) {
    comp.human_input__followVehicleRotationInFirstPerson = follow
  })
})

ecs.register_es("init_follow_vehicle_rotation_es",
  { onInit = function(_eid, comp) {
    let follow = get_setting_by_blk_path("gameplay/vehicle_camera_follow") ?? true
    comp.human_input__followVehicleRotationInFirstPerson = (follow == true)
  }},
  { comps_rw = [["human_input__followVehicleRotationInFirstPerson", ecs.TYPE_BOOL]] }
)
