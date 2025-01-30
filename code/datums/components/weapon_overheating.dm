/datum/component/weapon_overheating
	var/heat_value = 0
	var/heat_increase_per_shot = 1
	var/heat_cap = 100

/datum/component/weapon_overheating/Initialize(...)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/component/weapon_overheating/RegisterWithParent()
	..()
	RegisterSignal(parent, COMSIG_MOB_FIRED_GUN, PROC_REF(increase_heat))

/datum/component/weapon_overheating/proc/increase_heat()
	SIGNAL_HANDLER

	heat_value += heat_increase_per_shot

/datum/component/weapon_overheating/proc/decrease_heat()
	if(heat_value <= 0)
		return
	heat_value -= heat_increase_per_shot

/datum/component/weapon_overheating/process(delta_time)
	decrease_heat()

