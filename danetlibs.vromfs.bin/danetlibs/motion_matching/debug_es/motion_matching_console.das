options no_aot
require ecs
require DagorConsole
require danetlibs/motion_matching/es/mm_events


[console_cmd(name="motion_matching.invalidate_anim_data_base")]
def invalidate_anim_data_base()
  query() <| $ [es] (var main_database__loaded : bool&)
    main_database__loaded = false
    broadcastEvent([[InvalidateAnimationDataBase]])
