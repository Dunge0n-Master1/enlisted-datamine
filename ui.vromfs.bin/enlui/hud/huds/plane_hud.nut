import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

/*
todo:
 - use external settings to see RoC, HDG, and IAS instead of TAS
 - use external measure units settings
*/


let {dtext} = require("%ui/components/text.nut")
let {round_by_value} = require("%sqstd/math.nut")
let {secondsToString} = require("%ui/helpers/time.nut")
let {showFuel} = require("%ui/hud/state/plane_hud_state.nut")

//local showRoC = Watched(false) //export these settings outside and use it here, as well as measure units

let defCaption = @(obj) loc(obj.locId)

let defTransform = @(_obj, val) round_by_value(val, 1)

/*
local function rocTransform(val) {
  local ret = round_by_value(val, 0.1).tostring()
  if (ret.indexof(".")==null)
    return $"{ret}.0"
  return ret
}
*/

let transformPercentsFunc =  @(_obj, val) round_by_value(val*100, 1)

//local transformPercentsWithAutoFlagFunc = @(obj, val) obj.watchAuto.value ? loc("AUTO") : transformPercentsFunc(obj, val)

let transformTimeFunc = @(_obj, val) secondsToString(val)

let transformBoolFunc =@(obj, val) loc(obj.boolValues[val ? 1 : 0])

let transformEnumFunc = @(obj, val) loc(obj.enumValues[val])

let defStyle = {fontFx = FFT_GLOW, fontFxColor = Color(0,0,0,50), fontFxFactor = 64, fontFxOffsY=hdpx(0.9)}
let hText = calc_str_box(dtext("THROTTLE:   100%"))

let function mkCaption(obj) {
  let captionFunc = obj?.captionFunc ?? defCaption
  return @() {
    children = [dtext(captionFunc(obj), defStyle), dtext(":",defStyle)]
    flow = FLOW_HORIZONTAL
  }
}

let function mkValue(obj){
  let transformFunc = obj?.transformFunc ?? defTransform
  let watch = obj.watch
  let watches = obj.values().filter(@(v) v instanceof Watched)
  return @() {
    children = dtext(watch.value != null ? transformFunc(obj, watch.value).tostring() : "", defStyle)
    watch = watches
  }
}

let function mkExistIndicator(obj){
  let watch = obj.watch
  let locId = obj.locId
  let watches = obj.values().filter(@(v) v instanceof Watched)
  return function() {
    return {
      children = watch.value ? dtext(loc(locId), defStyle) : null
      size = watch.value!=null ? hText : null
      watch = watches
    }
  }
}

//let mkHide = @(_obj) dlog(_obj.locId, _obj.comp)

