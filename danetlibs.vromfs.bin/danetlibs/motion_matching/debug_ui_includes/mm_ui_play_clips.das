options no_aot
module mm_ui_play_clips shared

require ecs
require ECSGlobalTags
require DagorTime
require DagorConsole
require MotionMatching
require imgui
require imgui/imgui_boost
require daslib/safe_addr
require daslib/static_let
require danetlibs/motion_matching/debug_ui_includes/mm_ui_imgui_helpers

enum AnimationPlayMode : int
  DISABLED = 0
  ON_PAUSE = 1
  CONTINUOUS = 2

def history_slider(imgui_state_eid : EntityId; data_base : AnimationDataBase const?; var clip_frame_pair : int2&)
  query(imgui_state_eid) <| $ [es] (mm_clips_history : IPoint2List;
                                    var mm_clips_historyIndex : int2&)
    let historyLen = length(mm_clips_history)
    if historyLen > 0
      imgui::Text("History: ")
      imgui::SameLine()
      let currentIndex = (mm_clips_historyIndex.x + historyLen + mm_clips_historyIndex.y) % historyLen
      let clipId = mm_clips_history[currentIndex].x
      let frameId = mm_clips_history[currentIndex].y
      var v = mm_clips_historyIndex.x + 1
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
        mm_clips_historyIndex.x = v - 1
        let newIndex = (mm_clips_historyIndex.x + historyLen + mm_clips_historyIndex.y) % historyLen
        clip_frame_pair = mm_clips_history[newIndex]
      imgui::SameLine()
      imgui::Text("{data_base.clips[clipId].name} frame={frameId}")
      imgui::Separator()

def available_animation_sliders(data_base : AnimationDataBase const?;
                                controller : MotionMatchingController;
                                animation_play_mode : int;
                                var clip_progress : IntList;
                                var anim_play_speed : float&;
                                var clip_frame_pair : int2&)
  static_let <|
    var animationPlaySpeed = 1f

  if safe_slider("animation play speed", animationPlaySpeed, 0f, 2f) && animation_play_mode == int(AnimationPlayMode CONTINUOUS)
    anim_play_speed = animationPlaySpeed
    console_command("app.timeSpeed {animationPlaySpeed}")

  resize(clip_progress, length(data_base.clips))
  let curClipIdx = controller |> empty() ? -1 : controller |> getCurrentClip()
  for clip, clipIdx in data_base.clips, iter_range(data_base.clips)
    if animation_play_mode != int(AnimationPlayMode DISABLED) && curClipIdx == clipIdx
      clip_progress[clipIdx] = controller |> getCurrentFrame()
      if anim_play_speed > 0.0f && int(clip_progress[clipIdx]) == clip.tickDuration - 1
        clip_frame_pair = int2(clipIdx, 0)
    let curProgress = int(clip_progress[clipIdx]) //todo
    if imgui::Button("+##{clipIdx}")
      clip_frame_pair = int2(clipIdx, (curProgress + 1) % clip.tickDuration)
      anim_play_speed = 0.0f
    imgui::SameLine()
    if imgui::Button("-##{clipIdx}")
      clip_frame_pair = int2(clipIdx, curProgress - 1 >= 0 ? curProgress - 1 : clip.tickDuration - 1)
      anim_play_speed = 0.0f
    imgui::SameLine()
    if imgui::Button("play##{clipIdx}")
      clip_frame_pair = int2(clipIdx, curProgress)
      anim_play_speed = animationPlaySpeed
    imgui::SameLine()

    var v = int(curProgress)
    if imgui::SliderInt("{clip.name}", safe_addr(v), 0, clip.tickDuration - 1)
      clip_frame_pair = int2(clipIdx, v)
      anim_play_speed = 0.0f

def track_history(imgui_state_eid : EntityId; controller : MotionMatchingController)
  if !(controller |> empty())
    query(imgui_state_eid) <| $ [es] (var mm_clips_history : IPoint2List;
                                      var mm_clips_historyIndex : int2&)
      let maxHistorySize = 4096
      var prevValue = int2(-1, -1)
      let historyLen = length(mm_clips_history)
      if historyLen > 0
        prevValue = mm_clips_history[(mm_clips_historyIndex.y + historyLen - 1) % historyLen]
      let value = int2(controller |> getCurrentClip(), controller |> getCurrentFrame())
      if prevValue != value
        if historyLen < maxHistorySize
          mm_clips_history |> push(value)
          mm_clips_historyIndex.y = 0
        else
          mm_clips_historyIndex.y = mm_clips_historyIndex.y % maxHistorySize
          mm_clips_history[mm_clips_historyIndex.y] = value
          mm_clips_historyIndex.y++

def play_clips(character_eid : EntityId; data_base_eid : EntityId; imgui_state_eid : EntityId)
  query(character_eid) <| $ [es] (var motion_matching__controller : MotionMatchingController;
                                  var motion_matching__updateProgress : float&)
    query(imgui_state_eid) <| $ [es] (var mm_clips_clipProgress : IntList;
                                      var mm_clips_animationPlaySpeed : float&;
                                      var mm_clips_animationPlayMode : int&)
      if imgui::BeginTabItem("clips")
        assume dataBase = motion_matching__controller.dataBase
        if !(motion_matching__controller |> empty())
          let currentClip = motion_matching__controller |> getCurrentClip()
          imgui::Text("Current clip: ")
          imgui::SameLine()
          var currentFrame = motion_matching__controller |> getCurrentFrame()
          imgui::SliderInt("{dataBase.clips[currentClip].name}##display", safe_addr(currentFrame), 1, dataBase.clips[currentClip].tickDuration)
          imgui::Separator()

        var clipFramePair = int2(-1, -1)
        history_slider(imgui_state_eid, dataBase, clipFramePair)
        if !ecs_has_tag("tools") // not implemented in tools currently
          safe_checkbox("lock root node", motion_matching__controller.rootSynchronization)
        available_animation_sliders(dataBase, motion_matching__controller, mm_clips_animationPlayMode,
                                    mm_clips_clipProgress, mm_clips_animationPlaySpeed, clipFramePair)
        if clipFramePair != int2(-1, -1)
          motion_matching__controller |> clearAnimations()
          motion_matching__controller |> playAnimation(clipFramePair.x, clipFramePair.y, 0.1)
          mm_clips_animationPlayMode = mm_clips_animationPlaySpeed > 0.0f ? int(AnimationPlayMode CONTINUOUS) : int(AnimationPlayMode ON_PAUSE)
          console_command("app.timeSpeed {mm_clips_animationPlaySpeed}")
          if ecs_has_tag("tools") //console command for time doesn't work in tools, so just disable MM update at all
            query(data_base_eid) <| $ [es] (var main_database__perFrameLimit : int&)
              main_database__perFrameLimit = 0
        if mm_clips_animationPlayMode != int(AnimationPlayMode DISABLED)
          motion_matching__updateProgress = 0.0f //disables MM search in next frame

        imgui::EndTabItem()
      elif mm_clips_animationPlayMode != int(AnimationPlayMode DISABLED) //not in 'clips' tab anymore
        mm_clips_animationPlayMode = int(AnimationPlayMode DISABLED)
        motion_matching__controller.rootSynchronization = true
        console_command("app.timeSpeed 1")
        if ecs_has_tag("tools")
          query(data_base_eid) <| $ [es] (var main_database__perFrameLimit : int&)
            main_database__perFrameLimit = -1

      if mm_clips_animationPlayMode == int(AnimationPlayMode DISABLED)
        track_history(imgui_state_eid, motion_matching__controller)