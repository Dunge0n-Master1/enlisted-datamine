module rendinst_ui shared

require ecs
require math
require math.base
require imgui/imgui_boost
require daslib/static_let
require daslib/safe_addr
require strings
require danetlibs.assets_import.main.import_rendinst_common
require danetlibs.assets_import.das_includes.utility
require danetlibs.assets_import.das_includes.dag_ui
require AssetsImport
require DagorDataBlock
require stddlg

def create_rendinst(name : string; transform : float3x4; template_name : string)
  return createEntity(template_name) <| $(init)
    set(init, "transform", transform)
    set(init, "ri_extra__name", name)

def spawn_rendinst()
  view_dag_assets("rendInst") <| $(assetName)
    create_rendinst(assetName, find_transform(), "game_rendinst")


def create_new_rendinst_asset()
  query() <| $ [es] (asset__baseFolderAbsPath : string;
                     var activeRI__lodDistances : FloatList;
                     var activeRI__lodFiles : StringList)
    var removeLod = -1
    let lodsCount = length(activeRI__lodDistances)

    for lodDist, lodFile, lodNo in activeRI__lodDistances, activeRI__lodFiles, range(lodsCount)
      imgui::Text("lod {lodNo}")
      if empty(lodFile)
        imgui::TextColored(float4(1.0, 0.0, 0.0, 1.0), "empty path")
      //else if () add check of invalid path
      else
        imgui::Text("{lodFile}")
      imgui::SameLine()
      if imgui::Button("change source file##{lodNo}")
        get_local_path_to_dag(asset__baseFolderAbsPath, lodFile)

      if lodNo == lodsCount - 1
        imgui::SameLine()
        if imgui::Button("remove LOD##{lodNo}")
          removeLod = lodNo

      var tmpValue = lodDist
      imgui::InputFloat("LOD distance##{lodNo}", safe_addr(tmpValue))
      lodDist = tmpValue

    if removeLod >= 0
      activeRI__lodDistances |> erase(removeLod)
      activeRI__lodFiles |> erase(removeLod)

    if imgui::Button("add LOD")
      using() <| $(var lodFile : das_string#)
        if get_local_path_to_dag(asset__baseFolderAbsPath, lodFile)
          activeRI__lodDistances |> push(100f)
          activeRI__lodFiles |> push(lodFile)

    imgui::NewLine()
    var importedRI = false

    if length(activeRI__lodDistances) > 0
      if imgui::Button("save asset")
        let assetPath = get_dlg_save_file("", "", "rendinst.blk")
        if !empty(assetPath)
          let assetName = get_base_name_without_ext(assetPath)
          importedRI = true
          import_rendinst(assetPath, activeRI__lodDistances, activeRI__lodFiles)
      imgui::NewLine()

    if imgui::Button("clear") || importedRI
      activeRI__lodDistances |> clear()
      activeRI__lodFiles |> clear()

def composit_tree(var entities : EidList#; node : DataBlock; transform : float3x4)

  let nodeName = datablock_getStr(node, "name", "")
  let nodeType = datablock_getStr(node, "type", "")
  let localTransform = datablock_getTm(node, "tm", IDENT_TM)
  let nodeTransform = transform * localTransform

  if nodeType == "rendInst"
    entities |> push(create_rendinst(nodeName, nodeTransform, "composit_child_rendinst"))
  elif nodeType == "composit"
    entities |> push(create_composit_entity(nodeName, nodeTransform))


  datablock_for_each_block(node, "node") <| $(blk)
    composit_tree(entities, blk, nodeTransform)



def create_composit_entity(name : string; transform : float3x4)

  var eid : EntityId
  query() <| $ [es] (asset__manager : DagorAssetMgr)
    let asset = asset__manager |> findAsset(name)
    using() <| $(var entities : EidList#)

      composit_tree(entities, asset.props, transform)

      eid = createEntity("composit_rendinst") <| $(init)
        set(init, "transform", transform)
        set(init, "composit__name", name)
        set(init, "composit__prevTransform", transform)
        set(init, "composit__entities", entities)
  return eid


def spawn_composit()
  view_dag_assets("composit") <| $(assetName)

    create_composit_entity(assetName, find_transform())

