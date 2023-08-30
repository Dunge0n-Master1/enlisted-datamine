from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { DM_PROJECTILE, DM_MELEE, DM_EXPLOSION, DM_ZONE, DM_COLLISION, DM_HOLD_BREATH,
  DM_FIRE, DM_GAS, DM_BACKSTAB, DM_BARBWIRE } = require("dm")
let { killLogState } = require("%ui/hud/state/kill_log_es.nut")
let { is_console } = require("%dngscripts/platform.nut")
let style = require("%ui/hud/style.nut")
let { MY_SQUAD_COLOR, MY_GROUP_COLOR, MY_TEAM_COLOR, ENEMY_TEAM_COLOR
} = require("%enlSqGlob/ui/style/killog_colors.nut")
let defTextColor = style.DEFAULT_TEXT_COLOR
let { mkRankIcon } = require("%enlSqGlob/ui/rankPresentation.nut")
let { rnd_int } = require("dagor.random")

const MIN_RANK_TO_SHOW = 15

let commonFont = is_console ? fontBody : fontSub

let textElem = @(text, color = null) {
  rendObj = ROBJ_TEXT, text, color
}.__update(commonFont)

let fontLogSize = calc_str_box(textElem("A"))[1]
let killIconHeight = fontLogSize.tointeger()

let killIconsHeadshot = "killlog/kill_headshot.svg"

let damageTypeIcons = {
  [DM_PROJECTILE]  = null, //no need for icon in this case
  [DM_MELEE]       = "killlog/kill_melee.svg",
  [DM_EXPLOSION]   = "killlog/kill_explosion.svg",
  [DM_ZONE]        = "killlog/kill_zone_wh.svg",
  [DM_COLLISION]   = "killlog/kill_collision.svg",
  [DM_HOLD_BREATH] = "killlog/kill_asphyxia.svg",
  [DM_BACKSTAB]    = "killlog/kill_backstab.svg",
  [DM_FIRE]        = "killlog/kill_fire.svg",
  [DM_GAS]         = "killlog/kill_fire.svg",
  [DM_BARBWIRE]    = null
}

let getPicture = memoize(function(name) {
  return name!=null
    ? Picture("!ui/skin#{0}:{1}:{1}:K".subst(name, killIconHeight))
    : null
})

let xtext = freeze({
  rendObj = ROBJ_TEXT
  text = "x"
  color = Color(130,130,130,80)
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  pos = [0, -commonFont.fontSize * 0.05]
}.__update(commonFont))

let mkIcon = memoize(function(image){
  return image != null ? {
    size = [fontLogSize, fontLogSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [killIconHeight, killIconHeight]
        image = image
      }
    ]
  } : null
})

let function mkKillEventIcon(data) {
  let { isHeadshot = false, damageType = 0 } = data
  let image = getPicture(isHeadshot ? killIconsHeadshot : damageTypeIcons?[damageType])
  return mkIcon(image)
}

let killMsgAnim = [
  { prop=AnimProp.scale, from=[1,0.01], to=[1,1], duration=0.2, play=true, easing=OutCubic }
]

const BLUR_COLOR = 0x11000000

let blurBack = {
  rendObj = ROBJ_WORLD_BLUR
  size = flex()
  color = BLUR_COLOR
}

let function nameAndColor(entity) {//entity here is just table with description
  local name = entity?.name
  local color = ENEMY_TEAM_COLOR
  if (entity?.isHero) {
    name = loc("log/local_player")
    color = MY_SQUAD_COLOR
  } else if (entity?.inMyGroup) {
    name = (name ?? "") != ""? loc(name) : loc("log/squadmate")
    color = MY_GROUP_COLOR
  } else if (entity?.inMyTeam) {
    name = name != null && name != "" ? loc(name)
      : entity?.inMySquad ? loc("log/squadmate")
      : loc("log/teammate")
    color = (entity?.inMySquad ? MY_SQUAD_COLOR : MY_TEAM_COLOR)
  } else {
    name = name != null && name != "" ? loc(name) : ""
  }
  return { name, color }
}
let margin = [fontLogSize/4.0, 0]
let padding = [0, hdpx(5), 0, hdpx(5)]