let state = [
  // flight parameters
  {comp = "plane_view__tas",           watch = Watched(), locId="plane_hud/Tas",  typ = ecs.TYPE_FLOAT, transformFunc = @(_obj, val) round_by_value(val*3.6, 1)}
  //{comp = "plane_view.ias",           watch = Watched(), locId="IAS",  typ = ecs.TYPE_FLOAT, transformFunc = @(obj, val) round_by_value(val*3.6, 1)}
  {comp = "plane_view__altitude",      watch = Watched(), locId="plane_hud/Alt",  typ = ecs.TYPE_FLOAT}
  //{comp = "plane_view__vertical_speed",watch = Watched(), watchShow = showRoC, locId="RoC", typ = ecs.TYPE_FLOAT, transformFunc = rocTransform}
  //{comp = "plane_view.heading_deg",   watch = Watched(), locId="HDG",  typ = ecs.TYPE_INT  }

  // controls
  {comp = "plane_view__is_throttle_control_active", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__throttle", watch = Watched(),
    compShow = "plane_view__is_throttle_control_active", watchShow = Watched(false),
    locId="plane_hud/Thr",  typ = ecs.TYPE_FLOAT, transformFunc = transformPercentsFunc }
  {comp = "plane_view__is_climb_control_active", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__climb", watch = Watched(),
    compShow = "plane_view__is_climb_control_active", watchShow = Watched(false),
    locId="plane_hud/Clb",  typ = ecs.TYPE_FLOAT, transformFunc = transformPercentsFunc}
  {comp = "plane_view__has_gear_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__gear_position", watch = Watched(),
    compShow = "plane_view__has_gear_control", watchShow = Watched(false),
    locId="plane_hud/Gear",  typ = ecs.TYPE_BOOL,
    boolValues = ["plane_hud/GearUp", "plane_hud/GearDown"], transformFunc = transformBoolFunc}
  {comp = "plane_view__has_flaps_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "flaps_position",           watch = Watched(),
    compShow = "plane_view__has_flaps_control", watchShow = Watched(false),
    locId="plane_hud/Flaps", typ = ecs.TYPE_INT,
    enumValues = ["plane_hud/FlapsUp", "plane_hud/FlapsCombat", "plane_hud/FlapsTakeoff", "plane_hud/FlapsLanding"], transformFunc = transformEnumFunc}
  {comp = "plane_view__hasAirBrakes", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, show = false }
  {comp = "plane_view__isAirBrakesActive", watch = Watched(),
    compShow = "plane_view__hasAirBrakes", watchShow = Watched(false),
    locId="plane_hud/AirBrakes", typ = ecs.TYPE_BOOL,
    boolValues = ["plane_hud/AirBrakesUp", "plane_hud/AirBrakesDown"], transformFunc = transformBoolFunc}
/*
  {comp = "is_parking_brake_on",      watch=Watched(), locId = "PARKING BRAKE", typ = ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
*/
  // fuel
  {comp = "plane_view__fuel_time",  watch = Watched(), locId="plane_hud/Fuel", typ = ecs.TYPE_FLOAT, transformFunc = transformTimeFunc, watchShow=showFuel}
/*
  // engines + propellers
  {comp = "plane_view.engine_manual_control",  watch=Watched(), locId = "ENGINE CONTROL", typ = ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
  {comp = "plane_view__engine_speed",  watch = Watched(), locId="RPM", typ = ecs.TYPE_FLOAT, transformFunc = @(obj, val) round_by_value(val*9.55, 1)}
  {comp = "plane_view.engine_has_pitch_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_pitch_control_auto", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_pitch_control", watch = Watched(),
    compShow = "plane_view.engine_has_pitch_control", watchShow = Watched(false),
    compAuto = "plane_view.engine_pitch_control_auto", watchAuto = Watched(false),
    locId="PITCH", typ = ecs.TYPE_FLOAT,
    transformFunc = transformPercentsWithAutoFlagFunc}
  {comp = "plane_view.engine_has_radiator_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_radiator_control_auto", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_radiator",      watch = Watched(),
    compShow = "plane_view.engine_has_radiator_control", watchShow = Watched(false),
    compAuto = "plane_view.engine_radiator_control_auto", watchAuto = Watched(false),
    locId="RAD",   typ = ecs.TYPE_FLOAT,
    transformFunc = transformPercentsWithAutoFlagFunc}
  {comp = "plane_view.engine_has_oil_radiator_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_oil_radiator_control_auto", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_oil_radiator",  watch = Watched(),
    compShow = "plane_view.engine_has_oil_radiator_control", watchShow = Watched(false),
    compAuto = "plane_view.engine_oil_radiator_control_auto", watchAuto = Watched(false),
    locId="OIL RAD", typ = ecs.TYPE_FLOAT,
    transformFunc = transformPercentsWithAutoFlagFunc}
  {comp = "plane_view.engine_air_cooled",    watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "plane_view.engine_water_cooled",  watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkIndicator = mkHide }
  {comp = "flight_angles_enabled", watch=Watched(), locId = "AIM CONTROL",   typ = ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
*/
]
state.each(@(obj) obj.isActiveWatch <- Watched(false))
//state.each(@(watch, key) watch.subscribe(@(v) log_for_user(key, v)))

