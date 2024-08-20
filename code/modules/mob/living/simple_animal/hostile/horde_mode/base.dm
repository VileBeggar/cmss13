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
	langchat_color = "#b491c8"
	bubble_icon = "alien"
	mob_size = MOB_SIZE_XENO
	hivenumber = XENO_HIVE_HORDEMODE

	///Has the mob used a preattack ability?
	var/preattack_move = FALSE
	var/strain_icon_path
	var/strain_icon_state
	///Is the strain an overlay (drone gardener, healer...) or a full sprite?
	var/strain_is_overlay = FALSE
	///Reference to the icon overlay for strains. Mostly used for drone strains.
	var/mutable_appearance/strain_overlay
	///List of all actions that the mob is supposed to have. Given during initialization.
	var/list/base_actions = list()
	///How long the interval is before the mob is able to use a melee attack again.
	var/slash_delay = HORDE_MODE_ATTACK_DELAY_NORMAL
	///How long the interval is before the mob is able to use a ranged attack again.
	var/ranged_delay
	///The distance at which this mob will attempt to use its ranged attack.
	var/ranged_distance
	///How for away the target has to be for the mob to attempt to use its ranged attack.
	var/ranged_distance_min = 0
	///The projectile the mob fires for ranged attacks.
	var/projectile_to_fire
	var/ranged_sfx = "acid_spit"
	///Cooldown dictating how long the mob has to wait before being able to use a melee attack.
	COOLDOWN_DECLARE(slash_cooldown)
	///Cooldown dictating how long the mob has to wait before being able to use a ranged attack.
	COOLDOWN_DECLARE(ranged_cooldown)

//--------------------------------
// INIT AND ICONS

/mob/living/simple_animal/hostile/alien/horde_mode/Initialize()
	langchat_height = icon_size
	add_abilities()
	if(strain_icon_state && strain_is_overlay)
		strain_overlay = mutable_appearance(strain_icon_path, "[strain_icon_state] Walking")
		overlays += strain_overlay
	return ..()


//some strains are overlays while others are full icons. we need to take both into account.
/mob/living/simple_animal/hostile/alien/horde_mode/update_transform(instant_update)
	. = ..()

	if(strain_icon_state)
		if(strain_is_overlay)
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

		else

			if(stat == DEAD)
				icon_state = "[strain_icon_state] Dead"
			else if(body_position == LYING_DOWN)
				if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED))
					icon_state = "[strain_icon_state] Sleeping"
				else
					icon_state = "[strain_icon_state] Knocked Down"
			else
				icon_state = "[strain_icon_state] Walking"

/mob/living/simple_animal/hostile/alien/horde_mode/handle_icon()
	if(strain_icon_state)
		icon_state = "[strain_icon_state] Running"
		icon_living = "[strain_icon_state] Running"
		icon_dead = "[strain_icon_state] Dead"
	else
		icon_state = "Normal [caste_name] Running"
		icon_living = "Normal [caste_name] Running"
		icon_dead = "Normal [caste_name] Dead"


// we need to make a special case for defenders due to lowered crests & fortify
/mob/living/simple_animal/hostile/alien/horde_mode/update_wounds()
	if(!wound_icon_holder)
		return

	wound_icon_holder.layer = layer + 0.01
	wound_icon_holder.dir = dir
	var/health_threshold = max(ceil((health * 4) / (maxHealth)), 0) //From 0 to 4, in 25% chunks
	if(health > HEALTH_THRESHOLD_DEAD)
		if(health_threshold > 3)
			wound_icon_holder.icon_state = "none"
		else if(body_position == LYING_DOWN)
			if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED))
				wound_icon_holder.icon_state = "[caste_name]_rest_[health_threshold]"
			else
				wound_icon_holder.icon_state = "[caste_name]_downed_[health_threshold]"
		else if(istype(src, /mob/living/simple_animal/hostile/alien/horde_mode/defender/steelcrest))
			var/mob/living/simple_animal/hostile/alien/horde_mode/defender/steelcrest/defender = src
			var/datum/action/horde_mode_action/steelcrest_fortify/fortify_ability = locate() in defender.actions
			if(fortify_ability.fortified)
				wound_icon_holder.icon_state = "[caste_name]_fortify_[health_threshold]"
			else if (defender.crest_lowered)
				wound_icon_holder.icon_state = "[caste_name]_crest_[health_threshold]"
		else
			wound_icon_holder.icon_state = "[caste_name]_walk_[health_threshold]"

