//--------------------------------
// DRONE

/mob/living/simple_animal/hostile/alien/horde_mode/drone
	desc = "An alien drone."
	strain_icon_path = 'icons/mob/xenos/drone_strain_overlays.dmi'

/mob/living/simple_animal/hostile/alien/horde_mode/drone/healer
	desc = "An alien drone. Its hands and mouth are covered with weird purple goo."
	maxHealth = HORDE_MODE_HEALTH_LOW
	health = HORDE_MODE_HEALTH_LOW
	melee_damage_upper = HORDE_MODE_DAMAGE_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
	base_actions = list(/datum/action/horde_mode_action/heal)

	strain_icon_state = "Healer Drone"

/mob/living/simple_animal/hostile/alien/horde_mode/drone/gardener
	desc = "An alien drone. Resin is practically spilling out of its mouth."
	maxHealth = HORDE_MODE_HEALTH_LOW
	health = HORDE_MODE_HEALTH_LOW
	melee_damage_upper = HORDE_MODE_DAMAGE_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
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

	maxHealth = HORDE_MODE_HEALTH_VERY_LOW
	health = HORDE_MODE_HEALTH_VERY_LOW

	melee_damage_upper = HORDE_MODE_DAMAGE_LOW
	melee_damage_lower = HORDE_MODE_DAMAGE_VERY_LOW
	slash_delay = HORDE_MODE_ATTACK_DELAY_FAST
	move_to_delay = HORDE_MODE_SPEED_RUNNER

/mob/living/simple_animal/hostile/alien/horde_mode/runner/acid
	desc = "A small red alien that is covered in acid pustules. Its claws drip with acid."
	strain_icon_path = 'icons/mob/xenos/runner.dmi'
	strain_icon_state = "Acider Runner"

	maxHealth = HORDE_MODE_HEALTH_LOW
	health = HORDE_MODE_HEALTH_LOW

	melee_damage_lower = HORDE_MODE_DAMAGE_LOW
	move_to_delay = HORDE_MODE_SPEED_VERY_FAST
	base_actions = list(/datum/action/horde_mode_action/acid_slash)
