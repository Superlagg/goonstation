var/list/forensic_IDs = new/list() //Global list of all guns, based on bioholder uID stuff

/obj/item/gun
	name = "gun"
	icon = 'icons/obj/items/gun.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	flags =  FPRINT | TABLEPASS | CONDUCT | ONBELT | USEDELAY | EXTRADELAY
	event_handler_flags = USE_GRAB_CHOKE | USE_FLUID_ENTER
	special_grab = /obj/item/grab/gunpoint

	item_state = "gun"
	m_amt = 2000
	force = 10.0
	throwforce = 5
	w_class = 3.0
	throw_speed = 4
	throw_range = 6
	contraband = 4
	hide_attack = 2 //Point blanking... gross
	pickup_sfx = "sound/items/pickup_gun.ogg"
	inventory_counter_enabled = 1

	var/continuous = 0 //If 1, fire pixel based while button is held.
	var/c_interval = 3 //Interval between shots while button is held.
	var/c_windup = 0 //Time before we start firing while button is held - think minigun.
	var/c_windup_sound = null //Sound to play during windup. TBI

	var/c_firing = 0
	var/c_mouse_down = 0
	var/datum/gunTarget/c_target = null

	var/suppress_fire_msg = 0

	var/rechargeable = 0 // Can we put this gun in a recharger?
	var/robocharge = 800
	var/custom_cell_max_capacity = null // Is there a limit as to what power cell (in PU) we can use?
	var/wait_cycle = 0 // Using a self-charging cell should auto-update the gun's sprite.

	/// Currently loaded magazine, shoot will read whatever's in its mag_contents to determine what to shoot
	/// Should be null here, but can be overridden in the gun's New()
	var/obj/item/ammo/loaded_magazine
	/// Magazine to load into the gun when spawned
	/// Should *not* be null, empty guns should have at least some kind of obj/item/ammo/bullets/empty
	var/obj/item/ammo/ammo = /obj/item/ammo/bullets/empty
	/// Checks against the magazine's caliber to see if it'll hold it
	var/caliber = CALIBER_ANY // Can be a list too. The .357 Mag revolver can also chamber .38 Spc rounds, for instance (Convair880).
	/// What kind(s) of magazine do we accept?
	/// Set to AMMO_ENERGY to make the gun an energy weapon
	var/list/accepted_mag = list(AMMO_PILE, AMMO_CLIP)
	/// Is the magazine fixed in place and cant be removed, like a shotgun? Makes most sense with accepted_mag AMMO_PILE and AMMO_CLIP
	var/fixed_mag = FALSE

	/// Overrides the bullet's own shoot-sound. Uses bullet's sound if null
	var/shoot_sound
	/// Overrides the bullet's own shoot-sound, but when the gun is silenced. Uses bullet's sound if null
	var/shoot_sound_silenced
	/// Sound it plays when out of ammo
	var/shoot_sound_empty = "sound/weapons/Gunclick.ogg"

	/// Infinite Ammo -- Magazine list isnt changed on firing
	/// Projectile Override -- Shoot default projectile instead of what's in the mag's list

	var/has_empty_state = 0 //does this gun have a special icon state for having no ammo lefT?
	var/gildable = 0 //can this gun be affected by the [Helios] medal reward?

	var/auto_eject = 0 // Do we eject casings on firing, or on reload?
	/// Stores whatever casings dont get ejected
	var/list/casings_to_eject = list() // If we don't automatically ejected them, we need to keep track (Convair880).

	var/allowReverseReload = 1 //Use gun on ammo to reload
	var/allowDropReload = 1    //Drag&Drop ammo onto gun to reload

	// On non-energy weapons, this is set by the top index in src.loaded_magazine.mag_contents when asked to shoot
	// On energy weapons, this is set by the firemode's "projectile" setting
	// In either case, this should probably stay null
	var/datum/projectile/current_projectile = null

	var/silenced = 0
	var/can_dual_wield = 1

	var/slowdown = 0 //Movement delay attack after attack
	var/slowdown_time = 10 //For this long

	var/forensic_ID = null
	var/add_residue = 0 // Does this gun add gunshot residue when fired (Convair880)?

	var/charge_up = 0 //Does this gun have a charge up time and how long is it? 0 = normal instant shots.

	/// Number of times to shoot the gun when asked to shoot
	var/burst_count = 1
	/// Time after clicking the gun before it'll allow you to click with the gun again
	var/shoot_delay = 4
	/// Time between shots in a burst
	var/refire_delay = (0.7 DECI SECONDS)
	/// If not 0, the bullet will shoot off course by between 0 and this number degrees
	var/spread_angle = 0
	/// List of firemodes, changes how the gun fires
	/// structure: list(list("name" = "name of mode", "burst_count" = burst, "refire_delay" = refire_delay, "shoot_delay" = shoot_delay, "spread_angle" = spread_angle, "projectile" = null))
	/// if "projectile" is blank, it'll use the projectile stored in the magazine
	var/list/firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7, "shoot_delay" = 4, "spread_angle" = 0, "projectile" = null))
	/// Our current firemode's index
	var/firemode_index = 1

	/// Currently shooting, so don't accept more requests to shoot
	var/shooting = 0

	var/muzzle_flash = null //set to a different icon state name if you want a different muzzle flash when fired, flash anims located in icons/mob/mob.dmi

	buildTooltipContent()
		. = ..()
		if(current_projectile)
			. += "<br><img style=\"display:inline;margin:0\" src=\"[resource("images/tooltips/ranged.png")]\" width=\"10\" height=\"10\" /> Bullet Power: [current_projectile.power] - [current_projectile.ks_ratio * 100]% lethal"
		lastTooltipContent = .

	New()
		if(!islist(src.caliber))
			src.caliber = list(src.caliber)
		if(!islist(src.accepted_mag))
			src.accepted_mag = list(src.accepted_mag)
		if(!src.loaded_magazine)
			src.loaded_magazine = new src.ammo
			src.loaded_magazine.loaded_in = src
		src.set_firemode(TRUE)
		SPAWN_DBG(2 SECONDS)
			src.forensic_ID = src.CreateID()
			forensic_IDs.Add(src.forensic_ID)
		return ..()

