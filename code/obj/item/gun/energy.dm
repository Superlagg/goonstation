/obj/item/gun/energy
	name = "energy weapon"
	icon = 'icons/obj/items/gun.dmi'
	item_state = "gun"
	m_amt = 2000
	g_amt = 1000
	mats = 32
	add_residue = 0 // Does this gun add gunshot residue when fired? Energy guns shouldn't.
	rechargeable = 1

	accepted_mag = AMMO_ENERGY
	caliber = CALIBER_BATTERY
	muzzle_flash = null
	inventory_counter_enabled = 1

	// Ammo caliber defines
	// #define CALIBER_RIFLE_ASSAULT 0.223
	// #define CALIBER_RIFLE_HEAVY 0.308
	// #define CALIBER_RIFLE_CASELESS 0.185
	// #define CALIBER_PISTOL 0.355
	// #define CALIBER_PISTOL_SMALL 0.22
	// #define CALIBER_PISTOL_MAGNUM 0.50
	// #define CALIBER_PISTOL_GYROJET 0.512
	// #define CALIBER_PISTOL_FLINTLOCK 0.56
	// #define CALIBER_MINIGUN 0.10
	// #define CALIBER_REVOLVER_MAGNUM 0.357
	// #define CALIBER_REVOLVER_OLDTIMEY 0.45
	// #define CALIBER_REVOLVER 0.38
	// #define CALIBER_DERRINGER 0.41
	// #define CALIBER_WHOLE_DERRINGER 3.00
	// #define CALIBER_SHOTGUN 0.72
	// #define CALIBER_CANNON 0.787
	// #define CALIBER_CANNON_MASSIVE 15.7
	// #define CALIBER_GRENADE 1.57
	// #define CALIBER_ROCKET 1.12
	// #define CALIBER_RPG 1.58
	// #define CALIBER_ROD 1.00
	// #define CALIBER_CAT 9.5
	// #define CALIBER_FROG 8.0
	// #define CALIBER_CRAB 12
	// #define CALIBER_TRASHBAG 9.5
	// #define CALIBER_SECBOT 11.5
	// #define CALIBER_BATTERY 1.30
	// #define CALIBER_ANY -1

	New()
		if (!(src in processing_items)) // No self-charging cell? Will be kicked out after the first tick (Convair880).
			processing_items.Add(src)
		..()
		update_icon()

	disposing()
		processing_items -= src
		..()


	examine()
		. = ..()
		if(src.loaded_magazine)
			. += "It is set to [src.firemodes[src.firemode_index]["name"]]. There are [src.loaded_magazine.charge]/[src.loaded_magazine.max_charge] PUs left!"
		else
			. += "There is no cell loaded!"
		if(current_projectile)
			. += "Each shot will currently use [src.current_projectile.cost] PUs!"
		else
			. += "<span class='alert'>*ERROR* No output selected!</span>"

	update_icon()
		if (src.loaded_magazine)
			inventory_counter.update_percent(src.loaded_magazine.charge, src.loaded_magazine.max_charge)
		else
			inventory_counter.update_text("-")
		return 0

	emp_act()
		if (src.loaded_magazine && istype(src.loaded_magazine))
			src.loaded_magazine.charge = 0
			src.update_icon()
		return

	process()
		src.wait_cycle = !src.wait_cycle // Self-charging cells recharge every other tick (Convair880).
		if (src.wait_cycle)
			return

		if (!(src in processing_items))
			logTheThing("debug", null, null, "<b>Convair880</b>: Process() was called for an egun ([src]) that wasn't in the item loop. Last touched by: [src.fingerprintslast]")
			processing_items.Add(src)
			return
		if (!src?.loaded_magazine?.self_charging)
			processing_items.Remove(src)
			return
		if (src.loaded_magazine.charge == src.loaded_magazine.max_charge) // Keep them in the loop, as we might fire the gun later (Convair880).
			return

		src.update_icon()
		return

	// process_ammo(var/mob/user)
	// 	if(isrobot(user))
	// 		var/mob/living/silicon/robot/R = user
	// 		if(R.cell)
	// 			if(R.cell.charge >= src.robocharge)
	// 				R.cell.charge -= src.robocharge
	// 				return 1
	// 		return 0
	// 	else
	// 		if(src.loaded_magazine && src.current_projectile)
	// 			if(src.loaded_magazine.use(src.current_projectile.cost))
	// 				return 1
	// 		boutput(user, "<span class='alert'>*click* *click*</span>")
	// 		if (!src.silenced)
	// 			playsound(user, "sound/weapons/Gunclick.ogg", 60, 1)
	// 		return 0

	attackby(obj/item/b as obj, mob/user as mob)
		if (!fixed_mag && istype(b, /obj/item/ammo/power_cell))
			var/obj/item/ammo/power_cell/pcell = b
			if (src.custom_cell_max_capacity && (pcell.max_charge > src.custom_cell_max_capacity))
				boutput(user, "<span class='alert'>This [pcell.name] won't fit!</span>")
				return
			src.logme_temp(user, src, pcell) //if (!src.rechargeable)
			if (istype(pcell, /obj/item/ammo/power_cell/self_charging) && !(src in processing_items)) // Again, we want dynamic updates here (Convair880).
				processing_items.Add(src)
			if (src.loaded_magazine)
				if (src.swap(b))
					user.visible_message("<span class='alert'>[user] swaps [src]'s power cell.</span>")
			else
				src.loaded_magazine = pcell
				user.drop_item()
				pcell.set_loc(src)
				user.visible_message("<span class='alert'>[user] swaps [src]'s power cell.</span>")
		else
			..()

	attack_hand(mob/user as mob)
		if ((user.r_hand == src || user.l_hand == src) && src.contents && src.contents.len)
			if (!src.fixed_mag && src.loaded_magazine && !src.rechargeable)
				var/obj/item/ammo/power_cell/W = src.loaded_magazine
				user.put_in_hand_or_drop(W)
				src.loaded_magazine = null
				update_icon()
				src.add_fingerprint(user)
			else
				return ..()
		else
			return ..()
		return

	proc/charge(var/amt)
		if(src.loaded_magazine && rechargeable)
			return src.loaded_magazine.charge(amt)
		else
			//No cell, or not rechargeable. Tell anything trying to charge it.
			return -1

/obj/item/gun/energy/heavyion
	name = "heavy ion blaster"
	icon_state = "heavyion"
	item_state = "rifle"
	force = 1.0
	desc = "..."
	charge_up = 15
	can_dual_wield = 0
	two_handed = 1
	slowdown = 5
	slowdown_time = 5
	w_class = 4
	flags =  FPRINT | TABLEPASS | CONDUCT | USEDELAY | EXTRADELAY
	ammo = /obj/item/ammo/power_cell/self_charging/slowcharge/hundred
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/heavyion))

	pixelaction(atom/target, params, mob/user, reach)
		if(..(target, params, user, reach))
			playsound(get_turf(user), "sound/weapons/heavyioncharge.ogg", 90)