local enginesState = [ // NOTE for now we do not need more that 4 engine states
  { active = Watched(false), engineTemp = Watched(0), headState = Watched({warn=0,dead=false}), waterTemp = Watched(0), waterState = Watched({leak=false,low=false,warn=0}), oilTemp = Watched(0), oilState = Watched({leak=false,low=false,warn=0}) }
  { active = Watched(false), engineTemp = Watched(0), headState = Watched({warn=0,dead=false}), waterTemp = Watched(0), waterState = Watched({leak=false,low=false,warn=0}), oilTemp = Watched(0), oilState = Watched({leak=false,low=false,warn=0}) }
  { active = Watched(false), engineTemp = Watched(0), headState = Watched({warn=0,dead=false}), waterTemp = Watched(0), waterState = Watched({leak=false,low=false,warn=0}), oilTemp = Watched(0), oilState = Watched({leak=false,low=false,warn=0}) }
  { active = Watched(false), engineTemp = Watched(0), headState = Watched({warn=0,dead=false}), waterTemp = Watched(0), waterState = Watched({leak=false,low=false,warn=0}), oilTemp = Watched(0), oilState = Watched({leak=false,low=false,warn=0}) }
]

ecs.register_es("plane_basic_hud_es",
  {
    [["onInit","onChange"]] = function(_evt, _eid, comps){
      state.each(function(v) {
        let {comp, watch, isActiveWatch} = v
        watch(comps[comp])
        if (v?.watchShow != null && v?.compShow != null)
          v.watchShow(comps[v.compShow])
        isActiveWatch(comps[comp] != null && (v?.watchShow.value ?? true))
        if (v?.watchAuto != null && v?.compAuto != null)
          v.watchAuto(comps[v.compAuto])
      })
    }
    function onDestroy(_evt, _eid, _comp){
      state.each(function(v) {
        v.watch(null)
        v.isActiveWatch(false)
        if (v?.watchAuto != null)
         v.watchAuto(null)
      })
    }
  },
  {
    comps_track = state.map(@(obj) [obj.comp, obj.typ, null]),
    comps_rq = ["airplane", "heroVehicle"]
    comps_no = ["deadEntity"]
  },
  { tags="gameClient", after="*", before="*" }
)

ecs.register_es("plane_view_engines_temp_hud_es",
  {
    onInit = function(_eid, comps) {
      enginesState.each(@(st) st.active(false))
      foreach (i, _ in comps.plane_view_engine__headTemp)
        enginesState[i].active(true)
    }
    onChange = function(_eid, comps) {
      foreach (i, engineTemp in comps.plane_view_engine__headTemp) {
        enginesState[i].engineTemp(engineTemp)
        enginesState[i].waterTemp(comps.plane_view_engine__waterTemp[i])
        enginesState[i].oilTemp(comps.plane_view_engine__oilTemp[i])
      }
    }
    onDestroy = function(_eid, _comps) {
      enginesState.each(@(st) st.active(false))
    }
  },
  {
    comps_track = [
      ["plane_view_engine__waterTemp", ecs.TYPE_INT_LIST],
      ["plane_view_engine__oilTemp", ecs.TYPE_INT_LIST],
      ["plane_view_engine__headTemp", ecs.TYPE_INT_LIST]
    ]
    comps_rq = ["vehicleWithWatched"]
    comps_no = ["deadEntity"]
  },
  { tags="ui", updateInterval = 1.0, after="*", before="*" }
)

ecs.register_es("plane_view_engines_status_hud_es",
  {
    [["onInit","onChange"]] = function(_eid, comps){
      foreach (i, leak in comps.plane_view_engine__isWaterLeaking) {
        let low = comps.plane_view_engine__isWaterLow[i]
        let warn = comps.plane_view_engine__waterWarnLevel[i]
        enginesState[i].waterState({leak, low, warn})
      }
      foreach (i, leak in comps.plane_view_engine__isOilLeaking) {
        let low = comps.plane_view_engine__isOilLow[i]
        let warn = comps.plane_view_engine__oilWarnLevel[i]
        enginesState[i].oilState({leak, low, warn})
      }
      foreach (i, warn in comps.plane_view_engine__engineWarnLevel) {
        let dead = comps.plane_view_engine__isEngineDead[i]
        enginesState[i].headState({warn, dead})
      }
    }
  },
  {
    comps_track = [
      ["plane_view_engine__isWaterLeaking", ecs.TYPE_BOOL_LIST],
      ["plane_view_engine__isWaterLow", ecs.TYPE_BOOL_LIST],
      ["plane_view_engine__isOilLeaking", ecs.TYPE_BOOL_LIST],
      ["plane_view_engine__isOilLow", ecs.TYPE_BOOL_LIST],
      ["plane_view_engine__isEngineDead", ecs.TYPE_BOOL_LIST],
      ["plane_view_engine__engineWarnLevel", ecs.TYPE_INT_LIST],
      ["plane_view_engine__waterWarnLevel", ecs.TYPE_INT_LIST],
      ["plane_view_engine__oilWarnLevel", ecs.TYPE_INT_LIST]
    ]
    comps_rq = ["vehicleWithWatched"]
    comps_no = ["deadEntity"]
  },
  { tags="ui" }
)

