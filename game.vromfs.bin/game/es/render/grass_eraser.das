require ecs
require terraform
require WorldRenderer
require enlisted.events_enlisted
require math.base

[es(tag=server)]
def erase_grass_on_terraform(evt : CmdTerraform; var grass_erasers__spots : Point4List&)
  push(grass_erasers__spots, float4(evt.pos.x, evt.pos.y, evt.pos.z, evt.radius))
