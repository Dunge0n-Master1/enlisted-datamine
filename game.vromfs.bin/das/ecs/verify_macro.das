options no_aot
module verify_macro shared private

require EcsUtils
require ecs
require ast
require rtti
require daslib/ast_boost
require daslib/templates_boost


[call_macro(name="ecs_type_hash")]
class EcsTypeMacro : AstCallMacro
  [unused_argument(mod)] def override visit(prog : ProgramPtr; mod : Module ?; var expr : smart_ptr<ExprCallMacro>) : ExpressionPtr
    if expr.arguments.length != 1
      macro_error(prog, expr.at, "ecs_type_hash expecting 1 argument")
      return [[ExpressionPtr]]
    if expr.arguments[0]._type == null || expr.arguments[0]._type.isAutoOrAlias
      macro_error(prog, expr.at, "ecs_type_hash requires fully inferred type")
      return [[ExpressionPtr]]
    var res = 0u
    let foundCppType = get_underlying_ecs_type(expr.arguments[0]._type, true) <| $(typeName)
      res = ecs_hash(typeName)
    if !foundCppType || res == 0u
      macro_error(prog, expr.at, "ecs_type_hash unable to resolve ecs type for {describe(expr.arguments[0]._type)}")
      return [[ExpressionPtr]]
    return qmacro($v(res))
