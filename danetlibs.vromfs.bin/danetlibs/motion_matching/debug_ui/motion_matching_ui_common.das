module motion_matching_ui_common shared

require ecs
require DagorSystem
require imgui
require imgui/imgui_boost
require MotionMatching
require daslib/safe_addr
require daslib/strings_boost
require daslib/static_let
require DagorConsole
require DagorTime
//require stddlg
require danetlibs/motion_matching/es/motion_matching_common
require danetlibs/motion_matching/es/mm_events

let TICKS_PER_SECOND = 30f


def index(tags : StringList; tag : string) : int
  return find_index_if(each(tags)) <| $(s) { return eq(s, tag); }

def safe_slider(title : string; var value : float&; min_value, max_value : float)
  var tmpValue = value
  let result = imgui::SliderFloat(title, safe_addr(tmpValue), min_value, max_value)
  value = tmpValue
  return result

def edit_weights(var weights : FeatureWeights; nodes_name : StringList; prediction_times : FloatList)
  let hash = unsafe(addr(weights))
  for p, v, name in weights.nodePositions, weights.nodeVelocities, nodes_name
    imgui::Text("{name}")
    safe_slider("position##{name}{hash}", p, 0f, 10f)
    safe_slider("velocity##{name}{hash}", v, 0f, 10f)

  for p, v, t in weights.rootPositions, weights.rootDirections, prediction_times
    imgui::Text("prediction time {t}")

    safe_slider("position##{t}{hash}", p, 0f, 10f)
    safe_slider("velocity##{t}{hash}", v, 0f, 10f)
  imgui::Text("optional tag")
  safe_slider("##optional tag{hash}", weights.optionalTagWeight, 0f, 100f)
  commit_feature_weights(weights)

def edit_preset(var preset : TagPreset)
  let hash = unsafe(addr(preset))

  safe_slider("animationBlendTime##{hash}", preset.animationBlendTime, 0f, 1f)
  safe_slider("trajectoryInertionFactor##{hash}", preset.trajectoryInertionFactor, 0f, 1f)
  safe_slider("linearVelocityViscosity##{hash}", preset.linearVelocityViscosity, 0f, 1f)
  safe_slider("angularVelocityViscosity##{hash}", preset.angularVelocityViscosity, 0f, 1f)

def edit_value(text : string; var value : das_string&)
  let buf <- ImGuiInputTextBuffer("{value}", 256)
  if InputText(text, buf, ImGuiInputTextFlags AutoSelectAll)
    value := buf |> to_string()
    return true
  return false

def edit_value(text : string; var value : string&)
  let buf <- ImGuiInputTextBuffer("{value}", 256)
  if InputText(text, buf, ImGuiInputTextFlags AutoSelectAll)
    value := buf |> to_string()
    return true
  return false

def edit_value(text : string; var value : float&)
  var tmpValue = value
  let result = InputFloat(text, safe_addr(tmpValue))
  value = tmpValue
  return result

[generic]
def edit_list(var list : auto(TT)&; text : string) : tuple<edited : bool; enlarged : bool; eraseIdx : int>
  let listHash = unsafe(addr(list))
  var eraseIdx = -1
  var edited = false
  var enlarged = false
  imgui::Text("use Ctrl+C, Ctrl+V to edit these fields")
  for element, i in list, range(length(list))

    edited = edit_value("##{i}{listHash}", element) || edited
    imgui::SameLine()
    if imgui::Button("delete##{i}{listHash}")
      eraseIdx = i

  if eraseIdx >= 0
    erase(list, eraseIdx)
    edited = true
  if imgui::Button("add {text}##{listHash}")
    list |> resize(length(list) + 1)
    enlarged = true
    edited = true
  return [[auto edited, enlarged, eraseIdx]]

def edit_params(eid : EntityId)
  query(eid) <| $ [es] (motion_matching__presetIdx : int;
                        var motion_matching__animationBlendTime : float&;
                        var motion_matching__trajectoryInertionFactor : float&;
                        var motion_matching__linearVelocityViscosity : float&;
                        var motion_matching__angularVelocityViscosity : float&)
    if imgui::BeginTabItem("params")
      safe_slider("blend time", motion_matching__animationBlendTime, 0f, 1f)
      safe_slider("inertion", motion_matching__trajectoryInertionFactor, 0f, 1f)
      safe_slider("velocity viscosity", motion_matching__linearVelocityViscosity, 0f, 1f)
      safe_slider("rotation viscosity", motion_matching__angularVelocityViscosity, 0f, 1f)
      imgui::Text("weights preset index = {motion_matching__presetIdx}")
      if imgui::Button("toggle debug nodes")
        console_command("motion_matching.debug_nodes")
      if imgui::Button("toggle debug trajectory")
        console_command("motion_matching.debug_trajectory")

      imgui::EndTabItem()