/datum/gunTarget
	var/params = null
	var/target = null
	var/user = 0

/obj/item/gun/proc/sanitycheck(var/casings = 0, var/ammo = 1)
	if (casings && (src.casings_to_eject.len > 30 || src.current_projectile?.shot_number > 30))
		logTheThing("debug", usr, null, "<b>Convair880</b>: [usr]'s gun ([src]) ran into the casings_to_eject cap, aborting.")
		if (src.casings_to_eject > 0)
			src.casings_to_eject = 0
		return 0
	// if (ammo && (src.max_ammo_capacity > 200 || src.ammo.amount_left > 200))
	// 	logTheThing("debug", usr, null, "<b>Convair880</b>: [usr]'s gun ([src]) ran into the magazine cap, aborting.")
	// 	return 0
	return 1

/obj/item/gun/onMouseDrag(src_object,over_object,src_location,over_location,src_control,over_control,params)
	if(!continuous) return
	if(c_target == null) c_target = new()
	c_target.params = params2list(params)
	c_target.target = over_object
	c_target.user = usr

/obj/item/gun/onMouseDown(atom/object,location,control,params) //This doesnt work with reach, will pistolwhip once. FIX.
	if(!continuous) return
	if(object == src || (!isturf(object.loc) && !isturf(object))) return
	if(ishuman(usr))
		var/mob/living/carbon/human/H = usr
		if(H.in_throw_mode) return
	c_mouse_down = 1
	SPAWN_DBG(c_windup)
		if(!c_firing && c_mouse_down)
			continuousFire(object, params, usr)

/obj/item/gun/onMouseUp(object,location,control,params)
	c_mouse_down = 0

/obj/item/gun/proc/continuousFire(atom/target, params, mob/user)
	if(!continuous) return
	if(c_target == null) c_target = new()
	c_target.params = params2list(params)
	c_target.target = target
	c_target.user = user

	if(!c_firing)
		c_firing = 1
		SPAWN_DBG(0)
			while(src?.c_mouse_down)
				pixelaction(src.c_target.target, src.c_target.params, src.c_target.user, 0, 1)
				suppress_fire_msg = 1
				sleep(src.c_interval)
			src.c_firing = 0
			suppress_fire_msg = 0

/obj/item/gun/proc/CreateID() //Creates a new tracking id for the gun and returns it.
	var/newID = ""

	do
		for(var/i = 1 to 10) // 20 characters are way too fuckin' long for anyone to care about
			newID += "[pick(numbersAndLetters)]"
	while(forensic_IDs.Find(newID))

	return newID

///CHECK_LOCK
///Call to run a weaponlock check vs the users implant
///return FALSE for fail
/obj/item/gun/proc/check_lock(var/user as mob)
	return TRUE

///CHECK_VALID_SHOT
///Call to check and make sure the shot is ok
///Not called much atm might remove, is now inside shoot
/obj/item/gun/proc/check_valid_shot(atom/target as mob|obj|turf|area, mob/user as mob)
	var/turf/T = get_turf(user)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return FALSE
	if (U == T)
		//user.bullet_act(current_projectile)
		return FALSE
	return TRUE
/*
/obj/item/gun/proc/emag(obj/item/A as obj, mob/user as mob)
	if(istype(A, /obj/item/card/emag))
		boutput(user, "<span class='alert'>No lock to break!</span>")
		return TRUE
	return FALSE
*/
/obj/item/gun/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (user)
		boutput(user, "<span class='alert'>No lock to break!</span>")
	return FALSE

