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
	var/obj/item/reagent_container/glass/beaker
	var/growth_rate = 1

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
	data["status"] = status

	return data

/obj/structure/machinery/cell_generator/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CellGenerator", name)
		ui.open()

/obj/item/cell_sample
	name = "cell sample"
	desc = "An unassuming tissue sample."

/obj/item/cell_sample/get_examine_text(mob/user)
	. = ..()
	if(skillcheck(user, SKILL_RESEARCH, SKILL_RESEARCH_TRAINED))
		. += SPAN_NOTICE("You could use this tissue sample to generate a homunculi with the cell generator.")

#undef GROWTH_RATE_SLOW
#undef GROWTH_RATE_NORMAL
#undef GROWTH_RATE_FAST
