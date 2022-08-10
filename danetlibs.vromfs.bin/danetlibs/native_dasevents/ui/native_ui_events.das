require ecs
module native_ui_events shared

[cpp_event(broadcast, with_scheme, cpp_gen=false)]
struct EventUiShutdown {}
