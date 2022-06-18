import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let Rand = require("%sqstd/rand.nut")
let curGenFaces = require("%enlist/faceGen/gen_faces.nut")
let {
  genFacesOverrides, ASIAN, AFRICAN, EUROPEAN
} = require("%enlist/faceGen/animTree_gen_faces.nut")

let headsCompsQuery = ecs.SqQuery("headsCompsQuery",
  { comps_ro = ["animcharParams", "collres__res", "item__uniqueName"] })

let function faceGen(faceConfig = null) {
  let rand = Rand()
  let { race = EUROPEAN } = faceConfig
  let face = {}

  face["low_lip_root_y"] <- rand.rfloat(0.0, 1.0)
  face["ears_size"] <- rand.rfloat(0.6, 1.3)
  face["ears_angles"] <- rand.rfloat(0.0, 0.5)
  face["eyes_angle"] <- rand.rfloat(-0.5, 0.5)
  face["nose_root_vert"] <- rand.rfloat(-1.0, 0.2)
  face["nose_root_rotate"] <- rand.rfloat(-0.5, 0.8)
  face["nose_fracture"] <- rand.rint(0, 15) > 0 ? rand.rfloat(-0.3, 0.3)
    : rand.rint(0, 1) > 0 ? rand.rfloat(-1, -0.7)
    : rand.rfloat(0.7, 1)
  face["nose_center_2_scale_x"] <- rand.rfloat(0.3, 2.0)
  face["bottom_face_rot"] <- rand.rfloat(-0.5, 0.0)
  face["bottom_face_vert"] <- rand.rfloat(-1.0, 0.5)
  face["bottom_face_forw"] <- rand.rfloat(-3.4, 5.0)
  face["chin_face_vert"] <- rand.rfloat(-0.9, 1.0)
  face["chin_face_forw"] <- rand.rfloat(-1.0, 1.0)
  face["chin_face_rot"] <- rand.rfloat(-0.5, 1.0)
  face["chin_face_hor_scale"] <- rand.rfloat(0.3, 2.0)
  face["second_chin_face_hor_scale"] <- rand.rfloat(0.2, 2.2)
  face["cheeks_hor"] <- rand.rfloat(-2.0, 2.0)
  face["cheeks_vert"] <- rand.rfloat(0.0, 2.0)
  face["forehead_pos_y"] <- rand.rfloat(-2.0, 2.0)
  face["forehead_scale"] <- rand.rfloat(0.6, 1.2)
  face["forehead_hor_scale"] <- rand.rfloat(0.4, 1.5)
  face["jaw_root_bottom_scale"] <- rand.rfloat(0.8, 1.0)

  if (race == EUROPEAN) {
    face["lip_size"] <- rand.rfloat(0.7, 1.5)
    face["lip_thickness"] <- rand.rfloat(0.7, 2.0)
    face["nose_root_scale_diff"] <- rand.rfloat(0.0, 0.5)
    face["ears_angles"] <- rand.rfloat(0.0, 0.8)
  } else if (race == ASIAN) {
    face["lip_size"] <- rand.rfloat(0.6, 1.8)
    face["lip_thickness"] <- face["lip_size"] > 0.8 ? rand.rfloat(0.0, 1.0)
      : face["lip_size"] * 3.0 - 2.0
    face["eyes_angle"] <- rand.rfloat(0.0, 1.0)
    face["asia_eye"] <- face["eyes_angle"] / 2.0
    face["nose_root_scale_diff"] <- rand.rfloat(0.0, 0.2)
  } else if (race == AFRICAN) {
    face["lip_size"] <- rand.rfloat(0.9, 1.5)
    face["lip_thickness"] <- rand.rfloat(0.5, 1.5)
    face["nose_root_scale_diff"] <- rand.rfloat(0.0, 0.75)
    face["chin_face_rot"] <- rand.rfloat(-0.5, 0.5)
    face["jaw_root_bottom_scale"] <- rand.rfloat(0.5, 1.0)
  }
  if (faceConfig != null)
    foreach (key, value in faceConfig)
      if (key != "race")
        face[key] = rand.rfloat(value.x, value.y)
  return face
}

let function safeFaceToJson(data) {
  let json = require("json")
  let io = require("io")
  let file = io.file("EUFaces.json", "wt+")
  file.writestring(json.to_string(data, true))
  file.close()
  log("Saved to EUFaces.json")
}

console_register_command(function(asset, num) {
  log("These face parameters will change")
  let data = clone curGenFaces
  foreach (nameOfAsset, value in genFacesOverrides)
    if (nameOfAsset == asset)
      data[nameOfAsset][num.tostring()] = faceGen(value)
  safeFaceToJson(data)
}, "faceGen.fixErrorFace")

console_register_command(function() {
  log_for_user("These face parameters are not attractive")
  headsCompsQuery.perform(function(_eid, comp) {
    log_for_user(comp["collres__res"], comp["item__uniqueName"])
    log_for_user(comp["animcharParams"].getAll())
  })
}, "faceGen.faceError")

console_register_command(function(asset, num) {
  log("Add new face animchar to faceGen")
  log("Do not forget to add a name to animTree_gen_faces!")
  if (asset in curGenFaces)
    return log("ERROR This animchar is already in the config file")

  let data = clone curGenFaces
  let curNumConfig = {}
  for (local i = 0; i < num; i++)
    curNumConfig[i] <- faceGen(genFacesOverrides[asset])
  data[asset] <- curNumConfig
  safeFaceToJson(data)
}, "faceGen.AddNewFace")

console_register_command(function(num) {
  let data =  {}
  foreach (nameOfAsset, value in genFacesOverrides) {
    let curAssetFaces = {}
    let length = curGenFaces?[nameOfAsset].len() ?? 0
    if (nameOfAsset in curGenFaces)
      log($"{length} faces of asset {nameOfAsset}")
    else
      log($"no faces with asset {nameOfAsset}")
    for (local i = 0; i < length; i++)
      curAssetFaces[i] <- curGenFaces?[nameOfAsset][i.tostring()]

    for (local i = 0; i < num; i++)
      curAssetFaces[length + i] <- faceGen(value)

    data[nameOfAsset] <- curAssetFaces
  }
  safeFaceToJson(data)
}, "faceGen.genEUFaces")

return faceGen