////////////////////////////////////TASERGUN
/obj/item/gun/energy/taser_gun
	name = "taser gun"
	icon_state = "taser"
	item_state = "taser"
	uses_multiple_icon_states = 1
	force = 1.0
	ammo = /obj/item/ammo/power_cell/med_power
	desc = "A weapon that produces an cohesive electrical charge that stuns its target."
	module_research = list("weapons" = 4, "energy" = 4, "miniaturization" = 2)
	muzzle_flash = "muzzle_flash_elec"
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt),\
	                 list("name" = "3-round burst", "burst_count" = 3, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 12.5, "projectile" = /datum/projectile/energy_bolt))

	update_icon()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			if (src.firemodes[src.firemode_index]["name"] == "single-shot")
				src.icon_state = "taserburst[ratio]"
			else if(src.firemodes[src.firemode_index]["name"] == "3-round burst")
				src.icon_state = "taser[ratio]"
		..()

	attack_self()
		..()
		update_icon()

	borg
		ammo = new/obj/item/ammo/power_cell/self_charging/slowcharge/hundred

/obj/item/gun/energy/taser_gun/bouncy
	name = "richochet taser gun"
	desc = "A weapon that produces an cohesive electrical charge that stuns its target. This one appears to be capable of firing ricochet charges."
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt/bouncy),\
	                 list("name" = "3-round burst", "burst_count" = 3, "refire_delay" = 0.7, "shoot_delay" = 0, "spread_angle" = 12.5, "projectile" = /datum/projectile/energy_bolt/bouncy))

	update_icon()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			if(current_projectile.type == /datum/projectile/energy_bolt/bouncy)
				src.icon_state = "taser[ratio]"
		..()

/////////////////////////////////////LASERGUN
/obj/item/gun/energy/laser_gun
	name = "laser gun"
	icon_state = "laser"
	item_state = "laser"
	uses_multiple_icon_states = 1
	ammo = /obj/item/ammo/power_cell/med_plus_power
	force = 7.0
	desc = "A gun that produces a harmful laser, causing substantial damage."
	module_research = list("weapons" = 4, "energy" = 4)
	muzzle_flash = "muzzle_flash_laser"
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser))

	virtual
		icon = 'icons/effects/VR.dmi'
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser/virtual))

	update_icon()
		if(src.loaded_magazine)
			//Wire: Fix for Division by zero runtime
			var/maxCharge = (src.loaded_magazine.max_charge > 0 ? src.loaded_magazine.max_charge : 0)
			var/ratio = min(1, src.loaded_magazine.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "laser[ratio]"
			return
		..()

////////////////////////////////////// Antique laser gun
// Part of a mini-quest thing (see displaycase.dm). Typically, the gun's properties (cell, projectile)
// won't be the default ones specified here, it's here to make it admin-spawnable (Convair880).
/obj/item/gun/energy/laser_gun/antique
	name = "antique laser gun"
	icon_state = "caplaser"
	uses_multiple_icon_states = 1
	desc = "Wait, that's not a plastic toy..."
	muzzle_flash = "muzzle_flash_laser"
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser))

	update_icon()
		..()
		if (src.loaded_magazine)
			var/maxCharge = (src.loaded_magazine.max_charge > 0 ? src.loaded_magazine.max_charge : 0)
			var/ratio = min(1, src.loaded_magazine.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "caplaser[ratio]"
			return

//////////////////////////////////////// Phaser
/obj/item/gun/energy/phaser_gun
	name = "phaser gun"
	icon_state = "phaser-new"
	uses_multiple_icon_states = 1
	item_state = "phaser"
	force = 7.0
	desc = "A gun that produces a harmful phaser bolt, causing substantial damage."
	module_research = list("weapons" = 4, "energy" = 4)
	muzzle_flash = "muzzle_flash_phaser"
	ammo = new/obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser/light))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "phaser-new[ratio]"
			return


///////////////////////////////////////Rad Crossbow
/obj/item/gun/energy/crossbow
	name = "mini rad-poison-crossbow"
	desc = "A weapon favored by many of the syndicate's stealth specialists, which does damage over time using a slow-acting radioactive poison. Utilizes a self-recharging atomic power cell."
	icon_state = "crossbow"
	uses_multiple_icon_states = 1
	w_class = 2.0
	item_state = "crossbow"
	force = 4.0
	throw_speed = 3
	throw_range = 10
	rechargeable = 0 // Cannot be recharged manually.
	ammo = /obj/item/ammo/power_cell/self_charging/slowcharge
	is_syndicate = 1
	silenced = 1 // No conspicuous text messages, please (Convair880).
	hide_attack = 1
	custom_cell_max_capacity = 100 // Those self-charging ten-shot radbows were a bit overpowered (Convair880)
	module_research = list("medicine" = 2, "science" = 2, "weapons" = 2, "energy" = 2, "miniaturization" = 10)
	muzzle_flash = null
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/rad_bolt))

	update_icon()
		..()
		if(src.loaded_magazine)
			if(src.loaded_magazine.charge >= 37) //this makes it only enter its "final" sprite when it's actually able to fire, if you change the amount of charge regen or max charge the bow has, make this number one charge increment before full charge
				set_icon_state("crossbow")
				return
			else
				var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
				ratio = round(ratio, 0.25) * 100
				set_icon_state("crossbow[ratio]")
				return

////////////////////////////////////////EGun
/obj/item/gun/energy/egun
	name = "energy gun"
	icon_state = "energy"
	uses_multiple_icon_states = 1
	ammo = /obj/item/ammo/power_cell/med_plus_power
	desc = "Its a gun that has two modes, stun and kill"
	item_state = "egun"
	force = 5.0
	mats = 50
	module_research = list("weapons" = 5, "energy" = 4, "miniaturization" = 5)
	var/nojobreward = 0 //used to stop people from scanning it and then getting both a lawbringer/sabre AND an egun.
	muzzle_flash = "muzzle_flash_elec"
	firemodes = list(list("name" = "stun", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt),\
	                 list("name" = "kill", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser))


	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			if(src.firemodes[src.firemode_index]["name"] == "stun")
				src.item_state = "egun"
				src.icon_state = "energystun[ratio]"
				muzzle_flash = "muzzle_flash_elec"
			else if (src.firemodes[src.firemode_index]["name"] == "kill")
				src.item_state = "egun-kill"
				src.icon_state = "energykill[ratio]"
				muzzle_flash = "muzzle_flash_laser"
			else
				src.item_state = "egun"
				src.icon_state = "energy[ratio]"
				muzzle_flash = "muzzle_flash_elec"

	attack_self(var/mob/M)
		..()
		update_icon()
		M.update_inhands()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/electronics/scanner))
			nojobreward = 1
		..()

