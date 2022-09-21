options no_aot
module net_console_macro shared

require daslib/ast_boost
require daslib/templates_boost
require rtti
require ecs.macro_common

require EnlistedNet public
require ecs public
require player public
require DagorConsole public
require game.es.server_debug_common public
require game.utils.hero public


def get_controlled_hero_eid(possible_eid : uint)
  return possible_eid != 0u ? EntityId(possible_eid) : get_controlled_hero()

def get_controlled_player_eid(possible_eid : uint)
  return possible_eid != 0u ? EntityId(possible_eid) : get_local_player_eid()

[function_macro(name="net_console_cmd")]
class NetConsoleCommandAnnotation : AstFunctionAnnotation
  [unused_argument(group, progArgs)] def override patch(var func : FunctionPtr; var group : ModuleGroup; args, progArgs : AnnotationArgumentList; var errors : das_string; var astChanged : bool &) : bool
    if (func.flags & FunctionFlags exports) == FunctionFlags exports
      return true

    let nameArg = find_arg("name", args)
    if !validate_string_argument(nameArg, "name", errors)
      return false

    func.flags |= FunctionFlags exports

    var serverCmdArguments <- new [[ExprStringBuilder()]]
    serverCmdArguments.elements |> emplace_new(new [[ExprConstString() value := "{nameArg}"]])

    var netHeroArgIdx = -1
    var netPlayerArgIdx = -1
    for arg, i in func.arguments, iter_range(func.arguments)
      serverCmdArguments.elements |> emplace_new(new [[ExprConstString() value := " "]])
      serverCmdArguments.elements |> emplace_new(new [[ExprVar() name := arg.name]])

      // net_hero
      let isHero = find_arg("net_hero", arg.annotation)
      if !(isHero is nothing)
        netHeroArgIdx = i
      // net_player
      let isPlayer = find_arg("net_player", arg.annotation)
      if !(isPlayer is nothing)
        netPlayerArgIdx = i

    var qblock <- quote() <|
      if !is_server()
        exec_server_cmd(serverCmdArguments)
        return

    apply_template(func.at, qblock) <| $(rules)
      rules |> replaceVariable("serverCmdArguments") <| serverCmdArguments

    var funcBlk = unsafe(reinterpret<ExprBlock?> func.body)
    var blk <- move_unquote_block(qblock)
    blk.blockFlags ^= ExprBlockFlags isClosure
    funcBlk.list |> emplace(blk, 0)
    astChanged = true

    // net_hero
    if netHeroArgIdx >= 0
      assume heroEidArg = func.arguments[netHeroArgIdx]

      // all of this should probably be moved to a function used both for netHeroArg and netPlayerArg
      var ec <- new [[ExprCall() at=func.at, name := "get_controlled_hero_eid"]]
      ec.arguments |> emplace_new(new [[ExprVar() name := "_{heroEidArg.name}_"]])

      var el <- new [[ExprLet() at=func.at, atInit=func.at]]
      el.variables |> emplace_new() <| new [[Variable() at = func.at,
        name := heroEidArg.name,
        _type <- new [[TypeDecl() baseType=Type autoinfer, flags=TypeDeclFlags constant, at=func.at]],
        init <- ec
      ]]

      funcBlk.list |> emplace(el, 0)
      heroEidArg.name := "_{heroEidArg.name}_"
      heroEidArg._type := null
      heroEidArg._type <- new [[TypeDecl() baseType=Type tUInt, at=func.at]]
      heroEidArg.init := null
      heroEidArg.init <- new [[ExprConstUInt() at=func.at, value=0u]]

    // net player
    if netPlayerArgIdx >= 0
      assume playerEidArg = func.arguments[netPlayerArgIdx]

      var ec <- new [[ExprCall() at=func.at, name := "get_controlled_player_eid"]]
      ec.arguments |> emplace_new(new [[ExprVar() name := "_{playerEidArg.name}_"]])

      var el <- new [[ExprLet() at=func.at, atInit=func.at]]
      el.variables |> emplace_new() <| new [[Variable() at = func.at,
        name := playerEidArg.name,
        _type <- new [[TypeDecl() baseType=Type autoinfer, flags=TypeDeclFlags constant, at=func.at]],
        init <- ec
      ]]

      funcBlk.list |> emplace(el, 0)
      playerEidArg.name := "_{playerEidArg.name}_"
      playerEidArg._type := null
      playerEidArg._type <- new [[TypeDecl() baseType=Type tUInt, at=func.at]]
      playerEidArg.init := null
      playerEidArg.init <- new [[ExprConstUInt() at=func.at, value=0u]]

    let hint = find_arg("hint", args)
    func |> append_annotation("DagorConsole", "console_cmd", [{auto
      [[auto "name", [[RttiValue tString="{nameArg}"]] ]];
      [[auto "hint", [[RttiValue tString=hint is nothing ? "" : "{hint}"]] ]]
    }])

    return true
