import "%dngscripts/ecs.nut" as ecs
let {trackPlayerStart = null} = require("demo_track_player.nut")
if (trackPlayerStart==null)
  return
let { EventLevelLoaded } = require("gameevents")
let { take_screenshot_name=@(_name) null } = require_optional("screencap")
let { get_log_directory } = require("dagor.system")
let { exit_game, get_game_name } = require("app")
let io = require("io")
let { format } = require("string")
let { get_local_unixtime = @() 0, get_time_msec } = require("dagor.time")

const THUMBNAIL = "thumbnail"
const SCREENSHOT_FMT = ".avif"

// .../.logs~game/app-date/
local reportFolder = get_log_directory().split("/")
if (reportFolder.len() >= 2)
  reportFolder = $"{reportFolder[reportFolder.len()-2]}/" // app-date
// else raise an error
reportFolder = $"./.runs~{get_game_name()}/{reportFolder}"

let benchStatsComps = [
  ["averageDt", ecs.TYPE_FLOAT],
  ["prevMsec", ecs.TYPE_INT],
  ["firstMsec", ecs.TYPE_INT],
  ["frames", ecs.TYPE_INT],
  ["slowFrames", ecs.TYPE_INT],
  ["verySlowFrames", ecs.TYPE_INT],
  ["maxMemoryUsedKb", ecs.TYPE_INT],
  ["allMemoryUsedKb", ecs.TYPE_INT64],
  ["maxDeviceVRamUsedKb", ecs.TYPE_INT],
  ["allDeviceVRamUsedKb", ecs.TYPE_INT64],
  ["maxSharedVRamUsedKb", ecs.TYPE_INT],
  ["allSharedVRamUsedKb", ecs.TYPE_INT64]
]

let benchStatsQuery = ecs.SqQuery("benchStatsQuery", {comps_rw=benchStatsComps})

let function resetPerf() {
  benchStatsQuery.perform(function(_eid, comps){
    foreach (compName, _ in comps){
      if (compName == "averageDt")
        comps[compName] = 0.0
      else if (compName == "firstMsec")
        comps[compName] = get_time_msec()
      else
        comps[compName] = 0
    }
  })
}

let screens = []
local globalAvgFps = 0
let function savePerf(fileName) {
  let reportName = $"{fileName}.json"
  let f = io.file($"{reportFolder}{reportName}", "wt")
  let stats = benchStatsQuery.perform(@(_eid, comp) clone comp)
  local {slowFrames, frames, prevMsec, firstMsec, verySlowFrames, maxMemoryUsedKb, allMemoryUsedKb, maxDeviceVRamUsedKb, allDeviceVRamUsedKb, maxSharedVRamUsedKb, allSharedVRamUsedKb} = stats
  frames = max(frames, 1)
  prevMsec = max(prevMsec, firstMsec + 1)
  let avgFps = 1000.0 * frames / (prevMsec - firstMsec)

  let avgMemoryUsedKb = allMemoryUsedKb / frames
  let avgDeviceVRamUsedKb = allDeviceVRamUsedKb / frames
  let avgSharedVRamUsedKb = allSharedVRamUsedKb / frames

  let screen = $"{fileName}{SCREENSHOT_FMT}"
  let res = "\n".concat(
    "{",
    $"\"image\":\"{screen}\",",
    $"\"datetime\":{get_local_unixtime()},",
    $"\"avg_fps\":{avgFps},",
    $"\"score\":{frames},",
    $"\"slow_frames_pct\":{100.0 * slowFrames / frames},",
    $"\"very_slow_frames_pct\":{100.0 * verySlowFrames / frames},",
    "\"RawStats\": {",
    $"  \"frames\":{frames},",
    $"  \"slowFrames\":{slowFrames},",
    $"  \"verySlowFrames\":{slowFrames},",
    $"  \"timeTakenMs\":{prevMsec - firstMsec},",
    $"  \"timeStartedMs\":{firstMsec},",
    $"  \"timeEndMs\":{prevMsec},",

    $"  \"maxMemoryUsedInKb\":{maxMemoryUsedKb},",
    format("  \"avgMemoryUsedInKb\":%.2f,",avgMemoryUsedKb),
    $"  \"maxDeviceVRamUsedInKb\":{maxDeviceVRamUsedKb},",
    format("  \"avgDeviceVRamUsedInKb\":%.2f,",avgDeviceVRamUsedKb),
    $"  \"maxSharedVRamUsedInKb\":{maxSharedVRamUsedKb},",
    format("  \"avgSharedVRamUsedInKb\":%.2f",avgSharedVRamUsedKb),

    "}",
    "}\n"
  )
  f.writestring(res)
  f.close()
  globalAvgFps += avgFps
  screens.append($"\"{reportName}\"")
}

let function saveReportInfo() {
  let f = io.file($"{reportFolder}info.json", "wt")
  let screensArr = ",".join(screens)
  let res = "\n".concat(
    "{",
    $"\"avg_fps\":{globalAvgFps/max(screens.len(), 1)},",
    $"\"thumbnail\":\"{THUMBNAIL}{SCREENSHOT_FMT}\",",
    $"\"screens\":[{screensArr}],",
    $"\"name\":\"{get_game_name()}\",",
    $"\"datetime\":{get_local_unixtime()}",
    "}\n"
  )
  f.writestring(res)
  f.close()
}

let batch = []
local count = 1

// random screen to generate folder structure
batch.append( function() { take_screenshot_name($"../{reportFolder}{THUMBNAIL}"); } )

let function appendScreen(pos, dir, name = null) {
  local fileName = $"screen_{count++}";
  if (name != null)
    fileName = name
  batch.append({duration=0.5, from_pos=pos, from_dir=dir, from_fov=90.0, to_pos=pos, to_dir=dir, to_fov=90.0})
  batch.append(function() { resetPerf(); } )
  batch.append({duration=2.0, from_pos=pos, from_dir=dir, from_fov=90.0, to_pos=pos, to_dir=dir, to_fov=90.0})
  batch.append(function() { savePerf(fileName); } )
  batch.append( function() { take_screenshot_name($"../{reportFolder}{fileName}"); } )
  batch.append({duration=0.5, from_pos=pos, from_dir=dir, from_fov=90.0, to_pos=pos, to_dir=dir, to_fov=90.0})
}


local hasStarted = false
ecs.register_es("regression_tests", {
  [EventLevelLoaded] = function(_eid, comp) {
    foreach ( screen in comp.camera_locations?.getAll() ?? [] ) {
      appendScreen(screen.pos, screen.dir, screen?.name)
    }
    if (batch.len() > 0 && !hasStarted) {
      hasStarted=true
      comp.benchmark_active=true
      ecs.set_callback_timer(function() {
        batch.append(saveReportInfo)
        batch.append(exit_game)
        trackPlayerStart( batch )
      }, 1.0, false)
    }
  }
},{
  comps_rw = [
    ["benchmark_active",ecs.TYPE_BOOL],
  ],
  comps_ro = [
    ["camera_locations",ecs.TYPE_ARRAY, []],
  ],
  comps_rq = [
    "regression_tests"
  ]
})
