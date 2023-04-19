require ecs
require app
require math
require DagorMath
require HumanPhys
require DngHuman
require GamePhys
require DagorRandom
require game.es.events

[es(tag=server, no_order)]
def duck_hunt_init(evt : EventEntityCreated;
                   duck__dir : float3;
                   transform : float3x4;
                   duck__halfDist : float;
                   var duck__min : float3&;
                   var duck__max : float3&;
                   var duck__phaseShift : float&)
  duck__min = transform[3] + duck__dir *  duck__halfDist
  duck__max = transform[3] + duck__dir * -duck__halfDist
  duck__phaseShift = gsrnd() * PI * 2.f

[es(tag=server, no_order)]
def duck_hunt(evt : CmdPostPhysUpdate;
              duck__speed : float;
              duck__min : float3;
              duck__max : float3;
              duck__phaseShift : float;
              var human_net_phys : HumanActor)
  let maxPos = duck__max
  let minPos = duck__min
  let maxTime = duck__speed
  let curTime = get_sync_time()
  let k = sin(maxTime * curTime + duck__phaseShift)
  let pos = lerp(minPos, maxPos, float3(k))
  human_net_phys.phys.currentState.location.P.x = double(pos.x)
  human_net_phys.phys.currentState.location.P.y = double(pos.y)
  human_net_phys.phys.currentState.location.P.z = double(pos.z)