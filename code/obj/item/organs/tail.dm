/// Severed tail images go in 'icons/obj/surgery.dmi'
/// on-mob tail images are defined by organ_image_icon
/// both severed and on-mob tail icon_states are defined by just icon_state
/// try to keep the names the same, or everything breaks

#define TAIL_MONKEY_FLUFF "Jejunum"
#define TAIL_LIZARD_FLUFF "Colon"
#define TAIL_COW_FLUFF "Duodenum"
#define TAIL_NOTCOW_FLUFF "Human"
#define TAIL_WEREWOLF_FLUFF "Trichotic colon"
#define TAIL_SKELETON_FLUFF "Appendix"
#define TAIL_SEAMONKEY_FLUFF "Ileum"
#define TAIL_CAT_FLUFF "Trichotic Jejunum"
#define TAIL_ROACH_FLUFF "Torso"
#define CASH_PER_TAIL_OPTION 100

/obj/item/organ/tail
	name = "tail"
	organ_name = "tail"
	organ_holder_name = "tail"
	organ_holder_location = "chest"	// chest-ish
	organ_holder_required_op_stage = 11.0
	edible = 1
	organ_image_icon = 'icons/mob/werewolf.dmi' // please keep your on-mob tail icon_states with the rest of your mob's sprites
	icon_state = "tail-wolf"
	made_from = "flesh"
	var/tail_num = TAIL_NONE
	var/colorful = 0 // if we need to colorize it
	var/multipart_icon = 0 // if we need to run update_tail_icon
	var/icon_piece_1 = null	// For setting up the icon if its in multiple pieces
	var/icon_piece_2 = null	// Only modifies the dropped icon
	var/failure_ability = "clumsy"	// The organ failure ability associated with this organ.
	var/human_getting_monkeytail = 0	// If a human's getting a monkey tail
	var/monkey_getting_humantail = 0	// If a monkey's getting a human tail
	// vv these get sent to update_body(). no sense having it calculate all this shit multiple times
	var/image/tail_image_1
	var/image/tail_image_2
	var/image/tail_image_oversuit
	var/static/list/tail_styles = list(TAIL_LIZARD_FLUFF = TAIL_LIZARD,\
																		 TAIL_MONKEY_FLUFF = TAIL_MONKEY,\
																		 TAIL_ROACH_FLUFF = TAIL_ROACH,\
																		 TAIL_SKELETON_FLUFF = TAIL_SKELETON)
	var/static/list/tail_styles_extra = list(TAIL_WEREWOLF_FLUFF = TAIL_WEREWOLF,\
																					 TAIL_CAT_FLUFF = TAIL_CAT,\
																					 TAIL_SEAMONKEY_FLUFF = TAIL_SEAMONKEY)
	var/form_setting
	var/color_setting_1
	var/color_setting_2
	var/tail_contents = list("metal" = 0, "cash" = 0, "paint" = 0)
	var/transforming = 0
	var/mob/transformer

	New()
		..()
		if(src.colorful) // Set us some colors
			colorize_tail()
		else
			build_mob_tail_image()
			update_tail_icon()

	/// Grabs colors from the owner's appearance holder or, failing that, makes something up
	proc/colorize_tail(var/datum/appearanceHolder/AHL)
		if(src.colorful)
			if (AHL && istype(AHL, /datum/appearanceHolder))
				src.organ_color_1 = AHL.s_tone
				src.organ_color_2 = AHL.customization_second_color
				src.donor_AH = AHL
			else if (src.donor && ishuman(src.donor))	// Get the colors here so they dont change later, ie reattached on someone else
				src.organ_color_1 = fix_colors(src.donor_AH.customization_first_color)
				src.organ_color_2 = fix_colors(src.donor_AH.customization_second_color)
			else	// Just throw some colors in there or something
				src.organ_color_1 = rgb(rand(50,190), rand(50,190), rand(50,190))
				src.organ_color_2 = rgb(rand(50,190), rand(50,190), rand(50,190))
		build_mob_tail_image()
		update_tail_icon()

	attach_organ(var/mob/living/carbon/M as mob, var/mob/user as mob)
		/* Overrides parent function to handle special case for tails. */
		var/mob/living/carbon/human/H = M

		var/attachment_successful = 0
		var/boned = 0	// Tailbones just kind of pop into place

		if (src.type == /obj/item/organ/tail/monkey && !ismonkey(H))	// If we are trying to attach a monkey tail to a non-monkey
			src.human_getting_monkeytail = 1
			src.monkey_getting_humantail = 0
		else if(src.type != /obj/item/organ/tail/monkey && ismonkey(H))	// If we are trying to attach a non-monkey tail to a monkey
			src.human_getting_monkeytail = 0
			src.monkey_getting_humantail = 1
		else	// Tail is going to someone with a natively compatible butt-height
			src.human_getting_monkeytail = 0
			src.monkey_getting_humantail = 0

		if (!H.organHolder.tail && H.mob_flags & IS_BONER)
			attachment_successful = 1 // Just slap that tailbone in place, its fine
			boned = 1	// No need to sew it up

			var/fluff = pick("slap", "shove", "place", "press", "jam")

			if(istype(src, /obj/item/organ/tail/bone))
				H.tri_message("<span class='alert'><b>[user]</b> [fluff][fluff == "press" ? "es" : "s"] the coccygeal coruna of [src] onto the apex of [H == user ? "[his_or_her(H)]" : "[H]'s"] sacrum![prob(1) ? " The tailbone wiggles happily." : ""]</span>",\
				user, "<span class='alert'>You [fluff] the coccygeal coruna of [src] onto the apex of [H == user ? "your" : "[H]'s"] sacrum![prob(1) ? " The tailbone wiggles happily." : ""]</span>",\
				H, "<span class='alert'>[H == user ? "You" : "<b>[user]</b>"] [fluff][H == user && fluff == "press" ? "es" : "s"] the coccygeal coruna of [src] onto the apex of your sacrum![prob(1) ? " Your tailbone wiggles happily." : ""]</span>")
			else	// Any other tail
				H.tri_message("<span class='alert'><b>[user]</b> [fluff][fluff == "press" ? "es" : "s"] [src] onto the apex of [H == user ? "[his_or_her(H)]" : "[H]'s"] sacrum!</span>",\
				user, "<span class='alert'>You [fluff] [src] onto the apex of [H == user ? "your" : "[H]'s"] sacrum!</span>",\
				H, "<span class='alert'>[H == user ? "You" : "<b>[user]</b>"] [fluff][H == user && fluff == "press" ? "es" : "s"] [src] onto the apex of your sacrum!</span>")

		else if (!H.organHolder.tail && H.organHolder.chest.op_stage >= 11.0 && src.can_attach_organ(H, user))
			attachment_successful = 1

			var/fluff = pick("insert", "shove", "place", "drop", "smoosh", "squish")

			H.tri_message("<span class='alert'><b>[user]</b> [fluff][fluff == "smoosh" || fluff == "squish" ? "es" : "s"] [src] up against [H == user ? "[his_or_her(H)]" : "[H]'s"] sacrum!</span>",\
			user, "<span class='alert'>You [fluff] [src] up against [user == H ? "your" : "[H]'s"] sacrum!</span>",\
			H, "<span class='alert'>[H == user ? "You" : "<b>[user]</b>"] [fluff][fluff == "smoosh" || fluff == "squish" ? "es" : "s"] [src] up against your sacrum!</span>")

		if (attachment_successful)
			if (user.find_in_hand(src))
				user.u_equip(src)
			H.organHolder.receive_organ(src, "tail", 3.0)
			if (boned)
				H.organHolder.tail.op_stage = 0.0
			else
				H.organHolder.tail.op_stage = 11.0
			src.build_mob_tail_image()
			H.update_body()
			H.bioHolder.RemoveEffect(src.failure_ability)
			return 1

		return 0
	// Tail-loss clumsy-giving is handled in organ_holder's handle_missing
	on_life(var/mult = 1)
		if (!..())
			return 0
		if (src.get_damage() >= FAIL_DAMAGE && probmult(src.get_damage() * 0.2))
			src.breakme()
		return 1

	on_broken(var/mult = 1)
		if(src.get_damage() < FAIL_DAMAGE)
			src.unbreakme()
		if(ischangeling(src.holder.donor))
			return
		else if(src.failure_ability && src.holder?.donor?.mob_flags & SHOULD_HAVE_A_TAIL)
			if(src.holder?.donor?.reagents?.get_reagent_amount("ethanol") > 50) // Drunkenness counteracts un-tailedness
				src.holder?.donor?.bioHolder?.RemoveEffect(src.failure_ability)
			else
				src.holder?.donor?.change_misstep_chance(10)
				src.holder?.donor?.bioHolder?.AddEffect(src.failure_ability, 0, 0, 0, 1)

	unbreakme()
		. = ..()
		src.holder?.donor?.bioHolder?.RemoveEffect(src.failure_ability)


	/// builds the tail images that update_body() will use to display it on the mob
	proc/build_mob_tail_image() // lets mash em all into one image with overlays n shit, like the head, but on the ass
		var/humonkey = src.human_monkey_tail_interchange(src.organ_image_under_suit_1, src.human_getting_monkeytail, src.monkey_getting_humantail)
		var/image/tail_temp_image = image(icon=src.organ_image_icon, icon_state=humonkey, layer = MOB_TAIL_LAYER1)
		if (src.organ_color_1)
			tail_temp_image.color = src.organ_color_1
		src.tail_image_1 = tail_temp_image

		if(src.organ_image_under_suit_2)
			humonkey = src.human_monkey_tail_interchange(src.organ_image_under_suit_2, src.human_getting_monkeytail, src.monkey_getting_humantail)
			tail_temp_image = image(icon=src.organ_image_icon, icon_state=humonkey, layer = MOB_TAIL_LAYER2)
			if (src.organ_color_2)
				tail_temp_image.color = src.organ_color_2
			src.tail_image_2 = tail_temp_image

		if(src.organ_image_over_suit)
			humonkey = src.human_monkey_tail_interchange(src.organ_image_over_suit, src.human_getting_monkeytail, src.monkey_getting_humantail)
			tail_temp_image = image(icon=src.organ_image_icon, icon_state=humonkey, layer = MOB_OVERSUIT_LAYER1)
			if (src.organ_color_1)
				tail_temp_image.color = src.organ_color_1
			src.tail_image_oversuit = tail_temp_image

	/// Sets the proper images for monkeys and nonmonkeys if one gets the other's tail. Differing butt heights, yo
	proc/human_monkey_tail_interchange(var/tail_iconstate as text, var/human_getting_monkey_tail as num, var/monkey_getting_human_tail as num)
		if (!tail_iconstate || (human_getting_monkey_tail && monkey_getting_human_tail))
			logTheThing("debug", src, null, "HumanMonkeyTailInterchange fucked up. tail_iconstate = [tail_iconstate], [human_getting_monkey_tail] && [monkey_getting_human_tail]. call lagg")
			return null	// Something went wrong
		if (!human_getting_monkey_tail && !monkey_getting_human_tail)	// tail's going to the right place
			return tail_iconstate	// Send it as-is
		var/output_this_string
		output_this_string = tail_iconstate + (human_getting_monkey_tail ? "-human" : "-monkey")
		return output_this_string

	/// Colors images and overlays them on the item. Mostly used for lizard and cyber tails
	proc/update_tail_icon()
		src.overlays.len = 0
		if (!src.icon_piece_1 && !src.icon_piece_2)
			return	// Nothing really there to update

		if(istype(src, /obj/item/organ/tail/cyber) && src.tail_num != TAIL_LIZARD)
			var/image/organ_piece_base = image(src.icon, src.icon_state)
			organ_piece_base.color = src.organ_color_1
			src.overlays += organ_piece_base

		if (src.icon_piece_1)
			var/image/organ_piece_1 = image(src.icon, src.icon_piece_1)
			organ_piece_1.color = src.organ_color_1
			src.overlays += organ_piece_1

		if (src.icon_piece_2)
			var/image/organ_piece_2 = image(src.icon, src.icon_piece_2)
			organ_piece_2.color = src.organ_color_2
			src.overlays += organ_piece_2

