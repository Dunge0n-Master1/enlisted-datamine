require ecs
require app
require statsd


[es(tag=gameClient, on_event=(EventOnGameAppStarted, EventUserLoggedIn, EventDaScriptReloaded))]
def send_aot_statsd(evt : Event)
  if globally_enabled_aot()
    let version = get_exe_version_str()
    statsd_profile("das.load_time_ms", float(das_load_time_ms()), "version", version)
    statsd_counter("das.memory_usage_kb", int(das_memory_usage() / 1024l), "version", version)
