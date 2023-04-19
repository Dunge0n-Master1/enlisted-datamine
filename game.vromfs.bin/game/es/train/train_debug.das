options no_aot
require ecs
require ecs.ecs_template
require AnimV20
require GeomNodeTree
require DagorMath
require DagorConsole
require DagorDebug3D
require enlisted.game.es.train.train_common


[ecs_template]
struct train_debug_draw_tree
  trainTreeDebug : Tag


[ecs_template]
struct train_debug_draw_carts
  trainCartsDebug : Tag


[console_cmd(name="train.debug_tree")]
def train_debug_tree()
  query() <| $ [es(REQUIRE=train, REQUIRE_NOT=trainTreeDebug)] (eid : EntityId)
    addSubTemplate(eid, "train_debug_draw_tree")
  query() <| $ [es(REQUIRE=(train, trainTreeDebug))] (eid : EntityId)
    removeSubTemplate(eid, "train_debug_draw_tree")


[console_cmd(name="train.debug_carts")]
def train_debug_carts()
  query() <| $ [es(REQUIRE=train, REQUIRE_NOT=trainCartsDebug)] (eid : EntityId)
    addSubTemplate(eid, "train_debug_draw_carts")
  query() <| $ [es(REQUIRE=(train, trainCartsDebug))] (eid : EntityId)
    removeSubTemplate(eid, "train_debug_draw_carts")


def destory_train()
  query() <| $ [es] (train__cartEids : EidList)
    for cartEid in train__cartEids
      find_query() <| $ [es] (eid : EntityId; capzone__trainEid : EntityId)
        if capzone__trainEid == cartEid
          destroyEntity(eid)
          return true
        return false

      destroyEntity(cartEid)


[console_cmd(name="train.reinit")]
def train_reinit()
  destory_train()
  query() <| $ [es(REQUIRE=train__cartEids)] (eid : EntityId)
    sendEvent(eid, [[DebugReinitTrain]])


[console_cmd(name="train.destroy")]
def train_destroy()
  destory_train()


[es(tag=(render, dev), no_order, REQUIRE=trainCartsDebug)]
def draw_train_cart_names(info : UpdateStageInfoRenderDebug; eid : EntityId; transform : float3x4)
  add_debug_text_mark(transform[3], "{getEntityTemplateName(eid)}", -1, 0f, E3DCOLOR(0xFF00FF00))


[es(tag=(render, dev), no_order, REQUIRE=trainTreeDebug)]
def draw_train_geom_tree(info : UpdateStageInfoRenderDebug;
                         animchar : AnimcharBaseComponent)
  let color = E3DCOLOR(0xFF00FF00)

  var wtm : float3x4
  for i in range(animchar.nodeTree.nodeCount)
    let nodeName = *animchar.nodeTree |> geomtree_getNodeName(i)

    *animchar.nodeTree |> geomtree_getNodeWtmScalar(i, wtm)

    draw_debug_sphere_buffered(wtm[3], 0.05, color, 4, 1)
    add_debug_text_mark(wtm[3], "{nodeName}", -1, 0f, color)