/obj/item/organ/tail/monkey
	name = "monkey tail"
	desc = "A long, slender tail."
	icon_state = "tail-monkey"
	organ_image_icon = 'icons/mob/monkey.dmi'
	tail_num = TAIL_MONKEY
	organ_image_under_suit_1 = "monkey_under_suit"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "monkey_over_suit"

/obj/item/organ/tail/lizard
	name = "lizard tail"
	desc = "A long, scaled tail."
	icon_state = "tail-lizard"	// This is just the meat bit
	icon_piece_1 = "tail-lizard-detail-1"
	icon_piece_2 = "tail-lizard-detail-2"
	organ_image_icon = 'icons/mob/lizard.dmi'
	organ_image_under_suit_1 = "lizard_under_suit_1"
	organ_image_under_suit_2 = "lizard_under_suit_2"
	organ_image_over_suit = "lizard_over_suit"
	tail_num = TAIL_LIZARD
	colorful = 1
	multipart_icon = 1

/obj/item/organ/tail/cow
	name = "cow tail"
	desc = "A short, brush-like tail."
	icon_state = "tail-cow"
	organ_image_icon = 'icons/mob/cow.dmi'
	tail_num = TAIL_COW
	organ_image_under_suit_1 = "cow_under_suit"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "cow_over_suit_1"	// just the tail, no nose

