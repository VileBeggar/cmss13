#define GROWTH_RATE_SLOW 1
#define GROWTH_RATE_NORMAL 2
#define GROWTH_RATE_FAST 3

#define STATUS_OFF 0
#define STATUS_ON 1

/obj/structure/machinery/cell_generator
	name = "cloning vat"
	desc = "A donation from the old A.W. project, using cryogenic technology. It slowly heals whoever is inside the tube."
	icon = 'icons/obj/structures/machinery/cryogenics2.dmi'
	icon_state = "cell"
	density = FALSE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER

	use_power = USE_POWER_IDLE
	idle_power_usage = 20
	active_power_usage = 200

	var/status = STATUS_OFF
	var/mob/living/carbon/occupant
	var/obj/item/cell_sample/sample
	var/obj/item/reagent_container/glass/beaker/beaker
	var/growth_rate = GROWTH_RATE_NORMAL

/obj/structure/machinery/cell_generator/get_examine_text(mob/user)
	. = ..()
	if(!occupant)
		. += SPAN_NOTICE("It's currently empty.")

/obj/structure/machinery/cell_generator/attack_hand(mob/user)
	if(!skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED))
		to_chat(user, SPAN_WARNING("You have no idea how to use this."))
		return

	tgui_interact(user)
	return ..()

/obj/structure/machinery/cell_generator/ui_data(mob/user)
	var/list/data = list()
	data["growth_rate"] = growth_rate
	if(occupant)
		data["occupant"] = occupant
	if(beaker)
		data["beaker"] = beaker.name
		data["fluid_level_max"] = beaker.volume
		data["fluid_level_cur"] = beaker.reagents.total_volume
	if(sample)
		data["sample"] = sample
		data["sample_maturity"] = sample.maturity
	switch(status)
		if(STATUS_OFF)
			data["status"] = "off"
		if(STATUS_ON)
			data["status"] = "generating"

	return data

/obj/structure/machinery/cell_generator/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CellGenerator", name)
		ui.open()

/obj/structure/machinery/cell_generator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("eject_beaker")
			eject_item(usr, beaker)
			. = TRUE
			beaker = null
		if("eject_sample")
			eject_item(usr, sample)
			. = TRUE
			sample = null

/obj/structure/machinery/cell_generator/proc/eject_item(mob/living/user, obj/item/item_to_eject)
	item_to_eject.forceMove(loc)
	if(user && Adjacent(user))
		user.put_in_hands(item_to_eject)
	update_icon()
	SStgui.update_uis(src)

/obj/structure/machinery/cell_generator/attackby(obj/item/item_to_insert, mob/user)
	if(istype(item_to_insert, /obj/item/cell_sample) && user.drop_inv_item_to_loc(item_to_insert, src))
		var/obj/item/old_sample = sample
		sample = item_to_insert
		swap_item(item_to_insert, user, old_sample)
		return
	if(istype(item_to_insert, /obj/item/reagent_container/glass/beaker) && user.drop_inv_item_to_loc(item_to_insert, src))
		var/obj/item/old_beaker = beaker
		beaker = item_to_insert
		swap_item(item_to_insert, user, old_beaker)
		return

	return ..()

/obj/structure/machinery/cell_generator/proc/swap_item(obj/item/item_to_insert, mob/user, obj/item/old_item)
	if(old_item)
		to_chat(user, SPAN_NOTICE("You swap out [old_item] for [item_to_insert]."))
		user.put_in_hands(old_item)
	else
		to_chat(user, SPAN_NOTICE("You place [item_to_insert] into [src]."))
	SStgui.update_uis(src)

/obj/item/cell_sample
	name = "cell sample"
	desc = "An unassuming tissue sample."
	icon = 'icons/obj/items/seeds.dmi'
	icon_state = "seed"
	var/maturity = 0

/obj/item/cell_sample/get_examine_text(mob/user)
	. = ..()
	if(skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED))
		. += SPAN_NOTICE("You could use this tissue sample to generate a homunculi with the cell generator.")

#undef GROWTH_RATE_SLOW
#undef GROWTH_RATE_NORMAL
#undef GROWTH_RATE_FAST