//--------------------------------
// ABILITIES

/mob/living/simple_animal/hostile/alien/horde_mode/proc/add_abilities()
	if(!base_actions)
		return
	for(var/action_path in base_actions)
		give_action(src, action_path)

/mob/living/simple_animal/hostile/alien/horde_mode/proc/handle_abilities(ability_type, passed_arg)
	for(var/datum/action/horde_mode_action/action in actions)
		if(stat == DEAD || body_position == LYING_DOWN || action.ability_type != ability_type || !COOLDOWN_FINISHED(action, ability_cooldown))
			continue

		action.use_ability(passed_arg)
		if(ability_type == HORDE_MODE_ABILITY_PREATTACK)
			preattack_move = TRUE

//--------------------------------
// ATTACKING

/mob/living/simple_animal/hostile/alien/horde_mode/AttackingTarget()
	if(!COOLDOWN_FINISHED(src, slash_cooldown))
		return

	if(Adjacent(target_mob))
		handle_abilities(HORDE_MODE_ABILITY_PREATTACK, target_mob)

	if(preattack_move)
		return

	COOLDOWN_START(src, slash_cooldown, slash_delay)
	.  = ..()

	if(.)
		handle_abilities(HORDE_MODE_ABILITY_POSTATTACK, target_mob)

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
	AdjustKnockDown(-0.33)

	if(preattack_move)
		preattack_move = FALSE
	if(length(actions) && stat != DEAD)
		handle_abilities(HORDE_MODE_ABILITY_ACTIVE, target_mob)

	if(projectile_to_fire && get_dist(src, target_mob) <= ranged_distance && get_dist(src, target_mob) > ranged_distance_min && COOLDOWN_FINISHED(src, ranged_cooldown) && body_position != LYING_DOWN)
		var/datum/ammo/projectile_type = GLOB.ammo_list[projectile_to_fire]
		visible_message(SPAN_XENOWARNING("[src] spits at [target_mob]!"))
		playsound(loc, ranged_sfx, 25, 1)

		var/obj/projectile/projectile = new /obj/projectile(loc, create_cause_data(src))
		projectile.generate_bullet(projectile_type)
		projectile.permutated += src
		projectile.fire_at(target_mob, src, src, projectile_type.max_range, projectile_type.shell_speed)
		COOLDOWN_START(src, ranged_cooldown, ranged_delay)

	return ..()

//--------------------------------
// MOVEMENT

/mob/living/simple_animal/hostile/alien/horde_mode/MoveToTarget()
	if(stat == DEAD || HAS_TRAIT(src, TRAIT_INCAPACITATED) || HAS_TRAIT(src, TRAIT_FLOORED) || HAS_TRAIT(src, TRAIT_IMMOBILIZED))
		return

	return ..()

/mob/living/simple_animal/hostile/alien/horde_mode/stop_moving()
	walk_to(src, 0)

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


//--------------------------------
// EXTRA PROCS

/mob/living/simple_animal/hostile/alien/horde_mode/proc/throw_mob(mob/living/target, direction, distance, speed = SPEED_VERY_FAST, shake_camera = TRUE, mob_spin = TRUE)
	if(!direction)
		direction = get_dir(src, target)
	var/turf/target_destination = get_ranged_target_turf(target, direction, distance)

	target.throw_atom(target_destination, distance, speed, src, spin = mob_spin)
	if(shake_camera)
		shake_camera(target, 10, 1)
