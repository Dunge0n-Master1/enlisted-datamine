import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { HIT_RES_NORMAL, HIT_RES_DOWNED, HIT_RES_KILLED } = require("dm")
let { localizeSoldierName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { AI_ACTION_ATTACK } = require("ai")
let { GRENADES_ORDER } = require("%ui/hud/huds/player_info/grenadeIcon.nut")
let { MINES_ORDER } = require("%ui/hud/huds/player_info/mineIcon.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

const HEAL_RES_COMMON = "actHealCommon"
const HEAL_RES_REVIVE = "actHealRevive"
const ATTACK_RES = "actAttack"

let hitTriggers = {}

let function getHitTrigger(id) {
  local trigger = hitTriggers?[id]
  if (trigger)
    return trigger

  trigger = {
    [HIT_RES_NORMAL] = {}, [HIT_RES_DOWNED] = {}, [HIT_RES_KILLED] = {},
    [HEAL_RES_COMMON] = {}, [HEAL_RES_REVIVE] = {}, [ATTACK_RES] = {}
  }
  hitTriggers[id] <- trigger
  return trigger
}

let getGrenadeType = @(grenades)
  grenades.reduce(@(a, b)
    (GRENADES_ORDER?[a] ?? 0) <= (GRENADES_ORDER?[b] ?? 0) ? a : b)

let getMineType = @(mines)
  mines.reduce(@(a, b)
    (MINES_ORDER?[a] ?? 0) <= (MINES_ORDER?[b] ?? 0) ? a : b)


let sortMembers = @(a,b) a.memberIdx <=> b.memberIdx
let mkDefState = @() {watchedHeroSquadEid = ecs.INVALID_ENTITY_ID, controlledSquadEid = ecs.INVALID_ENTITY_ID, members = {}}
let {watchedHeroSquadMembersRaw, watchedHeroSquadMembersRawSetValue, watchedHeroSquadMembersRawModify} = mkFrameIncrementObservable(mkDefState(), "watchedHeroSquadMembersRaw")

let watchedHeroSquadMembersGetWatched = memoize(@(eid) Computed(@() watchedHeroSquadMembersRaw.value.members?[eid]))

let watchedHeroSquadMembers = Computed(@()
  watchedHeroSquadMembersRaw.value.members.values().sort(sortMembers))

let watchedHeroSquadMembersOrderedSet = Computed(function(old){
  let newres = watchedHeroSquadMembers.value.map(@(v) v.eid)
  if (!isEqual(newres, old))
    return newres
  return old
})

let watchedHeroSquadEid = Computed(@() watchedHeroSquadMembersRaw.value.watchedHeroSquadEid)
let controlledSquadEid = Computed(@() watchedHeroSquadMembersRaw.value.controlledSquadEid)

let localPlayerSquadMembers = Computed(@() controlledSquadEid.value == watchedHeroSquadEid.value ? watchedHeroSquadMembers.value : {})

let function startMemberAnimations(curState, oldState) {
  let {isAlive, isDowned, hp, currentAiAction} = curState
  if (oldState==null)
    return
  if (oldState.isAlive && !isAlive)
    anim_start(curState.hitTriggers[HIT_RES_KILLED])
  else if (!oldState.isDowned && isDowned)
    anim_start(curState.hitTriggers[HIT_RES_DOWNED])
  else if (oldState.hp > hp)
    anim_start(curState.hitTriggers[HIT_RES_NORMAL])
  else if (oldState.hp < hp)
    anim_start(curState.hitTriggers[HEAL_RES_COMMON])
  else if (oldState.isDowned && !isDowned)
    anim_start(curState.hitTriggers[HEAL_RES_REVIVE])

  if (currentAiAction == AI_ACTION_ATTACK &&
      currentAiAction != oldState.currentAiAction)
    anim_start(curState.hitTriggers[ATTACK_RES])
}

let function getState(data) {
  let { name, surname } = localizeSoldierName({name = data.name, surname = data.surname})
  return {
    isDowned = data.isDowned
    memberIdx = data.memberIdx
    currentAiAction = data.currentAiAction
    eid = data.eid
    guid = data.guid
    name = data.callname != "" ? data.callname : $"{loc(name)} {loc(surname)}"
    isAlive = data.isAlive
    hp = data.hp.tofloat()
    maxHp = data.maxHp.tofloat()
    weapTemplates = data.weapTemplates
    hasAI = data.hasAI
    kills = data.kills
    targetHealCount = data.targetHealCount
    hasFlask = data.hasFlask
    targetReviveCount = data.targetReviveCount
    sKind = data.sKind
    sClassRare = data.sClassRare
    canBeLeader = data.canBeLeader
    isPersonalOrder = data.isPersonalOrder
    hitTriggers = getHitTrigger(data.eid)
    grenadeType = getGrenadeType(data?.grenadeTypes ?? [])
    mineType = getMineType(data?.mineTypes ?? [])
  }
}

ecs.register_es("track_squad_members_state_ui",
  {
    [["onChange", "onInit"]] = function trackSquad(_, comp) {
      if (!comp.is_local)
        return
      let watchedSquadEid = comp["squad_members_ui__watchedSquadEid"]
      let prevWatchedHeroSquadEid = watchedHeroSquadEid.value
      if (prevWatchedHeroSquadEid != watchedSquadEid) {
        watchedHeroSquadMembersRawSetValue(mkDefState())
      }
      let controlled = comp["squad_members_ui__controlledSquadEid"]
      let squadMembers = comp["squad_members_ui__watchedSquadState"].getAll()
      watchedHeroSquadMembersRawModify(function(state) {
        state.watchedHeroSquadEid = watchedSquadEid
        state.controlledSquadEid = controlled
        foreach (k, v in squadMembers) {
          let eid = k.tointeger()
          let oldState = state.members?[eid]
          let updatedState = getState(v)
          startMemberAnimations(updatedState, oldState)
          state.members[eid] <- updatedState
        }
        return state
      })
    },
  },
  { comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["squad_members_ui__watchedSquadState", ecs.TYPE_OBJECT],
      ["squad_members_ui__watchedSquadEid", ecs.TYPE_EID],
      ["squad_members_ui__controlledSquadEid", ecs.TYPE_EID],
  ] }
)

let isPersonalContextCommandMode = Watched(false)
let selectedBotForOrderEid = Watched(ecs.INVALID_ENTITY_ID)

let function trackComponentsPersonalBotOrder(_evt, _eid, comp) {
  if (comp["input__enabled"]) {
    isPersonalContextCommandMode(comp["squad_member__isPersonalContextCommandMode"])
    selectedBotForOrderEid(comp["personal_bot_order__currentBotEid"])
  }
}

ecs.register_es("hero_personal_bot_order_ui_es",
  {
    onChange = trackComponentsPersonalBotOrder
    onInit = trackComponentsPersonalBotOrder
    onDestroy = function(_evt, _eid, _comp) {
      isPersonalContextCommandMode(false)
      selectedBotForOrderEid(ecs.INVALID_ENTITY_ID)
    }
  },
  {
    comps_track = [
      ["personal_bot_order__currentBotEid", ecs.TYPE_EID],
      ["squad_member__isPersonalContextCommandMode", ecs.TYPE_BOOL],
      ["input__enabled", ecs.TYPE_BOOL],
    ]
  }
)

return {
  watchedHeroSquadEid
  watchedHeroSquadMembers
  watchedHeroSquadMembersGetWatched
  watchedHeroSquadMembersOrderedSet
  localPlayerSquadMembers
  selectedBotForOrderEid
  isPersonalContextCommandMode

  HEAL_RES_COMMON
  HEAL_RES_REVIVE
  ATTACK_RES
}