/obj/item/gun/attackby(obj/item/ammo/b as obj, mob/user as mob)
	if(istype(b, /obj/item/ammo/))
		switch (b.loadammo(src, user))
			if(0)
				user.show_text("You can't reload this gun.", "red")
				return
			if(1)
				user.show_text("This ammo won't fit!", "red")
				return
			if(2)
				user.show_text("There's no ammo left in [b.name].", "red")
				return
			if(3)
				user.show_text("[src] is full!", "red")
				return
			if(4)
				user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>There wasn't enough ammo left in [b.name] to fully reload [src]. It only has [src.loaded_magazine.mag_contents.len] rounds remaining.</span>")
				src.logme_temp(user, src, b) // Might be useful (Convair880).
				return
			if(5)
				user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>You fully reload [src] with ammo from [b.name]. There are [b.amount_left] rounds left in [b.name].</span>")
				src.logme_temp(user, src, b)
				return
			if(6)
				// switch (src.ammo.swap(b,src))
				// 	if(0)
				// 		user.show_text("This ammo won't fit!", "red")
				// 		return
				// 	if(1)
				// 		user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>You swap out the magazine. Or whatever this specific gun uses.</span>")
				// 	if(2)
				// 		user.visible_message("<span class='alert'>[user] reloads [src].</span>", "<span class='alert'>You swap [src]'s ammo with [b.name]. There are [b.amount_left] rounds left in [b.name].</span>")
				src.logme_temp(user, src, b)
				return
	else
		..()

/obj/item/gun/attack_self(mob/user)
	if(src.firemodes.len > 1)
		src.set_firemode(user)

		// // Make a copy here to avoid item teleportation issues.
		// var/obj/item/ammo/bullets/ammoHand = new src.loaded_magazine.type
		// ammoHand.amount_left = src.loaded_magazine.mag_contents.len
		// ammoHand.name = src.loaded_magazine.name
		// ammoHand.icon = src.loaded_magazine.icon
		// ammoHand.icon_state = src.loaded_magazine.icon_state
		// ammoHand.ammo_type = src.loaded_magazine.ammo_type
		// ammoHand.delete_on_reload = 1 // No duplicating empty magazines, please (Convair880).
		// ammoHand.update_icon()
		// user.put_in_hand_or_drop(ammoHand)

		// // The gun may have been fired; eject casings if so.
		// src.ejectcasings()
		// src.casings_to_eject = 0

		// src.update_icon()
		// src.loaded_magazine.mag_contents.len = 0
		// src.add_fingerprint(user)
		// ammoHand.add_fingerprint(user)

		// user.visible_message("<span class='alert'>[user] unloads [src].</span>", "<span class='alert'>You unload [src].</span>")
		// //DEBUG_MESSAGE("Unloaded [src]'s ammo manually.")
		// return

	return ..()

/obj/item/gun/proc/set_firemode(var/mob/user, var/initialize = 0)
	if(initialize)
		if(!src.firemodes.len) // Not spawned with a list of firemodes? Generate one from the current settings
			src.firemodes = list(list("name" = "single shot", "burst_count" = src.burst_count, "refire_delay" = src.refire_delay, "shoot_delay" = src.shoot_delay, "projectile" = src.current_projectile))
	else
		src.firemode_index += 1
		if(src.firemode_index > round(src.firemodes.len) || src.firemode_index < 1)
			src.firemode_index = 1
	src.shoot_delay = src.firemodes[src.firemode_index]["shoot_delay"]
	src.burst_count = src.firemodes[src.firemode_index]["burst_count"]
	src.refire_delay = src.firemodes[src.firemode_index]["refire_delay"]
	src.spread_angle = src.firemodes[src.firemode_index]["spread_angle"]
	. = "<span class='notice'>you set [src] to [src.firemodes[src.firemode_index]["name"]].</span>"
	if(istype(src.firemodes[src.firemode_index]["projectile"], /datum/projectile))
		src.current_projectile = new src.firemodes[src.firemode_index]["projectile"]
		. += "<span class='notice'>Each shot will use [src.current_projectile.cost] ammo units.</span>"
	if(user)
		boutput(user, .)

