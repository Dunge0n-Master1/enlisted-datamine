from "%enlSqGlob/ui_library.nut" import *

let {Point3} = require("dagor.math")
let {cos, sin, PI} = require("math")
let {hitMarks, downedColor, hitColor, killColor, killSize, hitSize, killTtl, hitTtl, showWorldKillMark} = require("%ui/hud/state/hit_marks_es.nut")
let u = require("%sqstd/underscore.nut")
let {HitResult} = require("%enlSqGlob/dasenums.nut")
let { showCrosshairHints } = require("%ui/hud/state/hudOptionsState.nut")

let animations = [
  { prop=AnimProp.opacity, from=0.2, to=1, duration=0.1, play=true, easing=InCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop = AnimProp.scale, from =[0.25, 0.25], to = [1, 1], duration = 0.1, easing = InCubic, play = true}
]

local function mkAnimations(duration=0.4, appearPart = 0.15, stayPart = 0.25, fadePart = 0.65){
  duration = min(duration, 100)
  let appearDur = appearPart*duration
  let stayDur = stayPart*duration
  let fadeDur = fadePart*duration
  let fadeOutTrigger = {}
  let fadedTrigger = {}
  return [
    { prop=AnimProp.opacity, from=0.1, to=1.0, duration=appearDur, play=true, easing=InCubic, onExit=fadeOutTrigger}
    { prop=AnimProp.opacity, from=1.0, to=0.0, delay = stayDur, duration=fadeDur, easing = InCubic, trigger=fadeOutTrigger, onExit=fadedTrigger}
    { prop=AnimProp.opacity, from=0.0, to=0.0, duration=max(duration*3,100), trigger=fadedTrigger}//just a huge number to keep it hidden, until it removed

    { prop=AnimProp.scale, from=[1,1], to=[1.2,1.2], duration=0.15, playFadeOut=true, easing = InOutCubic}
  ]
}

let function build_hitmarks_commands(marksCount) {
  let commands = [[VECTOR_WIDTH, hdpx(1.8)]]
  let markSize = 100
  let percentile = 0.5
  let initAngle = PI * 0.5 / (marksCount + 1);
  let center = {
    x = 50
    y = 50
  }
  for (local markId = 0; markId < marksCount; ++markId) {
    //four lines for each mark
    for (local i = 0; i < 2; ++i) {
      let angle = initAngle*(markId + 1) - PI*0.5*i
      let c = cos(angle)
      let s = sin(angle)
      for (local j = -1; j <= 1; j += 2) {
        let coor = {
          x = markSize * c * j
          y = markSize * s * j
        }
        commands.append([VECTOR_LINE,
          center.x + coor.x * percentile, center.y + coor.y * percentile,
          center.x + coor.x, center.y + coor.y])
      }
    }
  }
  return commands
}

const maxHitCount = 1
let hitHairMap = {}
for(local i = 1; i <= maxHitCount; i += 2)
  hitHairMap[i] <- build_hitmarks_commands(i)

let simpleHitMark = hitHairMap[1]


local hitMarkParams
local posHitMarksParams
local showWorldKillMarkCached
let function updateLocalCache(...){
  let commonHitMarkAnims = mkAnimations(hitTtl.value/3.0) //this is needed because of different time scale. Hitmarks can disappear with not smooth animation
  let commonKillMarkAnims = mkAnimations(killTtl.value/3.0)
  hitMarkParams = {
    [HitResult.HIT_RES_NORMAL] = {size = hitSize.value, color = hitColor.value, animations = commonHitMarkAnims},
    [HitResult.HIT_RES_DOWNED] = {size = killSize.value, color = downedColor.value, animations = commonHitMarkAnims},
    [HitResult.HIT_RES_KILLED] = {size = killSize.value, color = killColor.value, animations = commonKillMarkAnims}
  }
  showWorldKillMarkCached = showWorldKillMark.value
  posHitMarksParams = {
    [HitResult.HIT_RES_NORMAL] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = hitSize.value transform = {} color = hitColor.value},
    [HitResult.HIT_RES_DOWNED] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = killSize.value transform = {} color = downedColor.value},
    [HitResult.HIT_RES_KILLED] = {rendObj = ROBJ_VECTOR_CANVAS commands = simpleHitMark size = killSize.value transform = {} color = killColor.value},
  }
}
{
  [downedColor, hitColor, killColor, killSize, hitSize, killTtl, hitTtl, showWorldKillMark]
    .map(@(v) v.subscribe(updateLocalCache))
}
updateLocalCache()
/*
  TODO:
   - to show multiple shots (very fast weapons or grenade or shortgun it is better to show some elements like in WT or Apex
   - melee probably can looks better when shown as kill Marks in World, espically in TPS view
  Notes:
  - animations could possible be better if made with transitions. however currently it's fine

*/
let currentHitMark = Watched(null)
let posHitMarks = Watched([])

let function isPositionalHitMark(v){
  if (v?.hitPos==null)
    return false
  if (showWorldKillMarkCached){
    return v?.isMelee || (!v?.isKillHit && !v?.isDownedHit)
  }
  return v?.isMelee
}
let function updateHitMarks(hitMarksRes){
  let res = u.partition(hitMarksRes, isPositionalHitMark)
  posHitMarks(res[0])
  let hitms = res[1]
  currentHitMark((hitms?.len() ?? 0)>0 ? hitms?[hitms.len()-1] : null)
}
hitMarks.subscribe(updateHitMarks)
updateHitMarks(hitMarks.value)

let function hitHair() {
  if (!showCrosshairHints.value)
    return { watch = showCrosshairHints }

  let curHitMark = currentHitMark.value
  let key = curHitMark?.id ?? {}
  return {
    watch = [currentHitMark, showCrosshairHints]
    size = SIZE_TO_CONTENT
    children = {
      rendObj = ROBJ_VECTOR_CANVAS
      transform = {}
      key = key
      commands = curHitMark!=null && !curHitMark.isImmunityHit ? simpleHitMark : null
    }.__update(hitMarkParams?[curHitMark?.hitRes] ?? hitMarkParams[HitResult.HIT_RES_NORMAL])
  }
}

let function mkPosHitMark(mark){
  let pos = mark.hitPos
  return {
    data = {
      minDistance = 0.1
      clampToBorder = true
      worldPos = Point3(pos[0], pos[1], pos[2])
    }
    animations = animations
    transform = {}
    children = posHitMarksParams?[mark?.hitRes] ?? posHitMarksParams[HitResult.HIT_RES_NORMAL]
    key = mark?.id ?? {}
  }
}

let function posHitMarksComp() {
  return {
    watch = [posHitMarks]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [sw(100), sh(100)]
    children = posHitMarks.value.map(mkPosHitMark)
    behavior = Behaviors.Projection
  }
}

return {
  hitMarks = hitHair
  posHitMarks = posHitMarksComp
  _updateLocalCache = updateLocalCache
}
