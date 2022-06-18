from "%enlSqGlob/ui_library.nut" import *

const UNLIMITED_FPS_LIMIT = 401

let fpsList = Watched([
  UNLIMITED_FPS_LIMIT,
  30, 60, 75, 85,
  100, 120, 144, 165, 170, 175, 180,
  200, 240, 280,
  360
])

return {
  fpsList
  UNLIMITED_FPS_LIMIT
}