module node_macro shared private
options strict_smart_pointers

require ast
require rtti
require daslib/ast_boost
require daslib/templates_boost

def public move_cls(var target, src)
  unsafe
    target <- src

[structure_macro(name="frame_graph_node")]
class FrameGraphNodeAnnotation : AstStructureAnnotation
  [unused_argument(group)] def override apply(var st : StructurePtr; var group : ModuleGroup; args : AnnotationArgumentList; var errors : das_string) : bool
    if length(args) != 0
      errors := "expecting [frame_graph_node] to have no arguments"
      return false

    var inscope initfn <- qmacro_function("init`{st.name}") <| $(var x : $t(st)) : void
      move_cls(x, $c(st.name)())
    initfn.flags |= FunctionFlags exports
    add_function(st._module, initfn)

    // add c++ part
    st |> append_annotation("daBfg", "_frame_graph_node", [[array< tuple<argname : string; argvalue : RttiValue> >]])

    return true