//////////////////////// nanotrasen gun
//Azungar's Nanotrasen inspired Laser Assault Rifle for RP gimmicks
/obj/item/gun/energy/ntgun
	name = "Laser Assault Rifle"
	icon_state = "ntneutral100"
	desc = "Rather futuristic assault rifle with two firing modes."
	item_state = "ntgun"
	force = 10.0
	contraband = 8
	two_handed = 1
	spread_angle = 6
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "stun", "burst_count" = 3, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 6, "projectile" = /datum/projectile/energy_bolt/ntburst),\
	                 list("name" = "kill", "burst_count" = 3, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 6, "projectile" = /datum/projectile/laser/ntburst))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			if(src.firemodes[src.firemode_index]["name"] == "stun")
				src.icon_state = "ntstun[ratio]"
			else if (src.firemodes[src.firemode_index]["name"] == "kill")
				src.icon_state = "ntlethal[ratio]"
			else
				src.icon_state = "ntneutral[ratio]"

	attack_self()
		..()
		update_icon()



//////////////////////// Taser Shotgun
//Azungar's Improved, more beefy weapon for security that can only be acquired via QM.
/obj/item/gun/energy/tasershotgun
	name = "Taser Shotgun"
	icon_state = "tasers100"
	desc = "A weapon that produces an cohesive electrical charge that stuns its target. Now in a shotgun format."
	item_state = "tasers"
	ammo = /obj/item/ammo/power_cell/high_power
	force = 8.0
	two_handed = 1
	can_dual_wield = 0
	shoot_delay = 6
	muzzle_flash = "muzzle_flash_elec"
	firemodes = list(list("name" = "spread", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 6, "spread_angle" = 6, "projectile" = /datum/projectile/special/spreader/tasershotgunspread),\
	                 list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 4, "spread_angle" = 6, "projectile" = /datum/projectile/energy_bolt/tasershotgun))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			set_icon_state("tasers[ratio]")
			return

////////////////////////////////////VUVUV
/obj/item/gun/energy/vuvuzela_gun
	name = "amplified vuvuzela"
	icon_state = "vuvuzela"
	uses_multiple_icon_states = 1
	item_state = "bike_horn"
	desc = "BZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZT, *fart*"
	is_syndicate = 1
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "BWAAAAAAMP", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt_v))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "vuvuzela[ratio]"

//////////////////////////////////////Crabgun
/obj/item/gun/energy/crabgun
	name = "a strange crab"
	desc = "Years of extreme genetic tinkering have finally led to the feared combination of crab and gun."
	icon = 'icons/obj/crabgun.dmi'
	icon_state = "crabgun"
	item_state = "crabgun-world"
	inhand_image_icon = 'icons/obj/crabgun.dmi'
	w_class = 4.0
	force = 12.0
	throw_speed = 8
	throw_range = 12
	rechargeable = 0
	ammo = /obj/item/ammo/power_cell/self_charging/slowcharge
	is_syndicate = 1
	custom_cell_max_capacity = 100 //endless crab
	firemodes = list(list("name" = "crab", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/claw))

	attackby(obj/item/b, mob/user)
		if(istype(b, /obj/item/ammo))
			boutput(user, "<span class='alert'>You attempt to swap the cell but \the [src] bites you instead.</span>")
			playsound(src.loc, "sound/impact_sounds/Flesh_Stab_1.ogg", 50, 1, -6)
			user.TakeDamage(user.zone_sel.selecting, 3, 0)
			take_bleeding_damage(user, user, 3, DAMAGE_CUT)
			return
		. = ..()

//////////////////////////////////////Disruptor
/obj/item/gun/energy/disruptor
	name = "Disruptor"
	icon_state = "disruptor"
	uses_multiple_icon_states = 1
	desc = "Disruptor Blaster - Comes equipped with self-charging powercell."
	m_amt = 4000
	force = 6.0
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/disruptor),\
	                 list("name" = "burst-fire", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/disruptor),\
	                 list("name" = "super-disrupt", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/disruptor/high))

	update_icon()
		..()
		if (src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.20) * 100
			src.icon_state = "disruptor[ratio]"
		return

