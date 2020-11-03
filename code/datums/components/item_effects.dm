///
/datum/component/item_effect
/datum/component/item_effect/Initialize()
	if(!istype(parent, /obj))
		return COMPONENT_INCOMPATIBLE

/datum/component/item_effect/burn_simple
/datum/component/item_effect/burn_simple/Initialize()
	..()
	RegisterSignal(parent, list(COMSIG_ITEM_ATTACK_OTHER_ITEM), .proc/can_we_burn_it)

/datum/component/item_effect/burn_simple/proc/can_we_burn_it(var/mob/M, var/mob/user, var/obj/item/I)

/datum/component/item_effect/burn_simple/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_OTHER_ITEM)
	. = ..()

/datum/component/item_effect/burn_welder

/datum/component/item_effect/burn_welder/Initialize()
	..()
	RegisterSignal(parent, list(COMSIG_ITEM_ATTACK_OTHER_ITEM), .proc/eat_organ_get_points)

/datum/component/item_effect/burn_welder/proc/eat_organ_get_points(var/mob/M, var/mob/user, var/obj/item/I)

/datum/component/item_effect/burn_welder/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_OTHER_ITEM)
	. = ..()

