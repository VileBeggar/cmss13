/datum/action/horde_mode_action
	hidden = TRUE
	var/cooldown_length = 4 SECONDS
	var/ability_type = HORDE_MODE_ABILITY_ACTIVE
	var/chance_to_activate = 100
	COOLDOWN_DECLARE(ability_cooldown)

/datum/action/horde_mode_action/proc/use_ability()
	if(!COOLDOWN_FINISHED(src, ability_cooldown) || owner.stat == DEAD || !prob(chance_to_activate))
		return

/datum/action/horde_mode_action/proc/apply_cooldown()
	COOLDOWN_START(src, ability_cooldown, cooldown_length)

//--------------------------------
// PLANT WEEDS

/datum/action/horde_mode_action/plant_weeds
	cooldown_length = 16 SECONDS
	///How far the mob has to be away from another (equal or weaker) resin node to plant another node.
	var/range_limit = 3
	var/weed_level = WEED_LEVEL_STANDARD
	var/node_type = /obj/effect/alien/weeds/node/horde_mode

/datum/action/horde_mode_action/plant_weeds/use_ability()
	. = ..()
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	var/turf/turf = xeno.loc
	if(!istype(turf) || turf.density || !turf.is_weedable())
		return

	var/obj/effect/alien/weeds/node/node
	for(var/obj/effect/alien/weeds/node/closest_node in view(xeno, range_limit))
		node = closest_node

	//if there is a node within a certain distance and it's the same level or stronger, don't plant
	if(node && node.weed_strength <= weed_level && get_dist(xeno, node) <= range_limit)
		return

	if(node && node.weed_strength >= weed_level)
		return

	var/obj/effect/alien/resin/trap/resin_trap = locate() in turf
	if(resin_trap)
		return

	var/obj/effect/alien/weeds/weed = node || locate() in turf
	if(weed && weed.weed_strength >= WEED_LEVEL_HIVE)
		return

	for(var/obj/structure/struct in turf)
		if(struct.density && !(struct.flags_atom & ON_BORDER))
			return

	var/area/area = get_area(turf)
	if(isnull(area) || !(area.is_resin_allowed))
		return

	var/list/to_convert
	if(node)
		to_convert = node.children.Copy()

	xeno.visible_message(SPAN_XENONOTICE("[xeno] regurgitates a pulsating node and plants it on the ground!"))
	var/obj/effect/alien/weeds/node/new_node = new node_type(xeno.loc, src, hive = GLOB.hive_datum[xeno.hivenumber])

	if(to_convert)
		for(var/cur_weed in to_convert)
			var/turf/target_turf = get_turf(cur_weed)
			if(target_turf && !target_turf.density)
				new /obj/effect/alien/weeds(target_turf, new_node)
			qdel(cur_weed)

	playsound(xeno.loc, "alien_resin_build", 25)
	apply_cooldown()

/datum/action/horde_mode_action/plant_weeds/weak
	weed_level = WEED_LEVEL_WEAK
	node_type = /obj/effect/alien/weeds/node/weak/horde_mode

//--------------------------------
// RESIN CONSTRUCTION

/datum/action/horde_mode_action/resin_construction
	cooldown_length = 20 SECONDS
	var/time_to_construct = 5 SECONDS
	var/construction_effect = "xeno_telegraph_brown_anim"
	var/constructed_object = /obj/structure/horde_mode_resin/hive_cluster

/datum/action/horde_mode_action/resin_construction/use_ability()
	. = ..()
	apply_cooldown()
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	var/obj/effect/resin_construct/con_effect = new(get_step(xeno, xeno.dir))
	con_effect.icon_state = construction_effect
	xeno.stop_moving()
	xeno.visible_message(SPAN_XENODANGER("[xeno] starts regurgitating resin and reshaping it into something..."))

	ADD_TRAIT(xeno, TRAIT_IMMOBILIZED, "resin construction")
	addtimer(CALLBACK(src, PROC_REF(finish_construction), con_effect), time_to_construct)
	playsound(xeno.loc, get_sfx("alien_resin_build"), 50, 7)

/datum/action/horde_mode_action/resin_construction/proc/finish_construction(obj/effect/resin_construct/con_effect)
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	REMOVE_TRAIT(xeno, TRAIT_IMMOBILIZED, "resin construction")

	if(xeno.stat == DEAD)
		qdel(con_effect)
		return

	playsound(xeno.loc, get_sfx("alien_resin_build"), 50, 7)
	new constructed_object(con_effect.loc, GLOB.hive_datum[xeno.hivenumber])
	qdel(con_effect)


