/obj/item/device/light/sparkler
	name = "sparkler"
	desc = "Be careful not to start a fire!"
	icon = 'icons/obj/items/sparklers.dmi'
	icon_state = "sparkler-off"
	icon_on = "sparkler-on"
	icon_off = "sparkler-off"
	inhand_image_icon = 'icons/obj/items/sparklers.dmi'
	item_state = "sparkler-off"
	var/item_on = "sparkler-on"
	var/item_off = "sparkler-off"
	w_class = 1
	density = 0
	anchored = 0
	opacity = 0
	col_r = 0.7
	col_g = 0.3
	col_b = 0.3
	var/sparks = 7
	var/burnt = 0


	New()
		src.AddComponent(/datum/component/item_effect/burn_things, needs_fuel = 0, do_welding = 0, burns_eyes = 1)
		..()

	attack_self(mob/user as mob)
		if (src.flags & THING_IS_ON)
			var/fluff = pick("snuff", "blow")
			user.visible_message("<b>[user]</b> [fluff]s out [src].",\
			"You [fluff] out [src].")
			src.put_out(user)

	attackby(obj/item/W as obj, mob/user as mob)
		if (src.flags & ~THING_IS_ON && src.flags & ~THING_IS_BROKEN && sparks)
			var/list/burn_return = list(HAS_EFFECT = ITEM_EFFECT_NOTHING, EFFECT_RESULT = ITEM_EFFECT_FAILURE)
			SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_OBJECT, this = W, user = user, results = burn_return, use_amt = 1, noisy = 1)
			if(burn_return[HAS_EFFECT] & ITEM_EFFECT_BURN || W.burning || W.hit_type == DAMAGE_BURN)
				if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NO_FUEL)
					boutput(user, "<span class='notice'>\the [W] is out of fuel!</span>")
				else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ENOUGH_FUEL)
					boutput(user, "<span class='notice'>\the [W] doesn't have enough fuel!</span>")
				else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ON)
					boutput(user, "<span class='notice'>\the [W] isn't lit!</span>")
				else if(burn_return[HAS_EFFECT] & ITEM_EFFECT_WELD)
					src.light(user, "<span class='alert'><b>[user]</b> casually lights [src] with [W], what a badass.</span>")
				else if (istype(W, /obj/item/clothing/head/cakehat))
					src.light(user, "<span class='alert'>Did [user] just light \his [src] with [W]? Holy Shit.</span>")
				else if (istype(W, /obj/item/device/igniter))
					src.light(user, "<span class='alert'><b>[user]</b> fumbles around with [W]; sparks erupt from [src].</span>")
				else if (istype(W, /obj/item/device/light/zippo))
					src.light(user, "<span class='alert'>With a single flick of their wrist, [user] smoothly lights [src] with [W]. Damn they're cool.</span>")
				else if (istype(W, /obj/item/match) || istype(W, /obj/item/device/light/candle))
					src.light(user, "<span class='alert'><b>[user] lights [src] with [W].</span>")
				else if (W.burning)
					src.light(user, "<span class='alert'><b>[user]</b> lights [src] with [W]. Goddamn.</span>")
				else
					src.light(user, "<span class='alert'><b>[user]</b> lights [src] with [W].</span>")
		else
			return ..()

	temperature_expose(datum/gas_mixture/air, temperature, volume)
		if((temperature > T0C+400))
			src.light()
		..()

	process()
		if (src.flags & THING_IS_ON)
			var/turf/location = src.loc
			if (ismob(location))
				var/mob/M = location
				if (M.find_in_hand(src))
					location = M.loc
			var/turf/T = get_turf(src.loc)
			if (T)
				T.hotspot_expose(700,5)

			if(prob(66))
				src.gen_sparks()

	proc/gen_sparks()
		src.sparks--
		elecflash(src)
		if(!sparks)
			src.put_out()
			src.burnt = 1
			src.name = "burnt-out sparkler"
			src.icon_state = "sparkler-burnt"
			src.item_state = "sparkler-burnt"
			var/mob/M = src.loc
			if(istype(M))
				M.update_inhands()
		return

	proc/light(var/mob/user as mob, var/message as text)
		if (!src) return
		if (burnt) return
		if (src.flags & ~THING_IS_ON)
			logTheThing("combat", user, null, "lights the [src] at [log_loc(src)].")
			src.flags |= THING_IS_ON
			src.hit_type = DAMAGE_BURN
			src.force = 3
			src.icon_state = src.icon_on
			src.item_state = src.item_on
			light.enable()
			processing_items |= src
			if(user)
				user.update_inhands()
		return

	proc/put_out(var/mob/user as mob)
		if (!src) return
		if (src.flags & THING_IS_ON)
			src.flags &= ~THING_IS_ON
			src.hit_type = DAMAGE_BLUNT
			src.force = 0
			src.icon_state = src.icon_off
			src.item_state = src.item_off
			light.disable()
			processing_items -= src
			if(user)
				user.update_inhands()
		return

/obj/item/storage/sparkler_box
	name = "sparkler box"
	desc = "Have fun!"
	icon = 'icons/obj/items/sparklers.dmi'
	icon_state = "sparkler_box-close"
	max_wclass = 1
	slots = 5
	spawn_contents = list(/obj/item/device/light/sparkler,/obj/item/device/light/sparkler,/obj/item/device/light/sparkler,/obj/item/device/light/sparkler,/obj/item/device/light/sparkler)
	var/open = 0

	attack_hand(mob/user as mob)
		if (src.loc == user && (!does_not_open_in_pocket || src == user.l_hand || src == user.r_hand))
			if(src.open)
				..()
			else
				src.open = 1
				src.icon_state = "sparkler_box-open"
				playsound(src.loc, "sound/impact_sounds/Generic_Snap_1.ogg", 20, 1, -2)
				boutput(usr, "<span class='notice'>You snap open the child-protective safety tape on [src].</span>")
		else
			..()

	attack_self(mob/user as mob)
		if(src.open)
			..()
		else
			src.open = 1
			src.icon_state = "sparkler_box-open"
			playsound(src.loc, "sound/impact_sounds/Generic_Snap_1.ogg", 20, 1, -2)
			boutput(usr, "<span class='notice'>You snap open the child-protective safety tape on [src].</span>")

	MouseDrop(atom/over_object, src_location, over_location)
		if(!src.open)
			if (over_object == usr && in_range(src, usr) && isliving(usr) && !usr.stat)
				return
			if (usr.is_in_hands(src))
				return
		..()