/obj/item/organ/tail/wolf
	name = "wolf tail"
	desc = "A long, fluffy tail."
	icon_state = "tail-wolf"
	organ_image_icon = 'icons/mob/werewolf.dmi'
	MAX_DAMAGE = 250	// Robust tail for a robust antag
	FAIL_DAMAGE = 240
	tail_num = TAIL_WEREWOLF
	organ_image_under_suit_1 = "wolf_under_suit"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "wolf_over_suit"

/obj/item/organ/tail/bone
	name = "tailbone"
	desc = "A short piece of bone."
	icon_state = "tail-bone"
	organ_image_icon = 'icons/mob/human.dmi'
	created_decal = null	// just a piece of bone
	tail_num = TAIL_SKELETON
	edible = 0
	made_from = "bone"
	organ_image_under_suit_1 = null
	organ_image_under_suit_2 = null
	organ_image_over_suit = null

/obj/item/organ/tail/monkey/seamonkey
	name = "seamonkey tail"
	desc = "A long, pink tail."
	icon_state = "tail-seamonkey"
	organ_image_icon = 'icons/mob/seamonkey.dmi'
	tail_num = TAIL_SEAMONKEY
	organ_image_under_suit_1 = "seamonkey_under_suit"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "seamonkey_over_suit"

/obj/item/organ/tail/cat
	name = "cat tail"
	desc = "A long, furry tail."
	icon_state = "tail-cat"
	organ_image_icon = 'icons/mob/cat.dmi'
	tail_num = TAIL_CAT
	organ_image_under_suit_1 = "cat_under_suit"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "cat_over_suit"

