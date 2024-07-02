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
	health = 450
	maxHealth = 450

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
	move_to_delay = 2.25

	var/is_fleeing = FALSE
	var/is_ravaging = FALSE
	var/aggression_value = 0
	///The mob's chance (%) to rest/get up when randomly wandering.
	var/chance_to_rest = 0
	///The food item that the mob is targetting.
	var/obj/item/reagent_container/food/snacks/meat/snack_target = null
	///Collision callbacks for the pounce proc.
	var/list/pounce_callbacks = list()
	///Every other mob that's within a certain radius of the current mob.
	var/mob/living/carbon/intruding_mob
	///Cooldown for the "growls at [target]!" message.
	COOLDOWN_DECLARE(growl_message)
	///Cooldown for the pounce ability.
	COOLDOWN_DECLARE(pounce_cooldown)
	///Cooldown for being able to eat food.
	COOLDOWN_DECLARE(snack_cooldown)
	///Short cooldown that will disable hostile actions for the mob, allowing other entities to get themselves to a safe distance.
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

	if(attacking_mob.a_intent == INTENT_HELP && stance == HOSTILE_STANCE_IDLE && friendly_factions.Find(attacking_mob.faction))
		update_value_clamped(aggression_value, -10)
		if(resting)
			chance_to_rest = update_value_clamped(chance_to_rest, -5)
		else
			chance_to_rest = update_value_clamped(chance_to_rest, 5)

	..()

/mob/living/simple_animal/hostile/retaliate/jagras/Retaliate()
	if(stat == DEAD || is_fleeing)
		return

	. = ..()
	if(!HAS_TRAIT(src, TRAIT_INCAPACITATED) && !HAS_TRAIT(src, TRAIT_FLOORED))
		//If resting, get up.
		if(body_position == LYING_DOWN)
			chance_to_rest = 0
			resting = FALSE
			set_body_position(STANDING_UP)
			update_transform(TRUE)
		// Immediately start attacking.
		if(mobility_flags & MOBILITY_MOVE)
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

/mob/living/simple_animal/hostile/retaliate/jagras/on_floored_start()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/on_floored_end()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/on_incapacitated_trait_gain()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/on_incapacitated_trait_loss()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/on_knockedout_trait_gain()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/on_knockedout_trait_loss()
	. = ..()
	update_transform()

/mob/living/simple_animal/hostile/retaliate/jagras/proc/disengage(length, distance, return_to_combat, no_message = FALSE)
	is_fleeing = TRUE
	stance = HOSTILE_STANCE_ALERT
	stop_automated_movement = TRUE
	if(!no_message)
		INVOKE_ASYNC(src, PROC_REF(manual_emote), "tries to disengage!", 1)
	move_to_delay = 2
	COOLDOWN_START(src, calm_cooldown, length + 4 SECONDS)
	COOLDOWN_START(src, snack_cooldown, length + 6 SECONDS)
	walk_away(src, target_mob, distance, move_to_delay)
	if(!return_to_combat)
		enemies = new()
		target_mob = null

	sleep(length)

	//If there are still enemies in view, keep retreating.
	if(!return_to_combat)
		for(intruding_mob in oview(7, src))
			if(friends.Find(intruding_mob) || friendly_factions.Find(intruding_mob.faction))
				continue
			disengage(length, distance, return_to_combat, no_message)
			break

	stop_moving()
	move_to_delay = 2.25
	stop_automated_movement = FALSE
	is_fleeing = FALSE
	if(return_to_combat)
		MoveToTarget()

/mob/living/simple_animal/hostile/retaliate/jagras/stop_moving()
	walk_to(src, 0)

//Do not stop hunting targets even if they're not visible anymore.
/mob/living/simple_animal/hostile/retaliate/jagras/ListTargets(dist = 9)
	if(!enemies.len)
		return list()
	var/list/see = orange(src, dist)
	see &= enemies
	return see

/mob/living/simple_animal/hostile/retaliate/jagras/Life(delta_time)
	if(!client)
		if(stance == HOSTILE_STANCE_ATTACKING)
			snack_target = null

		if(resting)
			health += maxHealth / 20

		if(stance >= HOSTILE_STANCE_ATTACK && health < maxHealth * 0.5 && !is_fleeing)
			INVOKE_ASYNC(src, PROC_REF(disengage), 10 SECONDS, 14, FALSE)

		//Once enough time passes without being hurt, stop chasing and become netural again.
		if(aggression_value == 0 && stance == HOSTILE_STANCE_ATTACKING && COOLDOWN_FINISHED(src, calm_cooldown))
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "calms down.", 1)
			COOLDOWN_START(src, calm_cooldown, 3 SECONDS)
			COOLDOWN_START(src, snack_cooldown, 6 SECONDS)
			enemies = new()
			LoseTarget()

		if(COOLDOWN_FINISHED(src, snack_cooldown) && stance <= HOSTILE_STANCE_ALERT && !snack_target && !is_fleeing)
			for(var/obj/item/reagent_container/food/snacks/snack in oview(5, src))
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
			check_if_food_taken()
			if(Adjacent(snack_target))
				INVOKE_ASYNC(src, PROC_REF(eat_food))

		if(aggression_value >= 80 && !target_mob && !is_fleeing)
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
			Retaliate()

		for(intruding_mob in oview(5, src))
			if(!COOLDOWN_FINISHED(src, calm_cooldown) || stance > HOSTILE_STANCE_ALERT || snack_target)
				break
			if(friends.Find(intruding_mob) || friendly_factions.Find(intruding_mob.faction))
				continue
			if(body_position == LYING_DOWN)
				lay_down()

			if(get_dist(src, intruding_mob) <= 3)
				growl(intruding_mob)

			if(stance < HOSTILE_STANCE_ALERT)
				stance = HOSTILE_STANCE_ALERT
				stop_moving()
				stop_automated_movement = TRUE
				if(COOLDOWN_FINISHED(src, growl_message))
					INVOKE_ASYNC(src, PROC_REF(manual_emote), "stares at [intruding_mob].", 1)

			setDir(get_dir(src, intruding_mob))

			if(get_dist(src, intruding_mob) <= 1)
				aggression_value = update_value_clamped(aggression_value, 100)
				if(!target_mob)
					INVOKE_ASYNC(src, PROC_REF(manual_emote), "snarls!", 1)
				Retaliate()

			break

		if(stance == HOSTILE_STANCE_IDLE && !is_fleeing)
			chance_to_rest = update_value_clamped(chance_to_rest, 5)
			if(prob(chance_to_rest))
				chance_to_rest = 0
				lay_down()

	. = ..()

	if(!client)
		if(target_mob && stance == HOSTILE_STANCE_ATTACKING && COOLDOWN_FINISHED(src, pounce_cooldown) && (prob(75) || get_dist(src, intruding_mob) < 5))
			pounce(target_mob)
			COOLDOWN_START(src, pounce_cooldown, 4 SECONDS)

		aggression_value = update_value_clamped(aggression_value, -10)

		if(!intruding_mob && stance <= HOSTILE_STANCE_ALERT && !is_fleeing)
			stance = HOSTILE_STANCE_IDLE
			stop_automated_movement = FALSE

