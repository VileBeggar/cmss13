
//-------------------------------------------------------
//M5 RPG

/obj/item/weapon/gun/launcher/rocket
	name = "\improper M5 RPG"
	desc = "The M5 RPG is the primary anti-armor weapon of the USCM. Used to take out light-tanks and enemy structures, the M5 RPG is a dangerous weapon with a variety of combat uses."
	icon = 'icons/obj/items/weapons/guns/guns_by_faction/uscm.dmi'
	icon_state = "m5"
	item_state = "m5"
	unacidable = TRUE
	indestructible = 1

	matter = list("metal" = 10000)
	current_mag = /obj/item/ammo_magazine/rocket
	flags_equip_slot = NO_FLAGS
	w_class = SIZE_HUGE
	force = 15
	wield_delay = WIELD_DELAY_HORRIBLE
	delay_style = WEAPON_DELAY_NO_FIRE
	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	attachable_allowed = list(
		/obj/item/attachable/magnetic_harness,
	)

	flags_gun_features = GUN_SPECIALIST|GUN_WIELDED_FIRING_ONLY|GUN_INTERNAL_MAG
	var/datum/effect_system/smoke_spread/smoke

	flags_item = TWOHANDED|NO_CRYO_STORE
	var/skill_locked = TRUE

/obj/item/weapon/gun/launcher/rocket/Initialize(mapload, spawn_empty)
	. = ..()
	smoke = new()
	smoke.attach(src)

/obj/item/weapon/gun/launcher/rocket/Destroy()
	QDEL_NULL(smoke)
	return ..()


/obj/item/weapon/gun/launcher/rocket/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 6, "rail_y" = 19, "under_x" = 19, "under_y" = 14, "stock_x" = 19, "stock_y" = 14)


/obj/item/weapon/gun/launcher/rocket/set_gun_config_values()
	..()
	set_fire_delay(FIRE_DELAY_TIER_6*2)
	accuracy_mult = BASE_ACCURACY_MULT
	scatter = SCATTER_AMOUNT_TIER_6
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil = RECOIL_AMOUNT_TIER_3


/obj/item/weapon/gun/launcher/rocket/get_examine_text(mob/user)
	. = ..()
	if(current_mag.current_rounds <= 0)
		. += "It's not loaded."
		return
	if(current_mag.current_rounds > 0)
		. += "It has an 84mm [ammo.name] loaded."


/obj/item/weapon/gun/launcher/rocket/able_to_fire(mob/living/user)
	. = ..()
	if (. && istype(user)) //Let's check all that other stuff first.
		if(skill_locked && !skillcheck(user, SKILL_SPEC_WEAPONS, SKILL_SPEC_ALL) && user.skills.get_skill_level(SKILL_SPEC_WEAPONS) != SKILL_SPEC_ROCKET)
			to_chat(user, SPAN_WARNING("You don't seem to know how to use \the [src]..."))
			return 0
		if(user.faction == FACTION_MARINE && explosive_antigrief_check(src, user))
			to_chat(user, SPAN_WARNING("\The [name]'s safe-area accident inhibitor prevents you from firing!"))
			msg_admin_niche("[key_name(user)] attempted to fire \a [name] in [get_area(src)] [ADMIN_JMP(loc)]")
			return FALSE
		if(current_mag && current_mag.current_rounds > 0)
			make_rocket(user, 0, 1)

/obj/item/weapon/gun/launcher/rocket/load_into_chamber(mob/user)
// if(active_attachable) active_attachable = null
	return ready_in_chamber()

//No such thing
/obj/item/weapon/gun/launcher/rocket/reload_into_chamber(mob/user)
	return TRUE

/obj/item/weapon/gun/launcher/rocket/delete_bullet(obj/projectile/projectile_to_fire, refund = 0)
	if(!current_mag)
		return
	qdel(projectile_to_fire)
	if(refund)
		current_mag.current_rounds++
	return TRUE