/obj/item/gun/proc/swap(var/obj/item/ammo/A, var/mob/user)
	// // I tweaked this for improved user feedback and to support zip guns (Convair880).
	// var/check = 0
	// if (!A || !src)
	// 	check = 0
	// if (src.sanitycheck() == 0)
	// 	check = 0
	// if (A.caliber == src.caliber)
	// 	check = 1
	// else if (A.caliber in src.caliber) // Some guns can have multiple calibers.
	// 	check = 1
	// else if (src.caliber == null) // Special treatment for zip guns, huh.
	// 	check = 1
	// if (!check)
	// 	return 0
	// 	//DEBUG_MESSAGE("Couldn't swap [src]'s ammo ([src.ammo.type]) with [A.type].")

	// // The gun may have been fired; eject casings if so.
	// src.ejectcasings()

	// // We can't delete A here, because there's going to be ammo left over.
	// if (src.max_ammo_capacity < A.amount_left)
	// 	// Some ammo boxes have dynamic icon/desc updates we can't get otherwise.
	// 	var/obj/item/ammo/bullets/ammoDrop = new src.ammo.type
	// 	ammoDrop.amount_left = src.ammo.amount_left
	// 	ammoDrop.name = src.ammo.name
	// 	ammoDrop.icon = src.ammo.icon
	// 	ammoDrop.icon_state = src.ammo.icon_state
	// 	ammoDrop.ammo_type = src.ammo.ammo_type
	// 	ammoDrop.delete_on_reload = 1 // No duplicating empty magazines, please.
	// 	ammoDrop.update_icon()
	// 	usr.put_in_hand_or_drop(ammoDrop)
	// 	src.ammo.amount_left = 0 // Make room for the new ammo.
	// 	src.ammo.loadammo(A, src) // Let the other proc do the work for us.
	// 	//DEBUG_MESSAGE("Swapped [src]'s ammo with [A.type]. There are [A.amount_left] round left over.")
	// 	return 2

	// else

	// 	usr.u_equip(A) // We need a free hand for ammoHand first.

	// 	// Some ammo boxes have dynamic icon/desc updates we can't get otherwise.
	// 	var/obj/item/ammo/bullets/ammoHand = new src.ammo.type
	// 	ammoHand.amount_left = src.ammo.amount_left
	// 	ammoHand.name = src.ammo.name
	// 	ammoHand.icon = src.ammo.icon
	// 	ammoHand.icon_state = src.ammo.icon_state
	// 	ammoHand.ammo_type = src.ammo.ammo_type
	// 	ammoHand.delete_on_reload = 1 // No duplicating empty magazines, please.
	// 	ammoHand.update_icon()
	// 	usr.put_in_hand_or_drop(ammoHand)

	// 	var/obj/item/ammo/bullets/ammoGun = new A.type // Ditto.
	// 	ammoGun.amount_left = A.amount_left
	// 	ammoGun.name = A.name
	// 	ammoGun.icon = A.icon
	// 	ammoGun.icon_state = A.icon_state
	// 	ammoGun.ammo_type = A.ammo_type
	// 	//DEBUG_MESSAGE("Swapped [src]'s ammo with [A.type].")
	// 	qdel(src.ammo) // Make room for the new ammo.
	// 	qdel(A) // We don't need you anymore.
	// 	ammoGun.set_loc(src)
	// 	src.ammo = ammoGun
	// 	src.current_projectile = ammoGun.ammo_type
	// 	if(src.silenced)
	// 		src.current_projectile.shot_sound = 'sound/machines/click.ogg'
	// 	src.update_icon()

	// 	return 1

	// ok lets load it
	// Only accept magazines, boxes, and batteries. Everything else it handled by mag-to-mag transfer procs
	var/list/allowed_kinds = list(AMMO_MAGAZINE, AMMO_ENERGY, AMMO_BOX)
	if(!(A.mag_type in allowed_kinds))
		boutput(user, "Wrong kind of thing to put into this thing!")
		return 0


	A.set_loc(src)
	user.u_equip(A)
	if(src.loaded_magazine.is_null_mag)
		qdel(src.loaded_magazine)
	else
		var/obj/item/ammo/old_mag = src.loaded_magazine
		old_mag.loaded_in = null
		old_mag.update_bullet_manifest()
		old_mag.update_icon()
		user.put_in_hand_or_drop(old_mag)
	src.loaded_magazine = A
	src.loaded_magazine.loaded_in = src
	src.loaded_magazine.update_bullet_manifest()
	src.loaded_magazine.update_icon()
	src.update_icon()
	//src.ejectcasings()
	//playsound(get_turf(src), sound_load, 50, 1)

	/* if (src.ammo.amount_left < 0)
		src.ammo.amount_left = 0
	if (A.amount_left < 1)
		return 2 // Magazine's empty.
	if (src.ammo.amount_left >= src.max_ammo_capacity)
		if (src.ammo.ammo_type.type != A.ammo_type.type)
			return 6 // Call swap().
		return 3 // Gun's full.
	if (src.ammo.amount_left > 0 && src.ammo.ammo_type.type != A.ammo_type.type)
		return 6 // Call swap().

	else */

	// Required for swap() to work properly (Convair880).
	/* if (src.ammo.type != A.type || A.force_new_current_projectile)
		var/obj/item/ammo/bullets/ammoGun = new A.type
		ammoGun.amount_left = src.ammo.amount_left
		ammoGun.ammo_type = src.ammo.ammo_type
		qdel(src.ammo)
		ammoGun.set_loc(src)
		src.ammo = ammoGun
		src.current_projectile = A.ammo_type
		if(src.silenced)
			src.current_projectile.shot_sound = 'sound/machines/click.ogg'

		//DEBUG_MESSAGE("Equalized [src]'s ammo type to [A.type]")

	var/move_amount = min(A.amount_left, src.max_ammo_capacity - src.ammo.amount_left)
	A.amount_left -= move_amount
	src.ammo.amount_left += move_amount
	src.ammo.ammo_type = A.ammo_type

	if ((A.amount_left < 1) && (src.ammo.amount_left < src.max_ammo_capacity))
		A.update_icon()
		src.update_icon()
		src.ammo.update_icon()
		if (A.delete_on_reload)
			//DEBUG_MESSAGE("[src]: [A.type] (now empty) was deleted on partial reload.")
			qdel(A) // No duplicating empty magazines, please (Convair880).
		return 4 // Couldn't fully reload the gun.
	if ((A.amount_left >= 0) && (src.ammo.amount_left == src.max_ammo_capacity))
		A.update_icon()
		src.update_icon()
		src.ammo.update_icon()
		if (A.amount_left == 0)
			if (A.delete_on_reload)
				//DEBUG_MESSAGE("[src]: [A.type] (now empty) was deleted on full reload.")
				qdel(A) // No duplicating empty magazines, please (Convair880).
		return 5 */ // Full reload or ammo left over.
	// swap(var/obj/item/gun/energy/E)
	// 	if(!istype(E.loaded_magazine ,/obj/item/ammo/power_cell))
	// 		return 0
	// 	var/obj/item/ammo/power_cell/swapped_cell = E.loaded_magazine
	// 	var/mob/living/M = src.loc
	// 	var/atom/old_loc = src.loc

	// 	if(istype(M) && src == M.equipped())
	// 		usr.u_equip(src)

	// 	src.set_loc(E)
	// 	E.loaded_magazine = src

	// 	if(istype(old_loc, /obj/item/storage))
	// 		swapped_cell.set_loc(old_loc)
	// 		var/obj/item/storage/cell_container = old_loc
	// 		cell_container.hud.remove_item(src)
	// 		cell_container.hud.update()
	// 	else
	// 		usr.put_in_hand_or_drop(swapped_cell)

	// 	src.add_fingerprint(usr)

	// 	E.update_icon()
	// 	swapped_cell.update_icon()
	// 	src.update_icon()

	// 	playsound(get_turf(src), sound_load, 50, 1)
	// 	return 1