def edit_tags(eid : EntityId; dataBase : AnimationDataBase)

  query(eid) <| $ [es] (var motion_matching__goalTags : StringList;
                        var motion_matching__optionalTags : StringList)
    if imgui::BeginTabItem("tags")
      imgui::Text("required tags")
      let tagsCount = dataBase |> tags_count()
      for i in range(tagsCount)
        let tag = dataBase |> get_tag(i)
        let idx = motion_matching__goalTags |> index(tag)
        var exists = idx != -1
        if imgui::Checkbox(tag, safe_addr(exists))
          if exists
            motion_matching__goalTags |> push(tag)
          else
            motion_matching__goalTags |> erase(idx)

      imgui::Text("optional tags")
      for i in range(dataBase |> optional_tags_count())
        let tag = dataBase |> get_optional_tag(i)
        let idx = motion_matching__optionalTags |> index(tag)
        var exists = idx != -1
        if imgui::Checkbox(tag, safe_addr(exists))
          if exists
            motion_matching__optionalTags |> push(tag)
          else
            motion_matching__optionalTags |> erase(idx)
      imgui::EndTabItem()

def edit_presets_weights(dataBaseEid : EntityId)
  var invalidateDatabase = false
  if imgui::BeginTabItem("weights")

    query(dataBaseEid) <| $ [es] (main_database__presetsTagsName : StringList;
                                  var dataBase : AnimationDataBase&;
                                  weightsPath : string)

      let editedNode = edit_list(dataBase.nodesName, "node")
      let editedTime = edit_list(dataBase.predictionTimes, "prediction time")
      if editedNode.edited || editedTime.edited
        for preset in dataBase.tagsPresets
          if editedNode.enlarged
            preset.weights.nodePositions |> push(0f)
            preset.weights.nodeVelocities |> push(0f)
          if editedNode.eraseIdx >= 0
            preset.weights.nodePositions |> erase(editedNode.eraseIdx)
            preset.weights.nodeVelocities |> erase(editedNode.eraseIdx)

          if editedTime.enlarged
            preset.weights.rootPositions |> push(0f)
            preset.weights.rootDirections |> push(0f)
          if editedTime.eraseIdx >= 0
            preset.weights.rootPositions |> erase(editedTime.eraseIdx)
            preset.weights.rootDirections |> erase(editedTime.eraseIdx)
          commit_feature_weights(preset.weights)

        dataBase.nodeCount = dataBase.nodesName |> length()
        dataBase.trajectorySize = dataBase.predictionTimes |> length()
        dataBase.featuresSize = get_features_sizes(dataBase.nodeCount, dataBase.trajectorySize)

        invalidateDatabase = true

      imgui::Separator()

      var first = true
      for preset, presetTagIdx, tagName in dataBase.tagsPresets, dataBase.presetsTagIdx, main_database__presetsTagsName
        if first
          edit_weights(preset.weights, dataBase.nodesName, dataBase.predictionTimes)
          edit_preset(preset)
        elif imgui::TreeNode("{tagName}, tag index = {presetTagIdx}")
          edit_weights(preset.weights, dataBase.nodesName, dataBase.predictionTimes)
          edit_preset(preset)
          imgui::TreePop()
        first = false

      if imgui::Button("save##weights")
        serialize_presets(weightsPath, dataBase.tagsPresets, dataBase.nodesName, dataBase.predictionTimes, main_database__presetsTagsName)
    imgui::EndTabItem()

  return invalidateDatabase

