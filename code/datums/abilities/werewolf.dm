// Converted everything related to werewolves from client procs to ability holders and used
// the opportunity to do some clean-up as well (Convair880).

// Added kyle2143's werewolf patch (Gannets).

/* 	/		/		/		/		/		/		Setup		/		/		/		/		/		/		/		/		*/

/mob/proc/make_werewolf(var/force=0, var/partwolf)
	if (ishuman(src))
		var/datum/abilityHolder/werewolf/A = src.get_ability_holder(/datum/abilityHolder/werewolf)
		if (A && istype(A))
			return
		var/datum/abilityHolder/werewolf/W = src.add_ability_holder(/datum/abilityHolder/werewolf)
		//W.addAbility(/datum/targetable/werewolf/werewolf_transform)
		W.addAbility(/datum/targetable/werewolf/werewolf_feast)
		W.addAbility(/datum/targetable/werewolf/werewolf_pounce)
		W.addAbility(/datum/targetable/werewolf/werewolf_thrash)
		W.addAbility(/datum/targetable/werewolf/werewolf_throw)
		W.addAbility(/datum/targetable/werewolf/werewolf_tainted_saliva)
		W.addAbility(/datum/targetable/werewolf/werewolf_defense)
		// W.addAbility(/datum/targetable/werewolf/werewolf_spread_affliction)	//not using for now, but could be fun later ish.
		if (force)
			W.addAbility(/datum/targetable/werewolf/werewolf_transform)
			boutput(src, "<span class='alert'>You are a full werewolf, you can transform immediately!</span>")
		else
			SPAWN_DBG(W.awaken_time)
				handle_natural_werewolf(W)

		src.resistances += /datum/ailment/disease/lycanthropy

		if (src.mind && src.mind.special_role != "omnitraitor")
			SHOW_WEREWOLF_TIPS(src)

	else return

/mob/proc/handle_natural_werewolf(var/datum/abilityHolder/werewolf/W)
	src.emote("shiver")
	boutput(src, "<span class='alert'><b>You feel feral!</b></span>")

	boutput(src, "<span class='alert'><b>Your body feels as if it's on fire! You think it's... IT'S CHANGING! You should probably get somewhere private!</b></span>")


#define WERE_TF_STAGE_1 (1<<0)
#define WERE_TF_STAGE_2 (1<<1)
#define WERE_TF_STAGE_3 (1<<2)
#define WERE_TF_STAGE_4 (1<<3)
#define WERE_TF_STAGE_1_1 (1<<4)
#define WERE_TF_STAGE_1_2 (1<<5)
#define WERE_TF_STAGE_1_3 (1<<6)
#define WERE_TF_STAGE_2_1 (1<<7)
#define WERE_TF_STAGE_2_2 (1<<8)
#define WERE_TF_STAGE_2_3 (1<<9)
#define WERE_TF_STAGE_3_1 (1<<10)
#define WERE_TF_STAGE_3_2 (1<<11)
#define WERE_TF_STAGE_3_3 (1<<12)
#define WERE_TF_STAGE_4_1 (1<<13)
#define WERE_TF_STAGE_4_2 (1<<14)
#define WERE_TF_STAGE_4_3 (1<<15)

