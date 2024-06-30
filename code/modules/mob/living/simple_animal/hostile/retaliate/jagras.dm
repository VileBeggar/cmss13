/mob/living/simple_animal/hostile/retaliate/jagras
	name = "jagras"
	desc = "It's a giant lizard!"
	icon = 'icons/mob/mob_64.dmi'
	icon_state = "Jagras"
	icon_living = "Jagras"
	icon_dead = "Jagras Dead"
	mob_size = MOB_SIZE_XENO_VERY_SMALL
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
	var/obj/item/reagent_container/food/snacks/meat/snack_target = null
	var/list/pounce_callbacks = null
	var/mob/living/carbon/intruder = null
	COOLDOWN_DECLARE(growl_message)
	COOLDOWN_DECLARE(pounce_cooldown)
	COOLDOWN_DECLARE(snack_cooldown)

/mob/living/simple_animal/hostile/retaliate/jagras/Initialize()
	. = ..()
	pain.ignore_oxyloss_checks = TRUE //Stops it from dying mid-lunge when suffering from intense pain.
	pounce_callbacks = list()
	pounce_callbacks[/mob] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob_wrapper)
	pounce_callbacks[/turf] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf_wrapper)


/mob/living/simple_animal/hostile/retaliate/jagras/attack_hand(mob/living/carbon/human/attacking_mob as mob)
	if(attacking_mob.a_intent == INTENT_DISARM && stat != DEAD)
		aggression_value = update_value_clamped(aggression_value, 15)

		if(COOLDOWN_FINISHED(src, growl_message) && aggression_value < 80)
			playsound(loc, 'sound/voice/jagras_growl.ogg', 33, 1)
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
	if(stat ==  DEAD)
		return

	. = ..()
	if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED))
		//If resting, get up.
		if(body_position == LYING_DOWN)
			clear_stun()
		// Immediately start attacking.
		if(mobility_flags & MOBILITY_MOVE)
			target_mob = FindTarget()
			MoveToTarget()

/mob/living/simple_animal/hostile/retaliate/jagras/proc/clear_stun()
	chance_to_rest = 0
	resting = FALSE
	set_body_position(STANDING_UP)
	update_transform(TRUE)

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

		if(COOLDOWN_FINISHED(src, snack_cooldown) && stance == HOSTILE_STANCE_IDLE && !snack_target)
			for(var/obj/item/reagent_container/food/snacks/meat/snack in oview(5, src))
				stop_automated_movement = TRUE
				snack_target = snack
				stance = HOSTILE_STANCE_ALERT
				if(body_position == LYING_DOWN)
					lay_down()
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "looks curiously at [snack].", 1)
				walk_to(src, snack_target, 1, move_to_delay)
				COOLDOWN_START(src, snack_cooldown, 10 SECONDS)
				break

		if(snack_target)
			if(!isturf(snack_target.loc))
				aggression_value = update_value_clamped(aggression_value, 50)
				if(aggression_value < 80)
					INVOKE_ASYNC(src, PROC_REF(manual_emote), "looks angrily at [snack_target.loc].", 1)
				stop_moving()
				stop_automated_movement = FALSE
				snack_target = null
			if(Adjacent(snack_target))
				eat_food(snack_target)

		var/mob/living/carbon/intruding_mob
		for(intruding_mob in oview(5, src))
			if(stance > HOSTILE_STANCE_ALERT)
				return
			intruder = intruding_mob
			if(stance < HOSTILE_STANCE_ALERT && intruder)
				stance = HOSTILE_STANCE_ALERT
				walk_to(src, 0)
				stop_automated_movement = TRUE
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "stares at [intruder].", 1)
			setDir(get_dir(src, intruder))
			if(get_dist(src, intruder) < 2)
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
				Retaliate()
			break
		if(!intruding_mob)
			intruder = null

		if(!intruder && stance =< HOSTILE_STANCE_ALERT)
			stance = HOSTILE_STANCE_IDLE
			stop_automated_movement = FALSE

		if(stance == HOSTILE_STANCE_IDLE)
			chance_to_rest = update_value_clamped(chance_to_rest, 5)
			if(prob(chance_to_rest))
				chance_to_rest = 0
				lay_down()

	. = ..()

	if(!client && target_mob && stance == HOSTILE_STANCE_ATTACKING && prob(75) && COOLDOWN_FINISHED(src, pounce_cooldown))
		pounce(target_mob)
		COOLDOWN_START(src, pounce_cooldown, 4 SECONDS)
	if(!client && aggression_value >= 80 && stance < HOSTILE_STANCE_ATTACK)
		INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
		Retaliate()
	aggression_value = update_value_clamped(aggression_value, -10)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/eat_food(food)
	playsound(loc, 'sound/items/eatfood.ogg', 35, 1)
	INVOKE_ASYNC(src, PROC_REF(manual_emote), pick("gobbles up", "tears into", "gnaws on", "eats up") + " [snack_target].", 1)
	snack_target = null
	stance = HOSTILE_STANCE_IDLE
	stop_automated_movement = FALSE
	chance_to_rest = update_value_clamped(chance_to_rest, 50)
	qdel(food)
	COOLDOWN_START(src, snack_cooldown, 20 SECONDS)

