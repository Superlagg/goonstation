/obj/item/organ/liver
	name = "liver"
	organ_name = "liver"
	desc = "Ew, this thing is just the wurst."
	organ_holder_name = "liver"
	organ_holder_location = "chest"
	organ_holder_required_op_stage = 3.0
	icon_state = "liver"
	failure_disease = /datum/ailment/disease/liver_failure

	on_life(var/mult = 1)
		if (!..())
			return 0
		if (src.get_damage() >= FAIL_DAMAGE && prob(src.get_damage() * 0.2))
			donor.contract_disease(failure_disease,null,null,1)
		return 1

	on_broken(var/mult = 1)
		donor.take_toxin_damage(2*mult, 1)

	disposing()
		if (holder)
			if (holder.liver == src)
				holder.liver = null
		..()

/obj/item/organ/liver/cyber
	name = "cyberliver"
	desc = "A fancy robotic liver to replace one that someone's lost!"
	icon_state = "cyber-liver"
	// item_state = "heart_robo1"
	robotic = 1
	edible = 0
	mats = 6
	var/overloading = 0

	emag_act(mob/user, obj/item/card/emag/E)
		. = ..()
		organ_abilities = list(/datum/targetable/organAbility/liverdetox)

	demag(mob/user)
		..()
		organ_abilities = initial(organ_abilities)

	on_life(var/mult = 1)
		if(!..())
			return 0
		if(overloading)
			if(donor.reagents.get_reagent_amount("ethanol") >= 5 * mult)
				donor.reagents.remove_reagent("ethanol", 5 * mult)
				donor.reagents.add_reagent("omnizine", 0.4 * mult)
				src.take_damage(0, 0, 3 * mult)
			else
				donor.reagents.remove_reagent("ethanol", 5 * mult)
				if(prob(20))
					boutput(donor, "<span class='alert'>You feel painfully sober.</span>")
				else if(prob(25)) //20% total
					boutput(donor, "<span class='alert'>You feel a burning in your liver!</span>")
					src.take_damage(2 * mult, 2 * mult, 0)
		return 1

	breakme()
		. = ..()
		overloading = 0

	on_removal()
		. = ..()
		overloading = 0

/obj/item/organ/liver/lizard
	name = "lizard liver"
	desc = "A large, colorful, wiggling chunk that resembles a human liver. "
	icon_state = "liver"
	robotic = 0
	edible = 1
	mats = 6
	var/liver_color = "#FFFFFF"

	New()
		. = ..()
		if(donor?.bioHolder.mobAppearance.customization_first_color)
			src.liver_color = donor.bioHolder.mobAppearance.customization_first_color
		else
			src.liver_color = rgb(rand(50,190), rand(50,190), rand(50,190))
		if(prob(10))
			src.name = "livard liver"

	attack_self(mob/user as mob)
		boutput(user, "You squeeze \the [src].")
		if (user.bodytemperature)
			var/organ_flavor
			var/organ_adverb
			if (prob(1))
				var/pop_type = pick("explodes", "pops", "bursts")
				var/like_what = pick("a zit", "a water balloon", "a liver", "a burrito")
				var/filled_with_what = pick("Discount Dan's", "blood", "gore", "pizza sauce", "...hair?", "liver meat")
				user.visible_message("<span class='alert'><b>[user]</b> squeezes \the [src] too hard! It [pop_type] like [like_what] filled with [filled_with_what]!</span>")
				playsound(src.loc, "sound/impact_sounds/Slimy_Splat_1.ogg", 50, 1)
				var/obj/decal/cleanable/vomit/splught = make_cleanable(/obj/decal/cleanable/vomit, donor.loc)
				splught.color = src.liver_color
				user.u_equip(src)
				qdel(src)
				return
			else if (user.bodytemperature > user.base_body_temp + 20)
				organ_adverb = pick("energetically", "unpleasantly", "audibly", "rapidly")
				organ_flavor = pick("jiggles", "twitches", "vibrates", "beats")
				boutput(user, "\The [src] [organ_flavor] [organ_adverb]!")
			else if (user.bodytemperature < user.base_body_temp - 20)
				organ_adverb = pick("slowly", "lethargically", "lazily", "sadly")
				organ_flavor = pick("shifts", "sighs", "spluts", "slumps")
				boutput(user, "\The [src] [organ_flavor] [organ_adverb]...")
			else
				organ_adverb = pick("happily", "contentedly")
				organ_flavor = pick("squaps", "flollops", "pulses", "flups")
				boutput(user, "\The [src] [organ_flavor] [organ_adverb]...?")
		. = ..()

	on_transplant(mob/M)
		. = ..()
		if(!broken)
			APPLY_MOB_PROPERTY(M, PROP_TEMP_CHEM_EFFECTS, src)

	on_removal()
		. = ..()
		REMOVE_MOB_PROPERTY(src.donor, PROP_TEMP_CHEM_EFFECTS, src)
