module blk_utils_common shared

require ecs.common
require ecs
require DagorDataBlock

def save_block_to_origin_template(full_template_name : string; component_name : string; blk_data : DataBlock)
  let templatesArr <- split_template(full_template_name)
  let baseTemplate = getTemplateByName(templatesArr[0])
  if baseTemplate == null
    return
  let templatePath = getTemplatePath(*baseTemplate)
  using() <| $(var blk : DataBlock)
    datablock_load(blk, templatePath)
    var originTemplate = datablock_get_block_by_name(blk, templatesArr[0])
    var originArray = datablock_get_block_by_name(*originTemplate, component_name)
    if originArray == null
      return
    datablock_clear_data(*originArray)
    datablock_set_from(*originArray, blk_data, /*fname*/"")
    datablock_save_to_text_file(blk, templatePath)

def save_param_to_origin_template(full_template_name; cb : block<(var originBlk : DataBlock) : void>)
  let templatesArr <- split_template(full_template_name)
  let baseTemplate = getTemplateByName(templatesArr[0])
  if baseTemplate == null
    return
  let templatePath = getTemplatePath(*baseTemplate)
  using() <| $(var blk : DataBlock)
    datablock_load(blk, templatePath)
    var originTemplate = datablock_get_block_by_name(blk, templatesArr[0])
    invoke(cb, *originTemplate)
    datablock_save_to_text_file(blk, templatePath)