/datum/action/bar/icon/guncharge
	duration = 150
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "guncharge"
	icon = 'icons/obj/items/tools/screwdriver.dmi'
	icon_state = "screwdriver"
	var/obj/item/gun/ownerGun
	var/pox
	var/poy
	var/user_turf
	var/target_turf

	New(_gun, _pox, _poy, _uturf, _tturf, _time, _icon, _icon_state)
		ownerGun = _gun
		pox = _pox
		poy = _poy
		user_turf = _uturf
		target_turf = _tturf
		icon = _icon
		icon_state = _icon_state
		duration = _time
		..()

	onEnd()
		..()
		ownerGun.shoot_manager(target_turf, user_turf, owner, pox, poy)

/obj/item/gun/pixelaction(atom/target, params, mob/user, reach, continuousFire = 0)
	if (reach)
		return FALSE
	if (!isturf(user.loc))
		return FALSE
	if(continuous && !continuousFire)
		return FALSE

	var/pox = text2num(params["icon-x"]) - 16
	var/poy = text2num(params["icon-y"]) - 16
	var/turf/user_turf = get_turf(user)
	var/turf/target_turf = get_turf(target)
	if(charge_up && !can_dual_wield && canshoot())
		actions.start(new/datum/action/bar/icon/guncharge(src, pox, poy, user_turf, target_turf, charge_up, icon, icon_state), user)
	else
		shoot_manager(target_turf, user_turf, user, pox, poy)

	//if they're holding a gun in each hand... why not shoot both!
	if (can_dual_wield && (!charge_up))
		if(ishuman(user))
			if(user.hand && istype(user.r_hand, /obj/item/gun) && user.r_hand:can_dual_wield)
				if (user.r_hand:canshoot())
					user.next_click = max(user.next_click, world.time + user.r_hand:shoot_delay)
				SPAWN_DBG(0.2 SECONDS)
					user.r_hand:shoot_manager(target_turf,user_turf,user, pox+rand(-2,2), poy+rand(-2,2))
			else if(!user.hand && istype(user.l_hand, /obj/item/gun)&& user.l_hand:can_dual_wield)
				if (user.l_hand:canshoot())
					user.next_click = max(user.next_click, world.time + user.l_hand:shoot_delay)
				SPAWN_DBG(0.2 SECONDS)
					user.l_hand:shoot_manager(target_turf,user_turf,user, pox+rand(-2,2), poy+rand(-2,2))
		else if(ismobcritter(user))
			var/mob/living/critter/M = user
			var/list/obj/item/gun/guns = list()
			for(var/datum/handHolder/H in M.hands)
				if(H.item && H.item != src && istype(H.item, /obj/item/gun) && H.item:can_dual_wield)
					if (H.item:canshoot())
						guns += H.item
						user.next_click = max(user.next_click, world.time + H.item:shoot_delay)
			SPAWN_DBG(0)
				for(var/obj/item/gun/gun in guns)
					sleep(0.2 SECONDS)
					gun.shoot_manager(target_turf,user_turf,user, pox+rand(-2,2), poy+rand(-2,2))
	return TRUE