//--------------------------------
// HEALING PHEREOS

/datum/action/horde_mode_action/heal
	cooldown_length = 16 SECONDS
	var/heal_strength = 0.2
	var/heal_strength_human = 0.05
	var/heal_range = 4

/datum/action/horde_mode_action/heal/use_ability()
	. = ..()
	owner.visible_message(SPAN_XENOBOLDNOTICE("[owner] starts emitting healing pheromones..."))
	for(var/mob/living/surrounding_mob in view(heal_range, owner))
		if(surrounding_mob.faction == owner.faction)
			if(ishuman(surrounding_mob))
				var/mob/living/carbon/human/friendly_human = surrounding_mob
				var/total_health = friendly_human.species.total_health
				friendly_human.heal_overall_damage(total_health * heal_strength_human, total_health * heal_strength_human)
				to_chat(friendly_human, SPAN_HELPFUL("[owner]'s pheromones appear to be closing your wounds!"))
			else
				surrounding_mob.health += surrounding_mob.maxHealth * heal_strength
			surrounding_mob.flick_heal_overlay(3 SECONDS, "#D9F500")
	apply_cooldown()


//--------------------------------
// ACID SLASH

/datum/action/horde_mode_action/acid_slash
	ability_type = HORDE_MODE_ABILITY_POSTATTACK

/datum/action/horde_mode_action/acid_slash/use_ability(mob/living/carbon/human/target)
	. = ..()
	if(!ishuman(target) || target.stat == DEAD)
		return

	for(var/datum/effects/acid/acid_effect in target.effects_list)
		qdel(acid_effect)
		break

	new /datum/effects/acid(target, src)

//--------------------------------
// NEURO SLASH

/datum/action/horde_mode_action/neuro_slash
	ability_type = HORDE_MODE_ABILITY_POSTATTACK
	cooldown_length = 6 SECONDS

/datum/action/horde_mode_action/neuro_slash/use_ability(mob/living/carbon/human/target)
	. = ..()
	if(!ishuman(target) || target.stat == DEAD)
		return

	target.apply_effect(0.5, SLOW)
	to_chat(target, SPAN_BOLDWARNING("You feel sluggish as [owner]'s claws inject you with neurotoxin!"))

//--------------------------------
// NEURO SLASH

/datum/action/horde_mode_action/lifesteal
	ability_type = HORDE_MODE_ABILITY_POSTATTACK
	cooldown_length = 0 SECONDS
	var/heal_amount = 0.2 //precentage

/datum/action/horde_mode_action/lifesteal/use_ability(mob/living/carbon/human/target)
	. = ..()
	if(!ishuman(target) || target.stat == DEAD)
		return

	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	xeno.health += xeno.maxHealth * heal_amount
	xeno.flick_heal_overlay(1 SECONDS, "#00B800")

//--------------------------------
// TAIL SWIPE

/datum/action/horde_mode_action/toss_mob/tail_swipe
	cooldown_length = 15 SECONDS
	damage_multiplier = 0.5
	var/swipe_range = 1

/datum/action/horde_mode_action/toss_mob/tail_swipe/use_ability()
	if(!COOLDOWN_FINISHED(src, ability_cooldown) || owner.stat == DEAD || !prob(chance_to_activate))
		return

	apply_cooldown()
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	xeno.spin_circle()
	xeno.emote("tail")
	for(var/mob/living/target in view(swipe_range, xeno))
		if(target.stat == DEAD || target.mob_size >= MOB_SIZE_BIG || target.faction == xeno.faction)
			continue
		if(ishuman(target))
			var/mob/living/carbon/human/human_target = target
			if(human_target.check_shields(0, name))
				playsound(xeno.loc, "bonk", 75, FALSE)
				continue

		var/facing = get_dir(xeno, target)
		target.apply_damage(rand(xeno.melee_damage_upper, xeno.melee_damage_lower) * damage_multiplier, BRUTE)
		playsound(target,'sound/weapons/alien_claw_block.ogg', 75, 1)
		xeno.throw_mob(target, facing, distance)
		if(paralyze)
			target.apply_effect(1, PARALYZE)
			target.apply_effect(1, WEAKEN)

//--------------------------------
// TOSS MOB

/datum/action/horde_mode_action/toss_mob
	ability_type = HORDE_MODE_ABILITY_PREATTACK
	cooldown_length = 10 SECONDS
	var/paralyze = FALSE
	var/distance = 4
	var/damage_multiplier = 1
	var/throw_sound = 'sound/weapons/alien_claw_block.ogg'
	var/mob_spin = TRUE

