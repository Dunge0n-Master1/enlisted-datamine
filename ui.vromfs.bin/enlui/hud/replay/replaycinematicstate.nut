import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { CmdChangeTimeOfDay, CmdSetCameraFov, CmdSetBloomThreshold, CmdSetChromaticAberrationOffset,
  CmdSetCinematicModeEnabled, CmdSetFilmGrain, CmdSetMotionBlurScale, CmdSetVignetteStrength,
  CmdSetDofIsFilmic, CmdSetDofBokehCorners, CmdSetDofBokehSize, CmdSetDofFStop,
  CmdSetDofFocalLength, CmdSetDofFocusDistance, CmdSetCameraDofEnabled, CmdWeather,
  CmdSetRain, CmdSetSnow, CmdSetLightning, CmdSetLenseFlareIntensity
} = require("dasevents")
let { chooseRandom } = require("%sqstd/rand.nut")

const SNOW_TEMPLATE = "camera_snow_heavy_template"
const RAIN_TEMPLATE = "camera_rain_heavy_template"
const LIGHTNING_TEMPLATE = "camera_lightning_heavy_template"
const CINEMATIC_MODE = "cinematic_mode"

let levelTimeOfDay = Watched(0)
let cameraFov = Watched(0)
let motionBlur = Watched(0)
let bloomEffect = Watched(0)
let filmGrain = Watched(0)
let abberation = Watched(0)
let vigneteEffect = Watched(0)
let isDofCameraEnabled = Watched(false)
let isDofFilmic = Watched(false)
let isDofFocalActive = Watched(false)
let dofFocusDist = Watched(0)
let dofFocalLength = Watched(0)
let dofStop = Watched(0)
let dofBokeCount = Watched(0)
let dofBokeSize = Watched(0)
let dofFocalValToSafe = Watched(-1)
let cinematicMode = Watched({})
let weatherPresetList = Watched([])
let weatherPreset = Watched(null)
let isSnow = Watched(false)
let isRain = Watched(false)
let isLightning = Watched(false)
let hasSnow = Watched(false)
let hasRain = Watched(false)
let hasLightning = Watched(false)
let isCinematicModeActive = Watched(false)
let lenseFlareIntensity = Watched(0)

ecs.register_es("ui_time_of_day_track_es",
  {
    [["onInit","onChange"]] = @(_eid, comp) levelTimeOfDay(comp.cinematic_mode__dayTime)
  },
  {
    comps_track=[["cinematic_mode__dayTime", ecs.TYPE_FLOAT]]
  }
)

ecs.register_es("ui_get_is_rain_or_snow_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      isRain(comp.cinematic_mode__rain)
      isSnow(comp.cinematic_mode__snow)
      isLightning(comp.cinematic_mode__lightning)
      hasRain(comp.cinematic_mode__hasRain)
      hasSnow(comp.cinematic_mode__hasSnow)
      hasLightning(comp.cinematic_mode__hasLightning)
    }
  },
  {
    comps_track=[
      ["cinematic_mode__rain", ecs.TYPE_BOOL],
      ["cinematic_mode__snow", ecs.TYPE_BOOL],
      ["cinematic_mode__lightning", ecs.TYPE_BOOL],
      ["cinematic_mode__hasRain", ecs.TYPE_BOOL],
      ["cinematic_mode__hasSnow", ecs.TYPE_BOOL],
      ["cinematic_mode__hasLightning", ecs.TYPE_BOOL],
    ]
  }
)


ecs.register_es("ui_camera_fov_track_es",
  {
    [["onInit","onChange"]] = @(_eid, comp) comp.camera__active ? cameraFov(comp.fovSettings) : null
  },
  {
    comps_track=[["fovSettings", ecs.TYPE_FLOAT], ["camera__active", ecs.TYPE_BOOL]]
  }
)

