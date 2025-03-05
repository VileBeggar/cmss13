#define CELL_GROWTH_MULTIPLIER 0.1
#define CELL_GROWTH_EMBRYO 1.5 MINUTES
#define CELL_GROWTH_HALF_GROWN 3 MINUTES
#define CELL_GROWTH_FULL_GROWN 5 MINUTES
#define STATUS_ON 1
#define STATUS_OFF 0

#define STOP_MANUAL 1
#define STOP_NO_FLUID 2
#define STOP_FINISHED 3

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
		if("eject_occupant")
			eject_occupant()
			. = TRUE

/obj/structure/machinery/homunculus_generator/proc/eject_occupant()
	if(!occupant)
		return
	switch(dir)
		if(NORTH)
			occupant.forceMove(get_step(loc, NORTH))
		if(EAST)
			occupant.forceMove(get_step(loc, EAST))
		if(WEST)
			occupant.forceMove(get_step(loc, WEST))
		else
			occupant.forceMove(get_step(loc, SOUTH))
	visible_message(SPAN_NOTICE("[src] hisses as [occupant] falls out."))
	occupant = null
	playsound(src, 'sound/machines/hydraulics_3.ogg')
	update_icon()

/obj/structure/machinery/homunculus_generator/proc/toggle_cycle()
	if(occupant)
		playsound(src, 'sound/machines/twobeep.ogg')
		visible_message(SPAN_WARNING("[src] is unable to start a cycle while the vat is currently occupied."))
		return
	if(!sample)
		playsound(src, 'sound/machines/twobeep.ogg')
		visible_message(SPAN_WARNING("[src] is unable to start a cycle without a proper tissue sample."))
		return
	if(!beaker || beaker.reagents.total_volume <= 0)
		playsound(src, 'sound/machines/twobeep.ogg')
		visible_message(SPAN_WARNING("[src] is unable to start a cycle without being supplied adequate nutrients."))
		return
	if(status == STATUS_ON)
		stop_processing(STOP_MANUAL)
		return

	start_processing()

/obj/structure/machinery/homunculus_generator/update_icon()
	if(!sample && !occupant)
		icon_state = "cell"
		return
	if(occupant)
		icon_state = "cell-on-occupied-fullgrown"
		return

	switch(sample.growth)
		if(0 to CELL_GROWTH_EMBRYO)
			icon_state = "cell-on-empty"
		if(CELL_GROWTH_EMBRYO to CELL_GROWTH_HALF_GROWN)
			icon_state = "cell-on-occupied-embryo"
		else
			icon_state = "cell-on-occupied-stage-2"


/obj/structure/machinery/homunculus_generator/process()
	if(!beaker || beaker.reagents.total_volume <= 0)
		stop_processing(STOP_NO_FLUID)
		return
	if(sample.growth >= CELL_GROWTH_FULL_GROWN)
		stop_processing(STOP_FINISHED)
		return

	calculate_growth_rate()
	sample.growth += 1 SECONDS * max(1, growth_rate / CELL_GROWTH_MULTIPLIER)
	beaker.reagents.remove_all_type(/datum/reagent, 0.5, 0, 1)
	sample.update_growth()
	update_icon()

/obj/structure/machinery/homunculus_generator/stop_processing(reason)
	STOP_PROCESSING(SSobj, src)
	status = STATUS_OFF

	switch(reason)
		if(STOP_NO_FLUID)
			playsound(src, 'sound/machines/twobeep.ogg')
			visible_message(SPAN_WARNING("[src] lets out a beep, notifying that its nutrient beaker has run dry."))
		if(STOP_MANUAL)
			playsound(src, 'sound/machines/terminal_off.ogg')
			visible_message(SPAN_NOTICE("[src] lets out a soft wheer. The growth cycle has now stopped."))
		if(STOP_FINISHED)
			qdel(sample)
			sample = null
			playsound(src, 'sound/machines/ping.ogg')
			visible_message(SPAN_NOTICE("[src] pings as it finishes the last stages of tissue generation."))
			occupant = new /mob/living/carbon/human/homunculus
			occupant.forceMove(src)

/obj/structure/machinery/homunculus_generator/start_processing()
	playsound(src, 'sound/machines/terminal_on.ogg')
	START_PROCESSING(SSobj, src)
	status = STATUS_ON

/obj/structure/machinery/homunculus_generator/proc/eject_item(mob/living/user, obj/item/item_to_eject)
	item_to_eject.forceMove(loc)
	if(user && Adjacent(user))
		user.put_in_hands(item_to_eject)
	SStgui.update_uis(src)
	update_icon()

/obj/structure/machinery/homunculus_generator/attackby(obj/item/item_to_insert, mob/user)
	if(istype(item_to_insert, /obj/item/cell_sample))
		var/obj/item/cell_sample/sample_to_insert = item_to_insert
		if(sample_to_insert.growth >= CELL_GROWTH_EMBRYO)
			to_chat(user, SPAN_WARNING("[src] only accepts untainted cell samples!"))
			return
		if(!user.drop_inv_item_to_loc(sample_to_insert, src))
			return
		var/obj/item/old_sample = sample
		sample = sample_to_insert
		swap_item(sample_to_insert, user, old_sample)
		return

	if(istype(item_to_insert, /obj/item/reagent_container/glass/beaker) && user.drop_inv_item_to_loc(sample_to_insert, src))
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
	.["occupant"] = FALSE
	if(occupant)
		.["occupant"] = TRUE

	.["growth_rate"] = growth_rate
	.["growth_time"] = calculate_growth_time()
	.["growth_goal"] = CELL_GROWTH_FULL_GROWN
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
	if(!growth_rate || !sample || sample.growth >= CELL_GROWTH_FULL_GROWN)
		return "N/A"

	return duration2text_sec((CELL_GROWTH_FULL_GROWN - sample.growth) / (growth_rate / CELL_GROWTH_MULTIPLIER))

/// CELL SAMPLE ITEM
///------------------
/obj/item/cell_sample
	name = "cell sample"
	desc = "An unassuming tissue sample."
	icon = 'icons/obj/items/homunculus.dmi'
	icon_state = "cell_sample"
	var/growth = 0

/obj/item/cell_sample/get_examine_text(mob/user)
	. = ..()
	if(skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED) && growth < CELL_GROWTH_EMBRYO)
		. += SPAN_NOTICE("You could use this tissue sample to generate a homunculus with the cell generator.")
//embryo squish
/obj/item/cell_sample/proc/update_growth()
	switch(growth)
		if(-INFINITY to CELL_GROWTH_EMBRYO)
			icon_state = "cell_sample"
		if(CELL_GROWTH_EMBRYO to CELL_GROWTH_HALF_GROWN)
			name = "embryo"
			desc = "A malformed embryo..."
			icon_state = "embryo"
		else
			name = "halfgrown homunculi"
			desc = "A malformed embryo that has failed to reach its final stages..."
			icon_state = "half_grown"

#undef CELL_GROWTH_FULL_GROWN
#undef STATUS_ON
#undef STATUS_OFF
