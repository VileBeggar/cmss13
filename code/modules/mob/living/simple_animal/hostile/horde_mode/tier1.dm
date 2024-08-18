//--------------------------------
// DRONE

/mob/living/simple_animal/hostile/alien/horde_mode/drone
	desc = "An alien drone."
	melee_damage_upper = HORDE_MODE_DAMAGE_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_LOW

	strain_icon_path = 'icons/mob/xenos/drone_strain_overlays.dmi'
	strain_is_overlay = TRUE

// HEALER
/mob/living/simple_animal/hostile/alien/horde_mode/drone/healer
	desc = "An alien drone. Its hands and mouth are covered with weird purple goo."
	maxHealth = HORDE_MODE_HEALTH_LOW
	health = HORDE_MODE_HEALTH_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_VERY_LOW
	base_actions = list(/datum/action/horde_mode_action/heal)

	strain_icon_state = "Healer Drone"

// GARDENER
/mob/living/simple_animal/hostile/alien/horde_mode/drone/gardener
	desc = "An alien drone. Resin is practically spilling out of its mouth."
	maxHealth = HORDE_MODE_HEALTH_LOW
	health = HORDE_MODE_HEALTH_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_VERY_LOW
	base_actions = list(/datum/action/horde_mode_action/plant_weeds/weak)

	strain_icon_state = "Gardener Drone"

/mob/living/simple_animal/hostile/alien/horde_mode/drone/gardener/Initialize()
	. = ..()
	strain_overlay.overlays.Cut()
	strain_overlay.color = LIGHT_COLOR_LAVENDER
	overlays += strain_overlay

//--------------------------------
// RUNNER

/mob/living/simple_animal/hostile/alien/horde_mode/runner
	name = "Runner"
	desc = "A small red alien that looks like it could run fairly quickly..."
	icon = 'icons/mob/xenos/runner.dmi'
	icon_size = 64
	pixel_x = -16
	old_x = -16
	base_pixel_x = 0
	base_pixel_y = -20
	mob_size = MOB_SIZE_XENO_SMALL

	maxHealth = HORDE_MODE_HEALTH_VERY_LOW
	health = HORDE_MODE_HEALTH_VERY_LOW

	melee_damage_upper = HORDE_MODE_DAMAGE_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_VERY_LOW
	slash_delay = HORDE_MODE_ATTACK_DELAY_FAST
	move_to_delay = HORDE_MODE_SPEED_RUNNER

// ACID RUNNER
/mob/living/simple_animal/hostile/alien/horde_mode/runner/acid
	desc = "A small red alien that is covered in acid pustules. Its claws drip with acid."
	strain_icon_path = 'icons/mob/xenos/runner.dmi'
	strain_icon_state = "Acider Runner"

	maxHealth = HORDE_MODE_HEALTH_LOW
	health = HORDE_MODE_HEALTH_LOW

	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
	move_to_delay = HORDE_MODE_SPEED_VERY_FAST
	base_actions = list(/datum/action/horde_mode_action/acid_slash)

//--------------------------------
// DEFENDER

/mob/living/simple_animal/hostile/alien/horde_mode/defender
	name = "Defender"
	desc = "A alien with an armored crest."
	icon = 'icons/mob/xenos/defender.dmi'
	icon_size = 64
	pixel_x = -16
	old_x = -16

	maxHealth = HORDE_MODE_HEALTH_HIGH
	health = HORDE_MODE_HEALTH_HIGH

	melee_damage_upper = HORDE_MODE_DAMAGE_MEDIUM
	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
	move_to_delay = HORDE_MODE_SPEED_SLOW

	base_actions = list(/datum/action/horde_mode_action/tail_swipe)
	status_flags = CANSTUN
	///How long does the mob have to wait before being able to raise its crest.
	COOLDOWN_DECLARE(crest_raise)
	var/crest_icon_state = "Normal Defender Crest"
	var/crest_lowered = FALSE

/mob/living/simple_animal/hostile/alien/horde_mode/defender/Life(delta_time)
	if(crest_lowered && COOLDOWN_FINISHED(src, crest_raise))
		raise_crest()
	return ..()

/mob/living/simple_animal/hostile/alien/horde_mode/defender/on_immobilized_trait_gain()
	lower_crest()

/mob/living/simple_animal/hostile/alien/horde_mode/defender/proc/lower_crest()
	COOLDOWN_START(src, crest_raise, COOLDOWN_TIMELEFT(src, crest_lowered) + 4 SECONDS)
	if(!crest_lowered)
		crest_lowered = TRUE
		icon_state = crest_icon_state
		move_to_delay += HORDE_MODE_SPEED_MOD_MEDIUM

/mob/living/simple_animal/hostile/alien/horde_mode/defender/proc/raise_crest()
	crest_lowered = FALSE
	if(stat == DEAD)
		icon_state = "[caste_name] Dead"
		return

	icon_state = crest_icon_state
	move_to_delay -= HORDE_MODE_SPEED_MOD_MEDIUM


/// STEELCREST
/mob/living/simple_animal/hostile/alien/horde_mode/defender/steelcrest
	strain_icon_path = 'icons/mob/xenos/defender.dmi'
	strain_icon_state = "Steelcrest Defender"

	melee_damage_upper = HORDE_MODE_DAMAGE_LOW
	base_actions = list(/datum/action/horde_mode_action/steelcrest_fortify, /datum/action/horde_mode_action/toss_mob/headbutt)

	crest_icon_state = "Steelcrest Defender Crest"
	var/fortified = FALSE
	var/datum/action/horde_mode_action/steelcrest_fortify/fortify

/mob/living/simple_animal/hostile/alien/horde_mode/defender/steelcrest/Initialize()
	. = ..()
	fortify = locate() in actions

/mob/living/simple_animal/hostile/alien/horde_mode/defender/steelcrest/Life(delta_time)
	. = ..()

	if(stat != DEAD)
		if(get_dist(src, target_mob) <= 4 && !fortified)
			fortify.use_ability()

		if(get_dist(src, target_mob) > 4 && fortified)
			fortify.use_ability()
