require ecs
require jsonwriter
require DagorTime
require DagorSystem
require DagorDataBlock
require CurrentCircuit
require app
require SystemInfo
require OnlineStorage
require WorldRenderer
require DagorDriver3D
require level

[es(tag=gameClient, no_order)]
def client_perf_stat_update_es(info : UpdateStageInfoAct;
                               var battle_perfstat__rendering : bool&;
                               var battle_perfstat__peakMemoryKb : int&;
                               var battle_perfstat__refTime : int64&;
                               var battle_perfstat__displayResolution : int2&;
                               var battle_perfstat__renderingResolution : int2&;
                               var battle_perfstat__vsyncRefreshRate : float&;
                               var battle_perfstat__segment_0_5 : float&;
                               var battle_perfstat__segment_5_15 : float&;
                               var battle_perfstat__segment_15_25 : float&;
                               var battle_perfstat__segment_25_30 : float&;
                               var battle_perfstat__segment_30_45 : float&;
                               var battle_perfstat__segment_45_60 : float&;
                               var battle_perfstat__segment_60_75 : float&;
                               var battle_perfstat__segment_75_85 : float&;
                               var battle_perfstat__segment_85_100 : float&;
                               var battle_perfstat__segment_100_120 : float&;
                               var battle_perfstat__segment_120_144 : float&;
                               var battle_perfstat__segment_144_165 : float&;
                               var battle_perfstat__segment_165_180 : float&;
                               var battle_perfstat__segment_180_200 : float&;
                               var battle_perfstat__segment_200_240 : float&;
                               var battle_perfstat__segment_240_280 : float&;
                               var battle_perfstat__segment_280_360 : float&;
                               var battle_perfstat__segment_360_400 : float&;
                               var battle_perfstat__segment_400_500 : float&;
                               var battle_perfstat__segment_500_600 : float&;
                               var battle_perfstat__segment_600_800 : float&;
                               var battle_perfstat__segment_800_1000 : float&;
                               var battle_perfstat__segment_1000_plus : float&)
  if (!is_level_loaded_not_empty() || !does_world_renderer_exist())
    return ;
  if (!battle_perfstat__rendering)
    battle_perfstat__refTime = DagorTime::ref_time_ticks()
    battle_perfstat__rendering = true
    // Store resolution in entity, because driver might be shut down when this entity is destroyed
    var displayResX, displayResY : int
    get_display_resolution(displayResX, displayResY)
    battle_perfstat__displayResolution = int2(displayResX, displayResY)
    var renderingResX, renderingResY : int
    get_rendering_resolution(renderingResX, renderingResY)
    battle_perfstat__renderingResolution = int2(renderingResX, renderingResY)
    battle_perfstat__vsyncRefreshRate = d3d_get_vsync_refresh_rate()
    return

  let memoryUsedKb = get_memory_allocated_kb(true)
  if battle_perfstat__peakMemoryKb < memoryUsedKb
    battle_perfstat__peakMemoryKb = memoryUsedKb

  let frameMsec = float(DagorTime::get_time_usec(battle_perfstat__refTime)) / 1000.0
  battle_perfstat__refTime = DagorTime::ref_time_ticks()
  let fps = 1000.0 / frameMsec

  if 1000.0 <= fps
    battle_perfstat__segment_1000_plus += frameMsec
  elif 800.0 <= fps
    battle_perfstat__segment_800_1000 += frameMsec
  elif 600.0 <= fps
    battle_perfstat__segment_600_800 += frameMsec
  elif 500.0 <= fps
    battle_perfstat__segment_500_600 += frameMsec
  elif 400.0 <= fps
    battle_perfstat__segment_400_500 += frameMsec
  elif 360.0 <= fps
    battle_perfstat__segment_360_400 += frameMsec
  elif 280.0 <= fps
    battle_perfstat__segment_280_360 += frameMsec
  elif 240.0 <= fps
    battle_perfstat__segment_240_280 += frameMsec
  elif 200.0 <= fps
    battle_perfstat__segment_200_240 += frameMsec
  elif 180.0 <= fps
    battle_perfstat__segment_180_200 += frameMsec
  elif 165.0 <= fps
    battle_perfstat__segment_165_180 += frameMsec
  elif 144.0 <= fps
    battle_perfstat__segment_144_165 += frameMsec
  elif 120.0 <= fps
    battle_perfstat__segment_120_144 += frameMsec
  elif 100.0 <= fps
    battle_perfstat__segment_100_120 += frameMsec
  elif 85.0 <= fps
    battle_perfstat__segment_85_100 += frameMsec
  elif 75.0 <= fps
    battle_perfstat__segment_75_85 += frameMsec
  elif 60.0 <= fps
    battle_perfstat__segment_60_75 += frameMsec
  elif 45.0 <= fps
    battle_perfstat__segment_45_60 += frameMsec
  elif 30.0 <= fps
    battle_perfstat__segment_30_45 += frameMsec
  elif 25.0  <= fps
    battle_perfstat__segment_25_30 += frameMsec
  elif 15.0 <= fps
    battle_perfstat__segment_15_25 += frameMsec
  elif 5.0 <= fps
    battle_perfstat__segment_5_15 += frameMsec
  else
    battle_perfstat__segment_0_5 += frameMsec

