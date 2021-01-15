/datum/targetable/werewolf/werewolf_feast
	name = "Maul victim"
	desc = "Feast on the target to quell your hunger."
	icon_state = "feast"
	targeted = 1
	target_nodamage_check = 1
	max_range = 1
	cooldown = 10
	pointCost = 0
	when_stunned = 0
	not_when_handcuffed = 1
	werewolf_only = 1
	restricted_area_check = 2

	cast(mob/target)
		if (!holder)
			return 1

		var/mob/living/M = holder.owner

		if (!M || !target || !ismob(target))
			return 1

		if (M == target)
			boutput(M, "<span class='alert'>Why would you want to maul yourself?</span>")
			return 1

		if (get_dist(M, target) > src.max_range)
			boutput(M, "<span class='alert'>[target] is too far away.</span>")
			return 1

		if (!ishuman(target)) // Critter mobs include robots and combat drones. There's not a lot of meat on them.
			boutput(M, "<span class='alert'>[target] probably wouldn't taste very good.</span>")
			return 1

		if (target.canmove)
			boutput(M, "<span class='alert'>[target] is moving around too much.</span>")
			return 1

		logTheThing("combat", M, target, "starts to maul [constructTarget(target,"combat")] at [log_loc(M)].")
		actions.start(new/datum/action/bar/private/icon/werewolf_feast(target, src), M)
		return 0