let selfContainer = {
  rendObj = ROBJ_FRAME
  borderWidth = [0, hdpx(3), 0, 0]
  color = MY_SQUAD_COLOR
  padding = [0, hdpx(3), 0, 0]
}

let appendRank = @(textBlock, rank) (rank ?? 0) < MIN_RANK_TO_SHOW
  ? textBlock
  : {
      flow = FLOW_HORIZONTAL
      children = [textBlock, mkRankIcon(rank)]
    }

let function message(data) {
  local children = null
  let gunInfo = {
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    children = [
      data?.gunName ? textElem(loc(data.gunName), defTextColor) : null
      mkKillEventIcon(data)
    ]
  }
  let num = (data?.num ?? 1) == 1 ? null : {
    flow = FLOW_HORIZONTAL
    children = [xtext, textElem(data.num)]
  }
  if (data?.victim?.eid == data?.killer?.eid && data?.victim?.eid != null) {
    let { name, color } = nameAndColor(data.victim)
    children = data.victim.isHero
      ? textElem(loc("log/local_player_suicide"), color)
      : data.victim.vehicle ?
        [
          gunInfo
          textElem(name, color)
        ]
      : [
          appendRank(textElem(loc("log/player_suicide", { user = name }), color), data.victim.rank)
          gunInfo
        ]
  } else {
    let victimInfo = nameAndColor(data.victim)
    let killerInfo = nameAndColor(data.killer)
    children = [
      appendRank(textElem(killerInfo.name, killerInfo.color), data.killer.rank)
      gunInfo
      appendRank(textElem(victimInfo.name, victimInfo.color), data.victim.rank)
      num
    ]
  }

  return {
    children = [
      blurBack
      {
        size = SIZE_TO_CONTENT
        flow = FLOW_HORIZONTAL
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        children
        margin
        gap = hdpx(9)
        padding
        key = data
        transform = { pivot = [0, 0.5] }
        animations = killMsgAnim
      }
    ]
  }.__update(data?.killer.isHero ? selfContainer : {})
}

let itemAnim = [
  //{ prop=AnimProp.color, from=style.MESSAGE_BG_START, to=style.MESSAGE_BG_END,
  //    duration=0.5, play=true }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true}
  { prop=AnimProp.scale, from=[1,1], to=[1,0], duration=0.2, playFadeOut=true}
]

let function killLogRoot() {
  let children = killLogState.events.value.map(
    @(item) {
      size = SIZE_TO_CONTENT
      key = item
      color = style.MESSAGE_BG_END
      children = message(item)
      transform = { pivot = [0, 0] }
      animations = itemAnim
    }
  )

  return {
    size   = [fsh(30), fsh(50)]
    halign = ALIGN_RIGHT
    behavior = Behaviors.SmoothScrollStack
    speed = fsh(20)
    watch = killLogState.events
    gap = hdpx(1)
    children = children
  }
}

let function fakeLog() {
  let names = ["", "Bob", "Alice", "John", "Jane"]
  let killerEid = rnd_int(1, names.len())
  let victimEid = rnd_int(1, names.len())
  let damageType = damageTypeIcons.keys()[rnd_int(0, damageTypeIcons.len() - 1)]
  killLogState.pushEvent({
    killer = { eid = killerEid, name = names[killerEid - 1], isHero = killerEid == 1 }
    victim = { eid = victimEid, name = names[victimEid - 1], isHero = victimEid == 1, isAlive = false }
    damageType
    gunName = damageType ? $"Boomstick Mk {"".join(array(rnd_int(1, 3), "I"))}" : null
  })
}

console_register_command(fakeLog, "ui.killog")
console_register_command(@(num) array(num).each(@(_) fakeLog()), "ui.killogSome")


return killLogRoot