/obj/item/weapon/gun/launcher/rocket/proc/make_rocket(mob/user, drop_override = 0, empty = 1)
	if(!current_mag)
		return

	var/obj/item/ammo_magazine/rocket/r = new current_mag.type()
	//if there's ever another type of custom rocket ammo this logic should just be moved into a function on the rocket
	if(istype(current_mag, /obj/item/ammo_magazine/rocket/custom) && !empty)
		//set the custom rocket variables here.
		var/obj/item/ammo_magazine/rocket/custom/k = new /obj/item/ammo_magazine/rocket/custom
		var/obj/item/ammo_magazine/rocket/custom/cur_mag_cast = current_mag
		k.contents = cur_mag_cast.contents
		k.desc = cur_mag_cast.desc
		k.fuel = cur_mag_cast.fuel
		k.icon_state = cur_mag_cast.icon_state
		k.warhead = cur_mag_cast.warhead
		k.locked = cur_mag_cast.locked
		k.name = cur_mag_cast.name
		k.filters = cur_mag_cast.filters
		r = k

	if(empty)
		r.current_rounds = 0
	if(drop_override || !user) //If we want to drop it on the ground or there's no user.
		r.forceMove(get_turf(src)) //Drop it on the ground.
	else
		user.put_in_hands(r)
		r.update_icon()

