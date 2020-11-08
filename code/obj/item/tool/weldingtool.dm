/obj/item/weldingtool
	name = "weldingtool"
	desc = "A tool that, when turned on, uses fuel to emit a concentrated flame, welding metal together or slicing it apart."
	icon = 'icons/obj/items/tools/weldingtool.dmi'
	inhand_image_icon = 'icons/mob/inhand/tools/weldingtool.dmi'
	icon_state = "weldingtool-off"
	item_state = "weldingtool-off"
	uses_multiple_icon_states = 1

	var/icon_state_variant_suffix = null
	var/item_state_variant_suffix = null

	var/status = 0 // flamethrower construction :shobon:
	flags = FPRINT | TABLEPASS | CONDUCT | ONBELT
	tool_flags = TOOL_WELDING
	force = 3.0
	throwforce = 5.0
	throw_speed = 1
	throw_range = 5
	w_class = 2.0
	m_amt = 30
	g_amt = 30
	stamina_damage = 30
	stamina_cost = 18
	stamina_crit_chance = 5
	module_research = list("tools" = 4, "metals" = 1, "fuels" = 5)
	rand_pos = 1
	inventory_counter_enabled = 1
	/// list("chemID" = "chemID", "default_use" = amt2useByDefault, "use_mult" = amt2useMultiplier)
	var/list/fueltype = list("fuel" = "fuel", "default_use" = 1, "use_mult" = 1)
	/// How much fuel can it hold?
	var/capacity = 20
	/// Does it try to cause eye damage to its user?
	var/burns_eyes = 1
	/// Which sounds to play when it gets used successfully
	var/list/sounds = list('sound/items/Welder.ogg', 'sound/items/Welder2.ogg')

	New()
		..()
		src.AddComponent(/datum/component/item_effect/burn_things, needs_fuel = 1, do_welding = 1, burns_eyes = src.burns_eyes, fuel_2_use = src.fueltype, sounds_2_play = src.sounds)
		src.create_reagents(src.capacity)
		src.reagents.add_reagent(src.fueltype["fuel"], src.capacity)
		src.inventory_counter.update_number(src.reagents.total_volume)
		src.setItemSpecial(/datum/item_special/flame)
		return

	examine()
		. = ..()
		. += "It has [src.reagents.total_volume] units of fuel left!"

	attack(mob/living/carbon/M as mob, mob/living/carbon/user as mob)
		if (src.flags & ~THING_IS_ON)
			if (!src.cautery_surgery(M, user, 0, src.flags & THING_IS_ON ? 1 : 0))
				return ..()
		if (!ismob(M))
			return
		src.add_fingerprint(user)
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.bleeding || (H.butt_op_stage == 4 && user.zone_sel.selecting == "chest"))
				if (!src.cautery_surgery(H, user, 15, src.flags & THING_IS_ON ? 1 : 0))
					return ..()
			else if (user.zone_sel.selecting != "chest" && user.zone_sel.selecting != "head")
				if (!H.limbs.vars[user.zone_sel.selecting])
					switch (user.zone_sel.selecting)
						if ("l_arm")
							if (H.limbs.l_arm_bleed) cauterise("l_arm")
							else
								boutput(user, "<span class='alert'>[H.name]'s left arm stump is not bleeding!</span>")
								return
						if ("r_arm")
							if (H.limbs.r_arm_bleed) cauterise("r_arm")
							else
								boutput(user, "<span class='alert'>[H.name]'s right arm stump is not bleeding!</span>")
								return
						if ("l_leg")
							if (H.limbs.l_leg_bleed) cauterise("l_leg")
							else
								boutput(user, "<span class='alert'>[H.name]'s left leg stump is not bleeding!</span>")
								return
						if ("r_leg")
							if (H.limbs.r_leg_bleed) cauterise("r_leg")
							else
								boutput(user, "<span class='alert'>[H.name]'s right leg stump is not bleeding!</span>")
								return
						else return ..()
				else
					if (!(locate(/obj/machinery/optable, M.loc) && M.lying) && !(locate(/obj/table, M.loc) && (M.getStatusDuration("paralysis") || M.stat)) && !(M.reagents && M.reagents.get_reagent_amount("ethanol") > 10 && M == user))
						return ..()
					// TODO: what is this line?
					if (istype(H.limbs.l_leg, /obj/item/parts/robot_parts/leg/treads)) attach_robopart("treads")
					else
						switch (user.zone_sel.selecting)
							if ("l_arm")
								if (istype(H.limbs.l_arm,/obj/item/parts/robot_parts) && H.limbs.l_arm.remove_stage > 0) attach_robopart("l_arm")
								else
									boutput(user, "<span class='alert'>[H.name]'s left arm doesn't need welding on!</span>")
									return
							if ("r_arm")
								if (istype(H.limbs.r_arm,/obj/item/parts/robot_parts) && H.limbs.r_arm.remove_stage > 0) attach_robopart("r_arm")
								else
									boutput(user, "<span class='alert'>[H.name]'s right arm doesn't need welding on!</span>")
									return
							if ("l_leg")
								if (istype(H.limbs.l_leg,/obj/item/parts/robot_parts) && H.limbs.l_leg.remove_stage > 0) attach_robopart("l_leg")
								else
									boutput(user, "<span class='alert'>[H.name]'s left leg doesn't need welding on!</span>")
									return
							if ("r_leg")
								if (istype(H.limbs.r_leg,/obj/item/parts/robot_parts) && H.limbs.r_leg.remove_stage > 0) attach_robopart("r_leg")
								else
									boutput(user, "<span class='alert'>[H.name]'s right leg doesn't need welding on!</span>")
									return
							else return ..()
			else return ..()

	attackby(obj/item/W as obj, mob/user as mob)
		if (isscrewingtool(W))
			if (status)
				status = 0
				boutput(user, "<span class='notice'>You resecure the welder.</span>")
			else
				status = 1
				boutput(user, "<span class='notice'>The welder can now be attached and modified.</span>")

		else if (status == 1 && istype(W,/obj/item/rods))
			if (src.loc != user)
				boutput(user, "<span class='alert'>You need to be holding [src] to work on it!</span>")
				return
			var/obj/item/rods/R = new /obj/item/rods
			R.amount = 1
			var/obj/item/rods/S = W
			S.amount = S.amount - 1
			if (S.amount == 0)
				qdel(S)
			var/obj/item/assembly/weld_rod/F = new /obj/item/assembly/weld_rod( user )
			src.set_loc(F)
			F.welder = src
			user.u_equip(src)
			user.put_in_hand_or_drop(F)
			R.master = F
			src.master = F
			src.layer = initial(src.layer)
			user.u_equip(src)
			src.set_loc(F)
			F.rod = R
			src.add_fingerprint(user)

	afterattack(obj/O as obj, mob/user as mob)
		if ((istype(O, /obj/reagent_dispensers/fueltank) || istype(O, /obj/item/reagent_containers/food/drinks/fueltank)) && get_dist(src,O) <= 1)
			if (O.reagents.total_volume)
				O.reagents.trans_to(src, capacity)
				src.inventory_counter.update_number(get_fuel())
				boutput(user, "<span class='notice'>Welder refueled</span>")
				playsound(src.loc, "sound/effects/zzzt.ogg", 50, 1, -6)
			else
				boutput(user, "<span class='alert'>The [O.name] is empty!</span>")
		else if (src.flags & THING_IS_ON)
			if (get_fuel() <= 0)
				boutput(usr, "<span class='notice'>Need more fuel!</span>")
				src.flags &= ~THING_IS_ON
				src.force = 3
				hit_type = DAMAGE_BLUNT
				set_icon_state("weldingtool-off" + src.icon_state_variant_suffix)
				src.item_state = "weldingtool-off" + src.item_state_variant_suffix
				user.update_inhands()
			var/turf/location = user.loc
			if (istype(location, /turf))
				location.hotspot_expose(700, 50, 1)
			if (O && !ismob(O) && O.reagents)
				boutput(usr, "<span class='notice'>You heat \the [O.name]</span>")
				O.reagents.temperature_reagents(2500,10)
		return

	attack_self(mob/user as mob)
		if (status > 1) return
		src.flags ^= THING_IS_ON
		if (src.flags & THING_IS_ON)
			if (get_fuel() <= 0)
				boutput(user, "<span class='notice'>Need more fuel!</span>")
				src.flags &= ~THING_IS_ON
				return 0
			boutput(user, "<span class='notice'>You will now weld when you attack.</span>")
			src.force = 15
			hit_type = DAMAGE_BURN
			set_icon_state("weldingtool-on" + src.icon_state_variant_suffix)
			src.item_state = "weldingtool-on" + src.item_state_variant_suffix
			processing_items |= src
		else
			boutput(user, "<span class='notice'>Not welding anymore.</span>")
			src.force = 3
			hit_type = DAMAGE_BLUNT
			set_icon_state("weldingtool-off" + src.icon_state_variant_suffix)
			src.item_state = "weldingtool-off" + src.item_state_variant_suffix
		user.update_inhands()
		return

	blob_act(var/power)
		if (prob(power * 0.5))
			qdel(src)

	temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
		if (exposed_temperature > 1000)
			return ..()
		return

	process()
		if(src.flags & ~THING_IS_ON)
			processing_items.Remove(src)
			return
		var/turf/location = src.loc
		if (ismob(location))
			var/mob/M = location
			if (M.l_hand == src || M.r_hand == src)
				location = M.loc
		if (istype(location, /turf))
			location.hotspot_expose(700, 5)
		if (prob(10))
			use_fuel(1)
			if (!get_fuel())
				src.flags &= ~THING_IS_ON
				force = 3
				hit_type = DAMAGE_BLUNT
				set_icon_state("weldingtool-off" + src.icon_state_variant_suffix)
				src.item_state = "weldingtool-off" + src.item_state_variant_suffix
				processing_items.Remove(src)
				return

	proc/get_fuel()
		if (reagents)
			return reagents.get_reagent_amount("fuel")

	proc/use_fuel(var/amount)
		amount = min(get_fuel(), amount)
		if (reagents)
			reagents.remove_reagent("fuel", amount)
		src.inventory_counter.update_number(get_fuel())
		return


	proc/cauterise(mob/living/carbon/human/H as mob, mob/living/carbon/user as mob, var/part)
		if(!istype(H)) return
		if(!istype(user)) return
		if(!part) return

		var/variant = H.bioHolder.HasEffect("lost_[part]")
		if (!variant) return

		var/list/burn_return = list(HAS_EFFECT = ITEM_EFFECT_NOTHING, EFFECT_RESULT = ITEM_EFFECT_FAILURE)
		SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_OBJECT, this = src, user = user, results = burn_return, use_amt = 1, noisy = 1)
		if(burn_return[HAS_EFFECT] & ITEM_EFFECT_BURN || src.burning || src.hit_type == DAMAGE_BURN)
			if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NO_FUEL)
				boutput(user, "<span class='notice'>\the [src] is out of fuel!</span>")
			else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ENOUGH_FUEL)
				boutput(user, "<span class='notice'>\the [src] doesn't have enough fuel!</span>")
			else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ON)
				boutput(user, "<span class='notice'>\the [src] isn't lit!</span>")
			else
				H.TakeDamage("chest",0,20)
				if (prob(50)) H.emote("scream")

				variant = max(1, variant-20)
				H.bioHolder.RemoveEffect("lost_[part]")
				H.bioHolder.AddEffect("lost_[part]", variant)

				for (var/mob/O in AIviewers(H, null))
					if (O == (user || H))
						continue
					if (H == user)
						O.show_message("<span class='alert'>[user.name] cauterises their own stump with [src]!</span>", 1)
					else
						O.show_message("<span class='alert'>[H.name] has their stump cauterised by [user.name] with [src].</span>", 1)

				if(H != user)
					boutput(H, "<span class='alert'>[user.name] cauterises your stump with [src].</span>")
					boutput(user, "<span class='alert'>You cauterise [H.name]'s stump with [src].</span>")
				else
					boutput(user, "<span class='alert'>You cauterise your own stump with [src].</span>")

	proc/attach_robopart(mob/living/carbon/human/H as mob, mob/living/carbon/user as mob, var/part)
		if (!istype(H)) return
		if (!istype(user)) return
		if (!part) return

		if (!H.bioHolder.HasEffect("loose_robot_[part]")) return

		var/list/burn_return = list(HAS_EFFECT = ITEM_EFFECT_NOTHING, EFFECT_RESULT = ITEM_EFFECT_FAILURE)
		SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_OBJECT, this = src, user = user, results = burn_return, use_amt = 1, noisy = 1)
		if(burn_return[HAS_EFFECT] & ITEM_EFFECT_BURN || src.burning || src.hit_type == DAMAGE_BURN)
			if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NO_FUEL)
				boutput(user, "<span class='notice'>\the [src] is out of fuel!</span>")
			else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ENOUGH_FUEL)
				boutput(user, "<span class='notice'>\the [src] doesn't have enough fuel!</span>")
			else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ON)
				boutput(user, "<span class='notice'>\the [src] isn't lit!</span>")
			else
				H.TakeDamage("chest",0,20)
				if (prob(50)) H.emote("scream")
				user.visible_message("<span class='alert'>[user.name] welds [H.name]'s robotic part to their stump with [src].</span>", "<span class='alert'>You weld [H.name]'s robotic part to their stump with [src].</span>")
				H.bioHolder.RemoveEffect("loose_robot_[part]")

/obj/item/weldingtool/vr
	icon_state = "weldingtool-off-vr"
	icon_state_variant_suffix = "-vr"

/obj/item/weldingtool/high_cap
	name = "high-capacity weldingtool"
	capacity = 100
