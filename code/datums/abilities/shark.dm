/datum/abilityHolder/shark
	usesPoints = 0
	regenRate = 0
	tabName = "Shark"
	notEnoughPointsMessage = "<span class='alert'>You aren't strong enough to use this ability.</span>"



// -----------------
// Shark person abilities
// -----------------
/datum/targetable/shark/bite
	name = "Shark Attack"
	desc = "Bite someone or something."
	cooldown = 150
	targeted = 1
	target_anything = 1
	var/sound_bite = 'sound/voice/animal/werewolf_attack1.ogg'
	var/brute_damage = 16

	var/datum/projectile/slam/proj = new

	cast(atom/target)
		if (..())
			return 1
		if (isobj(target))
			target = get_turf(target)
		if (isturf(target))
			target = locate(/mob/living) in target
			if (!target)
				boutput(holder.owner, __red("Nothing to bite there."))
				return 1
		if (target == holder.owner)
			return 1
		if (get_dist(holder.owner, target) > 1)
			boutput(holder.owner, __red("That is too far away to bite."))
			return 1
		playsound(target, src.sound_bite, 50, 1, -1)
		var/mob/MT = target
		MT.TakeDamageAccountArmor("All", src.brute_damage, 0, 0, DAMAGE_CRUSH)
		holder.owner.visible_message("<span class='combat'><b>[holder.owner] bites [MT]!</b></span>", "<span class='combat'>You bite [MT]!</span>")
		return 0

/datum/targetable/shark/gun
	name = "Use Gun"
	desc = "Deploy and fire your internal gun."
	cooldown = 10
	targeted = 1
	can_target_ghosts = 1
	check_range = 0
	sticky = 1
	ignore_sticky_cooldown = 1
	var/deployed = 0
	var/deploying = 0
	var/is_sharkgun = 0

	proc/deploy_gun()
		if (!holder)
			return 0

		var/mob/living/carbon/human/M = holder.owner

		if (!M)
			return 0

		if(ishuman(M))
			if (M.head || M.wear_mask || M.glasses)
				boutput(M, "<span class='notice'>You need to take off all your headgear first.</span>")
				return

			if (!M.insidegun)
				boutput(M, "<span class='notice'>You strain, but nothing comes up! The place where you hold your gun is empty!</span>")
				M.emote("burp")
				return

			if (!istype(M.insidegun, /obj/item/gun))
				M.visible_message("\An [M.insidegun] flies out of [M]'s mouth!", "<span class='alert'>You try to move your [M.insidegun] into firing position, but its odd shape makes it fly out of your mouth!</span>")
				M.emote("burp")
				var/obj/item/urp = M.insidegun
				urp.set_loc(get_turf(M))
				//something something throw it
				return

			if (istype(M.insidegun, /obj/item/gun/kinetic/minigun))
				deployed = 1
			else
				deployed = 1
				is_sharkgun = 1

			actions.start(new/datum/action/bar/sharkdeploy(M, src, M.insidegun, is_sharkgun), M)
			return


	proc/CheckMagCellWhatever()
		var/mob/living/carbon/human/M = src.holder.owner
		if(!M.insidegun)
			return 0 // You're just trying to puke on them, arent you?

		if (istype(M.insidegun, /obj/item/gun/kinetic/meowitzer/inert)) // cats4days
			var/obj/item/gun/kinetic/meowgun = M.insidegun
			meowgun.ammo.amount_left = meowgun.ammo.max_amount
			return 1 // mew2meow!

		if (istype(M.insidegun, /obj/item/gun/bling_blaster))
			var/obj/item/gun/bling_blaster/cash_gun = M.insidegun
			if (cash_gun.cash_max)
				if (cash_gun.cash_amt >= cash_gun.shot_cost)
					return 1 // totally cash!
				else
					return 0 // totally not cash!
			else // i blame haine
				return 0

		if (istype(M.insidegun, /obj/item/gun/kinetic))
			var/obj/item/gun/kinetic/shootgun = M.insidegun
			if (shootgun.ammo) // is our gun even loaded with anything?
				if (shootgun.ammo.amount_left >= shootgun.current_projectile.cost)
					return 1 // good2shoot!
				else
					return 0 // until we can fire an incomplete burst, our gun isnt good2shoot
			else // no?
				return 0 // huh

		else if (istype(M.insidegun, /obj/item/gun/energy))
			var/obj/item/gun/energy/pewgun = M.insidegun
			if(pewgun.cell) // did we remember to load our energygun?
				if (pewgun.cell.charge >= pewgun.current_projectile.cost) // okay cool we can shoot!
					return 1
				else // oh no we cant!
					return 0
			else
				return 0 // maybe try putting batteries in it next time

	proc/ShootTheGun(var/target as mob|turf|null, var/thing2shoot as null)
		var/mob/living/carbon/human/M = src.holder.owner
		if (!target) // if no target, then pick something!
			if (!thing2shoot || !istype(thing2shoot, /datum/projectile/))
				if(M?.insidegun?.current_projectile)
					thing2shoot = M.insidegun.current_projectile
				else
					thing2shoot = new/datum/projectile/bullet/revolver_38/stunners
			var/list/mob/nearby_dorks = list()
			for (var/mob/living/D in oview(7, src))
				nearby_dorks.Add(D)
			if(nearby_dorks.len > 0)
				var/griffed = pick(nearby_dorks)
				shoot_projectile_ST_pixel(src, thing2shoot, griffed)
				return griffed
			else
				var/random_direction = get_offset_target_turf(src, rand(5)-rand(5), rand(5)-rand(5))
				shoot_projectile_ST_pixel(src, thing2shoot, random_direction)

		var/target_turf = get_turf(target)
		var/my_turf = get_turf(src)
		M.insidegun.shoot(target_turf, my_turf, src)
		return 1

	cast(atom/target)
		var/mob/living/carbon/human/M = src.holder.owner
		if (..())
			return 1
		if(!deployed)
			deploy_gun()
			return
		if (src.deploying)
			boutput(holder.owner, "<span class='alert'>Your gun isn't ready yet!</span>")
			return
		else
			if (!M.insidegun)
				return
			if (CheckMagCellWhatever())
				ShootTheGun(target)
				M.visible_message("<span class='alert'><B>[M] fires [M.insidegun] at [target]!</B></span>")
			else
				playsound(M, "sound/weapons/Gunclick.ogg", 60, 1)
		return

