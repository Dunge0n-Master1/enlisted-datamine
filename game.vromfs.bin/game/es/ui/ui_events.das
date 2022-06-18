require ecs
module ui_events shared

[cpp_event(broadcast, with_scheme, cpp_gen=false)]
struct EventUiShutdown {}
