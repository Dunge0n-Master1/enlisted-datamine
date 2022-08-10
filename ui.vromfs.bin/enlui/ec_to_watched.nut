from "%enlSqGlob/library_logs.nut" import *
from "frp" import Watched

let { frameUpdateCounter } = require("%ui/scene_update.nut")

/*
  function receive Source Observable and Frame 'Event Stream' observable
  and returns new observable that will update it's value only on frame observable change
*/

let function FrameIncrementObservable(obs){
  let res = Watched(obs.value)
  local timeChangeReq = obs.timeChangeReq
  let function func(_){
    let newTime = obs.timeChangeReq
    if (timeChangeReq == newTime)
      return
    timeChangeReq = newTime
    res.update(obs.value)
  }

  frameUpdateCounter.subscribe(func)
  res.whiteListMutatorClosure(func)
  return res
}

/*
  function returns new observable of eid 'set' {eid:eid} that will update only at frameCounter change
  and 3 functions:
    - getWatched(eid) function will get Watched value that will be update on eid components change
    - updateEid(eid, value) - will update Watched value and add new eid to Set if it is needed
    - destroyEid(eid) - will remove eid from Set
    if mkCombined provided - function will return 'state' observable {eid: value}
    this can be needed for some Computed streams
*/
let TO_DELETE = persist("TO_DELETE", @() freeze({}))

let function mkWatchedSetAndStorage(key=null, mkCombined=false){
  let observableEidsSet = mkCombined ? null : Watched({})
  let state = mkCombined ? Watched({}) : null
  let storage = {}
  let eidToUpdate = {}
  local update
  update = mkCombined
    ? function (_){
      state.mutate(function(v) {
        foreach(eid, val in eidToUpdate){
          if (val == TO_DELETE) {
            if (eid in storage)
              delete storage[eid]
            if (eid in v)
              delete v[eid]
          }
          else
            v[eid] <- val
        }
      })
      eidToUpdate.clear()
      frameUpdateCounter.unsubscribe(update)
    }
    : function (_){
      observableEidsSet.mutate(function(v) {
        foreach(eid, val in eidToUpdate){
          if (val == TO_DELETE) {
            if (eid in storage)
              delete storage[eid]
            if (eid in v)
              delete v[eid]
          }
          else
            v[eid] <- eid
        }
      })
      eidToUpdate.clear()
      frameUpdateCounter.unsubscribe(update)
    }
  let destroyEid = function (eid) {
    if (eid not in storage)
      return
    eidToUpdate[eid] <- TO_DELETE
    frameUpdateCounter.subscribe(update)
  }
  let updateEidProps = mkCombined
    ? function ( eid, val ) {
        if (eid not in storage) {
          storage[eid] <- Watched(val)
        }
        else {
          storage[eid].update(val)
        }
        eidToUpdate[eid] <- val
        frameUpdateCounter.subscribe(update)
      }
    : function (eid, val) {
        if (eid not in storage) {
          storage[eid] <- Watched(val)
          eidToUpdate[eid] <- eid
          frameUpdateCounter.subscribe(update)
        }
        else
          storage[eid].update(val)
      }
  let function getWatchedByEid(eid){
    return storage?[eid]
  }
  if (mkCombined)
    state.whiteListMutatorClosure(update)
  else
    observableEidsSet.whiteListMutatorClosure(update)

  if (key==null) {
    return {
      getWatched = getWatchedByEid
      updateEid = updateEidProps
      destroyEid
    }.__update(mkCombined ? {state} : {set = observableEidsSet})
  }
  else {
    assert(type(key)=="string", @() $"key should be null or string, but got {type(key)}")
    return {
      [$"{key}GetWatched"] = getWatchedByEid,
      [$"{key}UpdateEid"] = updateEidProps,
      [$"{key}DestroyEid"] = destroyEid,
    }.__update(mkCombined ? {[$"{key}State"] = state} : {[$"{key}Set"] = observableEidsSet})
  }
}
let KeyAndVal = class{
  val = null
  key = null
  constructor(k, v){
    this.val = v
    this.key = k
  }
}
let Mutator = class{
  val = null
  constructor(v){
    this.val = v
  }
}
let DeleteKey = class{
  key = null
  constructor(k){
    this.key = k
  }
}

let function mkFrameIncrementObservable(defValue = null, name = null){
  local valsToSet = []
  let res = Watched(defValue)
  let function updateFunc(_) {
    local newResVal = res.value
    foreach (newVal in valsToSet) {
      let klass = newVal?.getclass()
      if (klass == KeyAndVal) {
        newResVal[newVal.key] <- newVal.val
      }
      else if (klass == DeleteKey){
        let key = newVal.key
        if (key in newResVal)
          delete newResVal[key]
      }
      else if (klass == Mutator) {
        newVal.val(newResVal)
      }
      else
        newResVal = newVal
    }
    frameUpdateCounter.unsubscribe(updateFunc)
    valsToSet.clear()
    let needToTrigger = newResVal == res.value
    res(newResVal)
    if (needToTrigger)
      res.trigger()
  }
  res.whiteListMutatorClosure(updateFunc)
  let function deleteKey(k){
    valsToSet.append(DeleteKey(k))
    frameUpdateCounter.subscribe(updateFunc)
  }
  let function setKeyVal(k, v){
    valsToSet.append(KeyAndVal(k, v))
    frameUpdateCounter.subscribe(updateFunc)
  }
  let function setValue(val){
    valsToSet.clear()
    valsToSet.append(val)
    frameUpdateCounter.subscribe(updateFunc)
  }
  let function mutate(val){
    valsToSet.append(Mutator(val))
    frameUpdateCounter.subscribe(updateFunc)
  }
  if (name==null)
    return {state = res, setValue, setKeyVal, deleteKey, mutate}
  return {[name] = res, [$"{name}SetValue"]=setValue, [$"{name}SetKeyVal"] = setKeyVal, [$"{name}DeleteKey"] = deleteKey, [$"{name}Mutate"]=mutate}
}

return {
  mkWatchedSetAndStorage
  FrameIncrementObservable
  mkFrameIncrementObservable
  MK_COMBINED_STATE = true
}