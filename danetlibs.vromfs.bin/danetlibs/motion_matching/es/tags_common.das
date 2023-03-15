module tags_common shared

require ecs
require daslib/strings_boost


def private index(var tags : StringList; tag : string) : int
  return find_index_if(each(tags)) <| $(s) { return eq(s, tag); }

def private has(var tags : StringList; tag : string) : bool
  return index(tags, tag) != -1

def private add_tag(var tags : StringList; tag : string)
  if !has(tags, tag)
    tags |> push(tag)

def private remove_tag(var tags : StringList; tag : string)
  let idx = index(tags, tag)
  if idx != -1
    tags |> erase(idx)

def set_tag(var tags : StringList; tag : bool; tag_name : string)
  if tag
    add_tag(tags, tag_name);
  else
    remove_tag(tags, tag_name);