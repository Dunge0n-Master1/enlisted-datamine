require ecs
require ecs.common
require PhysMat


[es(tag=server, on_appear)]
def human_collision_scrape_net_sound_appear(evt : Event;
                                            [[shared_comp]] human_collision_scrape_net_sound__physmatNames : StringList;
                                            var human_collision_scrape_net_sound__physmatIds : IntList&)
  human_collision_scrape_net_sound__physmatIds |> resize(length(human_collision_scrape_net_sound__physmatNames))
  for i in range(0, length(human_collision_scrape_net_sound__physmatNames))
    human_collision_scrape_net_sound__physmatIds[i] = get_material_id(string(human_collision_scrape_net_sound__physmatNames[i]))


[es(tag=server, track=human_net_phys__torsoContactMatId)]
def human_collision_scrape_net_sound_track(evt : Event;
                                           human_net_phys__torsoContactMatId : int;
                                           human_collision_scrape_net_sound__physmatIds : IntList;
                                           var human_collision_scrape_sound__descIdx : int&)
  human_collision_scrape_sound__descIdx = find_index(human_collision_scrape_net_sound__physmatIds, human_net_phys__torsoContactMatId)