/// Handles bursts, fire-rate, updating loaded magazine, etc
/obj/item/gun/proc/shoot_manager(var/target,var/start,var/mob/user,var/POX,var/POY,var/second_shot = 0)
	if(src.shooting) return
	if (isghostdrone(user))
		user.show_text("<span class='combat bold'>Your internal law subroutines kick in and prevent you from using [src]!</span>")
		return FALSE
	if(!isturf(target))
		target = get_turf(target)
	if(!isturf(start))
		start = get_turf(start)
	if (!isturf(target) || !isturf(start))
		return FALSE
	var/canshoot = src.canshoot()
	if (!canshoot)
		src.dry_fire(user)
		return
	else if (canshoot == GUN_IS_SHOOTING)
		return
	else if(canshoot == TRUE)
		user.next_click = max(user.next_click, world.time + src.shoot_delay)
	SPAWN_DBG(0)
		src.shooting = 1
		for(var/burst in 1 to src.burst_count)
			if (!process_ammo(user)) // handles magazine stuff, sets current projectile if needed
				break
			var/shoot_result = shoot(target, start, user, POX, POY)
			if(shoot_result == FALSE)
				break
			sleep(src.refire_delay)
		src.shooting = 0

// Gun can't fire
/obj/item/gun/proc/dry_fire(var/mob/user, var/mob/M, var/point_blank)
	if (!silenced)
		if(point_blank)
			user.visible_message("<span class='alert'><B>[user] tries to shoot [user == M ? "[him_or_her(user)]self" : M] with [src] point-blank, but it was empty!</B></span>")
		playsound(user, src.shoot_sound_empty, 60, 1)
	else
		user.show_text("*click* *click*", "red")


/obj/item/gun/attack(mob/M as mob, mob/user as mob)
	if (!M || !ismob(M)) //Wire note: Fix for Cannot modify null.lastattacker
		return ..()

	user.lastattacked = M
	M.lastattacker = user
	M.lastattackertime = world.time

	if(user.a_intent != INTENT_HELP && isliving(M))
		if (user.a_intent == INTENT_GRAB)
			attack_particle(user,M)
			return ..()
		else
			src.shoot_manager(M, user, user)
	else
		..()
		attack_particle(user,M)

#ifdef DATALOGGER
		game_stats.Increment("violence")
#endif
		return

/obj/item/gun/proc/shoot_point_blank(var/mob/M as mob, var/mob/user as mob, var/second_shot = 0)
	if (!M || !user)
		return

	if (!istype(src.current_projectile,/datum/projectile/))
		return FALSE

	//Ok. i know it's kind of dumb to add this param 'second_shot' to the shoot_point_blank proc just to make sure pointblanks don't repeat forever when we could just move these checks somewhere else.
	//but if we do the double-gun checks here, it makes stuff like double-hold-at-gunpoint-pointblanks easier!
	if (can_dual_wield && !second_shot)
		//brutal double-pointblank shots
		if (ishuman(user))
			if(user.hand && istype(user.r_hand, /obj/item/gun) && user.r_hand:can_dual_wield)
				var/target_turf = get_turf(M)
				SPAWN_DBG(0.2 SECONDS)
					if (get_dist(user,M)<=1)
						user.r_hand:shoot_point_blank(M,user,second_shot = 1)
					else
						user.r_hand:shoot(target_turf,get_turf(user), user, rand(-5,5), rand(-5,5))
			else if(!user.hand && istype(user.l_hand, /obj/item/gun) && user.l_hand:can_dual_wield)
				var/target_turf = get_turf(M)
				SPAWN_DBG(0.2 SECONDS)
					if (get_dist(user,M)<=1)
						user.l_hand:shoot_point_blank(M,user,second_shot = 11)
					else
						user.l_hand:shoot(target_turf,get_turf(user), user, rand(-5,5), rand(-5,5))

	if (ishuman(user) && src.add_residue) // Additional forensic evidence for kinetic firearms (Convair880).
		var/mob/living/carbon/human/H = user
		H.gunshot_residue = 1

	if (!src.silenced)
		for (var/mob/O in AIviewers(M, null))
			if (O.client)
				O.show_message("<span class='alert'><B>[user] shoots [user == M ? "[him_or_her(user)]self" : M] point-blank with [src]!</B></span>")
	else
		user.show_text("<span class='alert'>You silently shoot [user == M ? "yourself" : M] point-blank with [src]!</span>") // Was non-functional (Convair880).

	if (src.muzzle_flash)
		if (isturf(user.loc))
			muzzle_flash_attack_particle(user, user.loc, M, src.muzzle_flash)


	if(slowdown)
		SPAWN_DBG(-1)
			user.movement_delay_modifier += slowdown
			sleep(slowdown_time)
			user.movement_delay_modifier -= slowdown

	var/spread = 0
	if (user.reagents)
		var/how_drunk = 0
		var/amt = user.reagents.get_reagent_amount("ethanol")
		switch(amt)
			if (110 to INFINITY)
				how_drunk = 2
			if (1 to 110)
				how_drunk = 1
		how_drunk = max(0, how_drunk - isalcoholresistant(user) ? 1 : 0)
		spread += 5 * how_drunk
	spread = max(spread, spread_angle)

	var/obj/projectile/P = initialize_projectile_pixel_spread(user, current_projectile, M, 0, 0, spread, alter_proj = new/datum/callback(src, .proc/alter_projectile))
	if (!P)
		return
	if (user == M)
		P.shooter = null
		P.mob_shooter = user

	P.forensic_ID = src.forensic_ID // Was missing (Convair880).
	if(get_dist(user,M) <= 1)
		hit_with_existing_projectile(P, M) // Includes log entry.
		P.was_pointblank = 1
	else
		P.launch()
	handle_casings(user = user)

	var/mob/living/L = M
	if (M && isalive(M))
		L.lastgasp()
	M.set_clothing_icon_dirty()
	src.update_icon()
	sleep(current_projectile.shot_delay)

