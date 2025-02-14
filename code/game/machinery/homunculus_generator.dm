#define CELL_GROWTH_GOAL 5 MINUTES
#define STATUS_ON 1
#define STATUS_OFF 0

/obj/structure/machinery/homunculus_generator
	name = "homunculus generator"
	desc = "An eerie machine that is used for generating crude and grotesque imitations of human beings for experimental purposes."
	icon = 'icons/obj/structures/machinery/cryogenics2.dmi'
	icon_state = "cell"
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER

	var/obj/item/reagent_container/glass/beaker
	var/mob/living/carbon/occupant
	var/obj/item/cell_sample/sample
	var/growth_rate = 0
	var/status = STATUS_OFF

/obj/structure/machinery/homunculus_generator/attack_hand(mob/user)
	if(!skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED))
		to_chat(user, SPAN_WARNING("You have no idea how to use this."))
		return

	tgui_interact(user)
	return ..()

/obj/structure/machinery/homunculus_generator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("eject_beaker")
			eject_item(usr, beaker)
			beaker = null
			. = TRUE
		if("eject_sample")
			eject_item(usr, sample)
			sample = null
			. = TRUE
		if("toggle_cycle")
			toggle_cycle()
			. = TRUE

/obj/structure/machinery/homunculus_generator/proc/toggle_cycle()
	if(!sample)
		return
	if(status == STATUS_ON)
		stop_processing()
	else
		start_processing()

/obj/structure/machinery/homunculus_generator/process()
	if(beaker.reagents.total_volume <= 0)
		stop_processing()
		return
	if(sample.growth >= CELL_GROWTH_GOAL)
		finish_processing()
		return

	calculate_growth_rate()
	sample.growth += 1 SECONDS * max(1, growth_rate / 2)
	beaker.reagents.remove_all_type(/datum/reagent, 1, 0, 1)

/obj/structure/machinery/homunculus_generator/stop_processing()
	playsound(src, 'sound/machines/terminal_off.ogg')
	STOP_PROCESSING(SSobj, src)
	status = STATUS_OFF

/obj/structure/machinery/homunculus_generator/start_processing()
	playsound(src, 'sound/machines/terminal_on.ogg')
	START_PROCESSING(SSobj, src)
	status = STATUS_ON

/obj/structure/machinery/homunculus_generator/proc/finish_processing()
	playsound(src, 'sound/machines/ping.ogg')
	stop_processing()
	visible_message(SPAN_NOTICE("[src] pings as it finishes the last stages of tissue generation."))

/obj/structure/machinery/homunculus_generator/proc/eject_item(mob/living/user, obj/item/item_to_eject)
	item_to_eject.forceMove(loc)
	if(user && Adjacent(user))
		user.put_in_hands(item_to_eject)
	update_icon()
	SStgui.update_uis(src)

/obj/structure/machinery/homunculus_generator/attackby(obj/item/reagent_container/item_to_insert, mob/user)
	if(!user.drop_inv_item_to_loc(item_to_insert, src))
		return

	if(istype(item_to_insert, /obj/item/cell_sample))
		var/obj/item/old_sample = sample
		sample = item_to_insert
		swap_item(item_to_insert, user, old_sample)

	else if(istype(item_to_insert, /obj/item/reagent_container/glass/beaker))
		var/obj/item/old_beaker = beaker
		beaker = item_to_insert
		swap_item(item_to_insert, user, old_beaker)
		calculate_growth_rate()

/obj/structure/machinery/homunculus_generator/proc/swap_item(obj/item/item_to_insert, mob/user, obj/item/old_item)
	if(old_item)
		to_chat(user, SPAN_NOTICE("You swap out [old_item] for [item_to_insert]."))
		user.put_in_hands(old_item)
	else
		to_chat(user, SPAN_NOTICE("You place [item_to_insert] into [src]."))
	SStgui.update_uis(src)

/obj/structure/machinery/homunculus_generator/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HomunculusGenerator", name)
		ui.open()

/obj/structure/machinery/homunculus_generator/ui_data(mob/user)
	. = ..()

	.["beaker"] = null
	if(beaker)
		.["beaker"] = list(
			"name" = beaker.name,
			"vol_cur" = beaker.reagents.total_volume,
			"vol_max" = beaker.volume
		)

	.["sample"] = null
	if(sample)
		.["sample"] = list(
			"name" = sample.name,
			"growth" = sample.growth
		)

	.["growth_rate"] = growth_rate
	.["growth_time"] = calculate_growth_time()
	.["growth_goal"] = CELL_GROWTH_GOAL
	.["status"] = status

/obj/structure/machinery/homunculus_generator/proc/calculate_growth_rate()
	if(!beaker)
		return

	var/max_hemogenic_lvl = 0
	var/max_nutritious_lvl = 0
	var/max_hypergenetic_lvl = 0
	for(var/datum/reagent/reagent in beaker.reagents.reagent_list)
		for(var/datum/chem_property/property in reagent.properties)
			switch(property.name)
				if(PROPERTY_HEMOGENIC)
					if(property.level > max_hemogenic_lvl)
						max_hemogenic_lvl = property.level
				if(PROPERTY_NUTRITIOUS)
					if(property.level > max_nutritious_lvl)
						max_nutritious_lvl = property.level
				if(PROPERTY_HYPERGENETIC)
					if(property.level > max_nutritious_lvl)
						max_hypergenetic_lvl = property.level

	growth_rate = min(max_hemogenic_lvl + max_nutritious_lvl + max_hypergenetic_lvl, 10)

/obj/structure/machinery/homunculus_generator/proc/calculate_growth_time()
	if(!growth_rate)
		return "N/A"

	return duration2text_sec((CELL_GROWTH_GOAL - sample.growth) / (growth_rate / 2))

/// CELL SAMPLE ITEM
///------------------
/obj/item/cell_sample
	name = "cell sample"
	desc = "An unassuming tissue sample."
	icon = 'icons/obj/items/seeds.dmi'
	icon_state = "seed"
	var/growth = 0

/obj/item/cell_sample/get_examine_text(mob/user)
	. = ..()
	if(skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED))
		. += SPAN_NOTICE("You could use this tissue sample to generate a homunculus with the cell generator.")

#undef CELL_GROWTH_GOAL
#undef STATUS_ON
#undef STATUS_OFF
