/obj/structure/horde_mode_resin
	name = "resin structure"
	desc = "A large clump of gooey mass. It rhythmically pulses, as if its pumping something into the weeds below..."
	icon = 'icons/mob/xenos/structures48x48.dmi'
	icon_state = "hive_cluster_idle"

	pixel_x = -8
	pixel_y = -8

	health = 500

/obj/structure/horde_mode_resin/hive_cluster
	name = "hive cluster"

	var/node_type = /obj/effect/alien/weeds/node/pylon/cluster

/obj/structure/horde_mode_resin/hive_cluster/Initialize(mapload, hive_owner)
	. = ..()
	var/obj/effect/alien/weeds/node/pylon/cluster/weed_node = new node_type(loc, null, null, hive_owner)
	weed_node.resin_parent = src