let warnColors = [
  Color(255, 255, 255)
  Color(255, 180, 0)
  Color(255, 90,  0)
  Color(255, 0,   0)
]

let warnStyle = defStyle.__merge({color = Color(255, 90, 0)})
let warnColor = @(level)
  warnColors[clamp(level, 0, warnColors.len() - 1)]

let function mkEngineValue(temperature, engineState) {
  return function() {
    let temperatureVal = round_by_value(temperature.value, 1)
    let warn = engineState.value?.dead ? loc("plane_hud/EngineDead")
      : engineState.value?.low ? loc("plane_hud/WaterOilLow")
      : engineState.value?.leak ? loc("plane_hud/WaterOilLeak")
      : ""
    return {
      children = (engineState.value?.warn ?? 0) > 0 ? [
        dtext(loc("plane_hud/ValueCelsius", temperatureVal.tostring(), {val=temperatureVal}), defStyle.__merge({color = warnColor(engineState.value?.warn ?? 0)}))
        dtext(warn, warnStyle)
      ] : []
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      watch = [temperature, engineState]
    }
  }
}

let function mkEngineCaption(text, engineState) {
  return @() {
    watch = [engineState]
  }.__update(
    (engineState.value?.warn ?? 0) > 0
      ? {
          children = [dtext(text, defStyle), dtext(":",defStyle)]
          flow = FLOW_HORIZONTAL
        }
      : {}
  )
}

let function addEngineCaptionValues(captions, values, engines, locId, stateTemp, stateWarn) {
  let hasManyEngines = engines.len() > 1
  engines.each(function(engine, i) {
    captions.append(mkEngineCaption(loc(locId, {i = hasManyEngines ? i + 1 : ""}), engine[stateWarn]))
    values.append(mkEngineValue(engine[stateTemp], engine[stateWarn]))
  })
}

let planeState = state.filter(@(obj) "watch" in obj).reduce(function(memo, obj) {memo[obj.comp] <- obj.watch; return memo;}, {})
return {
  planeState
  mkExistIndicator //to prevent static analyzer warning

  function planeHud(){
    let captions = []
    let values = []
    foreach (obj in state) {
      if (obj?.isActiveWatch.value && obj?.show!=false ) {
        captions.append(obj?.mkCaption(obj) ?? mkCaption(obj))
        values.append(obj?.mkValue(obj) ?? mkValue(obj))
      }
    }
    let activeEngines = enginesState.filter(@(engine) engine.active.value)
    addEngineCaptionValues(captions, values, activeEngines, "plane_hud/EngineTemp", "engineTemp", "headState")
    addEngineCaptionValues(captions, values, activeEngines, "plane_hud/Water", "waterTemp", "waterState")
    addEngineCaptionValues(captions, values, activeEngines, "plane_hud/Oil", "oilTemp", "oilState")
    let watches = state.filter(@(obj) "isActiveWatch" in obj).map(@(obj) obj.isActiveWatch).extend(enginesState.map(@(engine) engine.active))
    return {
      flow = FLOW_HORIZONTAL
      gap = hdpx(5)
      children = [
        {children=captions, flow=FLOW_VERTICAL, gap = hdpx(3)}
        // {size = [0, 0] children=...} element here is to make only this part of the HUD to update when in a plane.
        // plane HUD updates a lot because of the ALT\TAS meters (change every frame). Ideally this should not be a thing, but daRg
        // can't yet deduce that we dont need to update parent elements unless they don't flow and have a const size
        {size = [0, 0] children = {children=values,   flow=FLOW_VERTICAL, gap = hdpx(3)}}
      ]
      watch = watches
    }
  }
}
