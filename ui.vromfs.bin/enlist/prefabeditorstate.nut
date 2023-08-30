import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%daeditor/ec_to_watched.nut")
let { selectedPrefabs, selectedPrefabsSetKeyVal, selectedPrefabsDeleteKey } = mkFrameIncrementObservable({}, "selectedPrefabs")
let { selectedPrefabObjects, selectedPrefabObjectsSetKeyVal, selectedPrefabObjectsDeleteKey } = mkFrameIncrementObservable({}, "selectedPrefabObjects")
let { selectedNoPrefabs, selectedNoPrefabsSetKeyVal, selectedNoPrefabsDeleteKey } = mkFrameIncrementObservable({}, "selectedNoPrefabs")
let {scan_folder} = require("dagor.fs")

const USER_PREFABS_FOLDER = "userPrefabs"
const PREFAB_EXT =".blk"

let isPrefabTool = Watched(false)
let selectedPrefab = Watched(null)

let function getPrefabsInLibrary() {
  let files = scan_folder({root = USER_PREFABS_FOLDER, vromfs = false, realfs = true, recursive = false, files_suffix = PREFAB_EXT})
  return files.map(@(v) v.slice(USER_PREFABS_FOLDER.len()+1, -PREFAB_EXT.len()))
}

let prefabsLibrary = Watched(getPrefabsInLibrary())

selectedPrefabs.subscribe(function(v) {
  if (v.len() == 1) {
    let eid = v.keys()[0]
    selectedPrefab(v[v.keys()[0]].__update({eid}))
  }
  else
    selectedPrefab(null)
})

ecs.register_es("selected_prefabs_ui", {
  onInit = @(eid, comp) selectedPrefabsSetKeyVal(eid, {
    name = comp.prefab__name
    id = comp.prefab__id
  })
  onDestroy = @(eid, _comp) selectedPrefabsDeleteKey(eid)
},
{
  comps_rq=["daeditor__selected"],
  comps_ro=[["prefab__name", ecs.TYPE_STRING], ["prefab__id", ecs.TYPE_INT]]
})

ecs.register_es("selected_prefab_objects_ui", {
  onInit = @(eid, _comp) selectedPrefabObjectsSetKeyVal(eid, true)
  onDestroy = @(eid, _comp) selectedPrefabObjectsDeleteKey(eid)
},
{
  comps_rq=["prefab__parentId", "daeditor__selected"]
})

ecs.register_es("selected_not_prefab_objects_ui", {
  onInit = @(eid, _comp) selectedNoPrefabsSetKeyVal(eid, true)
  onDestroy = @(eid, _comp) selectedNoPrefabsDeleteKey(eid)
},
{
  comps_rq=["daeditor__selected"],
  comps_no=["prefab__id", "prefab__parentId"]
})

return {
  isPrefabTool
  selectedPrefabs
  selectedPrefabObjects
  selectedNoPrefabs
  selectedPrefab
  prefabsLibrary
  getPrefabsInLibrary
}
