from "%enlSqGlob/ui_library.nut" import *

let function implode(pieces = [], glue = "") {
  return glue.join(pieces.filter(@(val) val != "" && val != null))
}

enum validationCheckBitMask {
  VARTYPE    = 0x01
  EXISTENCE  = 0x02
  INVALIDATE = 0x04

  // masks
  REQUIRED   = 0x03
  VITAL      = 0x07
}

local wasAssert = false //show inventory validate assert only once

let config = {
  item_json = {
    [ validationCheckBitMask.VITAL ] = {
      itemid = ""
      itemdef = -1
    },
    [ validationCheckBitMask.REQUIRED ] = {
      quantity = 0
      timestamp = ""
    },
    [ validationCheckBitMask.VARTYPE ] = {
    },
  }
  itemdef_json = {
    [ validationCheckBitMask.VITAL ] = {
      itemdefid = -1
    },
    [ validationCheckBitMask.REQUIRED ] = {
      meta = ""
      tags = ""
      granted_by_purch = ""
    },
    [ validationCheckBitMask.VARTYPE ] = {
      name = ""
      name_english = ""
      description = ""
      description_english = ""
      icon_url = ""
      icon_url_large = ""
      hidden = false
    },
  }
}

let tagsValueRemap = {
  yes         = true,
  no          = false,
  ["true"]    = true,
  ["false"]   = false,
}

let arrayTag = {
  characters = true
  disableItemTypes = true
  previewItems = true
}

const TAG_DELIMITER = "__"

let function parseTags(itemdef) {
  let tags = itemdef?.tags
  let parsedTags = {}
  if (typeof tags == "string")
    foreach (pair in tags.split(";")) {
      let parsed = pair.split(":")
      if (parsed.len() == 2) {
        let key = parsed[0]
        let v = parsed[1]
        parsedTags[key] <- arrayTag?[key] ? v.split(TAG_DELIMITER) : tagsValueRemap?[v] ?? v
      }
    }
  itemdef.tags <- parsedTags
}

let isNumeric = @(val) typeof val == "integer" || typeof val == "float"

let function validate(data, name) {
  let validation = config?[name]
  if (!data || !validation)
    return data

  if (type(data) != "array")
    return null

  local itemsBroken  = []
  local keysMissing   = {}
  local keysWrongType = {}

  for (local i = data.len() - 1; i >= 0; i--) {
    let item = data[i]
    local isItemValid = type(item)=="table"
    local itemErrors = 0

    foreach (checks, keys in validation) {
      let shouldInvalidate     = checks & validationCheckBitMask.INVALIDATE
      let shouldCheckExistence = checks & validationCheckBitMask.EXISTENCE
      let shouldCheckType      = checks & validationCheckBitMask.VARTYPE

      if (isItemValid) {
        foreach (key, defVal in keys) {
          let isExist = (key in item)
          let val = item?[key]
          let isTypeCorrect = isExist && (type(val) == type(defVal) || isNumeric(val) == isNumeric(defVal))

          let isMissing   = shouldCheckExistence && !isExist
          let isWrongType = shouldCheckType && isExist && !isTypeCorrect
          if (isMissing || isWrongType) {
            itemErrors++

            if (isMissing)
              keysMissing[key] <- true
            if (isWrongType)
              keysWrongType[key] <- $"{type(val)}, {val}"

            if (shouldInvalidate)
              isItemValid = false

            item[key] <- defVal
          }
        }
      }
    }

    if (!isItemValid || itemErrors) {
      let itemDebug = []
      foreach (checks, keys in validation)
        if (checks & validationCheckBitMask.INVALIDATE)
          foreach (key, _val in keys)
            if (key in item)
              itemDebug.append($"{key}={item[key]}")
      itemDebug.append(isItemValid ? ($"err={itemErrors}") : "INVALID")
      itemDebug.append(type(item)=="table" ? ($"len={item.len()}") : ($"var={type(item)}"))

      itemsBroken.append(implode(itemDebug, ","))
    }

    if (!isItemValid)
      data.remove(i)
    else
      parseTags(item)
  }

  if (!wasAssert && (itemsBroken.len() || keysMissing.len() || keysWrongType.len())) {
    keysWrongType = function() {
      local ret = ""
      foreach (k,v in keysWrongType)
        ret = $"{ret}{k}={v};"
      return ret
    }()
    assert(false, $"InventoryClient: Response has errors: {name}")
    wasAssert = true
  }

  return data
}

return {
  validate = validate
}