/obj/item/gun/afterattack(atom/target as mob|obj|turf|area, mob/user as mob, flag)
	src.add_fingerprint(user)
	if(continuous) return
	if (flag)
		return

/obj/item/gun/proc/alter_projectile(var/obj/projectile/P)
	return

/obj/item/gun/proc/shoot(var/target,var/start,var/mob/user,var/POX,var/POY,var/second_shot = 0)
	if (get_dist(user,target)<=1)
		src.shoot_point_blank(M = target, user = user, second_shot = second_shot)
		return

	if (!istype(src.current_projectile,/datum/projectile/))
		return FALSE

	if (src.muzzle_flash)
		if (isturf(user.loc))
			var/turf/origin = user.loc
			muzzle_flash_attack_particle(user, origin, target, src.muzzle_flash)

	if (ismob(user))
		var/mob/M = user
		if (M.mob_flags & AT_GUNPOINT)
			for(var/obj/item/grab/gunpoint/G in M.grabbed_by)
				G.shoot()
		if(slowdown)
			SPAWN_DBG(-1)
				M.movement_delay_modifier += slowdown
				sleep(slowdown_time)
				M.movement_delay_modifier -= slowdown

	var/spread = 0
	if (user.reagents)
		var/how_drunk = 0
		var/amt = user.reagents.get_reagent_amount("ethanol")
		switch(amt)
			if (110 to INFINITY)
				how_drunk = 2
			if (1 to 110)
				how_drunk = 1
		how_drunk = max(0, how_drunk - isalcoholresistant(user) ? 1 : 0)
		spread += 5 * how_drunk
	spread = max(spread, spread_angle)
	handle_casings(user = user)
	var/obj/projectile/P = shoot_projectile_ST_pixel_spread(user, current_projectile, target, POX, POY, spread, alter_proj = new/datum/callback(src, .proc/alter_projectile))
	if (P)
		P.forensic_ID = src.forensic_ID

	if(user && !suppress_fire_msg)
		if(!src.silenced)
			for(var/mob/O in AIviewers(user, null))
				O.show_message("<span class='alert'><B>[user] fires [src] at [target]!</B></span>", 1, "<span class='alert'>You hear a gunshot</span>", 2)
		else
			if (ismob(user)) // Fix for: undefined proc or verb /obj/item/mechanics/gunholder/show text().
				user.show_text("<span class='alert'>You silently fire the [src] at [target]!</span>") // Some user feedback for silenced guns would be nice (Convair880).

		var/turf/T = target
		logTheThing("combat", user, null, "fires \a [src] from [log_loc(user)], vector: ([T.x - user.x], [T.y - user.y]), dir: <I>[dir2text(get_dir(user, target))]</I>, projectile: <I>[P.name]</I>[P.proj_data && P.proj_data.type ? ", [P.proj_data.type]" : null]")

	if (ismob(user))
		var/mob/M = user
		if (ishuman(M) && src.add_residue) // Additional forensic evidence for kinetic firearms (Convair880).
			var/mob/living/carbon/human/H = user
			H.gunshot_residue = 1
	src.update_icon()

// Checks if the gun is able to shoot
/obj/item/gun/proc/canshoot()
	if(src.loaded_magazine)
		return 1
	return 0