////////////////////////////////////Wave Gun
/obj/item/gun/energy/wavegun
	name = "Wave Gun"
	icon = 'icons/obj/items/gun.dmi'
	icon_state = "wavegun100"
	item_state = "wave"
	ammo = /obj/item/ammo/power_cell/high_power
	uses_multiple_icon_states = 1
	m_amt = 4000
	force = 6.0
	module_research = list("weapons" = 2, "energy" = 2, "miniaturization" = 3)
	muzzle_flash = "muzzle_flash_wavep"
	firemodes = list(list("name" = "inverse", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/wavegun),\
	                 list("name" = "transverse", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/wavegun/transverse),\
	                 list("name" = "electromagnetoverse", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/wavegun/emp))

	// Old phasers aren't around anymore, so the wave gun might as well use their better sprite (Convair880).
	// Flaborized has made a lovely new wavegun sprite! - Gannets
	// Flaborized has made even more wavegun sprites!
	update_icon()
		..()
		if (src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			if(src.firemodes[src.firemode_index]["name"] == "inverse")
				src.icon_state = "wavegun[ratio]"
				item_state = "wave"
				muzzle_flash = "muzzle_flash_wavep"
			else if (src.firemodes[src.firemode_index]["name"] == "transverse")
				src.icon_state = "wavegun_green[ratio]"
				item_state = "wave-g"
				muzzle_flash = "muzzle_flash_waveg"
			else
				src.icon_state = "wavegun_emp[ratio]"
				item_state = "wave-emp"
				muzzle_flash = "muzzle_flash_waveb"

	attack_self(mob/user as mob)
		..()
		update_icon()
		user.update_inhands()

////////////////////////////////////BFG
/obj/item/gun/energy/bfg
	name = "BFG 9000"
	icon = 'icons/obj/items/gun.dmi'
	icon_state = "bfg"
	m_amt = 4000
	force = 6.0
	desc = "I think it stands for Banned For Griefing?"
	module_research = list("weapons" = 25, "energy" = 25)
	ammo = /obj/item/ammo/power_cell/high_power
	firemodes = list(list("name" = "obliterate", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bfg))

	shoot(var/target,var/start,var/mob/user)
		if (canshoot()) // No more attack messages for empty guns (Convair880).
			playsound(user, "sound/weapons/DSBFG.ogg", 75)
			sleep(0.9 SECONDS)
		return ..(target, start, user)

/obj/item/gun/energy/bfg/vr
	icon = 'icons/effects/VR.dmi'

///////////////////////////////////////Telegun
/obj/item/gun/energy/teleport
	name = "teleport gun"
	desc = "A hacked together combination of a taser and a handheld teleportation unit."
	icon_state = "teleport"
	uses_multiple_icon_states = 1
	w_class = 3.0
	item_state = "gun"
	force = 10.0
	throw_speed = 2
	throw_range = 10
	mats = 0
	var/obj/item/our_target = null
	var/obj/machinery/computer/teleporter/our_teleporter = null // For checks before firing (Convair880).
	module_research = list("weapons" = 3, "energy" = 2, "science" = 10)
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "teleport", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/tele_bolt))

	update_icon()
		..()
		if (!src.loaded_magazine)
			icon_state = "teleport"
			return

		icon_state = "teleport[round((src.loaded_magazine.charge / src.loaded_magazine.max_charge), 0.25) * 100]"
		return

	// I overhauled everything down there. Old implementation made the telegun unreliable and crap, to be frank (Convair880).
	attack_self(mob/user as mob)
		src.add_fingerprint(user)

		var/list/L = list()
		L += "None (Cancel)" // So we'll always get a list, even if there's only one teleporter in total.

		for(var/obj/machinery/teleport/portal_generator/PG as() in machine_registry[MACHINES_PORTALGENERATORS])
			if (!PG.linked_computer || !PG.linked_rings)
				continue
			var/turf/PG_loc = get_turf(PG)
			if (PG && isrestrictedz(PG_loc.z)) // Don't show teleporters in "somewhere", okay.
				continue

			var/obj/machinery/computer/teleporter/Control = PG.linked_computer
			if (Control)
				switch (Control.check_teleporter())
					if (0) // It's busted, Jim.
						continue
					if (1)
						L["Tele at [get_area(Control)]: Locked in ([ismob(Control.locked.loc) ? "[Control.locked.loc.name]" : "[get_area(Control.locked)]"])"] += Control
					if (2)
						L["Tele at [get_area(Control)]: *NOPOWER*"] += Control
					if (3)
						L["Tele at [get_area(Control)]: Inactive"] += Control
			else
				continue

		if (L.len < 2)
			user.show_text("Error: no working teleporters detected.", "red")
			return

		var/t1 = input(user, "Please select a teleporter to lock in on.", "Target Selection") in L
		if ((user.equipped() != src) || user.stat || user.restrained())
			return
		if (t1 == "None (Cancel)")
			return

		var/obj/machinery/computer/teleporter/Control2 = L[t1]
		if (Control2)
			src.our_teleporter = null
			src.our_target = null
			switch (Control2.check_teleporter())
				if (0)
					user.show_text("Error: selected teleporter is out of order.", "red")
					return
				if (1)
					src.our_target = Control2.locked
					if (!our_target)
						user.show_text("Error: selected teleporter is locked in to invalid coordinates.", "red")
						return
					else
						user.show_text("Teleporter selected. Locked in on [ismob(Control2.locked.loc) ? "[Control2.locked.loc.name]" : "beacon"] in [get_area(Control2.locked)].", "blue")
						src.our_teleporter = Control2
						return
				if (2)
					user.show_text("Error: selected teleporter is unpowered.", "red")
					return
				if (3)
					user.show_text("Error: selected teleporter is not locked in.", "red")
					return
		else
			user.show_text("Error: couldn't establish connection to selected teleporter.", "red")
			return

	attack(mob/M as mob, mob/user as mob)
		if (!src.our_target)
			user.show_text("Error: no target set. Please select a teleporter first.", "red")
			return
		if (!src.our_teleporter || (src.our_teleporter.check_teleporter() != 1))
			user.show_text("Error: linked teleporter is out of order.", "red")
			return

		var/datum/projectile/tele_bolt/TB = current_projectile
		TB.target = our_target
		return ..(M, user)

	shoot(var/target, var/start, var/mob/user)
		if (!src.our_target)
			user.show_text("Error: no target set. Please select a teleporter first.", "red")
			return
		if (!src.our_teleporter || (src.our_teleporter.check_teleporter() != 1))
			user.show_text("Error: linked teleporter is out of order.", "red")
			return

		var/datum/projectile/tele_bolt/TB = current_projectile
		TB.target = our_target
		return ..(target, start, user)

///////////////////////////////////////Ghost Gun
/obj/item/gun/energy/ghost
	name = "ectoplasmic destabilizer"
	desc = "If this had streams, it would be inadvisable to cross them. But no, it fires bolts instead.  Don't throw it into a stream, I guess?"
	icon_state = "ghost"
	w_class = 3.0
	item_state = "gun"
	force = 10.0
	throw_speed = 2
	throw_range = 10
	mats = 0
	module_research = list("weapons" = 1, "energy" = 5, "science" = 10)
	muzzle_flash = "muzzle_flash_waveg"
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "bust", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt_antighost))