/mob/living/simple_animal/hostile/retaliate/jagras/AttackingTarget()
	if(!Adjacent(target_mob) || is_ravaging)
		return
	if(isliving(target_mob))
		var/mob/living/living_mob = target_mob
		living_mob.attack_animal(src)
		animation_attack_on(living_mob)
		flick_attack_overlay(living_mob, "slash")
		playsound(loc, "alien_claw_flesh", 25, 1)
		if(prob(50) && !is_fleeing)
			INVOKE_ASYNC(src, PROC_REF(disengage), 2 SECONDS, 7, TRUE, TRUE)
		return living_mob

/mob/living/simple_animal/hostile/retaliate/jagras/proc/ravagingattack()
	var/mob/living/target = target_mob
	is_ravaging = TRUE
	visible_message(SPAN_DANGER("<B>[src]</B> tears into [target] repeatedly!"))

	for(var/attack_num = 0, attack_num < 3, attack_num++)
		if(Adjacent(target) && stat == CONSCIOUS)
			//This is just to scare the shit out of the target.
			var/damage = rand(melee_damage_lower, melee_damage_upper) * 0.20
			var/attack_type = pick("slash", "animalbite")
			target.apply_damage(damage, BRUTE)
			animation_attack_on(target)
			if(attack_type == "slash")
				playsound(loc, get_sfx("alien_claw_flesh"), 25, 1)
			else
				playsound(loc, get_sfx("alien_bite"), 25, 1)
			flick_attack_overlay(target, attack_type)
			sleep(0.5 SECONDS)
	is_ravaging = FALSE
	return target

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
	chance_to_rest = update_value_clamped(chance_to_rest, 15)
	snack_target = null
	for(intruding_mob in oview(5, src))
		if(isxeno(intruding_mob))
			break
		if(!friendly_factions.Find(intruding_mob.faction))
			friendly_factions += intruding_mob.faction
		playsound(loc, pick('sound/voice/jagras_hiss1.ogg', 'sound/voice/jagras_hiss2.ogg'), 35)
		INVOKE_ASYNC(src, PROC_REF(manual_emote), "hisses happily at [intruding_mob].", 1)
		break
	COOLDOWN_START(src, snack_cooldown, 30 SECONDS)

/mob/living/simple_animal/hostile/retaliate/jagras/proc/check_if_food_taken()
	if(!isturf(snack_target.loc))
		var/mob/living/friend = snack_target.loc
		if(ishuman(friend) && friendly_factions.Find(friend.faction))
			INVOKE_ASYNC(src, PROC_REF(manual_emote), "looks pleadingly at [friend]...", 1)
			setDir(get_dir(src, friend))
		else
			aggression_value = update_value_clamped(aggression_value, 50)
			if(aggression_value < 80)
				playsound(loc, pick('sound/voice/jagras_hiss1.ogg', 'sound/voice/jagras_hiss2.ogg'), 35)
				INVOKE_ASYNC(src, PROC_REF(manual_emote), "hisses angrily at [snack_target.loc].", 1)
				COOLDOWN_START(src, calm_cooldown, 3 SECONDS)
		stop_moving()
		stop_automated_movement = FALSE
		snack_target = null
		COOLDOWN_START(src, snack_cooldown, 15 SECONDS)

/mob/living/simple_animal/hostile/retaliate/jagras/adjustBruteLoss(damage)
	..(damage)

	aggression_value = update_value_clamped(aggression_value, 50)
	if(!is_fleeing)
		if(prob(50))
			INVOKE_ASYNC(src, PROC_REF(disengage), 2 SECONDS, 7, TRUE, TRUE)
			return
		Retaliate()

/mob/living/simple_animal/hostile/retaliate/jagras/proc/growl(target)
	if(COOLDOWN_FINISHED(src, growl_message))
		playsound(loc, 'sound/voice/jagras_growl.ogg', 45, 1)
		COOLDOWN_START(src, growl_message, 16 SECONDS)
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
		splatter_effect.pixel_y -= 6


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
	pounced_mob.KnockDown(0.5)
	step_to(src, pounced_mob)
	ravagingattack()

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
	if(stat != CONSCIOUS)
		obj_launch_collision(O)
		return

	if(!istype(O, /obj/structure/surface/table) && !istype(O, /obj/structure/surface/rack))
		O.hitby(src) //This resets throwing.