/obj/item/weapon/gun/launcher/rocket/reload(mob/user, obj/item/ammo_magazine/rocket)
	if(!current_mag)
		return
	if(flags_gun_features & GUN_BURST_FIRING)
		return

	if(!rocket || !istype(rocket) || !istype(src, rocket.gun_type))
		to_chat(user, SPAN_WARNING("That's not going to fit!"))
		return

	if(current_mag.current_rounds > 0)
		to_chat(user, SPAN_WARNING("[src] is already loaded!"))
		return

	if(rocket.current_rounds <= 0)
		to_chat(user, SPAN_WARNING("That frame is empty!"))
		return

	if(user)
		to_chat(user, SPAN_NOTICE("You begin reloading [src]. Hold still..."))
		if(do_after(user,current_mag.reload_delay, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
			qdel(current_mag)
			user.drop_inv_item_on_ground(rocket)
			current_mag = rocket
			rocket.forceMove(src)
			replace_ammo(,rocket)
			to_chat(user, SPAN_NOTICE("You load [rocket] into [src]."))
			if(reload_sound)
				playsound(user, reload_sound, 25, 1)
			else
				playsound(user,'sound/machines/click.ogg', 25, 1)
		else
			to_chat(user, SPAN_WARNING("Your reload was interrupted!"))
			return
	else
		qdel(current_mag)
		current_mag = rocket
		rocket.forceMove(src)
		replace_ammo(,rocket)
	return TRUE

/obj/item/weapon/gun/launcher/rocket/unload(mob/user,  reload_override = 0, drop_override = 0)
	if(user && current_mag)
		if(current_mag.current_rounds <= 0)
			to_chat(user, SPAN_WARNING("[src] is already empty!"))
			return
		to_chat(user, SPAN_NOTICE("You begin unloading [src]. Hold still..."))
		if(do_after(user,current_mag.reload_delay, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
			if(current_mag.current_rounds <= 0)
				to_chat(user, SPAN_WARNING("You have already unloaded \the [src]."))
				return
			playsound(user, unload_sound, 25, 1)
			user.visible_message(SPAN_NOTICE("[user] unloads [ammo] from [src]."),
			SPAN_NOTICE("You unload [ammo] from [src]."))
			make_rocket(user, drop_override, 0)
			current_mag.current_rounds = 0

//Adding in the rocket backblast. The tile behind the specialist gets blasted hard enough to down and slightly wound anyone
/obj/item/weapon/gun/launcher/rocket/apply_bullet_effects(obj/projectile/projectile_to_fire, mob/user, i = 1, reflex = 0)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_EAR_PROTECTION) && ishuman(user))
		var/mob/living/carbon/human/huser = user
		to_chat(user, SPAN_WARNING("Augh!! \The [src]'s launch blast resonates extremely loudly in your ears! You probably should have worn some sort of ear protection..."))
		huser.apply_effect(6, STUTTER)
		huser.emote("pain")
		huser.SetEarDeafness(max(user.ear_deaf,10))

	var/backblast_loc = get_turf(get_step(user.loc, turn(user.dir, 180)))
	smoke.set_up(1, 0, backblast_loc, turn(user.dir, 180))
	smoke.start()
	playsound(src, 'sound/weapons/gun_rocketlauncher.ogg', 100, TRUE, 10)
	for(var/mob/living/carbon/mob in backblast_loc)
		if(mob.body_position != STANDING_UP || HAS_TRAIT(mob, TRAIT_EAR_PROTECTION)) //Have to be standing up to get the fun stuff
			continue
		to_chat(mob, SPAN_BOLDWARNING("You got hit by the backblast!"))
		mob.apply_damage(15, BRUTE) //The shockwave hurts, quite a bit. It can knock unarmored targets unconscious in real life
		var/knockdown_amount = 6
		if(isxeno(mob))
			var/mob/living/carbon/xenomorph/xeno = mob
			knockdown_amount = knockdown_amount * (1 - xeno.caste?.xeno_explosion_resistance / 100)
		mob.KnockDown(knockdown_amount)
		mob.apply_effect(6, STUTTER)
		mob.emote("pain")

//-------------------------------------------------------
//M5 RPG'S MEAN FUCKING COUSIN

/obj/item/weapon/gun/launcher/rocket/m57a4
	name = "\improper M57-A4 'Lightning Bolt' quad thermobaric launcher"
	desc = "The M57-A4 'Lightning Bolt' is possibly the most destructive man-portable weapon ever made. It is a 4-barreled missile launcher capable of burst-firing 4 thermobaric missiles. Enough said."
	icon = 'icons/obj/items/weapons/guns/guns_by_faction/event.dmi'
	icon_state = "m57a4"
	item_state = "m57a4"

	current_mag = /obj/item/ammo_magazine/rocket/m57a4
	aim_slowdown = SLOWDOWN_ADS_SUPERWEAPON
	flags_gun_features = GUN_WIELDED_FIRING_ONLY

/obj/item/weapon/gun/launcher/rocket/m57a4/set_gun_config_values()
	..()
	set_fire_delay(FIRE_DELAY_TIER_5)
	set_burst_delay(FIRE_DELAY_TIER_7)
	set_burst_amount(BURST_AMOUNT_TIER_4)
	accuracy_mult = BASE_ACCURACY_MULT - HIT_ACCURACY_MULT_TIER_4
	scatter = SCATTER_AMOUNT_TIER_6
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil = RECOIL_AMOUNT_TIER_3


//-------------------------------------------------------
//AT rocket launchers, can be used by non specs

/obj/item/weapon/gun/launcher/rocket/anti_tank //reloadable
	name = "\improper QH-4 Shoulder-Mounted Anti-Tank RPG"
	desc = "Used to take out light-tanks and enemy structures, the QH-4 is a dangerous weapon specialised against vehicles. Requires direct hits to penetrate vehicle armor."
	icon_state = "m83a2"
	item_state = "m83a2"
	unacidable = FALSE
	indestructible = FALSE
	skill_locked = FALSE

	current_mag = /obj/item/ammo_magazine/rocket/anti_tank

	attachable_allowed = list()

	flags_gun_features = GUN_WIELDED_FIRING_ONLY

	flags_item = TWOHANDED

/obj/item/weapon/gun/launcher/rocket/anti_tank/set_bullet_traits()
	. = ..()
	LAZYADD(traits_to_give, list(
		BULLET_TRAIT_ENTRY_ID("vehicles", /datum/element/bullet_trait_damage_boost, 20, GLOB.damage_boost_vehicles),
	))

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable //single shot and disposable
	name = "\improper M83A2 SADAR"
	desc = "The M83A2 SADAR is a lightweight one-shot anti-armor weapon capable of engaging enemy vehicles at ranges up to 1,000m. Fully disposable, the rocket's launcher is discarded after firing. When stowed (unique-action), the SADAR system consists of a watertight carbon-fiber composite blast tube, inside of which is an aluminum launch tube containing the missile. The weapon is fired by pushing a charge button on the trigger grip.  It is sighted and fired from the shoulder."
	var/fired = FALSE

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/get_examine_text(mob/user)
	. = ..()
	. += SPAN_NOTICE("You can fold it up with unique-action.")

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/Fire(atom/target, mob/living/user, params, reflex, dual_wield)
	. = ..()
	if(.)
		fired = TRUE

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/unique_action(mob/M)
	if(fired)
		to_chat(M, SPAN_WARNING("\The [src] has already been fired - you can't fold it back up again!"))
		return

	M.visible_message(SPAN_NOTICE("[M] begins to fold up \the [src]."), SPAN_NOTICE("You start to fold and collapse closed \the [src]."))

	if(!do_after(M, 2 SECONDS, INTERRUPT_ALL, BUSY_ICON_GENERIC))
		to_chat(M, SPAN_NOTICE("You stop folding up \the [src]"))
		return

	fold(M)
	M.visible_message(SPAN_NOTICE("[M] finishes folding \the [src]."), SPAN_NOTICE("You finish folding \the [src]."))

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/proc/fold(mob/user)
	var/obj/item/prop/folded_anti_tank_sadar/F = new /obj/item/prop/folded_anti_tank_sadar(src.loc)
	transfer_label_component(F)
	qdel(src)
	user.put_in_active_hand(F)

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/reload()
	to_chat(usr, SPAN_WARNING("You cannot reload \the [src]!"))
	return

/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/unload()
	to_chat(usr, SPAN_WARNING("You cannot unload \the [src]!"))
	return

//folded version of the sadar
/obj/item/prop/folded_anti_tank_sadar
	name = "\improper M83 SADAR (folded)"
	desc = "An M83 SADAR Anti-Tank RPG, compacted for easier storage. Can be unfolded with the Z key."
	icon = 'icons/obj/items/weapons/guns/guns_by_faction/uscm.dmi'
	icon_state = "m83a2_folded"
	w_class = SIZE_MEDIUM
	garbage = FALSE

/obj/item/prop/folded_anti_tank_sadar/attack_self(mob/user)
	user.visible_message(SPAN_NOTICE("[user] begins to unfold \the [src]."), SPAN_NOTICE("You start to unfold and expand \the [src]."))
	playsound(src, 'sound/items/component_pickup.ogg', 20, TRUE, 5)

	if(!do_after(user, 4 SECONDS, INTERRUPT_ALL, BUSY_ICON_GENERIC))
		to_chat(user, SPAN_NOTICE("You stop unfolding \the [src]"))
		return

	unfold(user)

	user.visible_message(SPAN_NOTICE("[user] finishes unfolding \the [src]."), SPAN_NOTICE("You finish unfolding \the [src]."))
	playsound(src, 'sound/items/component_pickup.ogg', 20, TRUE, 5)
	. = ..()

/obj/item/prop/folded_anti_tank_sadar/proc/unfold(mob/user)
	var/obj/item/weapon/gun/launcher/rocket/anti_tank/disposable/F = new /obj/item/weapon/gun/launcher/rocket/anti_tank/disposable(src.loc)
	transfer_label_component(F)
	qdel(src)
	user.put_in_active_hand(F)

//-------------------------------------------------------
//UPP Rocket Launcher

/obj/item/weapon/gun/launcher/rocket/upp
	name = "\improper HJRA-12 Handheld Anti-Tank Grenade Launcher"
	desc = "The HJRA-12 Handheld Anti-Tank Grenade Launcher is the standard Anti-Armor weapon of the UPP. It is designed to be easy to use and to take out or disable armored vehicles."
	icon = 'icons/obj/items/weapons/guns/guns_by_faction/upp.dmi'
	icon_state = "hjra12"
	item_state = "hjra12"
	skill_locked = FALSE
	current_mag = /obj/item/ammo_magazine/rocket/upp/at

	attachable_allowed = list(/obj/item/attachable/upp_rpg_breech)

	flags_gun_features = GUN_WIELDED_FIRING_ONLY

	flags_item = TWOHANDED

/obj/item/weapon/gun/launcher/rocket/upp/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 6, "rail_y" = 19, "under_x" = 19, "under_y" = 14, "stock_x" = -6, "stock_y" = 16, "special_x" = 37, "special_y" = 16)

/obj/item/weapon/gun/launcher/rocket/upp/handle_starting_attachment()
	..()
	var/obj/item/attachable/upp_rpg_breech/S = new(src)
	S.flags_attach_features &= ~ATTACH_REMOVABLE
	S.Attach(src)
	update_attachables()

	var/obj/item/attachable/magnetic_harness/Integrated = new(src)
	Integrated.hidden = TRUE
	Integrated.flags_attach_features &= ~ATTACH_REMOVABLE
	Integrated.Attach(src)
	update_attachable(Integrated.slot)

/obj/item/weapon/gun/launcher/rocket/upp/apply_bullet_effects(obj/projectile/projectile_to_fire, mob/user, i = 1, reflex = 0)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_EAR_PROTECTION) && ishuman(user))
		return

	var/backblast_loc = get_turf(get_step(user.loc, turn(user.dir, 180)))
	smoke.set_up(1, 0, backblast_loc, turn(user.dir, 180))
	smoke.start()
	playsound(src, 'sound/weapons/gun_rocketlauncher.ogg', 100, TRUE, 10)
	for(var/mob/living/carbon/C in backblast_loc)
		if(C.body_position == STANDING_UP && !HAS_TRAIT(C, TRAIT_EAR_PROTECTION)) //Have to be standing up to get the fun stuff
			C.apply_damage(15, BRUTE) //The shockwave hurts, quite a bit. It can knock unarmored targets unconscious in real life
			C.apply_effect(4, STUN) //For good measure
			C.apply_effect(6, STUTTER)
			C.emote("pain")

