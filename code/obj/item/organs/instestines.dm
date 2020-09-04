/obj/item/organ/intestines
	name = "intestines"
	organ_name = "intestines"
	desc = "Did you know that if you laid your guts out in a straight line, they'd be about 9 meters long? Also, you'd probably be dying, so it's not something you should do. Probably."
	organ_holder_name = "intestines"
	organ_holder_location = "chest"
	organ_holder_required_op_stage = 4.0
	icon_state = "intestines"
	var/digestion_efficiency = 1

	// on_transplant()
	// 	..()
	// 	if (src.donor)
	// 		for (var/datum/ailment_data/disease in src.donor.ailments)
	// 			if (disease.cure == "Intestine Transplant")
	// 				src.donor.cure_disease(disease)
	// 		return

	on_transplant(mob/M)
		. = ..()
		if(!broken)
			APPLY_MOB_PROPERTY(M, PROP_DIGESTION_EFFICIENCY, src, digestion_efficiency)

	on_removal()
		. = ..()
		REMOVE_MOB_PROPERTY(src.donor, PROP_DIGESTION_EFFICIENCY, src)

	unbreakme()
		..()
		if(donor)
			APPLY_MOB_PROPERTY(src.donor, PROP_DIGESTION_EFFICIENCY, src, digestion_efficiency)

	breakme()
		..()
		if(donor)
			REMOVE_MOB_PROPERTY(src.donor, PROP_DIGESTION_EFFICIENCY, src)

	disposing()
		if (holder)
			if (holder.intestines == src)
				holder.intestines = null
		..()

/obj/item/organ/intestines/cyber
	name = "cyberintestines"
	desc = "A fancy robotic intestines to replace one that someone's lost!"
	icon_state = "cyber-intestines"
	// item_state = "heart_robo1"
	robotic = 1
	edible = 0
	mats = 6

	emag_act(mob/user, obj/item/card/emag/E)
		. = ..()
		organ_abilities = list(/datum/targetable/organAbility/quickdigest)

	demag(mob/user)
		..()
		organ_abilities = initial(organ_abilities)

	attackby(obj/item/W, mob/user)
		if(ispulsingtool(W)) //TODO kyle's robotics configuration console/machine/thing
			digestion_efficiency = input(user, "Set the digestion efficiency of the cyberintestines, from 0 to 200 percent.", "Digenstion efficincy", "100") as num
			digestion_efficiency = clamp(digestion_efficiency, 0, 200) / 100
		else
			. = ..()

/obj/item/organ/intestines/lizard
	name = "lizard intestines"
	desc = " wadded up length of fleshy tubing. As disgusting as it is colorful."
	icon_state = "intestines"
	robotic = 0
	edible = 0
	mats = 6
	var/gut_color = "#FFFFFF"
	var/squozen = 0

	New()
		. = ..()
		if(donor?.bioHolder.mobAppearance.customization_first_color)
			src.gut_color = donor.bioHolder.mobAppearance.customization_first_color
		else
			src.gut_color = rgb(rand(50,190), rand(50,190), rand(50,190))

	get_desc()
		. = ..()
		var/post_desc = .
		var/pre_desc
		if(prob(50))
			pre_desc = "A snake! Wait, no..."
		. = pre_desc + post_desc

	attack_self(mob/user as mob)
		boutput(user, "You pet \the [src].")
		if (user.bodytemperature)
			var/organ_flavor
			var/organ_adverb
			if (prob(1) && !src.squozen)
				var/yartz = pick("spews", "pukes", "horks", "yartzes")
				var/yarts_type = pick("spew", "puke", "hork", "yartz")
				var/what_they_ate = pick("Discount Dan's", "blood", "pizza", "hair", "yartz")
				var/when_they_ate_it = pick("lunch", "breakfast", "brunch", "dinner")
				user.visible_message("<span class='alert'><b>[user]</b> pets \the [src]. It spasms and [yartz] [yarts_type] all over the place! Looks like the previous owner had [what_they_ate] for [when_they_ate_it]...</span>")
				playsound(src.loc, "sound/impact_sounds/Slimy_Splat_1.ogg", 50, 1)
				if(what_they_ate == "blood")
					make_cleanable(/obj/decal/cleanable/blood, donor.loc)
				else
					var/obj/decal/cleanable/vomit/splught = make_cleanable(/obj/decal/cleanable/vomit, donor.loc)
					splught.color = src.gut_color
			if (user.bodytemperature > user.base_body_temp + 20)
				organ_adverb = pick("energetically", "unpleasantly", "audibly", "rapidly")
				organ_flavor = pick("jiggles", "twitches", "vibrates", "wiggles", "drips")
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
			M.AddComponent(/datum/component/consume/organpoints, /datum/abilityHolder/lizard)
		src.squozen = 0

	on_removal()
		. = ..()
		var/datum/component/C = src.donor.GetComponent(/datum/component/consume/organpoints)
		C?.RemoveComponent(/datum/component/consume/organpoints)
		src.squozen = 0

/obj/item/organ/intestines/werewolf
	name = "lupine intestines"
	desc = "A striking length of werewolf intestines. Very thick and leathery, designed to pull nutrients out of just about <i>anything</i>."
	icon_state = "intestines"
	robotic = 0
	edible = 1
	mats = 6

	on_transplant(mob/M)
		. = ..()
		if(!broken)
			M.AddComponent(/datum/component/consume/organheal)

	on_removal()
		. = ..()
		var/datum/component/C = donor.GetComponent(/datum/component/consume/organheal)
		C?.RemoveComponent(/datum/component/consume/organheal)

	unbreakme()
		..()
		if(donor)
			donor.AddComponent(/datum/component/consume/organheal)

	breakme()
		..()
		if(donor)
			var/datum/component/C = donor.GetComponent(/datum/component/consume/organheal)
			C?.RemoveComponent(/datum/component/consume/organheal)
