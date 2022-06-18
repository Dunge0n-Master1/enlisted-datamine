require app
require ecs

[es(on_appear, tag=server)]
def scene_loader_on_init(evt : Event; scene_loader__sceneBlk : string)
  app::load_game_scene(scene_loader__sceneBlk)

