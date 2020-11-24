/obj/item/gun/energy/artifact
	// an energy gun, it shoots things as you might expect
	name = "artifact energy gun"
	icon = 'icons/obj/artifacts/artifactsitem.dmi'
	icon_state = "laser"
	force = 5.0
	artifact = 1
	is_syndicate = 1
	module_research_no_diminish = 1
	mat_changename = 0
	mat_changedesc = 0
	var/art_projectiles = list()

	New(var/loc, var/forceartiorigin)
		..()
		var/datum/artifact/energygun/AS = new /datum/artifact/energygun(src)
		src.firemodes = AS.artifact_firemodes
		src.art_projectiles = AS.artifact_bullets
		if (forceartiorigin)
			AS.validtypes = list("[forceartiorigin]")
		src.artifact = AS
		// The other three are normal for energy gun setup, so proceed as usual i guess
		qdel(src.loaded_magazine)
		src.loaded_magazine = null

		SPAWN_DBG(0)
			src.ArtifactSetup()
			var/datum/artifact/A = src.artifact
			src.loaded_magazine = new/obj/item/ammo/power_cell/self_charging/artifact(src,A.artitype)
			src.ArtifactDevelopFault(15)
			src.firemode_index = 1
			src.set_firemode()
			src.loaded_magazine.max_charge = max(src.loaded_magazine.max_charge, src.current_projectile.cost * src.firemodes[1]["burst_count"])


		src.setItemSpecial(null)

	examine()
		. = list("You have no idea what this thing is!")
		if (!src.ArtifactSanityCheck())
			return
		var/datum/artifact/A = src.artifact
		if (istext(A.examine_hint))
			. += A.examine_hint

	UpdateName()
		src.name = "[name_prefix(null, 1)][src.real_name][name_suffix(null, 1)]"

	attackby(obj/item/W as obj, mob/user as mob)
		if (src.Artifact_attackby(W,user))
			..()

	set_firemode(mob/user)
		src.firemode_index = rand(1, src.firemodes.len)
		if(src.firemode_index > round(src.firemodes.len) || src.firemode_index < 1)
			src.firemode_index = 1
		src.shoot_delay = src.firemodes[src.firemode_index]["shoot_delay"]
		src.burst_count = src.firemodes[src.firemode_index]["burst_count"]
		src.refire_delay = src.firemodes[src.firemode_index]["refire_delay"]
		src.spread_angle = src.firemodes[src.firemode_index]["spread_angle"]
		src.current_projectile = src.firemodes[src.firemode_index]["projectile"]
		var/datum/artifact/A = src.artifact
		if(A.activated && user)
			boutput(user, "<span class='notice'>you set [src] to [src.firemodes[src.firemode_index]["name"]].</span>")

	process_ammo(var/mob/user)
		if(isrobot(user))
			var/mob/living/silicon/robot/R = user
			if(R.cell)
				if(R.cell.charge >= src.robocharge)
					R.cell.charge -= src.robocharge
					return 1
			return 0
		else
			if(src.current_projectile && src.loaded_magazine && src.loaded_magazine.use(src.current_projectile.cost))
				return 1
			return 0

	shoot(var/target,var/start,var/mob/user)
		if (!src.ArtifactSanityCheck())
			return
		var/datum/artifact/energygun/A = src.artifact

		if (!istype(A))
			return

		if (!A.activated)
			return

		..()

		A.ReduceHealth(src)

		src.ArtifactFaultUsed(user)
		return

/datum/artifact/energygun
	associated_object = /obj/item/gun/energy/artifact
	rarity_class = 2
	validtypes = list("ancient","eldritch","precursor")
	react_elec = list(0.02,0,5)
	react_xray = list(10,75,100,11,"CAVITY")
	var/integrity = 100
	var/integrity_loss = 5
	var/list/artifact_firemodes = list()
	var/list/artifact_bullets = list()
	var/datum/projectile/artifact/bullet = null
	examine_hint = "It seems to have a handle you're supposed to hold it by."
	module_research = list("weapons" = 8, "energy" = 8)
	module_research_insight = 3
#warn UNFUCK IT
	New()
		..()
		var/bullet_num = rand(1,3)
		src.artifact_bullets.len = bullet_num
		src.artifact_firemodes.len = bullet_num
		for(var/i in 1 to bullet_num)
			var/burst_count = rand(1, 3)
			var/refire_delay = rand(0.1, 10)
			var/shoot_delay = rand(0.1, 10)
			var/spread_angle = rand(0, 30)
			var/number_mult = rand(2, 20)
			var/mode_name = list(" lights", " things", " uncanny feelings")

			var/datum/projectile/artifact/artbullet = new/datum/projectile/artifact
			artbullet = new/datum/projectile/artifact
			artbullet.randomise()
			// artifact tweak buff, people said guns were useless compared to their cells
			// the next 3 lines override the randomize(). Doing this instead of editting randomize to avoid changing prismatic spray.
			artbullet.power = rand(15,35) / burst_count // randomise puts it between 2 and 50, let's make it less variable
			artbullet.dissipation_rate = rand(1,artbullet.power)
			artbullet.cost = rand(35,100) / burst_count // randomise puts it at 50-150
			src.artifact_firemodes[i] += list("name" = "[burst_count * number_mult][pick(mode_name)]", "burst_count" = burst_count, "refire_delay" = refire_delay, "shoot_delay" = shoot_delay, "spread_angle" = spread_angle, "projectile" = artbullet)


		integrity = rand(50, 100)
		integrity_loss = rand(1, 3) // was rand(1,7)
		react_xray[3] = integrity

	proc/ReduceHealth(var/obj/item/gun/energy/artifact/O)
		var/prev_health = integrity
		integrity -= integrity_loss
		if (integrity <= 20 && prev_health > 20)
			O.visible_message("<span class='alert'>[O] emits a terrible cracking noise.</span>")
		if (integrity <= 0)
			O.visible_message("<span class='alert'>[O] crumbles into nothingness.</span>")
			qdel(O)
		react_xray[3] = integrity
