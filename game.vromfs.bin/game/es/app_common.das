module app_common shared
require app
require DagorDataBlock

def get_environment() : string
  var res = ""
  get_circuit_conf() <| $(var blk : DataBlock?#)
    res = datablock_getStr(blk, "environment", "")
  return res

def is_dev_circuit() : bool
  return get_environment() != "production"

def is_production_circuit() : bool
  return !is_dev_circuit()