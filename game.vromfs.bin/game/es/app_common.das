module app_common shared
require net
require DagorDataBlock

def get_environment() : string
  return get_circuit_conf() |> datablock_getStr("environment", "")

def is_dev_circuit() : bool
  return get_environment() != "production"

def is_production_circuit() : bool
  return !is_dev_circuit()