ecs.register_es("ui_dof_track_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      isDofCameraEnabled(comp.dof__on)
      isDofFilmic(comp.dof__is_filmic)
      dofFocusDist(comp.dof__focusDistance)
      dofFocalLength(comp.dof__focalLength)
      dofStop(comp.dof__fStop)
      dofBokeCount(comp.dof__bokehShape_bladesCount)
      dofBokeSize(17.0 - comp.dof__bokehShape_kernelSize)
    }
  },
  {
    comps_track=[
      ["dof__on", ecs.TYPE_BOOL],
      ["dof__is_filmic", ecs.TYPE_BOOL],
      ["dof__focusDistance", ecs.TYPE_FLOAT],
      ["dof__focalLength", ecs.TYPE_FLOAT],
      ["dof__fStop", ecs.TYPE_FLOAT],
      ["dof__bokehShape_bladesCount", ecs.TYPE_FLOAT],
      ["dof__bokehShape_kernelSize", ecs.TYPE_FLOAT],
    ]
  }
)

ecs.register_es("ui_cinematic_mode_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      motionBlur(comp.cinematic_mode__mb_scale)
      bloomEffect(1.0 - comp.cinematic_mode__bloomThreshold)
      abberation(1.0 - comp.cinematic_mode__chromaticAberration.z)
      filmGrain(comp.cinematic_mode__filmGrain.x)
      vigneteEffect(comp.cinematic_mode__vignetteStrength)
      weatherPreset(comp.cinematic_mode__weatherPreset)
      lenseFlareIntensity(comp.cinematic_mode__lenseFlareIntensity)
      isCinematicModeActive(true)
    },
    onDestroy = function(_eid, _comp) {
      motionBlur(0)
      bloomEffect(0)
      abberation(0)
      filmGrain(0)
      vigneteEffect(0)
      lenseFlareIntensity(0)
      weatherPreset(null)
      isCinematicModeActive(false)
    }
  },
  {
    comps_track=[
      ["cinematic_mode__lenseFlareIntensity", ecs.TYPE_FLOAT],
      ["cinematic_mode__mb_scale", ecs.TYPE_FLOAT],
      ["cinematic_mode__bloomThreshold", ecs.TYPE_FLOAT],
      ["cinematic_mode__chromaticAberration", ecs.TYPE_POINT3],
      ["cinematic_mode__filmGrain", ecs.TYPE_POINT3],
      ["cinematic_mode__vignetteStrength", ecs.TYPE_FLOAT],
      ["cinematic_mode__weatherPreset", ecs.TYPE_STRING],
    ],
    comps_rq = [
      "cinematic_mode_tag",
    ]
  }
)

let function changeWeatherPreset(newVal) {
  if (newVal == null)
    return
  ecs.g_entity_mgr.broadcastEvent( CmdWeather({ preset = (typeof newVal == "string")
    ? newVal
    : weatherPresetList.value[newVal].preset }))
}

ecs.register_es("ui_cinematic_weather_presets_es",
  {
    function onInit(_eid, comp){
      local res = comp.cinematic_mode__weatherPresetList.getAll() ?? []
      res = res.map(@(v) {
        loc = loc($"weatherPreset/{v}")
        preset = v
        setValue = changeWeatherPreset
      })
      weatherPresetList(res)
    }
    onDestroy = @(_eid, _comp) weatherPresetList([])
  },
  {
    comps_ro=[
      ["cinematic_mode__weatherPresetList", ecs.TYPE_STRING_LIST]
    ]
  },
  {
    after="cinematic_mode_get_weathers_es"
  }
)

let function setRandomWeather() {
  let presets = weatherPresetList.value
  if (presets.len() <= 1)
    return
  let currentPreset = weatherPreset.value
  local newPreset = ""
  while (currentPreset != newPreset && newPreset == "")
    newPreset = chooseRandom(presets).preset
  changeWeatherPreset(newPreset)
}


let weatherChoiceQuery = ecs.SqQuery("weatherChoiceQuery",
  { comps_rq = ["weather_choice_tag"] })

