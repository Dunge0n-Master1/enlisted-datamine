require ecs
require app
require statsd
require DagorSystem


[es(tag=(gameClient, dev), on_event=EventOnGameAppStarted)]
def send_dev_aot_loading_statsd(evt : Event)
  if globally_enabled_aot() && get_DAGOR_THREAD_SANITIZER() == 0 && get_DAGOR_DBGLEVEL() == 1
    let platformId = get_platform_string_id()
    // These platforms may load das very differently because of hardware differences.
    // Only send stats from these platforms when we are running autotests, assuming all autotest machines have similar specs
    let isAutotestOnlyPlatform = (platformId == "win32" || platformId == "win64" ||
                                  platformId == "linux32" || platformId == "linux64" ||
                                  platformId == "macosx")
    let isAutotests = get_command_line_arguments() |> find_index("-sqexec:tests/test_scene.nut") >= 0
    if isAutotestOnlyPlatform && !isAutotests
      return

    let isAsan = get_DAGOR_ADDRESS_SANITIZER()
    statsd_profile("das.load_time_ms", float(das_load_time_ms()), "is_asan", "{isAsan}")
    statsd_counter("das.memory_usage_kb", int(das_memory_usage() / 1024l), "is_asan", "{isAsan}")