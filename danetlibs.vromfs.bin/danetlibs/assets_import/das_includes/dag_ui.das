module dag_ui shared

require ecs
require imgui/imgui_boost
require daslib/static_let
require strings
require danetlibs.assets_import.das_includes.utility
require AssetsImport

def edit_value(text : string; var value : das_string&)
  let buf <- ImGuiInputTextBuffer("{value}", 256)
  if InputText(text, buf, ImGuiInputTextFlags AutoSelectAll)
    value := buf |> to_string()
    return true
  return false

def imgui_click_to_copy(val : string)
  if imgui::IsItemHovered()
    imgui::BeginTooltip()
    imgui::PushTextWrapPos(GetFontSize() * 35.0f)
    imgui::TextUnformatted("right click to copy {val}")
    imgui::PopTextWrapPos()
    imgui::EndTooltip()
    if imgui::IsMouseClicked(ImGuiMouseButton Right)
      SetClipboardText("{val}")


def get_asset_status_color(status : AssetLoadingStatus)

  if status == AssetLoadingStatus LoadedWithErrors
    return float4(1f, 0f, 0f, 1f)
  elif status == AssetLoadingStatus Loading
    return float4(0f, 0f, 1f, 1f)
  elif status == AssetLoadingStatus Loaded
    return float4(0f, 1f, 0f, 1f)
  else //status == AssetLoadingStatus NotLoaded
    return float4(1f, 1f, 1f, 1f)


def asset_dependencies_tree(var asset : DagorAsset?; asset__manager : DagorAssetMgr; is_root = true)

  if imgui::TreeNodeEx("{asset.name}:{asset.typeName}##{asset}", is_root ? ImGuiTreeNodeFlags DefaultOpen : ImGuiTreeNodeFlags None)
    imgui_click_to_copy(*asset |> getSrcFilePath())
    let status = get_asset_status(*asset, false)
    imgui::SameLine()
    imgui::TextColored(get_asset_status_color(status), "[{status}]")


    imgui::Text("Source files: ")
    get_asset_source_files(*asset) <| $(srcFiles)
      for file, idx in srcFiles, iter_range(srcFiles)
        imgui::Text("{idx}) {file}")
        imgui_click_to_copy(file)

    get_asset_dependencies(*asset) <| $(assetsNames)
      for depName in assetsNames
        var depAsset = asset__manager |> findAsset(depName)
        if depAsset != null
          asset_dependencies_tree(depAsset, asset__manager, false)
        elif !empty(depName)
          imgui::TextColored(float4(1, 0, 0, 1), "{depName} broken ref")
    imgui::TreePop()
    imgui::Separator()
  else
    imgui_click_to_copy(*asset |> getSrcFilePath())
    let status = get_asset_status(*asset, false)
    imgui::SameLine()
    imgui::TextColored(get_asset_status_color(status), "[{status}]")



def view_dag_assets(assset_type : string; b : block<(arg1 : string const) : void>)
  static_let <|
    var selectedAssetIdx = 0

  query() <| $ [es] (var asset__currentSearchFilter : das_string&; var asset__currentDagTextures : StringList; asset__manager : DagorAssetMgr)
    edit_value("Filter:", asset__currentSearchFilter)

    get_filtered_assets(assset_type, string(asset__currentSearchFilter)) <| $(assetsNames)

      if (empty(assetsNames))
        imgui::Text("No assets {assset_type}")
      else
        let firstName = selectedAssetIdx < length(assetsNames) ? assetsNames[selectedAssetIdx] : ""
        if imgui::BeginCombo("##", firstName)
          for name, idx in assetsNames, iter_range(assetsNames)
            let isSelected = selectedAssetIdx == idx
            if imgui::Selectable(name, isSelected)
              selectedAssetIdx = idx
              asset__currentDagTextures |> clear()

              let asset = asset__manager |> findAsset(assetsNames[selectedAssetIdx])
              let path = *asset |> getSrcFilePath()
              if path |> ends_with(".dag")
                iterate_dag_textures(path) <| $(texPath : string)
                  asset__currentDagTextures |> push(get_base_name_without_ext(texPath))


          imgui::EndCombo()
        imgui::SameLine()

        if selectedAssetIdx < 0
          asset__currentDagTextures |> clear()
          return

        var asset = asset__manager |> findAsset(assetsNames[selectedAssetIdx])

        let name = *asset |> getName()
        let path = *asset |> getSrcFilePath()
        imgui::Spacing()
        imgui::Text("Asset name: {name}")
        imgui_click_to_copy(name)
        imgui::Spacing()

        imgui::Button("Copy path")
        imgui_click_to_copy(path)
        imgui::Spacing()


        let finalAssetStatus = get_asset_status(*asset, true)
        imgui::Text("Dependance assets: ")
        asset_dependencies_tree(asset, asset__manager)




        let spawn = imgui::Button("Spawn")
        imgui::SameLine()
        imgui::TextColored(get_asset_status_color(finalAssetStatus), "[{finalAssetStatus}]")
        if spawn
          invoke(b, assetsNames[selectedAssetIdx])