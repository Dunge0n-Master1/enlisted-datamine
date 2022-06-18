options indenting = 4
options no_unused_function_arguments = false
options no_aot = true

module log_utils shared

require ast
require rtti
require daslib/ast_boost
require daslib/templates_boost
require DagorSystem public

[tag_function(logerr_once_tag)]
def logerr_once(message : string) {}

// convert logerr_once(message) to
//  var
//      __logerr_once_I = true
//  if __logerr_once_I
//      __logerr_once_I = false
//      logerr(message)
[tag_function_macro(tag="logerr_once_tag")]
class AssertOnceMacro : AstFunctionAnnotation
    def override transform(var call : smart_ptr<ExprCallFunc>; var errors : das_string) : ExpressionPtr
        let once_name = make_unique_private_name("__logerr_once", call.at)
        compiling_module() |> add_global_var(once_name, call.at) <| quote(true)
        // if ..
        var qblock <- quote() <|
            if __logerr_once_I
                __logerr_once_I = false
                logerr(message)
        // rename
        var rules : Template
        rules |> renameVariable("__logerr_once_I") <| once_name
        rules |> replaceVariable("message") <| clone_expression(call.arguments[0])
        apply_template(rules, call.at, qblock)
        delete rules
        return move_unquote_block(qblock)
