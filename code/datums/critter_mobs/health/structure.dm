/datum/healthHolder/structure
	name = "structural"
	associated_damage_type = "brute"

	on_attack(var/obj/item/I, var/mob/M)
		var/list/burn_return = list(HAS_EFFECT = ITEM_EFFECT_NOTHING, EFFECT_RESULT = ITEM_EFFECT_FAILURE)
		SEND_SIGNAL(this = I, COMSIG_ITEM_ATTACK_OBJECT, src, user = M, results = burn_return, use_amt = 1, noisy = 1)
		if(burn_return[HAS_EFFECT] & ITEM_EFFECT_WELD)
			if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NO_FUEL)
				boutput(M, "<span class='notice'>\the [I] is out of fuel!</span>")
			else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ENOUGH_FUEL)
				boutput(M, "<span class='notice'>\the [I] doesn't have enough fuel!</span>")
			else if(burn_return[EFFECT_RESULT] & ITEM_EFFECT_NOT_ON)
				boutput(M, "<span class='notice'>\the [I] isn't lit!</span>")
			else if (damaged())
				holder.visible_message("<span class='notice'>[M] repairs some dents on [holder]!</span>")
				HealDamage(5)
			else
				M.show_message("<span class='alert'>Nothing to repair on [holder]!")
			return 0
		else
			return ..()
