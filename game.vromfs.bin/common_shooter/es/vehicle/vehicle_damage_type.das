require ecs
require dm

[es(tag=server, on_appear)]
def cache_explosion_damage_type(evt : Event; var damage_model__explosionDamageType : int&)
  damage_model__explosionDamageType = find_damage_type_id_by_name("explosion")

[es(tag=server, on_appear)]
def cache_fire_damage_type(evt : Event; var damage_model__fireDamageType : int&)
  damage_model__fireDamageType = find_damage_type_id_by_name("fire")
