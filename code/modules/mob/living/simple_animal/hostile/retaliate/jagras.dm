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
	speak_chance = 1
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT

	response_help = "pets"
	response_disarm = "tries to push aside"
	response_harm = "punches"

	melee_damage_lower = 20
	melee_damage_upper = 25
	attacktext = "bites"
	var/aggression_value = 0
	var/chance_to_rest = 0
	var/trying_to_eat = FALSE
	var/obj/item/reagent_container/food/snacks/meat/snack_target = null
	var/list/pounce_callbacks = list()
	var/mob/living/carbon/intruding_mob
	COOLDOWN_DECLARE(growl_message)
	COOLDOWN_DECLARE(pounce_cooldown)
	COOLDOWN_DECLARE(snack_cooldown)
	COOLDOWN_DECLARE(calm_cooldown)

/mob/living/simple_animal/hostile/retaliate/jagras/Initialize()
	. = ..()
	pain.ignore_oxyloss_checks = TRUE //Stops it from dying mid-lunge when suffering from intense pain.
	pounce_callbacks[/mob] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_mob_wrapper)
	pounce_callbacks[/turf] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_turf_wrapper)
	pounce_callbacks[/obj] = DYNAMIC(/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_obj_wrapper)


/mob/living/simple_animal/hostile/retaliate/jagras/attack_hand(mob/living/carbon/human/attacking_mob as mob)
	if(attacking_mob.a_intent == INTENT_DISARM && stat != DEAD)
		aggression_value = update_value_clamped(aggression_value, 15)

		if(COOLDOWN_FINISHED(src, growl_message) && aggression_value < 80)
			growl(attacking_mob)

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
	if(stat == DEAD)
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

/mob/living/simple_animal/hostile/retaliate/jagras/Move()
	if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED) && icon_state == "Jagras Knocked Down")
		icon_state = "Jagras"
	. = ..()

/mob/living/simple_animal/hostile/retaliate/jagras/Life(delta_time)
	if(!client)
		if(stance == HOSTILE_STANCE_ATTACKING)
			trying_to_eat = FALSE

		if(resting)
			health += maxHealth / 20

		//Once enough time passes without being hurt, stop chasing and become netural again.
		if(aggression_value == 0 && stance == HOSTILE_STANCE_ATTACKING)
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "calms down.", 1)
			COOLDOWN_START(src, calm_cooldown, 3 SECONDS)
			enemies = new()
			LoseTarget()

		if(COOLDOWN_FINISHED(src, snack_cooldown) && stance <= HOSTILE_STANCE_ALERT && !snack_target)
			for(var/obj/item/reagent_container/food/snacks/snack in oview(5, src))
				stop_automated_movement = TRUE
				snack_target = snack
				trying_to_eat = TRUE
				stance = HOSTILE_STANCE_ALERT
				if(body_position == LYING_DOWN)
					lay_down()
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "looks curiously at [snack].", 1)
				walk_to(src, snack_target, 1, move_to_delay)
				COOLDOWN_START(src, snack_cooldown, 10 SECONDS)
				break

		if(snack_target)
			check_if_food_taken()
			if(Adjacent(snack_target))
				INVOKE_ASYNC(src, PROC_REF(eat_food))

		if(aggression_value >= 80 && stance < HOSTILE_STANCE_ATTACK)
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
			Retaliate()

		for(intruding_mob in oview(5, src))
			if(!COOLDOWN_FINISHED(src, calm_cooldown) || stance > HOSTILE_STANCE_ALERT || trying_to_eat)
				break
			if(friends.Find(intruding_mob) || friendly_factions.Find(intruding_mob.faction))
				continue
			if(body_position == LYING_DOWN)
				lay_down()

			if(get_dist(src, intruding_mob) <= 3)
				growl(intruding_mob)

			if(stance < HOSTILE_STANCE_ALERT)
				stance = HOSTILE_STANCE_ALERT
				walk_to(src, 0)
				stop_automated_movement = TRUE
				if(COOLDOWN_FINISHED(src, growl_message))
					INVOKE_ASYNC(src, PROC_REF(manual_emote), "stares at [intruding_mob].", 1)

			setDir(get_dir(src, intruding_mob))

			if(get_dist(src, intruding_mob) <= 1)
				aggression_value = update_value_clamped(aggression_value, 100)
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
				Retaliate()

			break

		if(stance == HOSTILE_STANCE_IDLE)
			chance_to_rest = update_value_clamped(chance_to_rest, 5)
			if(prob(chance_to_rest))
				chance_to_rest = 0
				lay_down()

	. = ..()

	if(!client)
		if(target_mob && stance == HOSTILE_STANCE_ATTACKING && prob(75) && COOLDOWN_FINISHED(src, pounce_cooldown))
			pounce(target_mob)
			COOLDOWN_START(src, pounce_cooldown, 4 SECONDS)

		aggression_value = update_value_clamped(aggression_value, -10)

		if(!intruding_mob && stance <= HOSTILE_STANCE_ALERT)
			stance = HOSTILE_STANCE_IDLE
			stop_automated_movement = FALSE