/mob/living/simple_animal/hostile/retaliate/jagras/adjustBruteLoss(damage)
	..()
	aggression_value = update_value_clamped(aggression_value, 50)

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
		splatter_effect.pixel_y -= 8


// POUNCE PROCS //
//////////////////
/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounce(mob/living/target)
	var/pounce_distance = clamp((get_dist(src, target)), 1, 5)
	INVOKE_ASYNC(src, PROC_REF(manual_emote), "pounces at [target]!", 1)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, throw_atom), target, pounce_distance, SPEED_FAST, src, null, LOW_LAUNCH, PASS_OVER_THROW_MOB, null, pounce_callbacks)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob_wrapper(mob/living/pounced_mob)
	pounced_mob(pounced_mob)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob(mob/living/pounced_mob)
	if(stat == DEAD || pounced_mob.stat == DEAD || pounced_mob.mob_size >= MOB_SIZE_BIG || pounced_mob == src)
		throwing = FALSE
		return

	if(ishuman(pounced_mob) && (pounced_mob.dir in reverse_nearby_direction(dir)))
		var/mob/living/carbon/human/human = pounced_mob
		if(human.check_shields(15, "the pounce")) //Human shield block.
			visible_message(SPAN_DANGER("[src] slams into [human]!"))
			KnockDown(1)
			Stun(1)
			throwing = FALSE //Reset throwing manually.
			playsound(human, "bonk", 75, FALSE) //bonk
			return

		if(isyautja(human))
			if(human.check_shields(0, "the pounce", 1))
				visible_message(SPAN_DANGER("[human] blocks the pounce of [src] with the combistick!"))
				apply_effect(3, WEAKEN)
				throwing = FALSE
				playsound(human, "bonk", 75, FALSE)
				return
			else if(prob(75)) //Body slam.
				visible_message(SPAN_DANGER("[human] body slams [src]!"))
				KnockDown(3)
				Stun(3)
				throwing = FALSE
				playsound(loc, 'sound/weapons/alien_knockdown.ogg', 25, 1)
				return
		if(iscolonysynthetic(human) && prob(60))
			visible_message(SPAN_DANGER("[human] withstands being pounced and slams down [src]!"))
			KnockDown(1.5)
			Stun(1.5)
			throwing = FALSE
			playsound(loc, 'sound/weapons/alien_knockdown.ogg', 25, 1)
			return

	playsound(loc, rand(0, 100) < 95 ? 'sound/voice/alien_pounce.ogg' : 'sound/voice/alien_pounce2.ogg', 25, 1)
	pounced_mob.KnockDown(0.25)
	step_to(src, pounced_mob)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf(turf/turf_target)
	if(!turf_target.density)
		for(var/mob/living/mob in turf_target)
			pounced_mob(mob)
			break
	else
		turf_launch_collision(turf_target)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf_wrapper(turf/turf_target)
	pounced_turf(turf_target)
