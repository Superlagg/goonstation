// AI (i.e. game AI, not the AI player) controlled bots
#define DEFAULT_MOVE_SPEED 3
//movement control datum. Why yes, this is copied from guardbot.dm. Then also from secbot.dm
/datum/robo_mover
	var/obj/machinery/bot/master = null
	var/delay = 3

	New(var/newmaster)
		..()
		if(istype(newmaster, /obj/machinery/bot))
			src.master = newmaster
		return

	disposing()
		if(master.robo_mover == src)
			master.robo_mover = null
		src.master = null
		..()

	proc/master_move(var/atom/the_target as obj|mob, var/current_movepath,var/adjacent=0,var/max_dist=600)
		if(!master || !isturf(master.loc))
			src.master = null
			//dispose()
			return
		var/target_turf = null
		if(isturf(the_target))
			target_turf = the_target
		else
			target_turf = get_turf(the_target)
		SPAWN_DBG(0)
			if (!master)
				return
			var/compare_movepath = current_movepath
			master.path = AStar(get_turf(master), target_turf, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, max_dist, master.botcard)
			if(adjacent && master.path && master.path.len) //Make sure to check it isn't null!!
				master.path.len-- //Only go UP to the target, not the same tile.
			if(!master.path || !master.path.len || !the_target)
				master.frustration = INFINITY
				master.robo_mover = null
				master = null
				return 1

			master.moving = 1

			while(master && master.path && master.path.len && target_turf)
				if(compare_movepath != current_movepath) break
				if(!master.on)
					master.frustration = 0
					break

				if(master.act_n_move())
					break

				if(master?.path)
					step_to(master, master.path[1])
					if(master.loc != master.path[1])
						master.frustration++
						sleep(delay)
						continue
					master?.path -= master?.path[1]
					sleep(delay)
				else
					break // i dunno, it runtimes

			if (master)
				master.moving = 0
				master.robo_mover = null
				master.on_finished_moving()
				master = null