/// first time
/datum/action/bar/private/icon/force_wolf_tf
	duration = 1 MINUTE
	interrupt_flags = null
	id = "force_wolf_tf"
	icon = 'icons/mob/werewolf.dmi'
	icon_state = "head_tf_icon_anim"
	var/stages_done
	var/datum/abilityHolder/werewolf/awoo
	var/mob/living/carbon/human/master
	var/is_full_werewolf //
	var/list/cooldowns

	New(var/mob/living/carbon/human/H, var/_awoo, var/antagwolf)
		src.master = H
		src.awoo = _awoo
		src.is_full_werewolf = antagwolf
		..()

	onStart()
		..()
		if(fail_checks())
			interrupt(INTERRUPT_ALWAYS)
			return

		boutput(master, "<span class='alert'>You feel a sharp quivering echo through your bones.</span>")

	onInterrupt(flag)
		. = ..()
		boutput(master, "<span class='notice'>Everything just sort of stops transforming. Huh.</span>")

	onUpdate()
		. = ..()
		if(fail_checks())
			interrupt(INTERRUPT_ALWAYS)
			return

		var/elapsed = TIME - started

		if(!ON_COOLDOWN(src, "no_tf_spam", 5 SECONDS))
			switch(elapsed)
				if((1 SECOND) to (15 SECONDS - 1)) // It begins
					if(!(src.stages_done & WERE_TF_STAGE_1))
						switch(rand(1,3))
							if(1)
								if(!(src.stages_done & WERE_TF_STAGE_1_1))
									master.emote("shudder")
									boutput(master, "<span class='notice'>You feel restless.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_1
									src.stages_done |= WERE_TF_STAGE_1_1
							if(2)
								if(!(src.stages_done & WERE_TF_STAGE_1_2))
									if(!istype(get_area(master), /area/space))
										boutput(master, "<span class='notice'>You become acutely aware of the ambient scents.</span>")
									else
										boutput(master, "<span class='notice'>You become acutely aware of the smell off your own [prob(20) ? "awful " : ""]breath.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_1
									src.stages_done |= WERE_TF_STAGE_1_2
							if(3)
								if(!(src.stages_done & WERE_TF_STAGE_1_3))
									var/found_someone
									if(!istype(get_area(master), /area/space))
										for(var/mob/living/carbon/human/H in orange(5, master))
											if(!isdead(H) && H.organHolder.heart)
												boutput(master, "<span class='notice'>You hear a quiet thumping somewhere [dir2text(get_dir(master, H))].</span>")
												found_someone = 1
									if(!found_someone)
										boutput(master, "<span class='notice'>You hear your heart race.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_1
									src.stages_done |= WERE_TF_STAGE_1_3

				if((15 SECONDS) to (30 SECONDS - 1)) // physiology gets ready to change
					if(!(src.stages_done & WERE_TF_STAGE_2))
						switch(rand(1,3))
							if(1)
								if(!(src.stages_done & WERE_TF_STAGE_2_1))
									master.emote("scream") // also applicable if you somehow got here without a head
									boutput(master, "<span class='alert'>You feel like someone punched you in the face, but from the inside!</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_2
									src.stages_done |= WERE_TF_STAGE_2_1
							if(2)
								if(!(src.stages_done & WERE_TF_STAGE_2_2))
									master.emote("twitch")
									if(master.w_uniform)
										boutput(master, "<span class='alert'>Your [master.w_uniform] chafes ominously!</span>")
									else if(master.organHolder?.butt)
										boutput(master, "<span class='alert'>Your butt itches.</span>")
									else
										boutput(master, "<span class='alert'>Something itches.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_2
									src.stages_done |= WERE_TF_STAGE_2_2
							if(3)
								if(!(src.stages_done & WERE_TF_STAGE_2_3))
									var/num_legs
									if(master.limbs?.l_leg && !istype(master.limbs.l_leg, /obj/item/parts/robot_parts))
										num_legs ++
									if(master.limbs?.r_leg && !istype(master.limbs.r_leg, /obj/item/parts/robot_parts))
										num_legs ++
									if(num_legs)
										boutput(master, "<span class='notice'>Your knee[num_legs == 2 ? "s" : ""] feel[num_legs == 1 ? "s" : ""] rubbery.</span>")
									else
										boutput(master, "<span class='notice'>The stumps where your legs used to be feel disappointed in you.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_2
									src.stages_done |= WERE_TF_STAGE_2_3

				if((30 SECONDS) to (45 SECONDS - 1)) // more violent changes happen
					if(!(src.stages_done & WERE_TF_STAGE_3))
						switch(rand(1,3))
							if(1)
								if(!(src.stages_done & WERE_TF_STAGE_3_1))
									var/num_legs
									if(master.limbs?.l_leg && !istype(master.limbs.l_leg, /obj/item/parts/robot_parts))
										num_legs ++
									if(master.limbs?.r_leg && !istype(master.limbs.r_leg, /obj/item/parts/robot_parts))
										num_legs ++
									if(num_legs)
										master.force_laydown_standup()
										master.emote("scream")
										boutput(master, "<span class='alert'>Your knee[num_legs == 2 ? "s" : ""] suddenly fold[num_legs == 1 ? "s" : ""] in half!</span>")
										boutput(master, "<span class='notice'>[num_legs == 2 ? "They" : "It"] resolidif[num_legs == 1 ? "ies" : "y"] moments later, albeit a few inches shorter.</span>")
									else
										boutput(master, "<span class='notice'>The stumps where your legs used to be feel very disappointed in you.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_3
									src.stages_done |= WERE_TF_STAGE_3_1
							if(2)
								if(!(src.stages_done & WERE_TF_STAGE_3_2))
									master.emote("twitch")
									var/num_arms
									if(master.limbs?.l_arm && !istype(master.limbs.l_arm, /obj/item/parts/robot_parts))
										num_arms ++
									if(master.limbs?.r_arm && !istype(master.limbs.r_arm, /obj/item/parts/robot_parts))
										num_arms ++
									if(num_arms)
										if(master.gloves)
											if(istype(master.gloves, /obj/item/clothing/gloves/fingerless))
												boutput(master, "<span class='notice'>The fabric of your [master.gloves] shift as its contents change shape!</span>")
											else
												boutput(master, "<span class='notice'>Your fingernails scratch at the inside of your [master.gloves]!</span>")
										else
											boutput(master, "<span class='notice'>The pads on your hand[num_arms == 2 ? "s" : ""] thicken and your fingernails file themselves to a point.</span>")
									else
										boutput(master, "<span class='notice'>The stumps where your arms used to be feel very, very disappointed in you.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_3
									src.stages_done |= WERE_TF_STAGE_3_2
							if(3)
								if(!(src.stages_done & WERE_TF_STAGE_3_3))
									master.emote("burp")
									boutput(master, "<span class='notice'>You feel...</span> <span class='alert'>hungry.</span>")
									if(prob(70))
										src.stages_done |= WERE_TF_STAGE_3
									src.stages_done |= WERE_TF_STAGE_3_3

				if((45 SECONDS) to (60 SECONDS - 1)) // Visible changes happen. Violent!
					// tail!
					if(!(src.stages_done & WERE_TF_STAGE_4_1))
						master.emote("scream")
						boutput(master, "<span class='alert'>You feel a blinding surge of electricity shoot down your spine, then keep going!</span>")
						if(master.organHolder)
							var/datum/organHolder/OH = master.organHolder
							if(OH.drop_organ("tail"))
								boutput(master, "<span class='alert'>Your tail falls off!</span>")
							if(OH.receive_organ(new /obj/item/organ/tail/wolf(master, OH), "tail", 0, 1))
								boutput(master, "<span class='alert'>A fluffy, brown tail springs forth from your rear!</span>")
						src.stages_done |= WERE_TF_STAGE_4_1
					// arms!
					else if(!(src.stages_done & WERE_TF_STAGE_4_2))
						master.emote("scream")
						if(master.limbs.l_arm)
							var/obj/item/parts/larm = master.limbs.l_arm
							if(larm.limb_is_unnatural)
								larm.remove(0)
								boutput(master, "<span class='alert'>A sharp pressure in your chest pushes your [larm] off!</span>")
							else
								larm.delete()
								boutput(master, "<span class='alert'>Your left arm suddenly feels as strong as it does hairy!</span>")
							master.limbs.replace_with("l_arm", /obj/item/parts/human_parts/arm/mutant/werewolf/left, null, 0)
						if(master.limbs.r_arm)
							var/obj/item/parts/rarm = master.limbs.r_arm
							if(rarm.limb_is_unnatural)
								rarm.remove(0)
								boutput(master, "<span class='alert'>A sharp pressure in your chest pushes your [rarm] off!</span>")
							else
								rarm.delete()
								boutput(master, "<span class='alert'>Your right arm suddenly feels as strong as it does hairy!</span>")
							master.limbs.replace_with("r_arm", /obj/item/parts/human_parts/arm/mutant/werewolf/right, null, 0)
						src.stages_done |= WERE_TF_STAGE_4_2
					// arms, but find-replaced with leg!
					else if(!(src.stages_done & WERE_TF_STAGE_4_3))
						master.emote("scream")
						if(master.limbs.l_leg)
							var/obj/item/parts/lleg = master.limbs.l_leg
							if(lleg.limb_is_unnatural)
								lleg.remove(0)
								boutput(master, "<span class='alert'>A sharp pressure in your chest pushes your [lleg] off!</span>")
							else
								lleg.delete()
								boutput(master, "<span class='alert'>Your left leg suddenly feels as strong as it does hairy!</span>")
							master.limbs.replace_with("l_leg", /obj/item/parts/human_parts/leg/mutant/werewolf/left, null, 0)
						if(master.limbs.r_leg)
							var/obj/item/parts/rleg = master.limbs.r_leg
							if(rleg.limb_is_unnatural)
								rleg.remove(0)
								boutput(master, "<span class='alert'>A sharp pressure in your chest pushes your [rleg] off!</span>")
							else
								rleg.delete()
								boutput(master, "<span class='alert'>Your right leg suddenly feels as strong as it does hairy!</span>")
							master.limbs.replace_with("r_leg", /obj/item/parts/human_parts/leg/mutant/werewolf/right, null, 0)
						src.stages_done |= WERE_TF_STAGE_4_3

	onInterrupt(var/flag)
		..()
		boutput(owner, "<span class='alert'>Your attempt to remove your handcuffs was interrupted!</span>")

	onEnd()
		..()
		awoo.addAbility(/datum/targetable/werewolf/werewolf_transform)
		master.werewolf_transform()

	proc/fail_checks()
		if(!master || isdead(master))
			return 1

#undef WERE_TF_STAGE_1
#undef WERE_TF_STAGE_2
#undef WERE_TF_STAGE_3
#undef WERE_TF_STAGE_4
#undef WERE_TF_STAGE_1_1
#undef WERE_TF_STAGE_1_2
#undef WERE_TF_STAGE_1_3
#undef WERE_TF_STAGE_2_1
#undef WERE_TF_STAGE_2_2
#undef WERE_TF_STAGE_2_3
#undef WERE_TF_STAGE_3_1
#undef WERE_TF_STAGE_3_2
#undef WERE_TF_STAGE_3_3
#undef WERE_TF_STAGE_4_1
#undef WERE_TF_STAGE_4_2
#undef WERE_TF_STAGE_4_3

////////////////////////////////////////////// Helper procs //////////////////////////////

// Avoids C&P code for that werewolf disease.
/mob/proc/werewolf_transform()
	if (ishuman(src))
		var/mob/living/carbon/human/M = src
		var/which_way = 0

		// not a werewolf? Go become one!
		if (!istype(M.mutantrace, /datum/mutantrace/werewolf))
			/// Werewolf is typically a "temporary" MR, as few people start the round as a wolf. Or TF into a wolf while being a wolf
			if(istype(M.coreMR, /datum/mutantrace/werewolf)) // so if this somehow happens, uh. human?
				M.coreMR = null
			M.coreMR = M.mutantrace
			M.jitteriness = 0
			M.delStatus("stunned")
			M.delStatus("weakened")
			M.delStatus("paralysis")
			M.delStatus("slowed")
			M.delStatus("disorient")
			M.delStatus("radiation")
			M.delStatus("n_radiation")
			M.delStatus("burning")
			M.delStatus("staggered")
			M.change_misstep_chance(-INFINITY)
			M.stuttering = 0
			M.drowsyness = 0
			M.add_stun_resist_mod("wolf_stun_resist", 10)

			//wolfing removes all the implants in you
			for(var/obj/item/implant/I in M)
				// if (istype(I, /obj/item/implant/projectile))
				boutput(M, "<span class='alert'>\an [I] falls out of your abdomen.</span>")
				I.on_remove(M)
				M.implant.Remove(I)
				I.set_loc(M.loc)
				continue

			M.set_mutantrace(/datum/mutantrace/werewolf)

			playsound(M.loc, 'sound/impact_sounds/Slimy_Hit_4.ogg', 50, 1, -1)
			SPAWN_DBG(0.5 SECONDS)
				if (M?.mutantrace && istype(M.mutantrace, /datum/mutantrace/werewolf))
					M.emote("howl")

			M.visible_message("<span class='alert'><B>[M] [pick("metamorphizes", "transforms", "changes")] into a werewolf! Holy shit!</B></span>")
			if (M.find_ailment_by_type(/datum/ailment/disease/lycanthropy))
				boutput(M, "<span class='notice'><h3>You are now a werewolf.</span></h3>")
			else
				boutput(M, "<span class='notice'><h3>You are now a werewolf. You can remain in this form indefinitely or change back at any time.</span></h3>")

			//when in werewolf form, get more max health or regenerate
			// M.maxhealth = 200
			// M.health =
			if (src.bioHolder)
				src.bioHolder.AddEffect("regenerator_wolf")
				boutput(src, "<span class='alert'>You will now heal over time!</span>")

			if (M.hasStatus("handcuffed"))
				if (M.handcuffs.werewolf_cant_rip())
					boutput(M, "<span class='alert'>You can't seem to break free from these silver handcuffs.</span>")
				else
					M.visible_message("<span class='alert'><B>[M] rips apart the [M.handcuffs] with pure brute strength!</b></span>")
					M.handcuffs.destroy_handcuffs(M)

			which_way = 0

		// iswolf?
		else
			if (M.find_ailment_by_type(/datum/ailment/disease/lycanthropy)) // Wolfdisease? Whoops, you're a wolf forever!
				boutput(src, "<span class='alert'>Your body refuses to change!</span>")
				return

			M.remove_stun_resist_mod("wolf_stun_resist")
			if (src.bioHolder)
				src.bioHolder.RemoveEffect("regenerator")
				boutput(src, "<span class='alert'>You will no longer heal over time!</span>")

			boutput(M, "<span class='notice'><h3>You transform back into your original form.</span></h3>")

			M.set_mutantrace(M.coreMR) // return to monke/bove/herpe/etc

			//Changing back removes all the implants in you, wolves should have a non-surgery way to remove bullets. considering silver is so harmful
			for(var/obj/item/implant/I in M)
				// if (istype(I, /obj/item/implant/projectile))
				boutput(M, "<span class='alert'>\an [I] falls out of your abdomen.</span>")
				I.on_remove(M)
				M.implant.Remove(I)
				I.set_loc(M.loc)
				continue

			which_way = 1

		logTheThing("combat", M, null, "[which_way == 0 ? "transforms into a werewolf" : "changes back into human form"] at [log_loc(M)].")
		return

// There used to be more stuff here, most of which was moved to limb datums.
/mob/proc/werewolf_attack(var/mob/target = null, var/attack_type = "")
	if (!iswerewolf(src))
		return 0

	var/mob/living/carbon/human/M = src
	if (!ishuman(M))
		return 0

	if (!target || !ismob(target))
		return 0

	if (target == M)
		return 0

	if (check_target_immunity(target) == 1)
		target.visible_message("<span class='alert'><B>[M]'s swipe bounces off of [target] uselessly!</B></span>")
		return 0
	M.werewolf_tainted_saliva_transfer(target)

	var/damage = 0
	var/send_flying = 0 // 1: a little bit | 2: across the room

	switch (attack_type)
		if ("feast") // Only used by the feast ability.
			var/mob/living/carbon/human/HH = target

			if (!HH || !ishuman(HH))
				return 0

			var/healing = 0

			damage += rand(5,15)
			healing = damage - 4

			var/obj/item/organ/ono

			if (prob(40))
				ono = HH.organHolder?.drop_and_throw_organ("nonvital") // snack for later

			if(ono)
				if(M.limbs.l_arm || M.limbs.r_arm)
					if(istype(M.limbs.l_arm, /obj/item/parts/human_parts/arm/mutant/werewolf) || istype(M.limbs.r_arm, /obj/item/parts/human_parts/arm/mutant/werewolf))
						M.visible_message("<span class='alert'><B>[M] [pick("jams", "thrusts")] [his_or_her(M)] razor-sharp claws [istype(ono, /obj/item/organ/eye) ? "across [HH]'s face" : "through [HH]'s torso" ], [pick("eviscerating", "ripping out", "rending free")] [his_or_her(HH)] [ono] and sending it flying!</B></span>",\
						blind_message = "<span class='alert'>You hear a loud, wet thump, followed by a SPLAT!</span>")
					else
						M.visible_message("<span class='alert'><B>[M] [pick("grabs hold of", "clamps [his_or_her(M)] hand around")] [HH]'s [ono] with a vice-like grip and [pick("rips", "tears", "wrenches", "pulls")] it [istype(ono, /obj/item/clothing/head/butt) ? "off" : "out"] of [his_or_her(HH)] [istype(ono, /obj/item/organ/eye) ? "skull" : "torso"], [pick("flinging", "tossing", "throwing")] it aside for later!</B></span>",\
						blind_message = "<span class='alert'>You hear a slimy squidge, followed by a SPLAT!</span>")
				else
					M.visible_message("<span class='alert'><B>[M] [pick("chomps", "clamps", "bites")] deep into [HH]'s [istype(ono, /obj/item/organ/eye) ? "face" : "torso"] then wrenches [his_or_her(M)] head back, [pick("pulling", "ripping")] [istype(ono, /obj/item/clothing/head/butt) ? "off" : "out"] [HH]'s [ono] and [pick("flinging", "tossing", "throwing")] it aside for later!</B></span>",\
					blind_message = "<span class='alert'>You hear a loud shunk, followed by a SPLAT!</span>")

			else
				M.visible_message("<span class='alert'><B>[M] [pick("sinks [his_or_her(M)] fangs into", "clamps [his_or_her(M)] jaws around", "gnaws into", "chews on")] [HH]'s [pick("right arm", "left arm", "head", "right leg", "left leg")] and [pick("rips", "tears", "pulls", "rends")] [pick("off", "out", "free", 10;"asunder")] [pick("a hunk", "a chunk", "an ample serving", "a wad", "a clump")] of [pick("skin", "flesh", "meat", "connective tissue", "grody stuff", "[HH]")], devouring it on the spot!</B></span>",\
				blind_message = "<span class='alert'>You hear a loud shunk, followed by [prob(5) ? "VERY impolite lip-smacking" : "a CRUNCH"]!</span>")

			var/bloody = 1
			var/mangled
			var/rotted
			if (HH.health < -150)
				mangled = 1
				healing /= 1.5
				if(!ON_COOLDOWN(M, "yum_message_mangled", 15 SECONDS))
					boutput(M, "<span class='alert'>There isn't much left of [HH]...</span>")

			if (isdead(HH))
				if(HH.decomp_stage)
					rotted = 1
					M.emote("gag")
					if(!ON_COOLDOWN(M, "yum_message_dead_rot", 15 SECONDS))
						if(mangled)
							boutput(M, "<span class='alert'>Eugh! You scrape together and choke down a meager, sour, bitter pile of [HH]'s spoiled meat. You're a hunter, not a scavenger!</span>")
						else
							boutput(M, "<span class='alert'>Eugh! You hold your breath and choke down a sour, bitter hunk of [HH]'s spoiled meat. You're a hunter, not a scavenger!</span>")
					healing /= 2
				else
					if(!ON_COOLDOWN(M, "yum_message_dead", 15 SECONDS))
						boutput(M, "<span class='notice'>[HH]'s motionless carcass, while still warm and satisfying, is somewhat disappointing to eat.</span>")

			if (ismonkey(HH) && !rotted)
				if(isnpcmonkey(HH))
					if(!ON_COOLDOWN(M, "yum_message_monkey_npc", 15 SECONDS))
						boutput(M, "<span class='alert'>This monkey tastes bland, utterly devoid of the sapience you prefer.</span> <span class='notice'>Still, meat is meat...</span>")
					healing /= 2
				else
					if(!ON_COOLDOWN(M, "yum_message_monkey_player", 15 SECONDS))
						boutput(M, "<span class='notice'>This monkey is oddly delicious! It's short and wiry, yet tastes... human.</span>")
			else if (iswizard(HH))
				playsound(get_turf(M), "sound/misc/meat_plop.ogg", 100, 1)
				M.visible_message("<span class='alert'>[M] vomits <i>everywhere</i>.</span>", "<span class='alert'><b>UUAAAUGGHHH...</b> The wizard's meat is cursed.</span>", "<span class='notice'>You hear a pleasant waterfall...?</span>")
				M.emote("scream")
				M.changeStatus("paralysis", 4 SECONDS)
				for (var/turf/T in range(M, rand(2, 3)))
					if (prob(20))
						make_cleanable( /obj/decal/cleanable/greenpuke,T)
					else
						make_cleanable( /obj/decal/cleanable/vomit,T)
				return 0
			else if (isskeleton(HH) && !rotted) // while they shouldn't decompose, you never know!
				if(!ON_COOLDOWN(M, "yum_message_skelly", 15 SECONDS))
					M.emote("gasp")
					boutput(M, "<span class='notice'>THIS HUMAN IS FULL OF BONES!!!</span>")
					if(istype(M.organHolder.tail, /obj/item/organ/tail/wolf))
						M.visible_message("<span class='emote'><b>[M]</b> wags [his_or_her(src)] tail happily!</span>")
						var/list/thumpables = getNeighbors(get_turf(M), alldirs)
						for(var/turf/T in thumpables)
							if(!checkTurfPassable(T))
								M.audible_message("*thump* *thump* *thump*")
								break
					SPAWN_DBG(rand(3 SECONDS, 10 SECONDS))
						boutput(M, "<span class='alert'>Ahem.</span>")
				bloody = 0
				healing *= 2
			else if (iscluwne(HH))
				if(!ON_COOLDOWN(M, "yum_message_cluwne", 15 SECONDS))
					M.emote("gag")
					boutput(M, "<span class='alert'>Augh! The flesh on this monstrous thing is so sickeningly <i>sweet</i>! Most of what you ate comes right back up!</span>")
				healing /= 2
				M.vomit()
				M.take_toxin_damage(5)
			else if (iswerewolf(HH))
				var/wolfpoints
				var/datum/abilityHolder/werewolf/i_wolf = M.get_ability_holder(/datum/abilityHolder/werewolf)
				if(i_wolf?.feed_objective)
					var/datum/objective/specialist/werewolf/feed/i_wolf_feed = i_wolf.feed_objective
					var/datum/abilityHolder/werewolf/u_wolf = HH.get_ability_holder(/datum/abilityHolder/werewolf)
					if(istype(u_wolf) && u_wolf.feed_objective)
						wolfpoints = 1
						var/datum/objective/specialist/werewolf/feed/u_wolf_feed = u_wolf.feed_objective
						var/list/lunch_eaten = u_wolf_feed.mobs_fed_on ^ i_wolf_feed.mobs_fed_on
						var/ate_their_lunch = length(lunch_eaten)
						var/all_their_lunch = length(u_wolf_feed.mobs_fed_on)
						if(ate_their_lunch >= 1)
							for(var/i in 1 to ate_their_lunch)
								i_wolf.feed_objective.feed_count ++
								M.add_stam_mod_regen("feast-[i_wolf.feed_objective.feed_count]", 1)
								M.add_stam_mod_max("feast-[i_wolf.feed_objective.feed_count]", 5)
								M.max_health += 10
								i_wolf.lower_cooldowns(0.10)
							i_wolf_feed.mobs_fed_on |= lunch_eaten
							health_update_queue |= M
							healing *= (ate_their_lunch / 2)
							if(!ON_COOLDOWN(M, "yum_message_ate_pointwolf", 15 SECONDS))
								var/eatcompare
								if(ate_their_lunch == all_their_lunch)
									if(all_their_lunch > 1)
										eatcompare = "all"
									else
										eatcompare = "that"
								else
									eatcompare = "[get_english_num(ate_their_lunch)]"
								switch(ate_their_lunch)
									if(10 to INFINITY)
										boutput(M, "<span class='notice'>The flavors within this beast's flesh! Must've been a very successful [HH.gender == MALE ? "hunter" : "huntress"], [his_or_her(HH)] meat is an absolute banquet of sapience! You feel powerful...</span>")
									if(1 to 9)
										boutput(M, "<span class='notice'>An impressive [HH.gender == MALE ? "hunter" : "huntress"], you can taste [all_their_lunch > 1 ? "at least [get_english_num(all_their_lunch)] unique flavors" : "a flavor other than their own"] infused into their flesh, [eatcompare] of which you've yet to taste! You feel strong!</span>")
									if(2 to 9)
										if(all_their_lunch == 1)
											boutput(M, "<span class='notice'>An impressive [HH.gender == MALE ? "hunter" : "huntress"], you can taste [all_their_lunch > 1 ? "at least [get_english_num(all_their_lunch)] unique flavors" : "a flavor other than their own"] infused into their flesh, [eatcompare] of which you've yet to taste! You feel strong!</span>")
										else
											boutput(M, "<span class='notice'>How adorable, the telltale taste of a fledgeling [HH.gender == MALE ? "hunter" : "huntress"], bearing a single flavor other than [his_or_her(HH)] own, one you've yet to taste! You feel somewhat stronger.</span>")
									else
										boutput(M, "<span class='alert'>You suddenly feel an overwhelming urge to submit a bug report about how you ate a werewolf whose list of eaten people contained no entries common to your own, yet you're still seeing this message.</span>")
							else
								switch(all_their_lunch)
									if(10 to INFINITY)
										boutput(M, "<span class='notice'>This beast must've been a very successful [HH.gender == MALE ? "hunter" : "huntress"]! While [his_or_her(HH)] meat is an absolute banquet of sapience, each of the [get_english_num(all_their_lunch)] different flavors infused into their flesh are ones you've tasted before.</span>")
									if(2 to 9)
										boutput(M, "<span class='notice'>This creature must've been an impressive [HH.gender == MALE ? "hunter" : "huntress"], but all of the [get_english_num(all_their_lunch)] flavors infused into [his_or_her(HH)] flesh are ones you've previously tasted. Still very tasty!</span>")
									if(1)
										boutput(M, "<span class='notice'>How adorable, the telltale taste of a fledgeling [HH.gender == MALE ? "hunter" : "huntress"], bearing a single flavor other than [his_or_her(HH)] own. A single, familiar flavor.</span>")
									else
										boutput(M, "<span class='notice'>The only flavor within this \"[HH.gender == MALE ? "hunter" : "huntress"]\" is [his_or_her(HH)] own.</span>")
				if(!wolfpoints)
					if(!ON_COOLDOWN(M, "yum_message_ate_wolf", 15 SECONDS))
						boutput(M, "<span class='notice'>Though [his_or_her(HH)] meat is tough and stringy, the knowledge that [he_or_she(HH)] is no longer a rival [HH.gender == MALE ? "hunter" : "huntress"] is satisfying enough.</span>")
				healing *= 2
			else if (ishunter(HH))
				if(!ON_COOLDOWN(M, "yum_message_hunter", 15 SECONDS))
					boutput(M, "<span class='notice'>Well, that's something you don't taste every day!</span>")
				healing *= 2
			else if (ischangeling(HH))
				if(!ON_COOLDOWN(M, "yum_message_changer", 15 SECONDS))
					if(isabomination(HH))
						boutput(M, "<span class='notice'>The chunk you've ripped from this horrifying monster flails about in your mouth, trying to wriggle its way to safety! It proves unsuccessful.</span>")
					else
						boutput(M, "<span class='notice'>The hunk of flesh in your mouth tries to leap out of your mouth! It doesn't escape.</span>")

				var/wolflingpoints
				var/datum/abilityHolder/werewolf/me_wolf = M.get_ability_holder(/datum/abilityHolder/werewolf)
				if(me_wolf?.feed_objective)
					var/datum/objective/specialist/werewolf/feed/me_wolf_feed = me_wolf.feed_objective
					var/datum/abilityHolder/changeling/O = HH.get_ability_holder(/datum/abilityHolder/changeling)
					var/list/O_dna = O?.absorbed_dna
					if(length(O_dna) >= 1)
						var/list/O_Uids = list()
						for(var/Uid in O_dna)
							var/datum/bioHolder/BH = O_dna[Uid]
							O_Uids += BH.Uid
						var/list/ling_eaten = O_Uids ^ me_wolf_feed.mobs_fed_on
						me_wolf_feed.mobs_fed_on |= O_Uids
						var/ate_their_ling = length(ling_eaten)
						if(ate_their_ling >= 1)
							for(var/i in 1 to ate_their_ling)
								me_wolf.feed_objective.feed_count ++
								M.add_stam_mod_regen("feast-[me_wolf.feed_objective.feed_count]", 1)
								M.add_stam_mod_max("feast-[me_wolf.feed_objective.feed_count]", 5)
								M.max_health += 10
								me_wolf.lower_cooldowns(0.10)
							health_update_queue |= M
							healing *= (ate_their_ling / 2)

				if(wolflingpoints)
					boutput(M, "<span class='notice'>Your guts churn, trying to beat some sense into what you just ate!</span>")
					SPAWN_DBG(rand(3 SECONDS, 10 SECONDS))
						boutput(M, "<span class='notice'>Your guts prevail.</span>")
						M.emote("fart")
				healing *= 2
			else
				boutput(M, "<span class='notice'>That tasted good!</span>")

			if (HH.nutrition > 100 || istype(HH.mutantrace, /datum/mutantrace/cow)) //beefy
				if(!ON_COOLDOWN(M, "yum_message_cow", 15 SECONDS))
					boutput(M, "<span class='notice'>And there's a lot of it!</span>")
				M.unlock_medal("Space Ham", 1)
				healing *= 2

			if (HH.mind && HH.mind.assigned_role == "Clown")
				if(!ON_COOLDOWN(M, "yum_message_clown", 15 SECONDS))
					boutput(M, "<span class='notice'>...that tasted funny, huh.</span>")
				M.unlock_medal("That tasted funny", 1)

			if(bloody)
				HH.spread_blood_clothes(HH)
				M.spread_blood_hands(HH)

				var/obj/decal/cleanable/blood/gibs/G = null // For forensics.
				G = make_cleanable(/obj/decal/cleanable/blood/gibs,HH.loc)
				if (HH.bioHolder && HH.bioHolder.Uid && HH.bioHolder.bloodType)
					G.blood_DNA = HH.bioHolder.Uid
					G.blood_type = HH.bioHolder.bloodType

			HH.add_fingerprint(M) // Just put 'em on the mob itself, like pulling does. Simplifies forensic analysis a bit.
			M.werewolf_audio_effects(HH, "feast")

			HH.changeStatus("weakened", 2 SECONDS)
			if (prob(33) && !isdead(HH))
				HH.emote("scream")

			M.remove_stamina(60) // Werewolves have a very large stamina and stamina regen boost.
			if (healing > 0)
				M.HealDamage("All", healing, healing)
				M.add_stamina(healing)

		if ("spread")
			var/mob/living/carbon/human/HH = target
			if (!HH || !ishuman(HH))
				return 0
			if (!HH.canmove)
				damage += rand(5,15)
				if (prob(40))
					HH.spread_blood_clothes(HH)
					M.spread_blood_hands(HH)
					var/obj/decal/cleanable/blood/gibs/G = null // For forensics.
					G = make_cleanable(/obj/decal/cleanable/blood/gibs, HH.loc)
					if (HH.bioHolder && HH.bioHolder.Uid && HH.bioHolder.bloodType)
						G.blood_DNA = HH.bioHolder.Uid
						G.blood_type = HH.bioHolder.bloodType
					M.visible_message("<span class='alert'><B>[M] sinks its teeth into [target]! !</B></span>")
				HH.add_fingerprint(M) // Just put 'em on the mob itself, like pulling does. Simplifies forensic analysis a bit.
				M.werewolf_audio_effects(HH, "feast")
				HH.setStatus("weakened",rand(30,60))
				if (prob(70) && HH.stat != 2)
					HH.emote("scream")
		if ("pounce")
			wrestler_knockdown(M, target, 1)
			M.visible_message("<span class='alert'><B>[M] barrels through the air, slashing [target]!</B></span>")
			damage += rand(2,8)
			playsound(M.loc, pick('sound/voice/animal/werewolf_attack1.ogg', 'sound/voice/animal/werewolf_attack2.ogg', 'sound/voice/animal/werewolf_attack3.ogg'), 50, 1)
			if (prob(33) && target.stat != 2)
				target.emote("scream")
		if ("thrash")
			if (prob(75))
				wrestler_knockdown(M, target, 1)
				damage += rand(2,8)
			else
				wrestler_backfist(M, target)
				damage += rand(5,15)

			if (prob(60)) playsound(M.loc, pick('sound/voice/animal/werewolf_attack1.ogg', 'sound/voice/animal/werewolf_attack2.ogg', 'sound/voice/animal/werewolf_attack3.ogg'), 50, 1)
			if (prob(75)) target.setStatus("weakened",30)
			if (prob(33) && target.stat != 2)
				target.emote("scream")

		else
			return 0

	switch (send_flying)
		if (1)
			wrestler_knockdown(M, target)

		if (2)
			wrestler_backfist(M, target)

	if (damage > 0)
		random_brute_damage(target, damage,1)
		target.UpdateDamageIcon()
		target.set_clothing_icon_dirty()

	return 1

// Also called by limb datums.
/mob/proc/werewolf_audio_effects(var/mob/target = null, var/type = "disarm")
	if (!src || !ismob(src) || !target || !ismob(target))
		return

	var/sound_playing = 0

	switch (type)
		if ("disarm")
			playsound(src.loc, pick('sound/voice/animal/werewolf_attack1.ogg', 'sound/voice/animal/werewolf_attack2.ogg', 'sound/voice/animal/werewolf_attack3.ogg'), 50, 1)
			SPAWN_DBG(0.1 SECONDS)
				if (src) playsound(src.loc, "swing_hit", 50, 1)

		if ("swipe")
			if (prob(50))
				playsound(src.loc, pick('sound/voice/animal/werewolf_attack1.ogg', 'sound/voice/animal/werewolf_attack2.ogg', 'sound/voice/animal/werewolf_attack3.ogg'), 50, 1)
			else
				playsound(src.loc, pick('sound/impact_sounds/Flesh_Tear_1.ogg', 'sound/impact_sounds/Flesh_Tear_2.ogg'), 50, 1, -1)

			SPAWN_DBG(0.1 SECONDS)
				if (src) playsound(src.loc, "sound/impact_sounds/Flesh_Tear_3.ogg", 40, 1, -1)

		if ("feast")
			if (sound_playing == 0) // It's a long audio clip.
				playsound(src.loc, "sound/voice/animal/wendigo_maul.ogg", 80, 1)
				sound_playing = 1
				SPAWN_DBG(6 SECONDS)
					sound_playing = 0

			playsound(src.loc, pick('sound/impact_sounds/Flesh_Tear_1.ogg', 'sound/impact_sounds/Flesh_Tear_2.ogg'), 50, 1, -1)
			playsound(src.loc, "sound/items/eatfood.ogg", 50, 1, -1)
			if (prob(40))
				playsound(target.loc, "sound/impact_sounds/Slimy_Splat_1.ogg", 50, 1)
			SPAWN_DBG(1 SECOND)
				if (src && ishuman(src) && prob(50))
					src.emote("burp")

	return

//////////////////////////////////////////// Ability holder /////////////////////////////////////////

/obj/screen/ability/topBar/werewolf
	clicked(params)
		var/datum/targetable/werewolf/spell = owner
		if (!istype(spell))
			return
		if (!spell.holder)
			return
		if (!isturf(owner.holder.owner.loc))
			boutput(owner.holder.owner, "<span class='alert'>You can't use this ability here.</span>")
			return
		if (spell.targeted && usr.targeting_ability == owner)
			usr.targeting_ability = null
			usr.update_cursor()
			return
		if (spell.targeted)
			if (world.time < spell.last_cast)
				return
			usr.targeting_ability = owner
			usr.update_cursor()
		else
			SPAWN_DBG(0)
				spell.handleCast()
		return

/datum/abilityHolder/werewolf
	usesPoints = 0
	regenRate = 0
	tabName = "Werewolf"
	notEnoughPointsMessage = "<span class='alert'>You aren't strong enough to use this ability.</span>"
	var/datum/objective/specialist/werewolf/feed/feed_objective = null
	var/datum/reagents/tainted_saliva_reservoir = null
	var/awaken_time //don't really need this here, but admins might want to know when the werewolf's awaken time is.

	New()
		..()
		awaken_time = rand(5, 10)*100
		src.tainted_saliva_reservoir = new/datum/reagents(500)

	onAbilityStat() // In the 'Werewolf' tab.
		..()
		.= list()
		if (src.owner && src.owner.mind && src.owner.mind.special_role == "werewolf")
			for (var/datum/objective/specialist/werewolf/feed/O in src.owner.mind.objectives)
				src.feed_objective = O

			if (src.feed_objective && istype(src.feed_objective))
				.["Feedings:"] = src.feed_objective.feed_count

		return

//percent, give number 0.0-1.0
/datum/abilityHolder/proc/lower_cooldowns(var/percent)
	for (var/datum/targetable/werewolf/A in src.abilities)
		A.cooldown = A.cooldown * (1-percent)

/////////////////////////////////////////////// Werewolf spell parent ////////////////////////////

/datum/targetable/werewolf
	icon = 'icons/mob/werewolf_ui.dmi'
	icon_state = "template"  // No custom sprites yet.
	cooldown = 0
	last_cast = 0
	pointCost = 0
	preferred_holder_type = /datum/abilityHolder/werewolf
	var/when_stunned = 0 // 0: Never | 1: Ignore mob.stunned and mob.weakened | 2: Ignore all incapacitation vars
	var/not_when_handcuffed = 0
	var/werewolf_only = 0

	New()
		..()
		var/obj/screen/ability/topBar/werewolf/B = new /obj/screen/ability/topBar/werewolf(null)
		B.icon = src.icon
		B.icon_state = src.icon_state
		B.owner = src
		B.name = src.name
		B.desc = src.desc
		src.object = B
		return

	updateObject()
		..()
		if (!src.object)
			src.object = new /obj/screen/ability/topBar/werewolf()
			object.icon = src.icon
			object.owner = src
		if (src.last_cast > world.time)
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[src.name][pttxt] ([round((src.last_cast-world.time)/10)])"
			object.icon_state = src.icon_state + "_cd"
		else
			var/pttxt = ""
			if (pointCost)
				pttxt = " \[[pointCost]\]"
			object.name = "[src.name][pttxt]"
			object.icon_state = src.icon_state
		return

	proc/incapacitation_check(var/stunned_only_is_okay = 0)
		if (!holder)
			return 0

		var/mob/living/M = holder.owner
		if (!M || !ismob(M))
			return 0

		switch (stunned_only_is_okay)
			if (0)
				if (!isalive(M) || M.hasStatus(list("stunned", "paralysis", "weakened")))
					return 0
				else
					return 1
			if (1)
				if (!isalive(M) || M.getStatusDuration("paralysis") > 0)
					return 0
				else
					return 1
			else
				return 1

	castcheck()
		if (!holder)
			return 0

		var/mob/living/carbon/human/M = holder.owner

		if (!M)
			return 0

		if (!ishuman(M)) // Only humans use mutantrace datums.
			boutput(M, "<span class='alert'>You cannot use any powers in your current form.</span>")
			return 0

		if (M.transforming)
			boutput(M, "<span class='alert'>You can't use any powers right now.</span>")
			return 0

		if (werewolf_only == 1 && !iswerewolf(M))
			boutput(M, "<span class='alert'>You must be in your wolf form to use this ability.</span>")
			return 0

		if (incapacitation_check(src.when_stunned) != 1)
			boutput(M, "<span class='alert'>You can't use this ability while incapacitated!</span>")
			return 0

		if (src.not_when_handcuffed == 1 && M.restrained())
			boutput(M, "<span class='alert'>You can't use this ability when restrained!</span>")
			return 0

		return 1

	cast(atom/target)
		. = ..()
		actions.interrupt(holder.owner, INTERRUPT_ACT)
		return