/obj/item/organ/tail/roach
	name = "roach abdomen"
	desc = "A large insect behind."
	icon_state = "tail-roach"
	organ_image_icon = 'icons/mob/roach.dmi'
	tail_num = TAIL_ROACH
	organ_image_under_suit_1 = "roach_under_suit"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "roach_over_suit"

/obj/item/organ/tail/cyber
	name = "polymorphic meta-cyberorgan"
	desc = "A jagged, flexible \"meta-organ\" capable of \"transforming\" itself into various \"organs\" using inserted \"materials\". Would be great if any of the organs it turned into actually worked. Or even resembled organs. Should make for a passable tail replacement, though."
	icon_state = "table1"
	organ_image_icon = 'icons/mob/robots.dmi'
	tail_num = TAIL_CYBER
	organ_image_under_suit_1 = "up-pshield"
	organ_image_under_suit_2 = null
	organ_image_over_suit = "robot"
	made_from = "mauxite"
	robotic = 1
	colorful = 1
	var/accepts_multiple_colors = FALSE

	attackby(obj/item/W, mob/user)
		if(istype(W, /obj/item/spacecash) || istype(W, /obj/item/sheet) || istype(W, /obj/item/paint_can))
			if(src.put_stuff_in_tail(W, user))
				return
		else if (ispulsingtool(W))
			src.alter_cybertail_settings(user)
			return
		. = ..()

	MouseDrop(atom/over_object)
		if(get_dist(over_object,get_turf(src)) > 1)
			boutput(usr, "<span class='alert'>[src] is too far away from the target!</span>")
			return

		if(istype(over_object) && ismob(usr))
			var/mob/U = usr
			src.remove_stuff_from_tail(get_turf(over_object), U)
		else
			. = ..()

	attack_self(mob/user)
		if(src.transforming)
			boutput(user,"Hold your horses, it's doing something!")
			return
		if(check_needed_contents(TRUE))
			actions.start(new/datum/action/bar/tailshape(src), src)
			return
		. = ..()

	proc/alter_cybertail_settings(var/mob/user)
		if(!ismob(user))
			return FALSE
		if(!src.robotic)
			boutput(user, "[src] seems to be ignoring you.")
			return FALSE
		if(src.holder)
			boutput(user, "[src] refuses to alter its settings while attached to [src.holder].")
			return FALSE

		var/what_do = alert("Which part of [src]'s aesthetic settings do you want to configure?","Editing C:\\ctail\\config\\tailconfig.cfg","Form","Color","Neither")
		if(!what_do)
			boutput(user, "Never mind.")
			return FALSE
		switch(what_do)
			if("Form")
				var/list/cowtail = list(TAIL_COW_FLUFF = TAIL_COW)
				if(ishuman(user))
					var/mob/living/carbon/human/C = user
					if(istype(C?.mutantrace, /datum/mutantrace/cow))
						cowtail = list(TAIL_NOTCOW_FLUFF = TAIL_COW)
				var/list/tail_choices = src.tail_styles + cowtail
				if(src.emagged)
					tail_choices += src.tail_styles_extra
				var/new_look = input(user, "Restructure [src] into which form?", "Set cl_model") as null | anything in tail_choices
				if(!new_look || !(new_look in tail_choices))
					boutput(user, "[capitalize(src)] remains as-is.")
					return FALSE
				else
					src.form_setting = new_look
					boutput(user, "You configure [src]'s target form to \"[src.form_setting]\".")

			if("Color")
				var/color_region = "Base"
				if(src.form_setting == TAIL_LIZARD_FLUFF)
					color_region = alert(user,"Which part of [src]'s colors do you want to configure?", "Pick a region", "Skin", "Detail", "Nothing")
				if(!color_region || color_region == "Nothing")
					boutput(user, "[capitalize(src)] remains as-is.")
					return FALSE
				else
					var/coloration = input(user, "Please select an RGB setting.", "Set gl_colorhex")  as null | color
					if(color_region == "Base")
						if(!coloration)
							src.color_setting_1 = null
							boutput(user, "You reset the base color setting on [src].")
						else
							src.color_setting_1 = coloration
							boutput(user, "You configure [src]'s target base color to \"[src.color_setting_1]\".")
					else
						if(!coloration)
							src.color_setting_1 = null
							boutput(user, "You reset the detail color setting on [src].")
						else
							src.color_setting_2 = coloration
							boutput(user, "You configure [src]'s target detail color to \"[src.color_setting_2]\".")
		check_needed_contents()

	proc/update_tail_contents()
		src.tail_contents = list("metal" = 0, "cash" = 0, "paint" = 0)
		for(var/obj/item/W in src.contents)
			if(istype(W, /obj/item/spacecash))
				if(W.amount >= 1)
					src.tail_contents["cash"] = W.amount
				else if (W)
					qdel(W)
			else if(istype(W, /obj/item/sheet))
				if(W.amount >= 1)
					src.tail_contents["metal"] = W.amount
				else if (W)
					qdel(W)
			else if(istype(W, /obj/item/paint_can))
				var/obj/item/paint_can/P = W
				if(P?.uses >= 1)
					src.tail_contents["paint"] = P.uses
				else
					P.set_loc(get_turf(src))
					src.visible_message("[src] ejects an empty paint can!")
			else
				continue
	/// One use of paint per region to color, one sheet of metal to change form
	/// 100 credits for each if emagged
	proc/check_needed_contents(var/execute)
		if(!src.color_setting_1 && !src.color_setting_2 && !src.form_setting) return FALSE // Nothing needs changing
		var/needed_cash
		var/needed_metal
		var/needed_paint
		if(src.form_setting)
			if(src.emagged)
				needed_cash += CASH_PER_TAIL_OPTION
			else
				needed_metal = 1
		if(src.form_setting != TAIL_LIZARD_FLUFF)
			src.color_setting_2 = null
		if(src.color_setting_1 || src.color_setting_2)
			var/numcolors = clamp(!(!src.color_setting_1) + !(!src.color_setting_2), 1, 2) // ghoulish
			if(src.emagged)
				needed_cash += (CASH_PER_TAIL_OPTION * numcolors)
			else
				needed_paint = numcolors

		update_tail_contents()

		for(var/S in src.tail_contents)
			switch(S)
				if("metal")
					needed_metal = max(needed_metal - src.tail_contents[S], 0)
				if("cash")
					needed_cash = max(needed_cash - src.tail_contents[S], 0)
				if("paint")
					needed_paint = max(needed_paint - src.tail_contents[S], 0)

		if(!needed_cash && !needed_metal && !needed_paint) // got everything!
			if(!execute)
				src.audible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"All required materials present. Press 'START' to continue.\"")
			return TRUE
		else
			var/list/stuff_it_need = list()
			if(needed_cash)
				stuff_it_need.Add("[needed_cash] credit\s")
			if(needed_metal)
				stuff_it_need.Add("1 metal sheet")
			if(needed_paint)
				stuff_it_need.Add("[needed_paint] dram\s of paint")
			src.audible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"Please insert [english_list(stuff_it_need)] to continue.\"")
			return FALSE

	proc/put_stuff_in_tail(var/obj/item/W, var/mob/user)
		if(!user || !istype(W, /obj/item)) return FALSE

		var/obj/item/spacecash/S
		var/obj/item/sheet/M
		var/obj/item/paint_can/P

		for(var/obj/C in src.contents)
			if(istype(C, /obj/item/spacecash))
				if(!S)
					S = C
				else
					C.set_loc(get_turf(src)) // No duplicate entries, please!
			else if(istype(C, /obj/item/sheet))
				if(!M)
					M = C
				else
					C.set_loc(get_turf(src)) // No duplicate entries, please!
			else if(istype(C, /obj/item/paint_can))
				if(!P)
					P = C
				else
					C.set_loc(get_turf(src)) // No duplicate entries, please!
			else
				C.set_loc(get_turf(src)) // Unauthorized materials!


		if(istype(W, /obj/item/spacecash))
			if(W.amount >= 1)
				if(S)
					S.attackby(W, user)
				else
					W.set_loc(src)
					user.u_equip(W)
					user.visible_message("[user] inserts [W] into [src].")
		else if(istype(W, /obj/item/sheet))
			if(M)
				M.attackby(W, user)
			else
				W.set_loc(src)
				user.u_equip(W)
				user.visible_message("[user] inserts [W] into [src].")
		else if(istype(W, /obj/item/paint_can))
			var/obj/item/paint_can/WP = W
			if(WP?.uses)
				if(P)
					P.set_loc(get_turf(src))
				W.set_loc(src)
				user.u_equip(W)
				user.visible_message("[user] inserts [W] into [src].")
			else
				boutput(user,"[WP] doesn't have any paint!")
		else
			boutput(user,"[W] doesn't fit!")
		update_tail_contents()

	proc/remove_stuff_from_tail(var/atom/A, var/mob/user)
		if(!A || !user || !src.contents) return FALSE
		for(var/obj/C in src.contents)
			C.set_loc(get_turf(A))
		user.visible_message("[user] dumps everything inside \the [src] out onto \the [A].")
		return TRUE

	get_desc()
		. = ..()
		var/has_stuff = 0
		for(var/C in src.tail_contents)
			if(src.tail_contents[C] > 0)
				has_stuff = 1
				break
		if(has_stuff)
			var/list/stuff_it_has = list()
			for(var/S in src.tail_contents)
				switch(S)
					if("metal")
						if(src.tail_contents[S] == 1)
							stuff_it_has += "a metal sheet"
						else if(src.tail_contents[S] >= 2)
							stuff_it_has += "[src.tail_contents[S]] metal sheets"
					if("cash")
						if(src.tail_contents[S] == 1)
							stuff_it_has += "a single credit"
						else if(src.tail_contents[S] >= 2)
							stuff_it_has += "[src.tail_contents[S]] credits"
					if("paint")
						if(src.tail_contents[S] == 1)
							stuff_it_has += "a single dram of paint"
						else if(src.tail_contents[S] > 1)
							stuff_it_has += "[src.tail_contents[S]] drams of paint"

			. += "<br><span class='notice'>It appears to contain [english_list(stuff_it_has)].</span>"

	/// Ripped off of several hit-people-go-flying procs
	/// Finds nearby mobs and whollops them. Power muntiplies the damage and makes it shake the screen a bit, Everyone makes it kick up to 5 mobs around it
	proc/tailthrash(var/power = 0, var/everyone = FALSE)
		var/list/people_kicked = list()
		for(var/mob/M in view(src, 1))
			if(ismob(M))
				random_brute_damage(M, (5*(power)), 1)
				people_kicked.Add(M.name)
				var/turf/T = get_edge_target_turf(M, get_dir(M, get_step_away(src, M)))
				M.throw_at(T, power + 1, 2)
				M.changeStatus("weakened", 1 SECOND * power)
				M.changeStatus("stunned", 1 SECOND * power)
				M.force_laydown_standup()
				if(!everyone || people_kicked > 5)
					break
		if(length(people_kicked) < 1)
			return
		if(power)
			for (var/mob/C in viewers(src))
				shake_camera(C, 8, 24)
			playsound(get_turf(src), "sound/impact_sounds/Flesh_Break_1.ogg", 60, 1)
			src.visible_message("<span class='alert'><B>[src] [pick_string("wrestling_belt.txt", "kick")]-whips [english_list(people_kicked)]!</B></span>")
		else
			playsound(get_turf(src), "swing_hit", 60, 1)
			src.visible_message("<span class='alert'><B>[src] thrashes around and whacks [english_list(people_kicked)]!</B></span>")

	/// Flings the tail at someone, or something. Power also calls tailthrash.
	/// Range is how far it should look for people to fling itself at. If 0, pick a random direction and go that way
	/// Backfire tries to fling itself at whoever turned this thing on, if any
	proc/tailtorpedo(var/power = 0, var/range = 0, var/backfire = 0)
		var/list/people_to_fling_at
		if(range)
			if(!src.transformer)
				backfire = 0
			for(var/mob/M in view(src, range))
				if(ismob(M))
					people_to_fling_at.Add(M)
					if(length(people_to_fling_at) > 3)
						break
			if(length(people_to_fling_at) >= 1)
				var/mob/throw_at_them = pick(people_to_fling_at)
				if(backfire && (src.transformer in people_to_fling_at))
					throw_at_them = src.transformer
				src.throw_at(throw_at_them, 10, 4)
				if(power)
					src.tailthrash(power)
				else
					src.visible_message("<span class='alert'><B>[src]</B> flings itself at [throw_at_them]!</span>")
				return
		var/edge = get_edge_target_turf(get_turf(src), pick(alldirs))
		src.throw_at(edge, 3, 2)
		if(power)
			src.tailthrash(power)
		else
			src.visible_message("<span class='alert'><B>[src]</B> flings itself!</span>")

	proc/make_noise(var/severity)
		switch(rand(1,severity))
			if(1)
				playsound(get_turf(src), "sound/machines/pc_process.ogg", 40, 1)
			if(2)
				playsound(get_turf(src), "sound/items/ratchet.ogg", 40, 1)
			if(3)
				playsound(get_turf(src), "sound/machines/printer_press.ogg", 40, 1)
			if(4)
				playsound(get_turf(src), "sound/machines/scan.ogg", 40, 1)
			if(5)
				playsound(get_turf(src), "sound/machines/squeaky_rolling.ogg", 40, 1)
			if(6)
				playsound(get_turf(src), "sound/impact_sounds/Metal_Clang_3.ogg", 40, 1)
			if(7)
				playsound(get_turf(src), "sound/impact_sounds/Metal_Clang_1.ogg", 40, 1)
			if(8)
				playsound(get_turf(src), "sound/machines/glitch[pick(1,2,3)].ogg", 40, 1)
			if(9)
				playsound(get_turf(src), "sound/machines/printer_press.ogg", 40, 1)
			if(10)
				playsound(get_turf(src), "sound/impact_sounds/Metal_Hit_Light_1.ogg", 40, 1)
			if(11)
				playsound(get_turf(src), "sound/machines/engine_grump[pick(2,3)].ogg", 40, 1)
			if(12)
				playsound(get_turf(src), "sound/items/mining_conc.ogg", 40, 1)
			if(13)
				playsound(get_turf(src), "sound/impact_sounds/Metal_Hit_Heavy_1.ogg", 40, 1)
			if(14)
				playsound(get_turf(src), "sound/machines/engine_grump[pick(1,2,3)].ogg", 40, 1)

	proc/modify_cyberlimb()
		if(!src.color_setting_1 && !src.color_setting_2 && !src.form_setting) return FALSE // Nothing needs changing
		if(src.color_setting_1)
			src.organ_color_1 = fix_colors(src.color_setting_1)
		if(src.color_setting_2)
			src.organ_color_2 = fix_colors(src.color_setting_2)
		if(src.form_setting)
			switch(src.form_setting)
				if(TAIL_LIZARD_FLUFF)
					src.name = "cyber-reptilian appendage"
					src.desc = "A long metallic appendage molded into the rough shape of a large intestine."
					src.icon_state = "tail-lizard"
					src.icon_piece_1 = "tail-lizard-detail-1"
					src.icon_piece_2 = "tail-lizard-detail-2"
					src.organ_image_icon = 'icons/mob/lizard.dmi'
					src.organ_image_under_suit_1 = "lizard_under_suit_1"
					src.organ_image_under_suit_2 = "lizard_under_suit_2"
					src.organ_image_over_suit = "lizard_over_suit"
				if(TAIL_MONKEY_FLUFF)
					src.name = "cyber-simian appendage"
					src.desc = "A slender metallic tendril vaguely resembling a segment of small intestine."
					src.icon_state = "tail-monkey"
					src.organ_image_icon = 'icons/mob/monkey.dmi'
					src.tail_num = TAIL_MONKEY
					src.organ_image_under_suit_1 = "monkey_under_suit"
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = "monkey_over_suit"
				if(TAIL_COW_FLUFF)
					src.name = "cyber-bovine appendage"
					src.desc = "A short metal dowel with crude, wiry fuzz on one end, vaguely resembling a very hairy esophagus."
					src.icon_state = "tail-monkey"
					src.organ_image_icon = 'icons/mob/monkey.dmi'
					src.tail_num = TAIL_MONKEY
					src.organ_image_under_suit_1 = "monkey_under_suit"
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = "monkey_over_suit"
				if(TAIL_ROACH_FLUFF)
					src.name = "cyber-blattodean appendage"
					src.desc = "A metallic torso ."
					src.icon_state = "tail-roach"
					src.organ_image_icon = 'icons/mob/roach.dmi'
					src.tail_num = TAIL_ROACH
					src.organ_image_under_suit_1 = "roach_under_suit"
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = "roach_over_suit"
				if(TAIL_SKELETON_FLUFF)
					src.name = "oversized metallic appendix"
					src.desc = "An oblong chunk of appendix-shaped metal, too large for internal replacement, but oddly perfect as a makeshift coccyx."
					src.icon_state = "tail-bone"
					src.organ_image_icon = 'icons/mob/human.dmi'
					src.created_decal = null	// just a piece of bone
					src.tail_num = TAIL_SKELETON
					src.edible = 0
					src.made_from = "bone"
					src.organ_image_under_suit_1 = null
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = null
				if(TAIL_WEREWOLF_FLUFF)
					src.name = "cyber-lupine appendage"
					src.desc = "A long, metallic, makeshift toupee-log covered in stiff, wiry protrusions, resembling something between a cybernetic hairball and robot tinsel."
					src.icon_state = "tail-wolf"
					src.organ_image_icon = 'icons/mob/werewolf.dmi'
					src.MAX_DAMAGE = 250
					src.FAIL_DAMAGE = 240
					src.tail_num = TAIL_WEREWOLF
					src.organ_image_under_suit_1 = "wolf_under_suit"
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = "wolf_over_suit"
				if(TAIL_CAT_FLUFF)
					src.name = "cyber-feline appendage"
					src.desc = "A long, metallic cable covered in short, wiry protrusions, resembling an oversized pipecleaner."
					src.icon_state = "tail-cat"
					src.organ_image_icon = 'icons/mob/cat.dmi'
					src.tail_num = TAIL_CAT
					src.organ_image_under_suit_1 = "cat_under_suit"
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = "cat_over_suit"
				if(TAIL_SEAMONKEY_FLUFF)
					src.name = "cyber-aquasimian appendage"
					src.desc = "A slender metallic tendril vaguely resembling a segment of space-dolphin intestine."
					src.icon_state = "tail-seamonkey"
					src.organ_image_icon = 'icons/mob/seamonkey.dmi'
					src.tail_num = TAIL_SEAMONKEY
					src.organ_image_under_suit_1 = "seamonkey_under_suit"
					src.organ_image_under_suit_2 = null
					src.organ_image_over_suit = "seamonkey_over_suit"
		src.build_mob_tail_image()
		src.update_tail_icon()
		src.form_setting = null
		src.color_setting_1 = null
		src.color_setting_2 = null

