from "%enlSqGlob/ui_library.nut" import *

from "%sqstd/json.nut" import loadJson
from "dagor.debug" import logerr

let i = @(pos, sufx = "_weapon")
  "enlisted_idle_{0}{1}".subst(pos >= 10 ? pos : $"0{pos}", sufx)

const pathToCfg = "config/menu_poses_for_weapons.json"

let function transformArrayOfPoses(arr, arrName){
  foreach(idx, pose_name in arr) {
    let t = type(pose_name)
    if (t=="string")
      continue
    if (t=="integer")
      arr[idx] = i(pose_name)
    else {
      log($"in {arrName}, at position {idx} should be string (pose name) or integer (default pose name), but found {t}")
      logerr("incorrect pose in pose list")
    }
  }
  return arr
}


let {weaponToSittingAnimState, weaponToAnimState} = function loadPosedFromJson() {
  try{
    let fromJson = loadJson(pathToCfg)
    let namedPoses = fromJson["namedPoses"]
    foreach (k, v in namedPoses) {
      transformArrayOfPoses(v,k)
    }

    let function cvtToPosesLists(keyName){
      let toDeletePosesKeys = []
      let posesList = fromJson[keyName]
      foreach(k, v in posesList){
        if (k.startswith("__")) {
          toDeletePosesKeys.append(k)
          continue
        }
        if (type(v) == "array")
          transformArrayOfPoses(v, k)
        else if (type(v)=="string"){
          posesList[k] = namedPoses[v]
        }
        else {
          log(k, v)
          logerr($"incorrect pose list for {keyName}")
        }
      }
      foreach(k in toDeletePosesKeys)
        delete posesList[k]
      return posesList
    }
    return {
      weaponToAnimState = cvtToPosesLists("weaponToAnimState"),
      weaponToSittingAnimState = cvtToPosesLists("weaponToSittingAnimState")
    }
  }
  catch(e){
    log(e)
    if (!("__argv" in getroottable())) //silence validator
      logerr($"error loading animations {pathToCfg}, see log for details")
    return {
      weaponToAnimState = freeze({
        defaultPoses = [i(11)]
        unarmedPoses = ["enlisted_idle_01", "enlisted_idle_02","enlisted_idle_03", "enlisted_idle_04"]
        standardRifle = [9, 12, 13, 14, 15, 16, 18].map(@(v) i(v))
        specificRifle = [9, 12, 14, 16, 18].map(@(v) i(v))
        specificGun = [9, 11, 12, 13, 14, 15, 16, 18].map(@(v) i(v))
        standardPistol = ["enlisted_idle_03", "enlisted_idle_02", "enlisted_idle_19_weapon"]
      })
      weaponToSittingAnimState = {defaultPoses = [i(20)]}
    }
  }
}()

let getMentionedAnimStates = @(weaponToAnimStates) weaponToAnimStates.reduce(function(tbl, val) {
  val.each(@(id) tbl[id] <- true)
  return tbl
}, {})

let allIdleAnims =
  getMentionedAnimStates(weaponToAnimState)
  .__merge(getMentionedAnimStates(weaponToSittingAnimState))
  .keys().sort()

return {
  weaponToAnimState
  weaponToSittingAnimState
  allIdleAnims
}