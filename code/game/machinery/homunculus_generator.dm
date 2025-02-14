/obj/structure/machinery/homunculus_generator
	name = "homunculus generator"
	desc = "An eerie machine that is used for generating crude and grotesque imitations of human beings for experimental purposes."
	icon = 'icons/obj/structures/machinery/cryogenics2.dmi'
	icon_state = "cell"
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER

	var/obj/item/reagent_container/glass/beaker
	var/occupied = FALSE
	var/growth_rate = 0

/obj/structure/machinery/homunculus_generator/attack_hand(mob/user)
	if(!skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED))
		to_chat(user, SPAN_WARNING("You have no idea how to use this."))
		return

	tgui_interact(user)
	return ..()

/obj/structure/machinery/homunculus_generator/attackby(obj/item/reagent_container/attacking_object, mob/user)
	if(istype(attacking_object, /obj/item/reagent_container/glass) && user.drop_inv_item_to_loc(attacking_object, src))
		var/obj/item/old_beaker = beaker
		beaker = attacking_object
		if(old_beaker)
			to_chat(user, SPAN_NOTICE("You swap out [old_beaker] for [attacking_object]."))
			user.put_in_hands(old_beaker)
		else
			to_chat(user, SPAN_NOTICE("You set [attacking_object] on the machine."))
		calculate_growth_rate()
		SStgui.update_uis(src)

/obj/structure/machinery/homunculus_generator/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HomunculusGenerator", name)
		ui.open()

/obj/structure/machinery/homunculus_generator/ui_data(mob/user)
	var/list/data = list()
	if(beaker)
		data["beaker"] = beaker.name
		data["beaker_vol_max"] = beaker.volume
		data["beaker_vol_cur"] = beaker.reagents.total_volume
	data["growth_rate"] = growth_rate
	data["growth_time"] = calculate_growth_time()
	return data

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

	return duration2text_sec(2400 / growth_rate)
