require ecs
require strings
require math.base
require game.es.events
require DagorRandom
require DagorMath
require inventory


[es(tag=server, REQUIRE_NOT=riExtra__createOnDestroyRadius)]
def on_ri_extra_destroyed(evt : EventRiExtraDestroyed;
                          transform : float3x4;
                          riExtra__createOnDestroyTemplate : string;
                          riExtra__saveOffenderTo = "";
                          riExtra__createOnDestroyCountRange : int2 = int2(1, 1))
  let count = rnd_int(riExtra__createOnDestroyCountRange.x, riExtra__createOnDestroyCountRange.y)
  for _i in range(count)
    createEntity(riExtra__createOnDestroyTemplate) <| $(var init)
      init |> set("transform", transform)
      if !empty(riExtra__saveOffenderTo)
        init |> set(riExtra__saveOffenderTo, evt.offenderEid)


[es(tag=server)]
def on_ri_extra_destroyed_on_ground(evt : EventRiExtraDestroyed;
                                    transform : float3x4;
                                    riExtra__createOnDestroyTemplate : string;
                                    riExtra__createOnDestroyRadius : float;
                                    riExtra__createOnDestroyCountRange : int2 = int2(1, 1);
                                    riExtra__saveOffenderTo = "")
  let count = rnd_int(riExtra__createOnDestroyCountRange.x, riExtra__createOnDestroyCountRange.y)
  for _i in range(count)
    createEntity(riExtra__createOnDestroyTemplate) <| $(var init)
      var tm = IDENT_TM
      tm[3] += transform[3]
      var s, c : float
      sincos(rnd_float(0.0, TWOPI), s, c)
      tm[3] += float3(riExtra__createOnDestroyRadius * c, 0.0, riExtra__createOnDestroyRadius * s)
      var q : quat
      euler_to_quat(0.0, rnd_float(0.0, TWOPI), 0.0, q)
      var rotTm : float3x4
      make_tm(q, float3(), rotTm)
      tm = tm * rotTm
      drop_item_on_ground(tm)
      init |> set("transform", tm)
      if !empty(riExtra__saveOffenderTo)
        init |> set(riExtra__saveOffenderTo, evt.offenderEid)
