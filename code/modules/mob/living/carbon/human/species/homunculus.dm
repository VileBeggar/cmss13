// These may have some say.dm bugs regarding understanding common,
// might be worth adapting the bugs into a feature and using these
// subtypes as a basis for non-common-speaking alien foreigners. ~ Z

/datum/species/human/homunculus
	group = SPECIES_HOMUNCULUS
	name = "Homunculus"
	name_plural = "Homunculi"
	icobase = 'icons/mob/humans/species/r_homunculi.dmi'
	deform = 'icons/mob/humans/species/r_homunculi.dmi'

	flags = HAS_HARDCRIT
	mob_flags = NO_FLAGS
	can_emote = FALSE
	pain_type = /datum/pain/zombie
	death_message = "seizes up and falls limp."

	has_organ = list(
		"heart" = /datum/internal_organ/heart,
		"lungs" = /datum/internal_organ/lungs,
		"liver" = /datum/internal_organ/liver,
		"kidneys" = /datum/internal_organ/kidneys,
		)

/datum/species/human/homunculus/create_organs(mob/living/carbon/human/H)
	QDEL_LIST(H.limbs)
	QDEL_LIST(H.internal_organs)
	H.internal_organs_by_name.Cut()

	//This is a basic humanoid limb setup.
	var/obj/limb/chest/C = new(H, null, H)
	H.limbs += C
	var/obj/limb/groin/G = new(H, C, H)
	H.limbs += G

	for(var/organ in has_organ)
		var/organ_type = has_organ[organ]
		H.internal_organs_by_name[organ] = new organ_type(H)

/datum/species/human/homunculus/handle_post_spawn(mob/living/carbon/human/H)
	H.mobility_flags &= ~MOBILITY_STAND
	H.on_floored_start()
	return ..()