//-------------------------------------------------------
//M6B Rocket Launcher -- AVP2 weapon
//not a true subtype of rocket launcher due to unique behaviour

/obj/item/weapon/gun/launcher/m6b
	name = "\improper M6B rocket launcher"
	desc = "The M6B rocket launcher is the big brother to the M5 RPG. It has a capacity of 3 rockets, and with the capability to switch between unguided and guided rockets, the M6B is one of the USCM's most powerful single-shot weapons in their arsenal."
	icon = 'icons/obj/items/weapons/guns/guns_by_faction/uscm.dmi'
	icon_state = "m6b"
	item_state = "m6b"

	starting_attachment_types = list(/obj/item/attachable/stock/m6b)
	attachable_allowed = list(
		/obj/item/attachable/magnetic_harness,
		/obj/item/attachable/stock/m6b,
	)
	actions_types = list(/datum/action/item_action/m6b_guided_shot)
	has_empty_icon = TRUE

	reload_sound = 'sound/weapons/handling/m79_reload.ogg'
	unload_sound = 'sound/weapons/handling/m79_unload.ogg'
	fire_sound = null //sfx is handled by the bullet_effect() proc due to needing the VARY variable set to true

	has_cylinder = TRUE
	preload = /obj/item/ammo_magazine/rocket
	internal_max_w_class = SIZE_MEDIUM //MEDIUM = M15.
	internal_slots = 3
	direct_draw = FALSE

	flags_gun_features = GUN_WIELDED_FIRING_ONLY|GUN_UNUSUAL_DESIGN
	flags_item = TWOHANDED


	///How long it takes for a guided missile to get fired.
	var/aiming_time = 2 SECONDS
	///How long it takes for the user to fire another guided shot.
	var/guided_shot_cooldown_delay = 3.5 SECONDS
	///Smoke effect for fired rockets.
	var/datum/effect_system/smoke_spread/smoke

	///GFX for guided shot lock-ons.
	var/guided_lockon_icon = "sniper_lockon"
	///GFX for guided shot beam.
	var/obj/effect/ebeam/sniper_beam_type = /obj/effect/ebeam/laser
	var/guided_beam_icon = "laser_beam"

	///Cooldown for the guided missile ability.
	COOLDOWN_DECLARE(guided_shot_cooldown)