[es(tag=gameClient, on_disappear)]
def client_perf_stat_destr_es(evt : Event;
                              battle_perfstat__rendering : bool;
                              battle_perfstat__peakMemoryKb : int;
                              battle_perfstat__displayResolution : int2;
                              battle_perfstat__renderingResolution : int2;
                              battle_perfstat__vsyncRefreshRate : float;
                              battle_perfstat__segment_0_5 : float;
                              battle_perfstat__segment_5_15 : float;
                              battle_perfstat__segment_15_25 : float;
                              battle_perfstat__segment_25_30 : float;
                              battle_perfstat__segment_30_45 : float;
                              battle_perfstat__segment_45_60 : float;
                              battle_perfstat__segment_60_75 : float;
                              battle_perfstat__segment_75_85 : float;
                              battle_perfstat__segment_85_100 : float;
                              battle_perfstat__segment_100_120 : float;
                              battle_perfstat__segment_120_144 : float;
                              battle_perfstat__segment_144_165 : float;
                              battle_perfstat__segment_165_180 : float;
                              battle_perfstat__segment_180_200 : float;
                              battle_perfstat__segment_200_240 : float;
                              battle_perfstat__segment_240_280 : float;
                              battle_perfstat__segment_280_360 : float;
                              battle_perfstat__segment_360_400 : float;
                              battle_perfstat__segment_400_500 : float;
                              battle_perfstat__segment_500_600 : float;
                              battle_perfstat__segment_600_800 : float;
                              battle_perfstat__segment_800_1000 : float;
                              battle_perfstat__segment_1000_plus : float)
  if (!battle_perfstat__rendering)
    return ;
  let settings & = dgs_get_settings()
  let graphicsBlock = settings |> datablock_get_block_by_name("graphics")
  let videoBlock = settings |> datablock_get_block_by_name("video")

  let preset = graphicsBlock |> datablock_getStr("preset", "medium")
  let fpsLimit = videoBlock |> datablock_getInt("fpsLimit", 0)
  let vsync = videoBlock |> datablock_getBool("vsync", false)

  get_video_info() <| $(vid : VideoInfo#)
    get_cpu_info() <| $(cpu : CpuInfo#)
      print("Client perfstat sending in bq:")
      print("platform: {get_platform_string_id()}")
      print("circuit: {get_circuit_name()}")
      print("driver: {d3d_get_driver_name()}")
      print("preset: {preset}")
      print("fpsLimit: {fpsLimit}")
      print("vsync: {vsync}")
      print("vsyncRefreshRate: {battle_perfstat__vsyncRefreshRate}")
      print("dynamicResolutionTargetFPS: {worldRenderer_getDynamicResolutionTargetFps()}")
      print("displayRes: {battle_perfstat__displayResolution.x} x {battle_perfstat__displayResolution.y}")
      print("renderingRes: {battle_perfstat__renderingResolution.x} x {battle_perfstat__renderingResolution.y}")
      print("scene: {get_current_scene()}")
      print("cpu: {cpu.cpu}")
      print("cpuFreq: {cpu.cpuFreq}")
      print("cpuVendor: {cpu.cpuVendor}")
      print("cpuSeriesCores: {cpu.cpuSeriesCores}")
      print("numCores: {cpu.numCores}")
      print("desktopResolution: {vid.desktopResolution}")
      print("videoCard: {vid.videoCard}")
      print("videoVendor: {vid.videoVendor}")
      print("peakMemory: {battle_perfstat__peakMemoryKb}")
      print("battle_perfstat__segment_0_5: {battle_perfstat__segment_0_5}")
      print("battle_perfstat__segment_5_15: {battle_perfstat__segment_5_15}")
      print("battle_perfstat__segment_15_25: {battle_perfstat__segment_15_25}")
      print("battle_perfstat__segment_25_30: {battle_perfstat__segment_25_30}")
      print("battle_perfstat__segment_30_45: {battle_perfstat__segment_30_45}")
      print("battle_perfstat__segment_45_60: {battle_perfstat__segment_45_60}")
      print("battle_perfstat__segment_60_75: {battle_perfstat__segment_60_75}")
      print("battle_perfstat__segment_75_85: {battle_perfstat__segment_75_85}")
      print("battle_perfstat__segment_85_100: {battle_perfstat__segment_85_100}")
      print("battle_perfstat__segment_100_120: {battle_perfstat__segment_100_120}")
      print("battle_perfstat__segment_120_144: {battle_perfstat__segment_120_144}")
      print("battle_perfstat__segment_144_165: {battle_perfstat__segment_144_165}")
      print("battle_perfstat__segment_165_180: {battle_perfstat__segment_165_180}")
      print("battle_perfstat__segment_180_200: {battle_perfstat__segment_180_200}")
      print("battle_perfstat__segment_200_240: {battle_perfstat__segment_200_240}")
      print("battle_perfstat__segment_240_280: {battle_perfstat__segment_240_280}")
      print("battle_perfstat__segment_280_360: {battle_perfstat__segment_280_360}")
      print("battle_perfstat__segment_360_400: {battle_perfstat__segment_360_400}")
      print("battle_perfstat__segment_400_500: {battle_perfstat__segment_400_500}")
      print("battle_perfstat__segment_500_600: {battle_perfstat__segment_500_600}")
      print("battle_perfstat__segment_600_800: {battle_perfstat__segment_600_800}")
      print("battle_perfstat__segment_800_1000: {battle_perfstat__segment_800_1000}")
      print("battle_perfstat__segment_1000_plus: {battle_perfstat__segment_1000_plus}")

      jw_writer() <| $(var jw : JsonWriter)
        jw_start_obj(jw)
        jw_key_value(jw, "platform", get_platform_string_id())
        jw_key_value(jw, "circuit", get_circuit_name())
        jw_key_value(jw, "driver", d3d_get_driver_name())
        jw_key_value(jw, "preset", preset)
        jw_key_value(jw, "fpsLimit", fpsLimit)
        jw_key_value(jw, "vsync", vsync)
        jw_key_value(jw, "vsyncRefreshRate", battle_perfstat__vsyncRefreshRate)
        jw_key_value(jw, "dynamicResolutionTargetFPS", worldRenderer_getDynamicResolutionTargetFps())
        jw_key_value(jw, "displayRes", "{battle_perfstat__displayResolution.x} x {battle_perfstat__displayResolution.y}")
        jw_key_value(jw, "renderingRes", "{battle_perfstat__renderingResolution.x} x {battle_perfstat__renderingResolution.y}")
        jw_key_value(jw, "scene", get_current_scene())
        jw_key_value(jw, "cpu", "{cpu.cpu}")
        jw_key_value(jw, "cpuFreq", "{cpu.cpuFreq}")
        jw_key_value(jw, "cpuVendor", "{cpu.cpuVendor}")
        jw_key_value(jw, "cpuSeriesCores", "{cpu.cpuSeriesCores}")
        jw_key_value(jw, "numCores", cpu.numCores)
        jw_key_value(jw, "desktopResolution", "{vid.desktopResolution}")
        jw_key_value(jw, "videoCard", "{vid.videoCard}")
        jw_key_value(jw, "videoVendor", "{vid.videoVendor}")
        jw_key_value(jw, "peakMemory", battle_perfstat__peakMemoryKb)
        jw_key_value(jw, "battle_perfstat__segment_0_5", battle_perfstat__segment_0_5)
        jw_key_value(jw, "battle_perfstat__segment_5_15", battle_perfstat__segment_5_15)
        jw_key_value(jw, "battle_perfstat__segment_15_25", battle_perfstat__segment_15_25)
        jw_key_value(jw, "battle_perfstat__segment_25_30", battle_perfstat__segment_25_30)
        jw_key_value(jw, "battle_perfstat__segment_30_45", battle_perfstat__segment_30_45)
        jw_key_value(jw, "battle_perfstat__segment_45_60", battle_perfstat__segment_45_60)
        jw_key_value(jw, "battle_perfstat__segment_60_75", battle_perfstat__segment_60_75)
        jw_key_value(jw, "battle_perfstat__segment_75_85", battle_perfstat__segment_75_85)
        jw_key_value(jw, "battle_perfstat__segment_85_100", battle_perfstat__segment_85_100)
        jw_key_value(jw, "battle_perfstat__segment_100_120", battle_perfstat__segment_100_120)
        jw_key_value(jw, "battle_perfstat__segment_120_144", battle_perfstat__segment_120_144)
        jw_key_value(jw, "battle_perfstat__segment_144_165", battle_perfstat__segment_144_165)
        jw_key_value(jw, "battle_perfstat__segment_165_180", battle_perfstat__segment_165_180)
        jw_key_value(jw, "battle_perfstat__segment_180_200", battle_perfstat__segment_180_200)
        jw_key_value(jw, "battle_perfstat__segment_200_240", battle_perfstat__segment_200_240)
        jw_key_value(jw, "battle_perfstat__segment_240_280", battle_perfstat__segment_240_280)
        jw_key_value(jw, "battle_perfstat__segment_280_360", battle_perfstat__segment_280_360)
        jw_key_value(jw, "battle_perfstat__segment_360_400", battle_perfstat__segment_360_400)
        jw_key_value(jw, "battle_perfstat__segment_400_500", battle_perfstat__segment_400_500)
        jw_key_value(jw, "battle_perfstat__segment_500_600", battle_perfstat__segment_500_600)
        jw_key_value(jw, "battle_perfstat__segment_600_800", battle_perfstat__segment_600_800)
        jw_key_value(jw, "battle_perfstat__segment_800_1000", battle_perfstat__segment_800_1000)
        jw_key_value(jw, "battle_perfstat__segment_1000_plus", battle_perfstat__segment_1000_plus)
        jw_end_obj(jw)

        add_bigquery_record("enlisted_client_game_session_perfstat", jw.result)
        save_and_send_to_server()