/obj/screen/ability/topBar/shark
	clicked(params)
		var/datum/targetable/shark/gun/sharkgun = owner
		var/datum/abilityHolder/holder = owner.holder

		if (!istype(sharkgun))
			return
		if (!sharkgun.holder)
			return

		if (!isturf(usr.loc))
			return
		if (world.time < sharkgun.last_cast)
			return
		if (sharkgun.targeted && usr.targeting_ability == owner)
			sharkgun.deployed = 0
			boutput(holder.owner, "You put your gun away.")
			usr.targeting_ability = null
			usr.update_cursor()
			return
		if (sharkgun.targeted)
			usr.targeting_ability = owner
			usr.update_cursor()
		else
			SPAWN_DBG(0)
				sharkgun.handleCast()

/datum/action/bar/sharkdeploy
	duration = 2 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "sharkdeploy"
	var/mob/living/carbon/human/M
	var/obj/item/gun/sharkgun
	var/datum/targetable/shark/gun/thisability
	var/issharkgun

	New(var/mob/living/carbon/human/S, var/datum/targetable/shark/gun/ability, var/obj/item/gun/shark_gun, var/is_sharkgun)
		M = S
		sharkgun = shark_gun
		issharkgun = is_sharkgun
		thisability = ability

	onUpdate()
		..()

	onStart()
		..()

		M.visible_message("[M] throws [his_or_her(M)] head back and starts retching!",\
		"<span class='notice'>You open your mouth and start moving your gun into firing position!</span>")
		if (!issharkgun)
			boutput(M, "<span class='notice'>\The [sharkgun]'s unfamiliar shape makes it difficult to deploy!</span>")
			duration *= 2
		thisability.deploying = 1
		..()

	onEnd()
		thisability.deployed = 1
		M.visible_message("\A [sharkgun] pokes its way out of [M]'s mouth!",\
		"<span class='notice'>Your [sharkgun] slides its way into firing position!</span>")
		thisability.deploying = 0

	onInterrupt()
		M.visible_message("[M] swallows [his_or_her(M)] [sharkgun].",\
		"<span class='alert'>You were interrupted! Your [sharkgun] slides back to where it came from.</span>")
		thisability.deploying = 0
		..()