/obj/item/weapon/gun/launcher/m6b/set_gun_config_values()
	..()
	set_fire_delay(FIRE_DELAY_TIER_6*2)
	accuracy_mult = BASE_ACCURACY_MULT
	scatter = SCATTER_AMOUNT_TIER_6
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil = RECOIL_AMOUNT_TIER_3

/obj/item/weapon/gun/launcher/m6b/Initialize(mapload, spawn_empty)
	. = ..()
	smoke = new()
	smoke.attach(src)

/obj/item/weapon/gun/launcher/m6b/Destroy()
	QDEL_NULL(smoke)
	return ..()

/obj/item/weapon/gun/launcher/m6b/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 33, "muzzle_y" = 18,"rail_x" = 6, "rail_y" = 19, "under_x" = 19, "under_y" = 14, "stock_x" = 18, "stock_y" = 14)

/obj/item/weapon/gun/launcher/m6b/update_icon()
	..()
	var/GL_sprite = base_gun_icon
	if(cylinder && !length(cylinder.contents) )
		GL_sprite += "_e"
	icon_state = GL_sprite

//loading rockets into the launcher
/obj/item/weapon/gun/launcher/m6b/on_pocket_attackby(obj/item/ammo_magazine/rocket, mob/user)
	if(!istype(rocket))
		to_chat(user, SPAN_WARNING("You can't load [rocket] into [src]!"))
		return
	if(length(cylinder.contents) >= internal_slots)
		to_chat(user, SPAN_WARNING("[src] cannot hold more rockets!"))
		return
	if(!cylinder.can_be_inserted(rocket, user)) //Technically includes whether there's room for it, but the above gives a tailored message.
		return

	to_chat(user, SPAN_NOTICE("You begin loading [rocket] into [src]. Hold still..."))
	if(!do_after(user, 1.5 SECONDS, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
		to_chat(user, SPAN_WARNING("Your reload was interrupted!"))
		return

	to_chat(user, SPAN_INFO("Now storing: [length(cylinder.contents) + 1] / [internal_slots] rockets."))
	playsound(usr, reload_sound, 75, 1)
	cylinder.handle_item_insertion(rocket, TRUE, user)

///Proc for turning the fired rocket into a spent shell.
/obj/item/weapon/gun/launcher/m6b/proc/expend_rocket()
	var/obj/item/ammo_magazine/rocket/rocket_in_chamber = cylinder?.contents[1]
	if(!rocket_in_chamber)
		return

	var/obj/item/ammo_magazine/rocket/new_rocket = new rocket_in_chamber.type()
	//if there's ever another type of custom rocket ammo this logic should just be moved into a function on the rocket
	if(istype(new_rocket, /obj/item/ammo_magazine/rocket/custom))
		var/obj/item/ammo_magazine/rocket/custom/custom_rocket = new_rocket
		var/obj/item/ammo_magazine/rocket/custom/custom_rocket_in_chamber = rocket_in_chamber
		//set the custom rocket variables here.
		custom_rocket.contents = custom_rocket_in_chamber.contents
		custom_rocket.desc = custom_rocket_in_chamber.desc
		custom_rocket.fuel = custom_rocket_in_chamber.fuel
		custom_rocket.icon_state = custom_rocket_in_chamber.icon_state
		custom_rocket.warhead = custom_rocket_in_chamber.warhead
		custom_rocket.locked = custom_rocket_in_chamber.locked
		custom_rocket.name = custom_rocket_in_chamber.name
		custom_rocket.filters = custom_rocket_in_chamber.filters

	new_rocket.current_rounds = 0
	new_rocket.forceMove(get_turf(src)) //Drop it on the ground.
	new_rocket.update_icon()
	qdel(rocket_in_chamber)
	update_icon()

//handles the backblast
/obj/item/weapon/gun/launcher/m6b/apply_bullet_effects(obj/projectile/projectile_to_fire, mob/user, i = 1, reflex = 0)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_EAR_PROTECTION) && ishuman(user))
		var/mob/living/carbon/human/huser = user
		to_chat(user, SPAN_WARNING("Augh!! \The [src]'s launch blast resonates extremely loudly in your ears! You probably should have worn some sort of ear protection..."))
		huser.apply_effect(6, STUTTER)
		huser.emote("pain")
		huser.SetEarDeafness(max(user.ear_deaf,10))

	var/backblast_loc = get_turf(get_step(user.loc, turn(user.dir, 180)))
	smoke.set_up(1, 0, backblast_loc, turn(user.dir, 180))
	smoke.start()
	playsound(src, 'sound/weapons/gun_rocketlauncher.ogg', 100, TRUE, 10)
	for(var/mob/living/carbon/mob in backblast_loc)
		if(mob.body_position != STANDING_UP || HAS_TRAIT(mob, TRAIT_EAR_PROTECTION)) //Have to be standing up to get the fun stuff
			continue
		to_chat(mob, SPAN_BOLDWARNING("You got hit by the backblast!"))
		mob.apply_damage(15, BRUTE) //The shockwave hurts, quite a bit. It can knock unarmored targets unconscious in real life
		var/knockdown_amount = 6
		if(isxeno(mob))
			var/mob/living/carbon/xenomorph/xeno = mob
			knockdown_amount = knockdown_amount * (1 - xeno.caste?.xeno_explosion_resistance / 100)
		mob.KnockDown(knockdown_amount)
		mob.apply_effect(6, STUTTER)
		mob.emote("pain")
	to_chat(user, SPAN_INFO("Now storing: [length(cylinder.contents) - 1] / [internal_slots] rockets."))

