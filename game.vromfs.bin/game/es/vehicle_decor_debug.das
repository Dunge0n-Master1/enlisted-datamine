options no_aot
require ecs
require DagorConsole
require DagorDataBlock
require EcsUtils
require enlisted.game.es.blk_utils_common


[console_cmd(name="decor.calc_decor_block")]
def calc_decor_block()
  find_query() <| $ [es(REQUIRE=(daeditor__selected, attach_decorators__templates))] (eid : EntityId)
    using() <| $(var blk : DataBlock)
      components_to_blk(eid, blk, "attach_decorators__", true)
      datablock_get_block(blk, "templates:array") <| $(templatesArrayBlk)
        let templateName = getEntityTemplateName(eid)
        save_block_to_origin_template(templateName, "attach_decorators__templates:array", templatesArrayBlk)
    return true
