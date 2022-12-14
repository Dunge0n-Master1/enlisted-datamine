from "frp" import *
let decode_jwt = require("jwt").decode
let {logerr} = require("dagor.debug")

let permissionsPublicKey = @"
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDq1fQVfvjjJaxYIGzYZ/SI89kY
+7wTCbMROLlRUHMwWDq/358LzKaFZI+8yOikE2c3Bn/qcvVUHtDGYSLc3GqDRwNl
ZrWrbasCa6rnb+Qki2o6XLaHylMEPYlOOpY8dvI9DZNtGs4en7B++9usmI7nSkBV
mvmpcecs1xe0mKtwlQIDAQAB"

let function readValueFromJwt(jwt, userId, valueName) {
  if (!jwt)
    return null

  let jwtDecoded = decode_jwt(jwt, permissionsPublicKey)
  let uid = jwtDecoded?.payload.userid ?? -1

  if (uid != userId) {
    logerr($"jwt userid {uid} != userid {userId}. Return {valueName} as null")
    return null
  }

  let value = jwtDecoded?.payload[valueName] ?? []
  // TODO remove reading payload.time after update contact server
  let timestamp = jwtDecoded?.payload.iat ?? jwtDecoded?.payload.time ?? 0
  return {value, timestamp}
}

let readPermissions = @(permJwt, userId) readValueFromJwt(permJwt, userId, "perm")

let readPenalties = @(penaltiesJwt, userId) readValueFromJwt(penaltiesJwt, userId, "penalties")

return {readPermissions, readPenalties}
