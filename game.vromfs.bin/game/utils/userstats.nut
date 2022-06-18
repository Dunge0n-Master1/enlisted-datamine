from "%enlSqGlob/library_logs.nut" import *

let {format} = require("string")
let {put_to_mq=null, mq_gen_transactid=null, put_to_mq_raw=null} = require_optional("message_queue")
let {get_arg_value_by_name} = require("dagor.system")
let {get_time_msec} = require("dagor.time")
let {setTimeout=null} = require_optional("dagor.workcycle")
let {INVALID_USER_ID} = require("matching.errors")

let tubeName = get_arg_value_by_name("userstat_tube") ?? "userstat"
print($"userstat_tube: {tubeName}")

let tubeNameV2 = get_arg_value_by_name("userstat_tube_v2")
if ((tubeNameV2 ?? "") != "")
  print($"userstat_tube_v2: {tubeNameV2}")

let cachedStats = {}

let flushTime = (get_arg_value_by_name("userstat_flush_stats_time_msec") ?? 3000).tointeger()
print($"userstats flush time:{flushTime}")

local bulkSend = (get_arg_value_by_name("userstat_bulk_send") ?? 1).tointeger() > 0
print($"userstats bulk send:{bulkSend}")

if (bulkSend && setTimeout==null){
  bulkSend = false
  print("userstat - disable bulk send due no delayed actions")
}

let isPackSupportOnCircuit = true
if (!isPackSupportOnCircuit)
  print($"userstats packs not allowed for this circuit")

let packStats = isPackSupportOnCircuit && bulkSend &&
                  (get_arg_value_by_name("userstat_pack_send") ?? 1).tointeger() > 0
print($"userstats packs send:{packStats}")

let function putToQueue(userid, appid, sessionId, stats){
  if (sessionId != null && sessionId != 0)
    stats["$sessionId"] <- format("%X", sessionId)

  if (bulkSend){ // reduce spam in per stat mode
    print($"userstat - send stats userid:{userid}")
    debugTableData(stats)
  }

  if ((tubeNameV2 ?? "") != "") {
    let transactid = mq_gen_transactid()
    put_to_mq_raw(tubeNameV2, {
      action = "ChangeStats",
      headers = {
        userid, appid, transactid
      },
      body = stats
    })
  } else {
    put_to_mq(tubeName, {userid, appid, stats})
  }
}

let function sendCacheData(userid){
  let userStats = cachedStats?[userid]
  if (userStats){
    if (packStats){
      let packed = {}
      packed["$bulk"] <- userStats.packs
      putToQueue(userid, userStats.appId,
        userStats.sessionId,
        packed)
    } else {
      foreach (statVal in userStats.packs){
        putToQueue(userid, userStats.appId,
          userStats.sessionId,
          statVal)
      }
    }
    userStats.packs.clear()
  }
}

let function flushStats(userid){
  sendCacheData(userid)
  if (userid in cachedStats)
    delete cachedStats[userid]
}

let function get_next_send_time(){
  return get_time_msec() + flushTime
}

let function hasDuplicateCommands(storedStats, newStats){
  foreach (statName, statVal in newStats){
    if (typeof statVal == "table" && (statName in storedStats)){
      return true
    }
  }
  return false
}

let function addStatsPack(mode, packs){
  let newPack = {}
  newPack["$mode"] <- mode

  packs.append(newPack)

  return newPack
}

let function putToCache(userid, appId, stats, mode, sessionId) {
  local userStats = cachedStats?[userid]
  if (!userStats){
    userStats = {packs = [], sessionId = sessionId, time = get_next_send_time(),
                 appId = appId}
    cachedStats[userid] <- userStats
  }

  if (sessionId != null && userStats.sessionId != sessionId){
    sendCacheData(userid)
    userStats.sessionId = sessionId
    userStats.time = get_next_send_time()
  }

  if (!userStats.packs.len())
    addStatsPack(mode, userStats.packs)

  local curPack = userStats.packs.top(); // last element
  if (curPack["$mode"] != mode || hasDuplicateCommands(curPack, stats)){
    if (!packStats){
      sendCacheData(userid);
      userStats.time = get_next_send_time()
    }
    curPack = addStatsPack(mode, userStats.packs)
  }

  foreach (statName, statVal in stats){
    if (statName in curPack){
      curPack[statName] += statVal
    }
    else{
      curPack[statName] <- statVal
    }
  }
}

local isSendScheduled = false

let function scheduleSend(time, cb){
  if (!isSendScheduled){
    isSendScheduled = true
    setTimeout(
      time/1000.0 + 0.2, // add delay 200 ms to guaranteed call send stats in first iteration
      function(){
        isSendScheduled = false
        cb()
      }
    )
  }
}

let function sendAll(){
  let curTime = get_time_msec()
  local nextTime = flushTime
  let sent = []

  foreach (userid, stats in cachedStats){
    if (stats.time <= curTime){
      sendCacheData(userid)
      sent.append(userid)
    }
    else{
      nextTime = min(nextTime, stats.time - curTime)
    }
  }

  foreach (userid in sent)
    delete cachedStats[userid]

  if (cachedStats.len() > 0){
    scheduleSend(nextTime, sendAll)
  }
}

let function onAddStat(){
  scheduleSend(flushTime, sendAll)
}

let function sendToUserstats(userid, appid, stats, mode, sessionId = null) {
  if (put_to_mq==null || mode == "" || !mode)
    return

  if (!bulkSend){
    stats["$mode"] <- mode
    putToQueue(userid, appid, sessionId, stats)
    return
  }

  putToCache(userid, appid, stats, mode, sessionId)

  onAddStat()
}

let function addUserstat(playerstats, playerstats_mode, name, params) {
  if (name in playerstats.getAll())
    playerstats[name] = playerstats[name] + 1
  else
    playerstats[name] <- 1

  if (params && (params?.mode ?? "") != "") {
    let modeKey = $"{name}_{params.mode}"
    if (modeKey in playerstats_mode.getAll())
      playerstats_mode[modeKey] = playerstats_mode[modeKey] + 1
    else
      playerstats_mode[modeKey] <- 1
  }

  if (params && "userid" in params && "mode" in params && params.userid != INVALID_USER_ID) {
    let stats = {}
    stats[name] <- 1
    sendToUserstats(params.userid, params.appId, stats, params.mode)
  }
}

return {
  userstatsSend = sendToUserstats
  userstatsFlush = flushStats
  userstatsAdd = addUserstat
}
