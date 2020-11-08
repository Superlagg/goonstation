/// Just plonk some of these on an item and it'll be recognized as a thing that does that thing
/datum/component/item_effect
/datum/component/item_effect/Initialize()
	if(!istype(parent, /obj/item))
		return COMPONENT_INCOMPATIBLE

/datum/component/item_effect/proc/is_it_on(var/obj/item/thing)
	if (!thing) return FALSE

	if (thing.flags & THING_IS_ON && thing.flags & ~THING_IS_BROKEN)
		return TRUE
	else
		return FALSE

/// Sets things on fire, but can do other things, like consume fuel, weld things, and blind people
/datum/component/item_effect/burn_things
	var/needs_fuel
	var/do_welding
	var/burns_eyes
	var/list/sounds_2_play
	/// list("chemID" = "chemID", "default_use" = amt2useByDefault, "use_mult" = amt2useMultiplier)
	var/list/fuel_2_use

/// src.AddComponent(/datum/component/item_effect/burn_things, needs_fuel = 1, do_welding = 1, burns_eyes = src.burns_eyes, fuel_2_use = src.fueltype, sounds_2_play = src.sounds)
/datum/component/item_effect/burn_things/Initialize(var/needs_fuel = 0, var/do_welding = 0, var/burns_eyes, var/list/fuel_2_use, var/list/sounds_2_play)
	..()
	src.do_welding = do_welding
	src.fuel_2_use = fuel_2_use
	src.needs_fuel = needs_fuel
	src.burns_eyes = burns_eyes
	src.sounds_2_play = sounds_2_play
	RegisterSignal(parent, list(COMSIG_ITEM_ATTACK_OBJECT), .proc/try_to_burn)

/datum/component/item_effect/burn_things/proc/try_to_burn(var/obj/item/that, var/obj/item/this, var/mob/user, var/list/results, var/use_amt = 0, var/noisy = 0)
	if (!that || !this)
		results = list(HAS_EFFECT = ITEM_EFFECT_NOTHING, EFFECT_RESULT = ITEM_EFFECT_FAILURE)
		return

	results[HAS_EFFECT] |= ITEM_EFFECT_BURN
	if (src.do_welding)
		results[HAS_EFFECT] |= ITEM_EFFECT_WELD

	if(!src.is_it_on(this))
		results[EFFECT_RESULT] |= ITEM_EFFECT_NOT_ON
		return

	if (src.needs_fuel)
		var/fuel_amt = this?.reagents.get_reagent_amount(fuel_2_use["fuel"])
		if(!fuel_amt)
			results[EFFECT_RESULT] |= ITEM_EFFECT_NO_FUEL
			return

		var/amt_2_use = (use_amt * fuel_2_use["use_mult"])
		if ((fuel_amt =- amt_2_use) >= 0)
			this.reagents.remove_reagent(fuel_2_use["use_mult"], amt_2_use)
			this?.inventory_counter.update_number(this.reagents.get_reagent_amount(fuel_2_use["use_mult"]))
			results[EFFECT_RESULT] |= ITEM_EFFECT_SUCCESS
		else
			results[EFFECT_RESULT] |= ITEM_EFFECT_NOT_ENOUGH_FUEL
			return

	if(noisy && src.sounds_2_play)
		playsound(user ? user.loc : this.loc, pick(src.sounds_2_play), 50, 1)

	if(user && src.burns_eyes)
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

/datum/component/item_effect/burn_things/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ITEM_ATTACK_OBJECT)
	. = ..()
