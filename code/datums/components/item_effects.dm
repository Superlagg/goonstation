/// Just plonk some of these on an item and it'll be recognized as a thing that does that thing
/datum/component/item_effect
/datum/component/item_effect/Initialize()
	if(!istype(parent, /obj/item))
		return COMPONENT_INCOMPATIBLE

/// Sets things on fire if its on and not broken, or set to always work
/datum/component/item_effect/burn_simple
	var/always_works
/datum/component/item_effect/burn_simple/Initialize(var/always_works = 0)
	..()
	src.always_works = always_works
	RegisterSignal(parent, list(COMSIG_ITEM_ATTACK_OBJECT), .proc/burn_simple_check)

/datum/component/item_effect/burn_simple/proc/burn_simple_check(var/obj/item/that, var/obj/item/this, var/mob/user, var/use_amt = 0, var/noisy = 0)
	if (!that || !this) return ITEM_EFFECT_NOTHING

	if ((this.flags & THING_IS_ON && this.flags & ~THING_IS_BROKEN) || always_works)
		return ITEM_EFFECT_BURN
	else
		return ITEM_EFFECT_NOTHING

/datum/component/item_effect/burn_simple/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_OBJECT)
	. = ..()

/// Sets things on fire, but can do other things, like consume fuel, weld things, and cauterize
/datum/component/item_effect/burn_fueled
	/// list("chemID" = list("default_use" = amt2useByDefault, "use_mult" = amt2useMultiplier, "burns_eyes" = BurnsEyes?, "sounds" = list('sounds2play','whenUweld')))
	var/list/fuel_table
	var/always_works
	var/do_welding

/datum/component/item_effect/burn_fueled/Initialize(var/list/fuel_table, var/do_welding = 0, var/always_works = 0)
	..()
	src.fuel_table = fuel_table
	src.do_welding = do_welding
	src.always_works = always_works
	RegisterSignal(parent, list(COMSIG_ITEM_ATTACK_OBJECT), .proc/try_to_burn)

/datum/component/item_effect/burn_fueled/proc/try_to_burn(var/obj/item/that, var/obj/item/this, var/mob/user, var/use_amt = 0, var/noisy = 0)
	if (!that || !this || (!src.fuel_table && !src.always_works)) return ITEM_EFFECT_NOTHING
	if (src.do_welding) . |= ITEM_EFFECT_WELD
	if (src.always_works) . |= ITEM_EFFECT_BURN
	else if (this.reagents && this.flags & THING_IS_ON && this.flags & ~THING_IS_BROKEN)
		var/loaded_fuel
		for (var/chem_id in src.fuel_table)
			if (this?.reagents.has_reagent(chem_id))
				loaded_fuel = chem_id
				break
		if (!loaded_fuel) return ITEM_EFFECT_NOTHING // Whatever's in there, we can't use it
		var/fuel_amt = this?.reagents.get_reagent_amount(loaded_fuel)
		if(!fuel_amt) return ITEM_EFFECT_NOTHING // we don't have any fuel
		var/amt_2_use = (use_amt * fuel_table[loaded_fuel]["use_mult"])

		if ((fuel_amt =- amt_2_use) >= 0)
			this.reagents.remove_reagents(loaded_fuel, amt_2_use)
			. |= ITEM_EFFECT_BURN
		else
			if(user)
				boutput(user, "<span class='notice'>Need more fuel!</span>")
			return ITEM_EFFECT_NOTHING //welding, doesnt have fuel
		this.?inventory_counter.update_number(this.reagents.get_reagent_amount(loaded_fuel))

		if(user && noisy && fuel_table[loaded_fuel]["sounds"].len)
			var/where_plays_it = user ? user.loc : this.loc
			playsound(where_plays_it, pick(fuel_table[loaded_fuel]["sounds"]), 50, 1)
		if(user && fuel_table[loaded_fuel]["burns_eyes"])
			if(!user.isBlindImmune())
				var/safety = 0
				if (ishuman(user))
					var/mob/living/carbon/human/H = user
					// we want to check for the thermals first so having a polarized eye doesn't protect you if you also have a thermal eye
					if (istype(H.glasses, /obj/item/clothing/glasses/thermal) || H.eye_istype(/obj/item/organ/eye/cyber/thermal) || istype(H.glasses, /obj/item/clothing/glasses/nightvision) || H.eye_istype(/obj/item/organ/eye/cyber/nightvision))
						safety = -1
					else if (istype(H.head, /obj/item/clothing/head/helmet/welding))
						var/obj/item/clothing/head/helmet/welding/WH = H.head
						if(!WH.up)
							safety = 2
						else
							safety = 0
					else if (istype(H.head, /obj/item/clothing/head/helmet/space))
						safety = 2
					else if (istype(H.glasses, /obj/item/clothing/glasses/sunglasses) || H.eye_istype(/obj/item/organ/eye/cyber/sunglass))
						safety = 1
				switch (safety)
					if (1)
						boutput(usr, "<span class='alert'>Your eyes sting a little.</span>")
						user.take_eye_damage(rand(1, 2))
					if (0)
						boutput(usr, "<span class='alert'>Your eyes burn.</span>")
						user.take_eye_damage(rand(2, 4))
					if (-1)
						boutput(usr, "<span class='alert'><b>Your goggles intensify the welder's glow. Your eyes itch and burn severely.</b></span>")
						user.change_eye_blurry(rand(12, 20))
						user.take_eye_damage(rand(12, 16))
	return

/datum/component/item_effect/burn_fueled/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_OBJECT)
	. = ..()
