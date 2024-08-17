/datum/action/horde_mode_action
	hidden = TRUE
	var/cooldown_length = 4 SECONDS
	var/ability_type = HORDE_MODE_ABILITY_ACTIVE
	COOLDOWN_DECLARE(ability_cooldown)

/datum/action/horde_mode_action/proc/use_ability()
	if(!COOLDOWN_FINISHED(src, ability_cooldown))
		return

/datum/action/horde_mode_action/proc/apply_cooldown()
	COOLDOWN_START(src, ability_cooldown, cooldown_length * rand(0.9, 1.2))

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
	var/obj/effect/alien/weeds/node/new_node = new node_type(xeno.loc, src, xeno)

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
	ability_type = HORDE_MODE_ABILITY_ATTACK

/datum/action/horde_mode_action/acid_slash/use_ability(mob/living/carbon/human/target)
	. = ..()
	if(!ishuman(target) || target.stat == DEAD)
		return

	for(var/datum/effects/acid/acid_effect in target.effects_list)
		qdel(acid_effect)
		break

	new /datum/effects/acid(target, src)