def edit_presets_root_motion(dataBaseEid : EntityId)
  var invalidateDatabase = false
  if imgui::BeginTabItem("root motion")
    query(dataBaseEid) <| $ [es] (var main_database__root_node : das_string&;
                                  var main_database__direction_nodes : StringList;
                                  var main_database__direction_weights : FloatList;
                                  var main_database__center_of_mass_nodes : StringList;
                                  var main_database__center_of_mass_params : Point4List;
                                  rootMotionPath : string)
      imgui::Text("use Ctrl+C, Ctrl+V to edit the node name fields")
      invalidateDatabase = edit_value("##root_node", main_database__root_node) || invalidateDatabase
      imgui::Separator()
      imgui::Text("Direction")
      var eraseIdx = -1
      for name, weight, i in main_database__direction_nodes, main_database__direction_weights, range(length(main_database__direction_nodes))
        invalidateDatabase = edit_value("Node##{i}dirName", name) || invalidateDatabase
        imgui::SameLine()
        if imgui::Button("delete##{i}dir")
          eraseIdx = i
        safe_slider("Weight##{i}dirweight", weight, 0f, 100f)
      if eraseIdx >= 0
        erase(main_database__direction_nodes, eraseIdx)
        erase(main_database__direction_weights, eraseIdx)
        invalidateDatabase = true
        eraseIdx = -1
      if imgui::Button("add node##dir")
        main_database__direction_nodes |> resize(length(main_database__direction_nodes) + 1)
        main_database__direction_weights |> resize(length(main_database__direction_weights) + 1)
        invalidateDatabase = true
      imgui::Separator()
      imgui::Text("Center of mass")
      for name, params, i in main_database__center_of_mass_nodes, main_database__center_of_mass_params, range(length(main_database__center_of_mass_nodes))
        invalidateDatabase = edit_value("Node##{i}COMName", name) || invalidateDatabase
        imgui::SameLine()
        if imgui::Button("delete##{i}COM")
          eraseIdx = i

        imgui::Text("{name} Offset")
        imgui::SameLine()
        var step = 0.025f
        var fastStep = 0.25f
        invalidateDatabase = imgui::InputScalar("x##{i}paramsx", ImGuiDataType Float, safe_addr(params.x), safe_addr(step), safe_addr(fastStep), "%.2f", ImGuiInputTextFlags None) || invalidateDatabase
        imgui::SameLine()
        invalidateDatabase = imgui::InputScalar("y##{i}paramsy", ImGuiDataType Float, safe_addr(params.y), safe_addr(step), safe_addr(fastStep), "%.2f", ImGuiInputTextFlags None) || invalidateDatabase
        imgui::SameLine()
        invalidateDatabase = imgui::InputScalar("z##{i}paramsz", ImGuiDataType Float, safe_addr(params.z), safe_addr(step), safe_addr(fastStep), "%.2f", ImGuiInputTextFlags None) || invalidateDatabase

        imgui::Text("{name} Weight")
        imgui::SameLine()
        invalidateDatabase = safe_slider("Weight##{i}comweight", params.w, 0f, 10f) || invalidateDatabase
      if eraseIdx >= 0
        erase(main_database__center_of_mass_nodes, eraseIdx)
        erase(main_database__center_of_mass_params, eraseIdx)
        invalidateDatabase = true
      if imgui::Button("add node##COM")
        main_database__center_of_mass_nodes |> resize(length(main_database__center_of_mass_nodes) + 1)
        main_database__center_of_mass_params |> resize(length(main_database__center_of_mass_params) + 1)
        invalidateDatabase = true
      if imgui::Button("save##rootMotions")
        serialize_root_motions(rootMotionPath, main_database__root_node, main_database__direction_nodes, main_database__direction_weights, main_database__center_of_mass_nodes, main_database__center_of_mass_params)
    imgui::EndTabItem()
  return invalidateDatabase

def edit_presets(dataBaseEid : EntityId)

  query(dataBaseEid) <| $ [es] (var main_database__loaded : bool&)

    // add sub tabs for weights and root motion
    if imgui::BeginTabItem("presets")
      imgui::BeginTabBar("presets_Tabs")
      var invalidateDatabase = false
      invalidateDatabase = edit_presets_weights(dataBaseEid)
      invalidateDatabase = edit_presets_root_motion(dataBaseEid) || invalidateDatabase
      imgui::EndTabBar()

      if invalidateDatabase
        main_database__loaded = false
        broadcastEvent([[InvalidateAnimationDataBase]])

      imgui::EndTabItem()

