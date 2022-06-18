from "%enlSqGlob/ui_library.nut" import *

let {Point3, radToDeg, atan2} = require("%sqstd/math_ex.nut")
let {inGroundVehicle} = require("%ui/hud/state/vehicle_state.nut")
const w = 20
const h = 15
const th = 15
/*
  this code is bad
  what we REALLY need here is to replace vehicleDirection weird behavior with 2 new behaviors
  vehicleDirection and turretRotation - that should simply rotate its children correspondantly (and only when they change of course)
  that will elimate all performance cost and will make it simple.

  EVEN MORE better solution (but slower a bit - still faster than current) would be to expose turret rotation (and rotation limits, and turret type) in components
  that will also allow to make multi-turret vehicle
*/
let vehicleCommands = [
  [VECTOR_COLOR, Color(150, 150, 150, 50)],
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 100)],
  [VECTOR_WIDTH, hdpx(1.2)],
  [VECTOR_POLY,
    50+w, 50-h, 50+w, 50+h, 50-w, 50+h,
    50-w, 50-h, 50, 50-h-th
  ]
]

let turretCommands = [
  [VECTOR_COLOR, Color(255, 255, 255)],
  [VECTOR_LINE, 50, 40, 50, 10],
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_ELLIPSE, 50, 50, 10, 10],
]


let size = [fsh(10), fsh(10)]

let dirs = {
  cameraDir = Point3(1.0, 0.0, 0.0)
  cameraLeft = Point3(0.0, 0.0, 1.0)
  vehicleDir = Point3(1.0, 0.0, 0.0)
  turretDir = Point3(1.0, 0.0, 0.0)
}

let bas = {
  rendObj = ROBJ_VECTOR_CANVAS
  behavior = [Behaviors.RtPropUpdate, Behaviors.VehicleDirection]
  size = size,
  transform = {rotate = 0}
  cameraDir = dirs.cameraDir
  cameraLeft = dirs.cameraLeft
}
let turret = bas.__merge({
  turretDir = dirs.turretDir
  commands = turretCommands
  update = function(){
    return { transform = {rotate = radToDeg(atan2(this.cameraLeft*this.turretDir, this.cameraDir*this.turretDir))}}
  }
})
let vehicle = bas.__merge({
  vehicleDir = dirs.vehicleDir
  commands = vehicleCommands
  update = function(){
    return { transform = {rotate = radToDeg(atan2(this.cameraLeft*this.vehicleDir, this.cameraDir*this.vehicleDir))}}
  }
})

return function(){
  return {
    watch = inGroundVehicle
    size = SIZE_TO_CONTENT
    rendObj = ROBJ_WORLD_BLUR
    children = inGroundVehicle.value ? [vehicle, turret] : null
  }
}