///////////////////////////////////////Modular Blasters
/obj/item/gun/energy/blaster_pistol
	name = "blaster pistol"
	desc = "A dangerous-looking blaster pistol. It's self-charging by a radioactive power cell."
	icon = 'icons/obj/items/gun_mod.dmi'
	icon_state = "pistol"
	w_class = 3.0
	force = 5.0
	mats = 0
	ammo = new/obj/item/ammo/power_cell/self_charging/med_power
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser/blaster))

	/*
	var/obj/item/gun_parts/emitter/emitter = null
	var/obj/item/gun_parts/back/back = null
	var/obj/item/gun_parts/top_rail/top_rail = null
	var/obj/item/gun_parts/bottom_rail/bottom_rail = null
	var/heat = 0 // for overheating stuff

	New()
		if (!emitter)
			emitter = new /obj/item/gun_parts/emitter
		if(!current_projectile)
			current_projectile = src.emitter.projectile
		projectiles = list(current_projectile)
		..() */



	//handle gun mods at a workbench


	update_icon()
		..()
		if (src.loaded_magazine)
			var/maxCharge = (src.loaded_magazine.max_charge > 0 ? src.loaded_magazine.max_charge : 0)
			var/ratio = min(1, src.loaded_magazine.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "pistol[ratio]"
			return



	/*examine()
		set src in view()
		boutput(usr, "<span class='notice'>Installed components:</span><br>")
		if(emitter)
			boutput(usr, "<span class='notice'>[src.emitter.name]</span>")
		if(cell)
			boutput(usr, "<span class='notice'>[src.loaded_magazine.name]</span>")
		if(back)
			boutput(usr, "<span class='notice'>[src.back.name]</span>")
		if(top_rail)
			boutput(usr, "<span class='notice'>[src.top_rail.name]</span>")
		if(bottom_rail)
			boutput(usr, "<span class='notice'>[src.bottom_rail.name]</span>")
		..()*/

	/*proc/generate_overlays()
		src.overlays = null
		if(extension_mod)
			src.overlays += icon('icons/obj/items/gun_mod.dmi',extension_mod.overlay_name)
		if(converter_mod)
			src.overlays += icon('icons/obj/items/gun_mod.dmi',converter_mod.overlay_name)*/

/obj/item/gun/energy/blaster_smg
	name = "burst blaster"
	desc = "A special issue blaster weapon, configured for burst fire. It's self-charging by a radioactive power cell."
	icon = 'icons/obj/items/gun_mod.dmi'
	icon_state = "smg"
	can_dual_wield = 0
	w_class = 3.0
	force = 7.0
	mats = 0
	ammo = new/obj/item/ammo/power_cell/self_charging/med_power
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser/blaster),\
	                 list("name" = "3-round burst", "burst_count" = 3, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 12.5, "projectile" = /datum/projectile/laser/blaster))

	update_icon()
		..()
		if (src.loaded_magazine)
			var/maxCharge = (src.loaded_magazine.max_charge > 0 ? src.loaded_magazine.max_charge : 0)
			var/ratio = min(1, src.loaded_magazine.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "smg[ratio]"
			return

/obj/item/gun/energy/blaster_cannon
	name = "blaster cannon"
	desc = "A heavily overcharged blaster weapon, modified for extreme firepower. It's self-charging by a larger radioactive power cell."
	icon = 'icons/obj/items/gun_mod.dmi'
	icon_state = "cannon"
	item_state = "rifle"
	can_dual_wield = 0
	two_handed = 1
	w_class = 4
	force = 15
	ammo = new/obj/item/ammo/power_cell/self_charging/big
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/special/spreader/uniform_burst/blaster))

	New()
		flags |= ONBACK
		..()

	update_icon()
		..()
		if (src.loaded_magazine)
			var/maxCharge = (src.loaded_magazine.max_charge > 0 ? src.loaded_magazine.max_charge : 0)
			var/ratio = min(1, src.loaded_magazine.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "cannon[ratio]"
			return


///////////modular components - putting them here so it's easier to work on for now////////

/obj/item/gun_parts
	name = "gun parts"
	desc = "Components for building custom sidearms."
	item_state = "table_parts"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon = 'icons/obj/items/gun_mod.dmi'
	icon_state = "frame" // todo: make more item icons
	mats = 0

/obj/item/gun_parts/emitter
	name = "optical pulse emitter"
	desc = "Generates a pulsed burst of energy."
	icon_state = "emitter"
	var/datum/projectile/laser/light/projectile = new/datum/projectile/laser/light
	var/obj/item/device/flash/flash = new/obj/item/device/flash
	//use flash as the core of the device

	// inherit material vars from the flash

/obj/item/gun_parts/back
	name = "phaser stock"
	desc = "A gun stock for a modular phaser. Does this even do anything? Probably not."
	icon_state = "mod-stock"

/obj/item/gun_parts/top_rail
	name = "phaser pulse modifier"
	desc = "Modifies the beam path of modular phaser."
	icon_state = "mod-range"

	range
		name = "beam collimator"
		icon_state = "mod-range"

	width
		name = "beam spreader"
		icon_state = "mod-aoe"

/obj/item/gun_parts/bottom_rail
	name = "Phaser accessory"

	sight
		name = "phaser dot accessory"
		icon_state = "mod-sight"
		// idk what the hell this would even do

	flashlight
		name = "phaser flashlight accessory"
		icon_state = "mod-flashlight"

	heatsink
		name = "phaser heatsink"
		icon_state = "mod-heatsink"

	grip // tacticool
		name = "fore grip"
		icon_state = "mod-grip"

///////////////////////////////////////Owl Gun
/obj/item/gun/energy/owl
	name = "Owl gun"
	desc = "Its a gun that has two modes, Owl and Owler"
	item_state = "gun"
	force = 5.0
	icon_state = "ghost"
	uses_multiple_icon_states = 1
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "owl", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/owl),\
	                 list("name" = "owler", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/owl/owlate))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "ghost[ratio]"

/obj/item/gun/energy/owl_safe
	name = "Owl gun"
	desc = "Hoot!"
	item_state = "gun"
	force = 5.0
	icon_state = "ghost"
	uses_multiple_icon_states = 1
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "owl", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/owl))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "ghost[ratio]"

///////////////////////////////////////Frog Gun (Shoots :getin: and :getout:)
/obj/item/gun/energy/frog
	name = "Frog Gun"
	item_state = "gun"
	m_amt = 1000
	force = 0.0
	icon_state = "frog"
	desc = "It appears to be shivering and croaking in your hand. How creepy." //it must be unhoppy :^)
	ammo = /obj/item/ammo/power_cell/self_charging/big //gotta have power for the frog
	firemodes = list(list("name" = ":getin:", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/frog),\
	                 list("name" = ":getout:", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/frog/getout))

///////////////////////////////////////Shrink Ray
/obj/item/gun/energy/shrinkray
	name = "Shrink ray"
	item_state = "gun"
	force = 5.0
	icon_state = "ghost"
	uses_multiple_icon_states = 1
	ammo = new/obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/shrink_beam))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "ghost[ratio]"

/obj/item/gun/energy/shrinkray/growray
	name = "Grow ray"
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/shrink_beam/grow))

///////////////////////////////////////Glitch Gun
/obj/item/gun/energy/glitch_gun
	name = "Glitch Gun"
	icon = 'icons/obj/items/gun.dmi'
	icon_state = "airzooka"
	m_amt = 4000
	force = 0.0
	desc = "It's humming with some sort of disturbing energy. Do you really wanna hold this?"
	ammo = new/obj/item/ammo/power_cell/high_power
	firemodes = list(list("name" = "src.firemodes\[src.firemode_index\]\[\"name\"\]", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/glitch/gun))

	shoot(var/target,var/start,var/mob/user,var/POX,var/POY)
		if (canshoot()) // No more attack messages for empty guns (Convair880).
			playsound(user, "sound/weapons/DSBFG.ogg", 75)
			sleep(0.1 SECONDS)
		return ..(target, start, user)

