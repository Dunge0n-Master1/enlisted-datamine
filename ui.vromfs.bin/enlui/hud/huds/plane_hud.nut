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

let function mkHide(_obj){
  return function() {
    return null
  }
}

let state = [
  // flight parameters
  {comp = "plane_view__tas",           watch = Watched(), locId="plane_hud/Tas",  typ = ecs.TYPE_FLOAT, transformFunc = @(_obj, val) round_by_value(val*3.6, 1)}
  //{comp = "plane_view.ias",           watch = Watched(), locId="IAS",  typ = ecs.TYPE_FLOAT, transformFunc = @(obj, val) round_by_value(val*3.6, 1)}
  {comp = "plane_view__altitude",      watch = Watched(), locId="plane_hud/Alt",  typ = ecs.TYPE_FLOAT}
  //{comp = "plane_view__vertical_speed",watch = Watched(), watchShow = showRoC, locId="RoC", typ = ecs.TYPE_FLOAT, transformFunc = rocTransform}
  //{comp = "plane_view.heading_deg",   watch = Watched(), locId="HDG",  typ = ecs.TYPE_INT  }

  // controls
  {comp = "plane_view__throttle",      watch = Watched(), locId="plane_hud/Thr",  typ = ecs.TYPE_FLOAT, transformFunc = transformPercentsFunc}
  {comp = "plane_view__has_gear_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkCaption = mkHide, mkValue = mkHide }
  {comp = "plane_view__gear_position", watch = Watched(),
    compShow = "plane_view__has_gear_control", watchShow = Watched(false),
    locId="plane_hud/Gear",  typ = ecs.TYPE_BOOL,
    boolValues = ["plane_hud/GearUp", "plane_hud/GearDown"], transformFunc = transformBoolFunc}
  {comp = "plane_view__has_flaps_control", watch = Watched(), locId = "", typ = ecs.TYPE_BOOL, mkCaption = mkHide, mkValue = mkHide }
  {comp = "flaps_position",           watch = Watched(),
    compShow = "plane_view__has_flaps_control", watchShow = Watched(false),
    locId="plane_hud/Flaps", typ = ecs.TYPE_INT,
    enumValues = ["plane_hud/FlapsUp", "plane_hud/FlapsCombat", "plane_hud/FlapsTakeoff", "plane_hud/FlapsLanding"], transformFunc = transformEnumFunc}
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
  {comp = "plane_view.engine_water_temperature", watch = Watched(),
    compShow = "plane_view.engine_water_cooled", watchShow = Watched(false),
    locId="WATER", typ = ecs.TYPE_FLOAT}
  {comp = "plane_view.engine_head_temperature",  watch = Watched(),
    compShow = "plane_view.engine_air_cooled",   watchShow = Watched(false),
    locId="HEAD",  typ = ecs.TYPE_FLOAT}
  {comp = "plane_view.engine_oil_temperature",   watch = Watched(),
    locId="OIL",  typ = ecs.TYPE_FLOAT}
  {comp = "flight_angles_enabled", watch=Watched(), locId = "AIM CONTROL",   typ = ecs.TYPE_BOOL, mkIndicator = mkExistIndicator}
*/
]
state.each(@(obj) obj.isActiveWatch <- Watched(false))
//state.each(@(watch, key) watch.subscribe(@(v) log_for_user(key, v)))

ecs.register_es("plane_basic_hud_es",
  {
    [["onInit","onUpdate"]] = function(_evt, _eid, comp){
      state.each(@(v) v.watch(comp[v.comp]))
      state.each(@(v) v?.watchShow != null && v?.compShow != null ? v.watchShow(comp[v.compShow]) : null)
      state.each(@(v) v.isActiveWatch(comp[v.comp] != null && (v?.watchShow.value ?? true)))
      state.each(@(v) v?.watchAuto != null && v?.compAuto != null ? v.watchAuto(comp[v.compAuto]) : null)
    }
    function onDestroy(_evt, _eid, _comp){
      state.each(@(v) v.watch(null))
      state.each(@(v) v.isActiveWatch(false))
      state.each(@(v) v?.watchAuto != null ? v.watchAuto(null) : null)
    }
  },
  {
    comps_ro = state.map(@(obj) [obj.comp, obj.typ, null]),
    comps_rq = ["airplane", "heroVehicle"]
    comps_no = ["deadEntity"]
  },
  { updateInterval = 0.1, tags="gameClient", after="*", before="*" }
)

let planeState = state.filter(@(obj) "watch" in obj).reduce(function(memo, obj) {memo[obj.comp.replace("plane_view.", "plane_")] <- obj.watch; return memo;}, {})
return {
  planeState = planeState
  mkExistIndicator = mkExistIndicator //to prevent static analyzer warning

  function planeHud(){
    let captions = []
    let values = []
    foreach (obj in state) {
      if (obj?.isActiveWatch.value) {
        captions.append(obj?.mkCaption(obj) ?? mkCaption(obj))
        values.append(obj?.mkValue(obj) ?? mkValue(obj))
      }
    }
    let watches = state.filter(@(obj) "isActiveWatch" in obj).map(@(obj) obj?.isActiveWatch)
    return {
      flow = FLOW_HORIZONTAL
      gap = hdpx(5)
      children = [
        {children=captions, flow=FLOW_VERTICAL, gap = hdpx(3)}
        {children=values,   flow=FLOW_VERTICAL, gap = hdpx(3)}
      ]
      watch = watches
    }
  }
}