/mob/living/simple_animal/hostile/retaliate/jagras/proc/eat_food()
	setDir(get_dir(src, snack_target))
	INVOKE_ASYNC(src, PROC_REF(manual_emote), "gnaws on [snack_target].", 1)
	playsound(loc, 'sound/items/eatfood.ogg', 35, 1)
	sleep(2 SECONDS)

	if(!Adjacent(snack_target) || !isturf(snack_target.loc))
		check_if_food_taken()
		return

	playsound(loc, 'sound/items/eatfood.ogg', 35, 1)
	qdel(snack_target)
	stance = HOSTILE_STANCE_IDLE
	stop_automated_movement = FALSE
	trying_to_eat = FALSE
	chance_to_rest = update_value_clamped(chance_to_rest, 15)
	snack_target = null
	for(intruding_mob in oview(5, src))
		if(isxeno(intruding_mob))
			break
		if(!friendly_factions.Find(intruding_mob.faction))
			friendly_factions += intruding_mob.faction
		playsound(loc, 'sound/voice/jagras_hiss1.ogg', 35)
		INVOKE_ASYNC(src, PROC_REF(manual_emote), "hisses happily at [intruding_mob].", 1)
		break
	COOLDOWN_START(src, snack_cooldown, 20 SECONDS)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/check_if_food_taken()
	if(!isturf(snack_target.loc))
		var/mob/living/friend = snack_target.loc
		if(ishuman(friend) && friendly_factions.Find(friend.faction))
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "looks pleadingly at [friend]...", 1)
			setDir(get_dir(src, friend))
		else
			aggression_value = update_value_clamped(aggression_value, 50)
			if(aggression_value < 80)
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "looks angrily at [snack_target.loc].", 1)
				COOLDOWN_START(src, calm_cooldown, 3 SECONDS)
		stop_moving()
		stop_automated_movement = FALSE
		snack_target = null
		trying_to_eat = FALSE
		COOLDOWN_START(src, snack_cooldown, 5 SECONDS)

/mob/living/simple_animal/hostile/retaliate/jagras/adjustBruteLoss(damage)
	..()
	aggression_value = update_value_clamped(aggression_value, 50)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/growl(target)
	if(COOLDOWN_FINISHED(src, growl_message))
		playsound(loc, 'sound/voice/jagras_growl.ogg', 45, 1)
		COOLDOWN_START(src, growl_message, 8 SECONDS)
		if(target)
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "growls at [target]!", 1)
		else
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "growls!", 1)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/update_value_clamped(variable, value)
	variable += value
	variable = clamp(variable, 0, 100)
	return variable

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


/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_obj_wrapper(obj/O)
	pounced_obj(O)


/mob/living/simple_animal/hostile/retaliate/jagras/proc/pounced_obj(obj/O)
	// Unconscious or dead, or not throwing but used pounce
	if(!check_state() || (!throwing && !pounceAction.action_cooldown_check()))
		obj_launch_collision(O)
		return

	if(!istype(O, /obj/structure/surface/table) && !istype(O, /obj/structure/surface/rack))
		O.hitby(src) //This resets throwing.
