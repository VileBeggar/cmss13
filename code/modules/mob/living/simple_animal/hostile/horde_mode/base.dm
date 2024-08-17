/mob/living/simple_animal/hostile/alien/horde_mode
	icon = 'icons/mob/xenos/drone.dmi'
	icon_gib = "gibbed-a"
	attack_sound = "alien_claw_flesh"
	health = HORDE_MODE_HEALTH_MEDIUM
	maxHealth = HORDE_MODE_HEALTH_MEDIUM

	melee_damage_upper = HORDE_MODE_DAMAGE_MEDIUM
	melee_damage_lower = HORDE_MODE_DAMAGE_MEDIUM

	move_to_delay = HORDE_MODE_SPEED_NORMAL

	icon_size = 48
	pixel_x = -12
	old_x = -12

	var/strain_icon_path
	var/strain_icon_state
	var/mutable_appearance/strain_overlay
	///List of all actions that the mob is supposed to have. Given during initialization.
	var/list/base_actions = list()
	///How long the interval is before the mob is able to attack again.
	var/slash_delay = HORDE_MODE_ATTACK_DELAY_NORMAL
	///Cooldown dictating how long the mob has to wait before being able to attack again.
	COOLDOWN_DECLARE(slash_cooldown)

//--------------------------------
// INIT

/mob/living/simple_animal/hostile/alien/horde_mode/Initialize()
	add_abilities()
	if(strain_icon_state)
		strain_overlay = mutable_appearance(strain_icon_path, "[strain_icon_state] Walking")
		overlays += strain_overlay
	return ..()

/mob/living/simple_animal/hostile/alien/horde_mode/update_transform(instant_update)
	. = ..()

	overlays -= strain_overlay
	strain_overlay.overlays.Cut()
	if(stat == DEAD)
		strain_overlay.icon_state = "[strain_icon_state] Dead"
	else if(body_position == LYING_DOWN)
		if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED))
			strain_overlay.icon_state = "[strain_icon_state] Sleeping"
		else
			strain_overlay.icon_state = "[strain_icon_state] Knocked Down"
	else
		strain_overlay.icon_state = "[strain_icon_state] Walking"
	overlays += strain_overlay

//--------------------------------
// ABILITIES

/mob/living/simple_animal/hostile/alien/horde_mode/proc/add_abilities()
	if(!base_actions)
		return
	for(var/action_path in base_actions)
		give_action(src, action_path)

/mob/living/simple_animal/hostile/alien/horde_mode/proc/handle_abilities(ability_type, passed_arg)
	for(var/datum/action/horde_mode_action/action in actions)
		if(stat == DEAD || body_position == LYING_DOWN || action.ability_type != ability_type)
			continue
		if(COOLDOWN_FINISHED(action, ability_cooldown))
			action.use_ability(passed_arg)

//--------------------------------
// ATTACKING

/mob/living/simple_animal/hostile/alien/horde_mode/AttackingTarget()
	if(!COOLDOWN_FINISHED(src, slash_cooldown))
		return

	COOLDOWN_START(src, slash_cooldown, slash_delay)
	.  = ..()
	if(.)
		handle_abilities(HORDE_MODE_ABILITY_ATTACK, target_mob)

//--------------------------------
// STATUS EFFECT HANDLING

//the AI gets funky when it gets stunned midcombat. this will help them get back into the fight more organically.
/mob/living/simple_animal/hostile/alien/horde_mode/on_immobilized_trait_loss(datum/source)
	. = ..()
	find_target_on_trait_loss()

/mob/living/simple_animal/hostile/alien/horde_mode/on_knockedout_trait_loss(datum/source)
	. = ..()
	find_target_on_trait_loss()

/mob/living/simple_animal/hostile/alien/horde_mode/on_incapacitated_trait_loss(datum/source)
	. = ..()
	find_target_on_trait_loss()

///Proc for handling the AI post-status effect.
/mob/living/simple_animal/hostile/alien/horde_mode/proc/find_target_on_trait_loss()
	FindTarget()
	MoveToTarget()

//--------------------------------
// LIFE() PROCS

/mob/living/simple_animal/hostile/alien/horde_mode/Life(delta_time)
	AdjustKnockDown(-0.1)

	if(length(actions) && stat != DEAD)
		handle_abilities(HORDE_MODE_ABILITY_ACTIVE)

	return ..()

//--------------------------------
// MOVEMENT

/mob/living/simple_animal/hostile/alien/horde_mode/MoveToTarget()
	if(stat == DEAD || HAS_TRAIT(src, TRAIT_INCAPACITATED) || HAS_TRAIT(src, TRAIT_FLOORED))
		return

	return ..()

//--------------------------------
// BLOOD, GUTS AND GIBS

/mob/living/simple_animal/hostile/alien/horde_mode/gib_animation()
	var/icon_path
	if(mob_size >= MOB_SIZE_BIG)
		icon_path = 'icons/mob/xenos/xenomorph_64x64.dmi'
	else
		icon_path = 'icons/mob/xenos/xenomorph_48x48.dmi'

	playsound(src, 'sound/voice/alien_death.ogg', 50, 1)
	new /obj/effect/overlay/temp/gib_animation/xeno(loc, src, icon_gib, icon_path)

/mob/living/simple_animal/hostile/alien/horde_mode/generate_name()
	change_real_name(src, "[caste_name] (XX-[rand(1, 999)])")

/mob/living/simple_animal/hostile/alien/horde_mode/handle_blood_splatter(splatter_dir)
	if(prob(33))
		add_splatter_floor(loc, FALSE)
	new /obj/effect/temp_visual/dir_setting/bloodsplatter/xenosplatter(loc, splatter_dir)

/mob/living/simple_animal/hostile/alien/horde_mode/spawn_gibs()
	xgibs(get_turf(src))

/mob/living/simple_animal/hostile/alien/horde_mode/add_splatter_floor(turf/turf, small_drip, b_color)
	if(!turf)
		turf = get_turf(src)

	if(!turf.can_bloody)
		return

	var/obj/effect/decal/cleanable/blood/xeno/xeno_blood = locate() in turf.contents
	if(!xeno_blood)
		xeno_blood = new(turf)
		xeno_blood.color = get_blood_color()

/mob/living/simple_animal/hostile/alien/horde_mode/get_blood_color()
	return BLOOD_COLOR_XENO
