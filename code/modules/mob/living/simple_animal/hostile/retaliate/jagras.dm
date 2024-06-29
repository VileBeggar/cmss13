/mob/living/simple_animal/hostile/retaliate/jagras
	name = "jagras"
	desc = "It's a giant lizard!"
	icon = 'icons/mob/mob_64.dmi'
	icon_state = "Jagras"
	icon_living = "Jagras"
	icon_dead = "Jagras Dead"
	mob_size = MOB_SIZE_SMALL
	pixel_x = -16  //Needed for 2x2
	old_x = -16
	base_pixel_x = 0
	base_pixel_y = -20
	health = 200
	maxHealth = 200

	speak_emote = list("roars", "growls", "hisses")
	emote_see = list("wags its tail.", "shakes its head.")
	speak_chance = 5
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT

	response_help = "pets"
	response_disarm = "tries to push aside"
	response_harm = "punches"

	melee_damage_lower = 20
	melee_damage_upper = 25
	attacktext = "bites"
	var/aggression_value = 0
	var/chance_to_rest = 0
	var/list/pounce_callbacks = null
	COOLDOWN_DECLARE(growl_message)
	COOLDOWN_DECLARE(pounce_cooldown)

/mob/living/simple_animal/hostile/retaliate/jagras/Initialize()
	. = ..()
	pain.ignore_oxyloss_checks = TRUE
	pounce_callbacks = list()
	pounce_callbacks[/mob] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob_wrapper)
	pounce_callbacks[/turf] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf_wrapper)


/mob/living/simple_animal/hostile/retaliate/jagras/attack_hand(mob/living/carbon/human/attacking_mob as mob)
	if(attacking_mob.a_intent == INTENT_DISARM && stat != DEAD)
		aggression_value = update_value_clamped(aggression_value, 15)

		if(COOLDOWN_FINISHED(src, growl_message))
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "growls at [attacking_mob].", 1)
			COOLDOWN_START(src, growl_message, 10 SECONDS)

		if(prob(33))
			playsound(loc, 'sound/weapons/alien_knockdown.ogg', 25, 1)
			KnockDown(1)
			update_transform(TRUE)
			aggression_value = update_value_clamped(aggression_value, 45)

	if(attacking_mob.a_intent == INTENT_HELP && stance == HOSTILE_STANCE_IDLE)
		update_value_clamped(aggression_value, -10)
		if(resting)
			chance_to_rest = update_value_clamped(chance_to_rest, -5)
		else
			chance_to_rest = update_value_clamped(chance_to_rest, 5)

	..()

/mob/living/simple_animal/hostile/retaliate/jagras/Retaliate()
	chance_to_rest = 0
	SetKnockDown(0)
	resting = FALSE
	set_body_position(STANDING_UP)
	update_transform(TRUE)
	. = ..()

	// Immediately start attacking.
	if(stat != DEAD && (mobility_flags & MOBILITY_MOVE))
		target_mob = FindTarget()
		MoveToTarget()

/mob/living/simple_animal/hostile/retaliate/jagras/update_transform(instant_update = TRUE)
	if(stat == DEAD)
		icon_state = "Jagras Dead"
	else if(body_position == LYING_DOWN)
		if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED))
			icon_state = "Jagras Sleeping"
		else
			icon_state = "Jagras Knocked Down"
	else
		icon_state = "Jagras"
	. = ..()

/mob/living/simple_animal/hostile/retaliate/jagras/lay_down()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/Life(delta_time)
	if(!client)
		//Once enough time passes without being hurt, stop chasing and become netural again.
		if(aggression_value == 0 && stance == HOSTILE_STANCE_ATTACKING)
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "calms down.", 1)
			enemies = new()
			LoseTarget()

		if(stance == HOSTILE_STANCE_IDLE)
			chance_to_rest = update_value_clamped(chance_to_rest, 5)
			if(prob(chance_to_rest))
				chance_to_rest = 0
				lay_down()

	. = ..()
	if(!client && target_mob && stance == HOSTILE_STANCE_ATTACKING && prob(75) && COOLDOWN_FINISHED(src, pounce_cooldown))
		pounce(target_mob)
		COOLDOWN_START(src, pounce_cooldown, 4 SECONDS)
	if(!client && aggression_value >= 100 && stance == HOSTILE_STANCE_IDLE)
		INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
		Retaliate()
	aggression_value = update_value_clamped(aggression_value, -10)

/mob/living/simple_animal/hostile/retaliate/jagras/adjustBruteLoss(damage)
	..()
	aggression_value = update_value_clamped(aggression_value, 80)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/update_value_clamped(variable, value)
	variable += value
	variable = clamp(variable, 0, 100)
	return variable

/mob/living/simple_animal/hostile/retaliate/jagras/AttackingTarget()
	aggression_value = update_value_clamped(aggression_value, 25) // Bloodlust. Make sure they don't stop in the middle of slashing someone apart.
	. = ..()

/mob/living/simple_animal/hostile/retaliate/jagras/bullet_act(obj/projectile/bullet)
	. = ..()
	if(bullet.damage)
		var/splatter_dir = get_dir(bullet.starting, loc)
		var/obj/effect/temp_visual/dir_setting/bloodsplatter/splatter_effect = new(loc, splatter_dir)
		splatter_effect.pixel_y -= 20


// POUNCE PROCS //
//////////////////
/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounce(mob/living/target)
	var/pounce_distance = clamp((get_dist(src, target)), 1, 5)
	INVOKE_ASYNC(src, PROC_REF(manual_emote), "pounces at [target]!", 1)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, throw_atom), target, pounce_distance, SPEED_FAST, src, null, LOW_LAUNCH, PASS_OVER_THROW_MOB, null, pounce_callbacks)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob_wrapper(mob/living/pounced_mob)
	pounced_mob(pounced_mob)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob(mob/living/pounced_mob)
	if(stat == DEAD)
		return

	if(pounced_mob.stat == DEAD || pounced_mob.mob_size >= MOB_SIZE_BIG || pounced_mob == src)
		throwing = FALSE
		return

	playsound(loc, rand(0, 100) < 95 ? 'sound/voice/alien_pounce.ogg' : 'sound/voice/alien_pounce2.ogg', 25, 1)
	pounced_mob.KnockDown(0.25)
	step_to(src, pounced_mob)
	if(stance == HOSTILE_STANCE_ATTACKING)
		AttackingTarget()

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf(turf/turf_target)
	if(!turf_target.density)
		for(var/mob/living/mob in turf_target)
			pounced_mob(mob)
			break
	else
		turf_launch_collision(turf_target)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf_wrapper(turf/turf_target)
	pounced_turf(turf_target)