let function changeWeather(weatherTemplates) {
  weatherChoiceQuery.perform(@(eid, _comp) ecs.g_entity_mgr.destroyEntity(eid))
  foreach (tmpl in weatherTemplates)
    ecs.g_entity_mgr.createEntity($"{tmpl}+weather_choice_created", {})
}

let changeDayTime = @(time)
  ecs.g_entity_mgr.broadcastEvent(CmdChangeTimeOfDay({ timeOfDay = time }))
let changeCameraFov = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetCameraFov({ fov = newVal.tointeger() }))
let changeBloom = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetBloomThreshold({ threshold = 1.0 - newVal }))
let changeAbberation = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetChromaticAberrationOffset({ offset = 1.0 - newVal }))
let changeFilmGrain = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetFilmGrain({ strength = newVal }))
let changeMotionBlur = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetMotionBlurScale({ scale = newVal }))
let changeVignette = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetVignetteStrength({ strength = newVal }))


let changeBoke = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofBokehCorners({ bokehCorners = newVal }))
let changeBokeSize = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofBokehSize({ bokehSize = 17.0 - newVal }))
let changeStop = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofFStop({ fStop = newVal }))
let changeFocalLength = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofFocalLength({ focalLength = newVal }))
let changeFocusDist = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofFocusDistance({ focusDistance = newVal }))
let changeLenseFlareIntensity = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetLenseFlareIntensity({ intensity = newVal }))


let updateDofCinematic = @() ecs.g_entity_mgr.broadcastEvent(
  CmdSetCameraDofEnabled({ enabled  = isDofCameraEnabled.value }))
let updateDofFilmic = @() ecs.g_entity_mgr.broadcastEvent(
  CmdSetDofIsFilmic({ isFilmic = isDofCameraEnabled.value }))

isDofCameraEnabled.subscribe(function(v) {
  updateDofCinematic()
  isDofFilmic(v)
  updateDofFilmic()
})

isDofFocalActive.subscribe(function(v) {
  if (!v) {
    dofFocalValToSafe(dofFocalLength.value)
    changeFocalLength(-1)
  }
  else{
    changeFocalLength(dofFocalValToSafe.value)
    dofFocalLength(dofFocalValToSafe.value)
  }
})


let updateCinematicMode = @() ecs.g_entity_mgr.broadcastEvent(
  CmdSetCinematicModeEnabled({ enabled = isCinematicModeActive.value}))

isCinematicModeActive.subscribe(@(_v) updateCinematicMode())

let changeRain = @(v) ecs.g_entity_mgr.broadcastEvent(CmdSetRain({ enabled = v }))
let changeSnow = @(v) ecs.g_entity_mgr.broadcastEvent(CmdSetSnow({ enabled = v }))
let changeLightning = @(v) ecs.g_entity_mgr.broadcastEvent(CmdSetLightning({ enabled = v }))


isRain.subscribe(@(v) changeRain(v))
isSnow.subscribe(@(v) changeSnow(v))
isLightning.subscribe(@(v) changeLightning(v))

return {
  levelTimeOfDay
  cameraFov
  changeWeather
  weatherChoiceQuery
  cinematicMode
  changeDayTime
  changeCameraFov
  isRain
  isSnow
  isLightning
  isCinematicModeActive
  changeBloom
  changeAbberation
  changeFilmGrain
  changeMotionBlur
  changeVignette
  motionBlur
  bloomEffect
  filmGrain
  abberation
  vigneteEffect
  weatherPreset
  weatherPresetList
  isDofCameraEnabled
  isDofFocalActive
  dofFocusDist
  dofFocalLength
  dofStop
  dofBokeCount
  dofBokeSize
  changeBoke
  changeBokeSize
  changeStop
  changeFocalLength
  changeFocusDist
  setRandomWeather
  hasSnow
  hasRain
  hasLightning
  changeWeatherPreset
  lenseFlareIntensity
  changeLenseFlareIntensity
  changeRain
  changeSnow
  changeLightning
}