/obj/machinery/bot
	icon = 'icons/obj/bots/aibots.dmi'
	layer = MOB_LAYER
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	object_flags = CAN_REPROGRAM_ACCESS
	machine_registry_idx = MACHINES_BOTS
	var/botname = "robot" // The name that shows up on the ping
	var/obj/item/card/id/botcard // ID card that the bot "holds".
	var/access_lookup = "Captain" // For the get_access() proc. Defaults to all-access.
	var/locked = null
	var/on = 1 // We on?
	var/health = 25
	var/exploding = 0 //So we don't die like five times at once.
	var/muted = 0 // shut up omg shut up.
	var/no_camera = 0
	var/setup_camera_network = "Robots"
	var/obj/machinery/camera/cam = null
	var/emagged = 0
	var/mob/emagger = null
	var/mode = 0 // Defines what set of instructions to follow
	var/mode_max = 0
	var/stunned = 0 //It can be stunned by tasers. Delicate circuits.
	var/text2speech = 0 // dectalk!
	var/tacticool = 0 // Do we shit up our report with useless lingo?
	var/badge_number = null // what dumb thing are we calling ourself today?
	var/badge_number_length = 2 // How long is that dumb thing supposed to be?
	var/badge_number_length_forcemax = 0 // always make it that long

	// pathfinding stuff
	var/datum/robo_mover/robo_mover = null // The thing that makes a path and shoves us down it
	var/beacon_freq = FREQ_BOT_NAV // navigation beacon frequency
	var/control_freq = FREQ_SECBOT_CONTROL // bot control frequency
	var/new_destination // pending new destination (waiting for beacon response)
	var/destination // destination description tag
	var/next_destination // the next destination in the patrol route
	var/list/path = null // list of path turfs
	var/moving = 0 //Are we currently ON THE MOVE?
	var/current_movepath = 0 // Time we made the path
	var/blockcount = 0 //number of times retried a blocked path
	var/awaiting_beacon	= 0 // count of pticks awaiting a beacon response
	var/nearest_beacon // the nearest beacon's tag
	var/turf/nearest_beacon_loc	// the nearest beacon's location
	var/patrol_target // this is turf to navigate to (location of beacon)
	var/auto_patrol // Do we automatically just go wandering?
	var/frustration // Increments when unable to get to a place
	var/frustration_max = 8 // The most frustrated we'll let ourselves get before giving up
	var/atom/target
	var/target_lastloc //Loc of target when arrested.
	var/last_found = 0
	var/oldloc = null
	var/move_patrol_delay_mult //There's a delay
	var/move_summon_delay_mult //There's a delay

	p_class = 2

	power_change()
		return

	CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
		if (istype(mover, /obj/projectile))
			return 0
		return ..()

	New()
		..()

		if(!no_camera)
			src.cam = new /obj/machinery/camera(src)
			src.cam.c_tag = src.name
			src.cam.network = setup_camera_network

	disposing()
		botcard = null
		if(cam)
			cam.dispose()
			cam = null
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		user.lastattacked = src
		attack_particle(user,src)
		hit_twitch(src)
		if (W.hitsound)
			playsound(src,W.hitsound,50,1)
		..()

	// Generic default. Override for specific bots as needed.
	bullet_act(var/obj/projectile/P)
		if (!P || !istype(P))
			return

		hit_twitch(src)

		var/damage = 0
		damage = round(((P.power/4)*P.proj_data.ks_ratio), 1.0)

		if (P.proj_data.damage_type == D_KINETIC)
			src.health -= damage
		else if (P.proj_data.damage_type == D_PIERCING)
			src.health -= (damage*2)
		else if (P.proj_data.damage_type == D_ENERGY)
			src.health -= damage

		if (src.health <= 0)
			src.explode()
		return

	proc/explode()
		return

	proc/speak(var/message)
		if (!src.on || !message || src.muted)
			return
		src.audible_message("<span class='game say'><span class='name'>[src]</span> beeps, \"[message]\"")
		if (src.text2speech)
			SPAWN_DBG(0)
				var/audio = dectalk("\[:nk\][message]")
				if (audio && audio["audio"])
					for (var/mob/O in hearers(src, null))
						if (!O.client)
							continue
						if (O.client.ignore_sound_flags & (SOUND_VOX | SOUND_ALL))
							continue
						ehjax.send(O.client, "browseroutput", list("dectalk" = audio["audio"]))
					return 1
				else
					return 0

	proc/toggle_power(var/force_on = 0)
		if (!src)
			return 1
		if (force_on == 1)
			src.on = 1
		else
			src.on = !src.on
		kill_path(give_up = 1)

	proc/on_finished_moving()
		return

	proc/act_n_move()
		return

	proc/be_stunned()
		return

	proc/be_frustrated()
		if (src.frustration >= src.frustration_max)
			kill_path(give_up = 1)
			return 1

	proc/do_the_thing()
		return

	proc/do_mode(var/mode_do)
		if (isnull(src.mode) || src.mode > mode_max)
			return

	proc/patrol_the_bot(var/delay = 3) // Quick shorthand for making the bot go to the patrol target
		navigate_to(patrol_target, delay)
		return

	// finds a new patrol target
	proc/find_patrol_target()
		send_status()
		if(awaiting_beacon)			// awaiting beacon response
			awaiting_beacon++
			if(awaiting_beacon > 5)	// wait 5 secs for beacon response
				find_nearest_beacon()	// then go to nearest instead
				return 0
			else
				return 1

		if(next_destination)
			set_destination(next_destination)
			return 1
		else
			find_nearest_beacon()
			return 0

	// finds the nearest beacon to self
	// signals all beacons matching the patrol code
	proc/find_nearest_beacon()
		nearest_beacon = null
		new_destination = "__nearest__"
		post_signal(beacon_freq, "findbeacon", "patrol")
		awaiting_beacon = 1
		SPAWN_DBG(1 SECOND)
			awaiting_beacon = 0
			if(nearest_beacon)
				set_destination(nearest_beacon)
			else
				auto_patrol = 0
				mode = 0
				//speak("Disengaging patrol mode.")
				send_status()

	proc/at_patrol_target()
		find_patrol_target()
		return

	// sets the current destination
	// signals all beacons matching the patrol code
	// beacons will return a signal giving their locations
	proc/set_destination(var/new_dest)
		new_destination = new_dest
		post_signal(beacon_freq, "findbeacon", "patrol")
		awaiting_beacon = 1

	proc/kill_path(var/mode_do = 0, var/give_up = 0)
		if(src.robo_mover)
			src.robo_mover.master = null
			src.robo_mover = null
		src.moving = 0
		if(give_up)
			src.frustration = 0
			src.path = null
			src.target = null
			src.last_found = world.time
			do_mode(mode_do)

	proc/navigate_to(atom/the_target, var/move_delay = DEFAULT_MOVE_SPEED, var/adjacent = 0, max_dist=600, var/reset_mind = 0)
		var/release_frustration = 0
		if (src.frustration >= src.frustration_max)
			release_frustration = 1
		else
			release_frustration = reset_mind
		kill_path(give_up = release_frustration)
		current_movepath = world.time
		src.robo_mover = new /datum/robo_mover(src)

		// drsingh for cannot modify null.delay
		if (!isnull(src.robo_mover))
			src.robo_mover.master_move(the_target,current_movepath,adjacent)

		// drsingh again for the same thing further down in a moment.
		// Because master_move can delete the robo_mover

		if (!isnull(src.robo_mover))
			src.robo_mover.delay = move_delay

		return 0

	proc/post_signal(var/freq, var/key, var/value)
		post_signal_multiple(freq, list("[key]" = value) )

	// send a radio signal with multiple data key/values
	proc/post_signal_multiple(var/freq, var/list/keyval)

		var/datum/radio_frequency/frequency = radio_controller.return_frequency("[freq]")

		if(!frequency) return

		var/datum/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = 1
		for(var/key in keyval)
			signal.data[key] = keyval[key]
			//boutput(world, "sent [key],[keyval[key]] on [freq]")
		frequency.post_signal(src, signal)

	// signals bot status etc. to controller
	proc/send_status()
		var/list/kv = new()
		kv["type"] = botname
		kv["name"] = name
		kv["loca"] = get_area(src)
		kv["mode"] = mode
		post_signal_multiple(control_freq, kv)

	proc/make_tacticool()
		src.tacticool = 1
		src.badge_number = generate_dorkcode(src.badge_number_length, src.badge_number_length_forcemax)

	proc/generate_dorkcode(var/num_of_em = 1, var/force_max = 0)
		var/how_many_dorkcodes = force_max ? num_of_em : rand(1, num_of_em)
		while(how_many_dorkcodes >= 1)
			how_many_dorkcodes--
			switch(pick(1,5))
				if (1)
					. += pick_string("agent_callsigns", "nato")
				if (2)
					. += pick_string("agent_callsigns", "birds")
				if (3)
					. += pick_string("agent_callsigns", "mammals")
				if (4)
					. += pick_string("agent_callsigns", "colors")
				if (5)
					. += pick_string("shittybill", "nouns")
			. += "-"
		. += "[rand(1,99)]-"
		. += "[rand(1,99)]"

/obj/machinery/bot/examine()
	. = ..()
	var/healthpct = src.health / initial(src.health)
	if (healthpct <= 0.8)
		if (healthpct >= 0.4)
			. += "<span class='alert'>[src]'s parts look loose.</span>"
		else
			. += "<span class='alert'><B>[src]'s parts look very loose!</B></span>"

#undef DEFAULT_MOVE_SPEED