/datum/action/horde_mode_action/toss_mob/use_ability(mob/living/target)
	. = ..()

	apply_cooldown()
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner

	xeno.animation_attack_on(target)
	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.check_shields(0, name))
			playsound(xeno.loc, "bonk", 75, FALSE)
			return

	var/facing = get_dir(xeno, target)
	target.apply_damage(rand(xeno.melee_damage_upper, xeno.melee_damage_lower) * damage_multiplier, BRUTE)
	playsound(target, throw_sound, 75, 1)
	xeno.throw_mob(target, facing, distance, mob_spin = mob_spin)
	if(paralyze)
		target.apply_effect(1, PARALYZE)
		target.apply_effect(1, WEAKEN)

/datum/action/horde_mode_action/toss_mob/headbutt
	damage_multiplier = 0.33
	distance = 2

/datum/action/horde_mode_action/toss_mob/headbutt/use_ability(mob/living/target)
	. = ..()
	owner.visible_message(SPAN_XENOWARNING("[owner] rams [target] with its armored crest!"))

/datum/action/horde_mode_action/toss_mob/tail_jab
	ability_type = HORDE_MODE_ABILITY_ACTIVE
	damage_multiplier = 1
	distance = 2
	throw_sound = 'sound/weapons/alien_tail_attack.ogg'
	mob_spin = FALSE

/datum/action/horde_mode_action/toss_mob/tail_jab/use_ability(mob/living/target)
	if(get_dist(owner, target) > 2)
		return
	. = ..()

	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	xeno.visible_message(SPAN_XENOWARNING("[xeno] pierces [target] with its sharp tail!"))
	xeno.flick_attack_overlay(target, "tail")


//--------------------------------
// STEELCREST FORTIFY

/datum/action/horde_mode_action/steelcrest_fortify
	cooldown_length = 0 SECONDS
	///Whether the mob is currently fortified or not.
	var/fortified = FALSE

/datum/action/horde_mode_action/steelcrest_fortify/use_ability(mob/living/target)
	. = ..()
	if(get_dist(owner, target) <= 4 && !fortified)
		fortify()

	else if(get_dist(owner, target) > 4 && fortified)
		fortify()

/datum/action/horde_mode_action/steelcrest_fortify/proc/fortify()
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	fortified = !fortified
	switch(fortified)
		if(TRUE)
			xeno.icon_state = "Steelcrest Defender Walking"
			xeno.brute_damage_mod = 1
			xeno.move_to_delay -= HORDE_MODE_SPEED_MOD_MEDIUM
			xeno.status_flags |= CANSTUN
			xeno.mob_size = MOB_SIZE_XENO
		if(FALSE)
			xeno.icon_state = "Steelcrest Defender Fortify"
			xeno.brute_damage_mod = 0.66
			xeno.move_to_delay += HORDE_MODE_SPEED_MOD_MEDIUM
			xeno.status_flags &= ~CANSTUN
			xeno.mob_size = MOB_SIZE_BIG
	xeno.update_wounds()

//--------------------------------
// RUSH

/datum/action/horde_mode_action/rush
	cooldown_length = 14 SECONDS
	var/speed_mod = HORDE_MODE_SPEED_MOD_HIGH
	var/rush_length = 2 SECONDS

/datum/action/horde_mode_action/rush/use_ability(mob/living/target)
	. = ..()
	if(in_range(owner, target))
		return

	apply_cooldown()
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	xeno.emote("roar")
	var/outline_color = "#FF0000"
	outline_color += num2text(70, 2, 16)

	xeno.add_filter("outline", 1, outline_filter(size = 0, color = outline_color))
	xeno.transition_filter("outline", list(size = 2), 2 SECONDS, QUAD_EASING)

	xeno.visible_message(SPAN_DANGER("[xeno] begins to dash forward!"))
	xeno.move_to_delay -= speed_mod
	addtimer(CALLBACK(src, PROC_REF(remove_rush), outline_color), rush_length)


/datum/action/horde_mode_action/rush/proc/remove_rush(outline_color)
	var/mob/living/simple_animal/hostile/alien/horde_mode/xeno = owner
	outline_color += num2text(35, 2, 16)

	xeno.transition_filter("outline", list(size = 0, color = outline_color), 2 SECONDS, QUAD_EASING)
	xeno.move_to_delay += speed_mod
	addtimer(CALLBACK(xeno, TYPE_PROC_REF(/atom/, remove_filter)), 2 SECONDS)