///////////////////////////////////////Hunter
/obj/item/gun/energy/laser_gun/pred // Made use of a spare sprite here (Convair880).
	name = "laser rifle"
	desc = "This advanced bullpup rifle contains a self-recharging power cell."
	icon_state = "bullpup"
	item_state = "bullpup"
	uses_multiple_icon_states = 1
	force = 5.0
	muzzle_flash = "muzzle_flash_plaser"
	ammo = new/obj/item/ammo/power_cell/self_charging/big
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser/pred))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "bullpup[ratio]"
			return

/obj/item/gun/energy/laser_gun/pred/vr
	name = "advanced laser gun"
	icon = 'icons/effects/VR.dmi'
	icon_state = "wavegun"

	update_icon() // Necessary. Parent's got a different sprite now (Convair880).
		return

/////////////////////////////////////// Pickpocket Grapple, Grayshift's grif gun
/obj/item/gun/energy/pickpocket
	name = "pickpocket grapple gun" // absurdly shitty name
	desc = "A complicated, camoflaged claw device on a tether capable of complex and stealthy interactions. It steals shit."
	icon_state = "pickpocket"
	w_class = 2.0
	item_state = "pickpocket"
	force = 4.0
	throw_speed = 3
	throw_range = 10
	rechargeable = 0 // Cannot be recharged manually.
	ammo = /obj/item/ammo/power_cell/self_charging/slowcharge
	is_syndicate = 1
	silenced = 1
	hide_attack = 1
	mats = 100 //yeah no, you can do it if you REALLY want to
	custom_cell_max_capacity = 100
	module_research = list("medicine" = 2, "science" = 2, "weapons" = 2, "energy" = 2, "miniaturization" = 10)
	var/obj/item/heldItem = null
	tooltip_flags = REBUILD_DIST
	firemodes = list(list("name" = "steal", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/pickpocket/steal),\
	                 list("name" = "plant", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/pickpocket/plant),\
	                 list("name" = "harass", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/pickpocket/harass))

	get_desc(dist)
		..()
		if (dist < 1) // on our tile or our person
			if (.) // we're returning something
				. += " " // add a space
			if (src.heldItem)
				. += "It's currently holding \a [src.heldItem]."
			else
				. += "It's not holding anything."

	attack_hand(mob/user as mob)
		if (src.loc == user && (src == user.l_hand || src == user.r_hand))
			if (heldItem)
				boutput(user, "You remove \the [heldItem.name] from the gun.")
				user.put_in_hand_or_drop(heldItem)
				heldItem = null
				tooltip_rebuild = 1
			else
				boutput(user, "The gun does not contain anything.")
		else
			return ..()

	attackby(obj/item/I as obj, mob/user as mob)
		if (I.cant_drop) return
		if (heldItem)
			boutput(user, "The gun is already holding [heldItem.name].")
		else
			heldItem = I
			user.u_equip(I)
			I.dropped(user)
			boutput(user, "You insert \the [heldItem.name] into the gun's gripper.")
			tooltip_rebuild = 1
		return ..()

	attack(mob/M as mob, mob/user as mob)
		if (src.firemodes[src.firemode_index]["name"] == "steal" && heldItem)
			boutput(user, "Cannot steal while gun is holding something!")
			return
		if (src.firemodes[src.firemode_index]["name"] == "plant" && !heldItem)
			boutput(user, "Cannot plant item if gun is not holding anything!")
			return

		var/datum/projectile/pickpocket/shot = current_projectile
		shot.linkedGun = src
		shot.firer = user.key
		shot.targetZone = user.zone_sel.selecting
		var/turf/us = get_turf(src)
		var/turf/tgt = get_turf(M)
		if(isrestrictedz(us.z) || isrestrictedz(tgt.z))
			boutput(user, "\The [src.name] jams!")
			return
		return ..(M, user)

	shoot(var/target, var/start, var/mob/user)
		if (src.firemodes[src.firemode_index]["name"] == "steal" && heldItem)
			boutput(user, "Cannot steal items while gun is holding something!")
			return
		if (src.firemodes[src.firemode_index]["name"] == "plant" && !heldItem)
			boutput(user, "Cannot plant item if gun is not holding anything!")
			return

		var/turf/us = get_turf(src)
		var/turf/tgt = get_turf(target)
		if(isrestrictedz(us.z) || isrestrictedz(tgt.z))
			boutput(user, "\The [src.name] jams!")
			message_admins("[key_name(usr)] is a nerd and tried to fire a pickpocket gun in a restricted z-level at [showCoords(us.x, us.y, us.z)].")
			return


		var/datum/projectile/pickpocket/shot = current_projectile
		shot.linkedGun = src
		shot.targetZone = user.zone_sel.selecting
		shot.firer = user.key
		return ..(target, start, user)

/obj/item/gun/energy/pickpocket/testing // has a beefier cell in it
	ammo = /obj/item/ammo/power_cell/self_charging/big

