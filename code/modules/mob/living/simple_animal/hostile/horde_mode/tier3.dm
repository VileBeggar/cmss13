//--------------------------------
// RAVAGER

/mob/living/simple_animal/hostile/alien/horde_mode/ravager
	name = "Ravager"
	desc = "A huge, nasty red alien with enormous scythed claws."
	icon = 'icons/mob/xenos/ravager.dmi'
	health = HORDE_MODE_HEALTH_BOSS
	maxHealth = HORDE_MODE_HEALTH_BOSS
	melee_damage_upper = HORDE_MODE_DAMAGE_VERY_HIGH
	melee_damage_lower = HORDE_MODE_DAMAGE_HIGH
	move_to_delay = HORDE_MODE_SPEED_SLOW
	slash_delay = HORDE_MODE_ATTACK_DELAY_FAST

	icon_size = 64
	pixel_x = -16
	old_x = -16

	status_flags = CANSTUN
	mob_size = MOB_SIZE_BIG

	base_actions = list(
		/datum/action/horde_mode_action/eviscerate,
		/datum/action/horde_mode_action/scissor_cut,
		/datum/action/horde_mode_action/rush/charge,
		/datum/action/horde_mode_action/toss_mob/clothesline,
		/datum/action/horde_mode_action/toss_mob/tail_jab
		)