/obj/item/gun/proc/handle_casings(var/eject_stored = 0, var/mob/user)

	if(eject_stored)
		if(!user)
			return
		if ((src.loc == user) && user.find_in_hand(src)) // Make sure it's not on the belt or in a backpack.
			src.add_fingerprint(user)
			if (src.sanitycheck(0, 1) == 0)
				user.show_text("You can't unload this gun.", "red")
				return
			if (src.loaded_magazine.mag_contents.len <= 0)
				// The gun may have been fired; eject casings if so.
				if ((src.casings_to_eject.len > 0))
					if (src.sanitycheck(1, 0) == 0)
						logTheThing("debug", usr, null, "<b>Convair880</b>: [usr]'s gun ([src]) ran into the casings_to_eject cap, aborting.")
						src.casings_to_eject.len = 0
						return
					else
						user.show_text("You eject [src.casings_to_eject] casings from [src].", "red")
						var/turf/T = get_turf(src)
						if(T)
							var/obj/item/casing/C = null
							while (src.casings_to_eject.len > 0)
								C = new src.current_projectile.casing(T)
								C.forensic_ID = src.forensic_ID
								C.set_loc(T)
								src.casings_to_eject--
						return
				else
					user.show_text("[src] is empty!", "red")
					return
	else
		if (!istype(src.current_projectile, /datum/projectile))
			return

		if (src.auto_eject)
			var/turf/T = get_turf(src)
			if(T)
				if (src?.current_projectile?.casing && (src.sanitycheck(1, 0) == 1))
					var/number_of_casings = max(1, src.current_projectile?.shot_number)
					//DEBUG_MESSAGE("Ejected [number_of_casings] casings from [src].")
					for (var/i in 1 to number_of_casings)
						var/obj/item/casing/C = new src.current_projectile.casing(T)
						C.forensic_ID = src.forensic_ID
						C.set_loc(T)
		else
			if (src.casings_to_eject < 0)
				src.casings_to_eject = 0
			src.casings_to_eject += new src.current_projectile.casing(src)

/obj/item/gun/examine()
	if (src.artifact)
		return list("You have no idea what the hell this thing is!")
	return ..()

/obj/item/gun/proc/update_icon()
	if (src.loaded_magazine)
		inventory_counter.update_number(src.loaded_magazine.mag_contents.len)
	else
		inventory_counter.update_text("-")

	if(src.has_empty_state)
		if (src.loaded_magazine.mag_contents.len < 1 && !findtext(src.icon_state, "-empty")) //sanity check
			src.icon_state = "[src.icon_state]-empty"
		else
			src.icon_state = replacetext(src.icon_state, "-empty", "")
	return FALSE

/// Checks if it can shoot, then deducts ammo from the magazine
/obj/item/gun/proc/process_ammo()
	if(src.loaded_magazine.mag_type == AMMO_ENERGY) // Has a battery
		if(!src.current_projectile?.name)
			var/proj = src.firemodes[1]["projectile"]
			if(ispath(proj, /datum/projectile))
				src.current_projectile = new proj
			else
				return FALSE
		if (src.loaded_magazine.charge >= src.current_projectile.cost)
			src.loaded_magazine.charge -= src.current_projectile.cost
			return TRUE
	else // uses bullets
		if(istype(src.loaded_magazine.mag_contents[1], /datum/projectile))
			src.current_projectile = src.loaded_magazine.mag_contents[1]
			src.loaded_magazine.mag_contents.Cut(1,2)
			return TRUE
	return FALSE

// Could be useful in certain situations (Convair880).
/obj/item/gun/proc/logme_temp(mob/user as mob, obj/item/gun/G as obj, obj/item/ammo/A as obj)
	if (!user || !G || !A)
		return

	else if (istype(G, /obj/item/gun/kinetic) && istype(A, /obj/item/ammo/bullets))
		logTheThing("combat", user, null, "reloads [G] (<b>Ammo type:</b> <i>[G.current_projectile.type]</i>) at [log_loc(user)].")
		return

	else if (istype(G, /obj/item/gun/energy) && istype(A, /obj/item/ammo/power_cell))
		logTheThing("combat", user, null, "reloads [G] (<b>Cell type:</b> <i>[A.type]</i>) at [log_loc(user)].")
		return

	else return

/obj/item/gun/custom_suicide = 1
/obj/item/gun/suicide(var/mob/living/carbon/human/user as mob)
	if (!src.user_can_suicide(user))
		return FALSE
	if (!src.canshoot())
		return FALSE

	if(!src.process_ammo(user)) return FALSE
	user.visible_message("<span class='alert'><b>[user] places [src] against [his_or_her(user)] head!</b></span>")
	var/dmg = user.get_brute_damage() + user.get_burn_damage()
	src.shoot_manager(user, user)
	var/new_dmg = user.get_brute_damage() + user.get_burn_damage()
	if (new_dmg >= (dmg + 20)) // it did some appreciable amount of damage
		user.TakeDamage("head", 500, 0)
	else if (new_dmg < (dmg + 20))
		user.visible_message("<span class='alert'>[user] hangs their head in shame because they chose such a weak gun.</span>")
	return TRUE

/obj/item/gun/on_spin_emote(var/mob/living/carbon/human/user as mob)
	. = ..(user)
	if ((user.bioHolder && user.bioHolder.HasEffect("clumsy") && prob(50)) || (user.reagents && prob(user.reagents.get_reagent_amount("ethanol") / 2)) || prob(5))
		user.visible_message("<span class='alert'><b>[user] accidentally shoots [him_or_her(user)]self with [src]!</b></span>")
		src.shoot_manager(user, user)
		JOB_XP(user, "Clown", 3)