/obj/item/gun/energy/alastor
	name = "Alastor pattern laser rifle"
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	icon_state = "alastor100"
	item_state = "alastor"
	icon = 'icons/obj/38x38.dmi'
	uses_multiple_icon_states = 1
	force = 7.0
	can_dual_wield = 0
	two_handed = 1
	desc = "A gun that produces a harmful laser, causing substantial damage."
	muzzle_flash = "muzzle_flash_laser"
	ammo = /obj/item/ammo/power_cell/med_power
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/laser/alastor))

	update_icon()
		..()
		if(src.loaded_magazine)
			//Wire: Fix for Division by zero runtime
			var/maxCharge = (src.loaded_magazine.max_charge > 0 ? src.loaded_magazine.max_charge : 0)
			var/ratio = min(1, src.loaded_magazine.charge / maxCharge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "alastor[ratio]"
			return

///////////////////////////////////////////////////
/obj/item/gun/energy/lawbringer/old
	name = "Antique Lawbringer"
	icon = 'icons/obj/items/gun.dmi'
	icon_state = "old-lawbringer0"
	old = 1

/obj/item/gun/energy/lawbringer
	name = "Lawbringer"
	icon = 'icons/obj/items/gun.dmi'
	item_state = "lawg-detain"
	icon_state = "lawbringer0"
	desc = "A gun with a microphone. Fascinating."
	var/old = 0
	m_amt = 5000
	g_amt = 2000
	mats = 16
	var/owner_prints = null
	var/image/indicator_display = null
	rechargeable = 0
	fixed_mag = TRUE
	muzzle_flash = "muzzle_flash_elec"
	ammo = new/obj/item/ammo/power_cell/self_charging/lawbringer
	firemode_index = "detain" // assoc'd list of assoc'd lists so the yell-a-mode thing works properly
	firemodes = list("detain" = list("name" = "detain", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt/aoe),\
	                 "execute" = list("name" = "execute", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/revolver_38/lawbringer),\
	                 "smokeshot" = list("name" = "smokeshot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/smoke/lawbringer),\
	                 "hotshot" = list("name" = "hotshot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/flare/lawbringer),\
	                 "knockout" = list("name" = "knockout", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/tranq_dart/lawbringer),\
	                 "bigshot" = list("name" = "bigshot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/aex/lawbringer),\
	                 "clownshot" = list("name" = "clownshot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/bullet/clownshot),\
	                 "pulse" = list("name" = "pulse", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt/pulse))

	New(var/mob/M)
		src.indicator_display = image('icons/obj/items/gun.dmi', "")
		assign_name(M)
		..()

	disposing()
		indicator_display = null
		..()

	attack_hand(mob/user as mob)
		if (!owner_prints)
			boutput(user, "<span class='alert'>[src] has accepted your fingerprint ID. You are its owner!</span>")
			assign_name(user)
		..()

	set_firemode(var/mob/user)
		src.shoot_delay = src.firemodes[src.firemode_index]["shoot_delay"]
		src.burst_count = src.firemodes[src.firemode_index]["burst_count"]
		src.refire_delay = src.firemodes[src.firemode_index]["refire_delay"]
		src.spread_angle = src.firemodes[src.firemode_index]["spread_angle"]
		src.current_projectile = new src.firemodes[src.firemode_index]["projectile"]

	//if it has no owner prints scanned, the next person to attack_self it is the owner.
	//you have to use voice activation to change modes. haha!
	attack_self(mob/user as mob)
		src.add_fingerprint(user)
		if (!owner_prints)
			boutput(user, "<span class='alert'>[src] has accepted your fingerprint ID. You are its owner!</span>")
			assign_name(user)
		else
			boutput(user, "<span class='notice'>There don't seem to be any buttons on [src] to press.</span>")

	proc/assign_name(var/mob/M)
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.bioHolder)
				owner_prints = H.bioHolder.uid_hash
				src.name = "HoS [H.real_name]'s Lawbringer"
				tooltip_rebuild = 1

	//stolen the heartalk of microphone. the microphone can hear you from one tile away. unless you wanna
	hear_talk(mob/M as mob, msg, real_name, lang_id)
		var/turf/T = get_turf(src)
		if (M in range(1, T))
			src.talk_into(M, msg, null, real_name, lang_id)

	//can only handle one name at a time, if it's more it doesn't do anything
	talk_into(mob/M as mob, msg, real_name, lang_id)
		//Do I need to check for this? I can't imagine why anyone would pass the wrong var here...
		if (!islist(msg))
			return

		//only work if the voice is the same as the voice of your owner fingerprints.
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (owner_prints && (H.bioHolder.uid_hash != owner_prints))
				are_you_the_law(M, msg[1])
				return
		else
			are_you_the_law(M, msg[1])
			return //AFAIK only humans have fingerprints/"palmprints(in judge dredd)" so just ignore any talk from non-humans arlight? it's not a big deal.

		if(!src.firemodes || !src.firemodes.len)
			boutput(M, "<span class='notice'>Gun broke. Call 1-800-CODER.</span>")
			src.firemodes = initial(src.firemodes)
			src.firemode_index = "detain"
			src.set_firemode()
			item_state = "lawg-detain"
			M.update_inhands()
			update_icon()

		var/text = msg[1]
		text = sanitize_talk(text)
		if (fingerprints_can_shoot(M))
			switch(text)
				if ("detain")
					src.firemode_index = "detain"
					item_state = "lawg-detain"
					playsound(M, "sound/vox/detain.ogg", 50)
				if ("execute")
					src.firemode_index = "execute"
					item_state = "lawg-execute"
					playsound(M, "sound/vox/exterminate.ogg", 50)
				if ("smokeshot")
					src.firemode_index = "smokeshot"
					item_state = "lawg-smokeshot"
					playsound(M, "sound/vox/smoke.ogg", 50)
				if ("knockout")
					src.firemode_index = "knockout"
					item_state = "lawg-knockout"
					playsound(M, "sound/vox/sleep.ogg", 50)
				if ("hotshot")
					src.firemode_index = "hotshot"
					item_state = "lawg-hotshot"
					playsound(M, "sound/vox/hot.ogg", 50)
				if ("bigshot","highexplosive","he")
					src.firemode_index = "bigshot"
					item_state = "lawg-bigshot"
					playsound(M, "sound/vox/high.ogg", 50)
					sleep(0.4 SECONDS)
					playsound(M, "sound/vox/explosive.ogg", 50)
				if ("clownshot")
					src.firemode_index = "clownshot"
					item_state = "lawg-clownshot"
					playsound(M, "sound/vox/clown.ogg", 30)
				if ("pulse")
					src.firemode_index = "pulse"
					item_state = "lawg-pulse"
					playsound(M, "sound/vox/push.ogg", 50)
			src.set_firemode()
		else		//if you're not the owner and try to change it, then fuck you
			switch(text)
				if ("detain","execute","knockout","hotshot","bigshot","highexplosive","he","clownshot", "pulse")
					random_burn_damage(M, 50)
					M.changeStatus("weakened", 4 SECONDS)
					elecflash(src,power=2)
					M.visible_message("<span class='alert'>[M] tries to fire [src]! The gun initiates its failsafe mode.</span>")
					return

		M.update_inhands()
		update_icon()

	//Are you really the law? takes the mob as speaker, and the text spoken, sanitizes it. If you say "i am the law" and you in fact are NOT the law, it's gonna blow. Moved out of the switch statement because it that switch is only gonna run if the owner speaks
	proc/are_you_the_law(mob/M as mob, text)
		text = sanitize_talk(text)
		if (findtext(text, "iamthelaw"))
			//you must be holding/wearing the weapon
			//this check makes it so that someone can't stun you, stand on top of you and say "I am the law" to kill you
			if (src in M.contents)
				if (M.job != "Head of Security")
					src.cant_self_remove = 1
					playsound(src.loc, "sound/weapons/armbomb.ogg", 75, 1, -3)
					logTheThing("combat", src, null, "Is not the law. Caused explosion with Lawbringer.")

					SPAWN_DBG(2 SECONDS)
						explosion_new(null, get_turf(src), 15)
					return 0
				else
					return 1

	//all gun modes use the same base sprite icon "lawbringer0" depending on the current projectile/current mode, we apply a coloured overlay to it.
	update_icon()
		..()
		src.icon_state = "[old ? "old-" : ""]lawbringer0"
		src.overlays = null

		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			//if we're showing zero charge, don't do any overlay, since the main image shows an empty gun anyway
			if (ratio == 0)
				return
			indicator_display.icon_state = "[old ? "old-" : ""]lawbringer-d[ratio]"

			if(src.firemode_index == "detain")			//detain - yellow
				indicator_display.color = "#FFFF00"
				muzzle_flash = "muzzle_flash_elec"
			else if (src.firemode_index == "execute")			//execute - cyan
				indicator_display.color = "#00FFFF"
				muzzle_flash = "muzzle_flash"
			else if (src.firemode_index == "smoke")			//smokeshot - dark-blue
				indicator_display.color = "#0000FF"
				muzzle_flash = "muzzle_flash"
			else if (src.firemode_index == "knockout")	//knockout - green
				indicator_display.color = "#008000"
				muzzle_flash = null
			else if (src.firemode_index == "hotshot")			//hotshot - red
				indicator_display.color = "#FF0000"
				muzzle_flash = null
			else if (src.firemode_index == "bigshot")	//bigshot - purple
				indicator_display.color = "#551A8B"
				muzzle_flash = null
			else if (src.firemode_index == "clownshot")		//clownshot - pink
				indicator_display.color = "#FFC0CB"
				muzzle_flash = null
			else if (src.firemode_index == "pulse")		//pulse - pale-blue
				indicator_display.color = "#EEEEFF"
				muzzle_flash = "muzzle_flash_bluezap"
			else
				indicator_display.color = "#000000"				//default, should never reach. make it black
			src.overlays += indicator_display

	//just remove all capitalization and non-letter characters
	proc/sanitize_talk(var/msg)
		//find all characters that are not letters and remove em
		var/regex/r = regex("\[^a-z\]+", "g")
		msg = lowertext(msg)
		msg = r.Replace(msg, "")
		return msg

	// Checks if the gun can shoot based on the fingerprints of the shooter.
	//returns true if the prints match or there are no prints stored on the gun(emagged). false if it fails
	proc/fingerprints_can_shoot(var/mob/user)
		if (!owner_prints || (user.bioHolder.uid_hash == owner_prints))
			return 1
		return 0

	shoot(var/target,var/start,var/mob/user)
		if (canshoot())
			//removing this for now so anyone can shoot it. I PROBABLY will want it back, doing this for some light appeasement to see how it goes.
			//shock the guy who tries to use this if they aren't the proper owner. (or if the gun is not emagged)
			// if (!fingerprints_can_shoot(user))
			// 	// shock(user, 70)
			// 	random_burn_damage(user, 50)
			// 	user.changeStatus("weakened", 4 SECONDS)
			// 	var/datum/effects/system/spark_spread/s = unpool(/datum/effects/system/spark_spread)
			// 	s.set_up(2, 1, (get_turf(src)))
			// 	s.start()
			// 	user.visible_message("<span class='alert'>[user] tries to fire [src]! The gun initiates its failsafe mode.</span>")
			// 	return

			if (src.firemode_index == "hotshot")
				shoot_fire_hotspots(target, start, user)
		return ..(target, start, user)