def edit_clips(eid : EntityId; dataBaseEid : EntityId)

  static_let <|
    var time = get_time_msec()
    var animationPlaySpeed = 1f

  let newTime = get_time_msec()
  let dt = float(newTime - time) * 0.001f // in seconds
  time = newTime

  query(eid) <| $ [es] (var motion_matching__clipProgress : FloatList;
                        var motion_matching__history : IPoint2List;
                        var motion_matching__controller : MotionMatchingController;
                        var motion_matching__historyIndex : int2&)
    assume dataBase = motion_matching__controller.dataBase
    resize(motion_matching__clipProgress, length(dataBase.clips))
    if imgui::BeginTabItem("clips")

      safe_slider("animation play speed", animationPlaySpeed, 0f, 2f)

      if !(motion_matching__controller |> empty())
        let currentClip = motion_matching__controller |> getCurrentClip()
        imgui::Text("Current clip: ")
        imgui::SameLine()
        var currentFrame = motion_matching__controller |> getCurrentFrame()
        imgui::SliderInt("{dataBase.clips[currentClip].name}##display", safe_addr(currentFrame), 1, dataBase.clips[currentClip].tickDuration)
        imgui::Separator()
      let historyLen = length(motion_matching__history)
      if historyLen > 0
        imgui::Text("History: ")
        imgui::SameLine()
        let currentIndex = (motion_matching__historyIndex.x + historyLen + motion_matching__historyIndex.y) % historyLen
        let clipId = motion_matching__history[currentIndex].x
        let frameId = motion_matching__history[currentIndex].y
        var v = motion_matching__historyIndex.x + 1
        var playAnim = false
        if imgui::Button("+##history") && v < historyLen
          v++
          playAnim = true
        imgui::SameLine()
        if imgui::Button("-##history") && v > 0
          v--
          playAnim = true
        imgui::SameLine()
        if imgui::SliderInt("##history", safe_addr(v), 1, historyLen)
          playAnim = true
        if playAnim
          motion_matching__historyIndex.x = v - 1
          let newIndex = (motion_matching__historyIndex.x + historyLen + motion_matching__historyIndex.y) % historyLen
          let historyClipId = motion_matching__history[newIndex].x
          let historyFrameId = motion_matching__history[newIndex].y
          motion_matching__controller |> clearAnimations()
          motion_matching__controller |> playAnimation(historyClipId, historyFrameId, 0.1)
          query(dataBaseEid) <| $ [es] (var main_database__perFrameLimit : int&)
            main_database__perFrameLimit = 0
        imgui::SameLine()
        imgui::Text("{dataBase.clips[clipId].name} frame={frameId}")
        imgui::Separator()

      for clip, clipIdx in dataBase.clips, iter_range(dataBase.clips)
        var playAnim = false
        if imgui::Button("+##{clipIdx}")
          motion_matching__clipProgress[clipIdx]++
          playAnim = true
        imgui::SameLine()
        if imgui::Button("-##{clipIdx}")
          motion_matching__clipProgress[clipIdx]--
          playAnim = true
        imgui::SameLine()

        imgui::Button("play##{clipIdx}")
        if imgui::IsItemHovered() && imgui::IsMouseDown(ImGuiMouseButton Left)
          motion_matching__clipProgress[clipIdx] += dt * TICKS_PER_SECOND * animationPlaySpeed;
          playAnim = true
        imgui::SameLine()
        let duration = float(clip.tickDuration) - 1f
        let progress = duration > 0f ? motion_matching__clipProgress[clipIdx] % duration : 0f;
        //catch negative and overgrowth values
        motion_matching__clipProgress[clipIdx] = progress < 0f ? progress + duration : progress

        var v = int(motion_matching__clipProgress[clipIdx]) + 1


        if imgui::SliderInt("{clip.name}", safe_addr(v), 1, clip.tickDuration)
          motion_matching__clipProgress[clipIdx] = float(v - 1)
          playAnim = true
        if playAnim
          motion_matching__controller |> clearAnimations()
          motion_matching__controller |> playAnimation(clipIdx, v - 1, 0.1)
          query(dataBaseEid) <| $ [es] (var main_database__perFrameLimit : int&)
            main_database__perFrameLimit = 0
      imgui::EndTabItem()
    else
      query(dataBaseEid) <| $ [es] (var main_database__perFrameLimit : int&)
        main_database__perFrameLimit = -1
    if !(motion_matching__controller |> empty())
      query(dataBaseEid) <| $ [es] (main_database__perFrameLimit : int)
        if main_database__perFrameLimit != 0
          let maxHistorySize = 4096
          var prevValue = int2(-1, -1)
          let historyLen = length(motion_matching__history)
          if historyLen > 0
            prevValue = motion_matching__history[(motion_matching__historyIndex.y + historyLen - 1) % historyLen]
          let value = int2(motion_matching__controller |> getCurrentClip(), motion_matching__controller |> getCurrentFrame())
          if prevValue != value
            if historyLen < maxHistorySize
              motion_matching__history |> push(value)
              motion_matching__historyIndex.y = 0
            else
              motion_matching__historyIndex.y = motion_matching__historyIndex.y % maxHistorySize
              motion_matching__history[motion_matching__historyIndex.y] = value
              motion_matching__historyIndex.y++


def motion_matching_imgui(eid : EntityId)

  imgui::PushItemWidth(150f);
  imgui::BeginTabBar("Tabs")

  query(eid) <| $ [es] (motion_matching__controller : MotionMatchingController;
                        motion_matching__dataBaseEid : EntityId)
    edit_params(eid)

    var dataBase = motion_matching__controller.dataBase

    edit_tags(eid, *dataBase)
    edit_presets(motion_matching__dataBaseEid)
    edit_clips(eid, motion_matching__dataBaseEid)

  imgui::EndTabBar()
