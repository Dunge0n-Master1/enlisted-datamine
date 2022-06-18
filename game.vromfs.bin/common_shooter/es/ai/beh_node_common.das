module beh_node_common shared

require ecs
require DagorDataBlock
require DagorSystem
require strings
require BehNodes
require BehNodes

class BehNodeAdapter
  [[hidden]] thisNode : BehNode?
  [[hidden]] owner : BehaviourTree?
  def abstract loadFromBlk(var data : DataBlock) : void
  def abstract init() : void
  def abstract update(dt : float) : EBehResult
  def abstract drawDebug(children : bool) : void
  def abstract exit() : void
  def abstract reset() : void


def get_or(var blk : DataBlock; name : string; or_block)
  let res = blk |> datablock_find_param(name)
  return res >= 0 ? res : invoke(or_block)

def get_or_create(var blk : DataBlock; name : string; default_value : float3) : int
  return get_or(blk, name) <| $() => blk |> datablock_setPoint3(name, default_value)

def get_or_create(var blk : DataBlock; name : string; default_value : int) : int
  return get_or(blk, name) <| $() => blk |> datablock_setInt(name, default_value)

def get_or_create(var blk : DataBlock; name : string; default_value : float) : int
  return get_or(blk, name) <| $() => blk |> datablock_setReal(name, default_value)

def get_or_create(var blk : DataBlock; name : string; default_value : string) : int
  return get_or(blk, name) <| $() => blk |> datablock_setStr(name, default_value)

def get_or_create(var blk : DataBlock; name : string; default_value : bool) : int
  return get_or(blk, name) <| $() => blk |> datablock_setBool(name, default_value)


def load_ecs_param(var blk : DataBlock implicit; param_name : string; var name : string&; var hash : uint&; node : BehNode? = null) : bool
  if load_optional_ecs_param(blk, param_name, name, hash)
    return true
  let nodeData = node != null ? node |> beh_node_hierarchy_name(true) : ""
  logerr("expected param '{param_name}' to be defined - {nodeData} file: {blk |> datablock_resolveFilename(false)}")
  return false


def load_optional_ecs_param(var blk : DataBlock implicit; param_name : string; var name : string&; var hash : uint&) : bool
  let paramName = blk |> datablock_getStr(param_name, "")
  if !empty(paramName)
    hash = ecs_hash(paramName)
    if get_DAGOR_DBGLEVEL() > 0
      name = paramName
    return true
  return false