/obj/item/gun/energy/lawbringer/emag_act(var/mob/user, var/obj/item/card/emag/E)
	if (user)
		boutput(user, "<span class='alert'>Anyone can use this gun now. Be careful! (use it in-hand to register your fingerprints)</span>")
		owner_prints = null
	return 0

//stolen from firebreath in powers.dm
/obj/item/gun/energy/lawbringer/proc/shoot_fire_hotspots(var/target,var/start,var/mob/user)
	var/list/affected_turfs = getline(get_turf(start), get_turf(target))
	var/range = 6
	playsound(user.loc, "sound/effects/mag_fireballlaunch.ogg", 50, 0)
	var/turf/currentturf
	var/turf/previousturf
	for(var/turf/F in affected_turfs)
		previousturf = currentturf
		currentturf = F
		if(currentturf.density || istype(currentturf, /turf/space))
			break
		if(previousturf && LinkBlocked(previousturf, currentturf))
			break
		if (F == get_turf(user))
			continue
		if (get_dist(user,F) > range)
			continue
		tfireflash(F,0.5,2400)

// Pulse Rifle //
// An energy gun that uses the lawbringer's Pulse setting, to beef up the current armory.

/obj/item/gun/energy/pulse_rifle
	name = "pulse rifle"
	desc = "todo"
	icon_state = "pulse_rifle"
	uses_multiple_icon_states = 1
	item_state = "pulse_rifle"
	force = 5
	two_handed = 1
	can_dual_wield = 0
	muzzle_flash = "muzzle_flash_bluezap"
	ammo = /obj/item/ammo/power_cell/high_power //300 PU
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/energy_bolt/pulse))

	update_icon()
		..()
		if(src.loaded_magazine)
			var/ratio = min(1, src.loaded_magazine.charge / src.loaded_magazine.max_charge)
			ratio = round(ratio, 0.25) * 100
			src.icon_state = "pulse_rifle[ratio]"
			return


///////////////////////////////////////Wasp Gun
/obj/item/gun/energy/wasp
	name = "mini wasp-egg-crossbow"
	desc = "A weapon favored by many of the syndicate's stealth apiarists, which does damage over time using swarms of angry wasps. Utilizes a self-recharging atomic power cell to synthesize more wasp eggs. Somehow."
	icon_state = "crossbow" //placeholder, would prefer a custom wasp themed icon
	w_class = 2.0
	item_state = "crossbow" //ditto
	force = 4.0
	throw_speed = 3
	throw_range = 10
	rechargeable = 0 // Cannot be recharged manually.
	ammo = /obj/item/ammo/power_cell/self_charging/slowcharge
	is_syndicate = 1
	silenced = 1
	custom_cell_max_capacity = 100
	module_research = list("science" = 2, "weapons" = 2, "energy" = 2, "miniaturization" = 10, "hydroponics" = 10) //deprecated in current code
	firemodes = list(list("name" = "wasp", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/special/spreader/quadwasp))

// HOWIZTER GUN
// dumb meme admin item. not remotely fair, will probably kill person firing it.

/obj/item/gun/energy/howitzer
	name = "man-portable plasma howitzer"
	desc = "How can you even lift this?"
	icon_state = "bfg"
	uses_multiple_icon_states = 0
	force = 25
	two_handed = 1
	can_dual_wield = 0
	ammo = /obj/item/ammo/power_cell/self_charging/howitzer
	firemodes = list(list("name" = "single-shot", "burst_count" = 1, "refire_delay" = 0.7 DECI SECONDS, "shoot_delay" = 0, "spread_angle" = 0, "projectile" = /datum/projectile/special/howitzer))
