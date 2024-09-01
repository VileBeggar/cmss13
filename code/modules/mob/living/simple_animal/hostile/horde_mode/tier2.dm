//--------------------------------
// LURKER

/mob/living/simple_animal/hostile/alien/horde_mode/lurker
	name = "Lurker"
	desc = "A beefy, fast alien with sharp claws."
	icon = 'icons/mob/xenos/lurker.dmi'
	melee_damage_upper = HORDE_MODE_DAMAGE_MEDIUM
	melee_damage_lower = HORDE_MODE_DAMAGE_MEDIUM
	base_actions = list(/datum/action/horde_mode_action/invisibility)

// VAMPIRE
/mob/living/simple_animal/hostile/alien/horde_mode/lurker/vampire
	desc = "A fast alien with sharp claws, and a intense thirst for blood."
	strain_icon_path = 'icons/mob/xenos/lurker.dmi'
	strain_icon_state = "Vampire Lurker"
	health = HORDE_MODE_HEALTH_LOW
	maxHealth = HORDE_MODE_HEALTH_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
	move_to_delay = HORDE_MODE_SPEED_VERY_FAST

	base_actions = list(/datum/action/horde_mode_action/lifesteal, /datum/action/horde_mode_action/toss_mob/tail_jab, /datum/action/horde_mode_action/rush)


//--------------------------------
// SPITTER

/mob/living/simple_animal/hostile/alien/horde_mode/spitter
	name = "Spitter"
	desc = "A gross, oozing alien of some kind."
	icon = 'icons/mob/xenos/spitter.dmi'
	move_to_delay = HORDE_MODE_SPEED_SLOW

	projectile_to_fire = /datum/ammo/xeno/acid/glob
	ranged_distance = 5
	ranged_distance_min = 2
	ranged_delay = HORDE_MODE_ATTACK_DELAY_SLUGGISH * 2


//--------------------------------
// HIVELORD

/mob/living/simple_animal/hostile/alien/horde_mode/hivelord
	name = "Hivelord"
	desc = "A builder of really big hives."
	icon = 'icons/mob/xenos/hivelord.dmi'

	mob_size = MOB_SIZE_BIG
	health = HORDE_MODE_HEALTH_HIGH
	maxHealth = HORDE_MODE_HEALTH_HIGH
	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
	move_to_delay = HORDE_MODE_SPEED_VERY_SLOW

	icon_size = 64
	pixel_x = -16
	old_x = -16
	status_flags = CANPUSH
	base_actions = list(/datum/action/horde_mode_action/plant_weeds, /datum/action/horde_mode_action/resin_construction, /datum/action/horde_mode_action/resin_construction/recovery)


//--------------------------------
// BURROWER

/mob/living/simple_animal/hostile/alien/horde_mode/burrower
	name = "Burrower"
	desc = "A beefy alien with sharp claws."
	icon = 'icons/mob/xenos/burrower.dmi'

	health = HORDE_MODE_HEALTH_HIGH
	maxHealth = HORDE_MODE_HEALTH_HIGH
	melee_damage_upper = HORDE_MODE_DAMAGE_MEDIUM
	move_to_delay = HORDE_MODE_SPEED_VERY_SLOW

	icon_size = 64
	pixel_x = -16
	old_x = -16
	//todo: add tunnel construction
	base_actions = list(/datum/action/horde_mode_action/tremor)

// CARRIERS btfo :(