//convert the first loaded rocket into the respective bullet datum
/obj/item/weapon/gun/launcher/m6b/load_into_chamber()
	var/obj/item/ammo_magazine/rocket/rocket_in_chamber = cylinder?.contents[1]
	if(!rocket_in_chamber)
		return

	QDEL_NULL(in_chamber)
	in_chamber = create_bullet(GLOB.ammo_list[rocket_in_chamber.default_ammo], initial(name))
	apply_traits(in_chamber)
	expend_rocket()
	return in_chamber

//not needed for this type of weapon
/obj/item/weapon/gun/launcher/m6b/reload_into_chamber()
	return

/obj/item/weapon/gun/launcher/m6b/on_pocket_insertion()
	playsound(usr, reload_sound, 25, 1)
	update_icon()

/obj/item/weapon/gun/launcher/m6b/on_pocket_removal()
	update_icon()

/obj/item/weapon/gun/launcher/m6b/on_pocket_open(first_open)
	playsound(usr, reload_sound, 25, 1)

/obj/item/weapon/gun/launcher/m6b/get_examine_text(mob/user)
	. = ..()
	if(get_dist(user, src) > 2 && user != loc)
		return
	if(length(cylinder.contents))
		. += SPAN_NOTICE("It is loaded with <b>[length(cylinder.contents)] / [internal_slots]</b> rockets.")
	else
		. += SPAN_NOTICE("It is empty.")