/datum/action/bar/private/icon/werewolf_feast
	duration = 25 SECONDS
	interrupt_flags = INTERRUPT_STUNNED // Wolf can move around while eating, and is interrupted with stuns or moving the target out of reach
	id = "werewolf_feast"
	icon = 'icons/mob/critter_ui.dmi'
	icon_state = "devour_over"
	var/mob/living/target
	var/datum/targetable/werewolf/werewolf_feast/feast
	var/times_eaten = 0
	var/do_we_get_points = 0 // For the specialist objective. Did we feed on the target long enough?

	New(Target, Feast)
		target = Target
		feast = Feast
		..()

	onStart()
		..()

		var/mob/living/M = owner
		var/datum/abilityHolder/A = feast.holder

		if (!feast || get_dist(M, target) > feast.max_range || target == null || M == null || !ishuman(target) || !ishuman(M) || !A || !istype(A))
			interrupt(INTERRUPT_ALWAYS)
			return

		// It's okay when the victim expired half-way through the feast, but plain corpses are too cheap.
		if (target.stat == 2)
			boutput(M, "<span class='alert'>Urgh, this cadaver tasted horrible. Better find some fresh meat.</span>")
			if(ishuman(target))
				var/mob/living/carbon/human/H = target
				var/obj/item/organ/O = H.organHolder?.drop_and_throw_organ("any")
				if(O) // take an organ for your trouble
					target.visible_message("<span class='alert'><B>[M] rips \an [O] out of [target]'s corpse!</B></span>")
			interrupt(INTERRUPT_ALWAYS)
			return

		A.locked = 1
		playsound(M.loc, pick('sound/voice/animal/werewolf_attack1.ogg', 'sound/voice/animal/werewolf_attack2.ogg', 'sound/voice/animal/werewolf_attack3.ogg'), 50, 1)
		M.visible_message("<span class='alert'><B>[M] lunges at [target]!</b></span>")

	onUpdate()
		..()

		var/mob/living/M = owner
		var/datum/abilityHolder/werewolf/A = feast.holder
		var/mob/living/carbon/human/HH = target

		if (!feast || get_dist(M, target) > feast.max_range || target == null || M == null || !ishuman(target) || !ishuman(M) || !A || !istype(A))
			interrupt(INTERRUPT_ALWAYS)
			return

		// imagine this copypasted about a dozen times
		if(!ON_COOLDOWN(owner, "feast_cooldown", 2.5 SECONDS)) // at least I think it was 2.5 seconds
			if (M.werewolf_attack(target, "feast"))
				src.times_eaten++
			else
				boutput(M, "<span class='alert'>[target] is moving around too much.</span>")
				interrupt(INTERRUPT_ALWAYS)
				return

		if(src.times_eaten > 6 && !src.do_we_get_points)
			if (HH.decomp_stage <= 2 && !(isnpcmonkey(target))) // Can't farm npc monkeys.
				src.do_we_get_points = 1
				if ((HH?.bioHolder?.Uid in A.feed_objective.mobs_fed_on))
					boutput(M, "<span class='alert'>[HH] is still just as delicious as <i>the last time you ate [him_or_her(HH)]</i>.</span>")
				else
					boutput(M, "<span class='notice'>[HH] is a very satisfying meal!</span>")

	onEnd()
		..()

		var/datum/abilityHolder/A = feast.holder
		var/mob/living/M = owner
		var/mob/living/carbon/human/HH = target

		// AH parent var for AH.locked vs. specific one for the feed objective.
		// Critter mobs only use one specific type of abilityHolder for instance.
		if (istype(A, /datum/abilityHolder/werewolf))
			var/datum/abilityHolder/werewolf/W = A
			if (W.feed_objective && istype(W.feed_objective, /datum/objective/specialist/werewolf/feed/))
				if (src.do_we_get_points == 1)
					if (istype(HH) && HH.bioHolder)
						if (!W.feed_objective.mobs_fed_on.Find(HH.bioHolder.Uid))
							W.feed_objective.mobs_fed_on.Add(HH.bioHolder.Uid)
							W.feed_objective.feed_count++
							M.add_stam_mod_regen("feast-[W.feed_objective.feed_count]", 2)
							M.add_stam_mod_max("feast-[W.feed_objective.feed_count]", 10)
							M.max_health += 10
							health_update_queue |= M
							W.lower_cooldowns(0.10)
							boutput(M, "<span class='notice'>You finish chewing on [HH], but what a feast it was!</span>")
						else
							boutput(M, "<span class='alert'>You've mauled [HH] before and didn't like the aftertaste. Better find a different prey.</span>")
					else
						boutput(M, "<span class='alert'>What a meagre meal. You're still hungry...</span>")
				else
					boutput(M, "<span class='alert'>What a meagre meal. You're still hungry...</span>")
			else
				boutput(M, "<span class='alert'>You finish chewing on [HH].</span>")
		else
			boutput(M, "<span class='alert'>You finish chewing on [HH].</span>")

		if (A && istype(A))
			A.locked = 0

	onInterrupt()
		..()

		var/datum/abilityHolder/A = feast.holder
		var/mob/living/M = owner
		var/mob/living/carbon/human/HH = target

		if (istype(A, /datum/abilityHolder/werewolf))
			var/datum/abilityHolder/werewolf/W = A
			if (W.feed_objective && istype(W.feed_objective, /datum/objective/specialist/werewolf/feed/))
				if (src.do_we_get_points == 1)
					if (istype(HH) && HH.bioHolder)
						if (!W.feed_objective.mobs_fed_on.Find(HH.bioHolder.Uid))
							W.feed_objective.mobs_fed_on.Add(HH.bioHolder.Uid)
							W.feed_objective.feed_count++
							M.add_stam_mod_regen("feast-[W.feed_objective.feed_count]", 1)
							M.add_stam_mod_max("feast-[W.feed_objective.feed_count]", 5)
							M.max_health += 10
							health_update_queue |= M
							W.lower_cooldowns(0.10)
							boutput(M, "<span class='notice'>Your feast was interrupted, but it satisfied your hunger for the time being.</span>")
						else
							boutput(M, "<span class='alert'>You've mauled [HH] before and didn't like the aftertaste. Better find a different prey.</span>")
					else
						boutput(M, "<span class='alert'>Your feast was interrupted and you're still hungry...</span>")
				else
					boutput(M, "<span class='alert'>Your feast was interrupted and you're still hungry...</span>")
			else
				boutput(M, "<span class='alert'>Your feast was interrupted.</span>")
		else
			boutput(M, "<span class='alert'>Your feast was interrupted.</span>")

		if (A && istype(A))
			A.locked = 0