/datum/action/bar/tailshape
	duration = 0 SECONDS
	interrupt_flags = INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "tailshape"
	var/obj/item/organ/tail/cyber/T
	var/reforming
	var/recoloring
	var/minviolence
	var/violence
	var/next_grumble = 0
	var/grumble_cooldown = (5 SECONDS)
	var/oldthrowforce

	New(var/obj/item/organ/tail/cyber/C)
		src.T = C
		src.oldthrowforce = C.throwforce
		src.reforming = !(!T.form_setting)
		src.recoloring = clamp(!(!T.color_setting_1) + !(!T.color_setting_2), 1, 2)

		/// Duration's based on how much stuff we're changing. 40 seconds if we're changing *everything*, plus 10 if its busted
		src.duration += (!(!src.reforming) * 20 SECONDS) + (src.recoloring * 10 SECONDS) + (T.broken * 10 SECONDS)
		if(T.emagged) // Emagged? Goes faster!
			src.duration *= 0.25
			if(reforming)
				T.visible_message("<span class='notice'>[T] twitches violently as its metallic form changes shape!</span>")
		else
			if(reforming)
				T.visible_message("<span class='notice'>[T] wriggles around as its metallic form changes shape.</span>")
		if(recoloring)
			T.visible_message("<span class='notice'>[T] begins changing color!</span>")

		/// How violent will this thing be while transforming? between 1 and 6
		/// 1 it just kinda wriggles, 6 it'll kick the shit out of everyone in the room
		src.violence = (!(!src.reforming) * 2) + src.recoloring + T.broken + T.emagged
		/// The least violence it's capable of
		src.minviolence = clamp(round(src.violence) * 0.5, 1, 6)
		if(src.violence > 3)
			T.throwforce += 3
		src.grumble_cooldown = max(src.grumble_cooldown - (src.violence * 1 SECONDS), 0 SECONDS)
		..()

	onUpdate()
		. = ..()
		if(world.time > src.next_grumble)
			src.next_grumble = world.time + src.grumble_cooldown
			if(istype(T.loc, /mob))
				var/mob/M = T.loc
				M.u_equip(T)
				M.drop_item(T)
			switch(rand(src.minviolence, src.violence))
				if(1 to 2)
					attack_twitch(T)
					T.tailthrash(0, 0)
					step_rand(T,1)
					T.make_noise(2)
				if(3 to 4)
					T.tailthrash(0, 1)
					violent_standup_twitch(T)
					T.tailtorpedo(0, 0, 0)
					elecflash(get_turf(T), 0, power=2, exclude_center = 0)
					T.make_noise(6)
				if(5)
					violent_standup_twitch(T)
					T.tailthrash(1, 1)
					T.tailtorpedo(0, 3, 0)
					elecflash(get_turf(T), 0, power=2, exclude_center = 0)
					T.make_noise(10)
				if(6)
					T.make_noise(14)
					violent_standup_twitch(T)
					T.tailthrash(2, 1)
					T.tailtorpedo(1, 7, 1)
					elecflash(get_turf(T), 1, power=3, exclude_center = 0)
					// metchoe maen
					// wrestling kick anyone who gets near
					// smash shit
					// puke its contents
					// paint tiles
					// lots of sparks
					// RRRR RRR RRR RRR
	onEnd()
		T.visible_message("[T] finishes reshaping itself!")
		T.modify_cyberlimb()
		T.transforming = FALSE
		T.throwforce = src.oldthrowforce
		..()