//Need to have the rocket launcher in your hands to open the cylinder.
/obj/item/weapon/gun/launcher/m6b/attack_hand(mob/user)
	if(src != user.get_inactive_hand())
		return ..()
	if(cylinder.handle_attack_hand(user))
		..()

/obj/item/weapon/gun/launcher/m6b/unload(mob/user, reload_override = FALSE, drop_override = FALSE, loc_override = FALSE)
	if(!length(cylinder.contents))
		to_chat(user, SPAN_WARNING("It's empty!"))
		return

	var/obj/item/ammo_magazine/rocket/rocket = cylinder.contents[length(cylinder.contents)] //Grab the last-inserted one. Or the only one, as the case may be.
	cylinder.remove_from_storage(rocket, user.loc)

	if(drop_override || !user)
		rocket.forceMove(get_turf(src))
	else
		user.put_in_hands(rocket)

	user.visible_message(SPAN_NOTICE("[user] unloads [rocket] from [src]."),
	SPAN_NOTICE("You unload [rocket] from [src]."), null, 4, CHAT_TYPE_COMBAT_ACTION)
	playsound(user, unload_sound, 30, 1)

/obj/item/weapon/gun/launcher/m6b/attackby(obj/item/I, mob/user)
	if(istype(I,/obj/item/attachable) && check_inactive_hand(user))
		attach_to_gun(user, I)
		return
	return cylinder.attackby(I, user)

/obj/item/weapon/gun/launcher/m6b/unique_action(mob/user)
	var/datum/action/item_action/m6b_guided_shot/guided_shot = locate(/datum/action/item_action/m6b_guided_shot) in actions
	guided_shot.use_ability()

//-----------------------
// GUIDED MISSLE ABILITY

/datum/action/item_action/m6b_guided_shot
	var/obj/item/weapon/gun/launcher/m6b/rocket_launcher

/datum/action/item_action/m6b_guided_shot/New(mob/living/user, obj/item/holder)
	..()
	rocket_launcher = holder_item
	name = "Toggle Guided Missiles"
	button.name = name
	button.overlays.Cut()
	var/image/IMG = image('icons/mob/hud/actions.dmi', button, "guided_shot")
	button.overlays += IMG

/datum/action/item_action/m6b_guided_shot/action_activate()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	playsound(owner, 'sound/effects/sebb_beep.ogg', 25)
	if(H.selected_ability == src)
		to_chat(H, SPAN_NOTICE("[rocket_launcher] is now set to utilize guided missiles with \
			[H.client && H.client.prefs && H.client.prefs.toggle_prefs & TOGGLE_MIDDLE_MOUSE_CLICK ? "middle-click" : "shift-click"]."))
		button.icon_state = "template"
		H.selected_ability = null
	else
		to_chat(H, SPAN_NOTICE("[rocket_launcher] will no longer fire guided missiles."))
		if(H.selected_ability)
			H.selected_ability.button.icon_state = "template"
			H.selected_ability = null
		button.icon_state = "template_on"
		H.selected_ability = src

/datum/action/item_action/m6b_guided_shot/can_use_action()
	var/mob/living/carbon/human/H = owner
	if(istype(H) && !H.is_mob_incapacitated() && (holder_item == H.r_hand || holder_item || H.l_hand))
		return TRUE

/datum/action/item_action/m6b_guided_shot/proc/use_ability(atom/A)
	var/mob/living/carbon/human/human = owner
	if(!istype(A, /mob/living))
		return

	var/mob/living/target = A

	if(target.stat == DEAD || target == human || !COOLDOWN_FINISHED(rocket_launcher, guided_shot_cooldown) || !check_can_use(target))
		return

	human.face_atom(target)

	///Add a decisecond to the default 1.5 seconds for each two tiles to hit.
	var/distance = floor(get_dist(target, human) * 0.5)
	var/f_aiming_time = rocket_launcher.aiming_time + distance

	var/beam = rocket_launcher.guided_beam_icon
	var/lockon = rocket_launcher.guided_lockon_icon

	var/image/lockon_icon = image(icon = 'icons/effects/Targeted.dmi', icon_state = lockon)

	var/x_offset =  -target.pixel_x + target.base_pixel_x
	var/y_offset = (target.icon_size - world.icon_size) * 0.5 - target.pixel_y + target.base_pixel_y

	lockon_icon.pixel_x = x_offset
	lockon_icon.pixel_y = y_offset
	target.overlays += lockon_icon

	if(human.client)
		playsound_client(human.client, 'sound/effects/nightvision.ogg', human, 50)
	playsound(target, 'sound/effects/nightvision.ogg', 70, FALSE, 8, falloff = 0.4)

	var/datum/beam/laser_beam = target.beam(human, beam, 'icons/effects/beam.dmi', (f_aiming_time + 1 SECONDS), beam_type = rocket_launcher.sniper_beam_type)
	laser_beam.visuals.alpha = 0
	animate(laser_beam.visuals, alpha = initial(laser_beam.visuals.alpha), f_aiming_time, easing = SINE_EASING|EASE_OUT)

	if(!do_after(human, f_aiming_time, INTERRUPT_INCAPACITATED, NO_BUSY_ICON))
		target.overlays -= lockon_icon
		qdel(laser_beam)
		return

	target.overlays -= lockon_icon
	qdel(laser_beam)

	if(!check_can_use(target, TRUE) || target.is_dead())
		return

	var/obj/projectile/aimed_proj = rocket_launcher.in_chamber
	aimed_proj.AddComponent(/datum/component/homing_projectile, target, human)
	rocket_launcher.Fire(target, human)

/datum/action/item_action/m6b_guided_shot/proc/check_can_use(mob/M)
	var/mob/living/carbon/human/H = owner
	var/obj/item/weapon/gun/launcher/m6b/rocket_launcher = holder_item

	if(!can_use_action())
		return FALSE

	if(!(rocket_launcher.flags_item & WIELDED))
		to_chat(H, SPAN_WARNING("Your aim is not stable enough with one hand. Use both hands!"))
		return FALSE

	if(!rocket_launcher.in_chamber)
		to_chat(H, SPAN_WARNING("\The [rocket_launcher] is unloaded!"))
		return FALSE

	var/obj/projectile/P = rocket_launcher.in_chamber
	if(check_shot_is_blocked(H, M, P))
		to_chat(H, SPAN_WARNING("[rocket_launcher] beeps as it stops tracking [target]."))
		COOLDOWN_START(rocket_launcher, guided_shot_cooldown, rocket_launcher.guided_shot_cooldown_delay * 0.5)
		return FALSE

	COOLDOWN_START(rocket_launcher, guided_shot_cooldown, rocket_launcher.guided_shot_cooldown_delay)
	return TRUE

/datum/action/item_action/m6b_guided_shot/proc/check_shot_is_blocked(mob/firer, mob/target, obj/projectile/P)
	var/list/turf/path = get_line(firer, target, include_start_atom = FALSE)
	if(!length(path) || get_dist(firer, target) > P.ammo.max_range)
		return TRUE

	var/blocked = FALSE
	for(var/turf/T in path)
		if(T.density && T.opacity)
			blocked = TRUE
			break

		for(var/obj/O in T)
			if(O.get_projectile_hit_boolean(P) && O.opacity)
				blocked = TRUE
				break

		for(var/obj/effect/particle_effect/smoke/S in T)
			blocked = TRUE
			break

	return blocked
