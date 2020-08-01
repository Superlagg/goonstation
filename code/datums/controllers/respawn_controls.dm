var/datum/respawn_controls/respawn_controller

// Datum to handle automatic respawns
/*

	MVP should cover:
	- Tracking dead players and allowing them to respawn if possible - DONE
		- Triggered when player dies, player is put into waiting list  - DONE
		- Player removed from waiting list when respawned in-game (eg. ghost drone, cloning, borging) - DONE

	- Granting the dead players a "Respawn" verb when they're brought back - DONE
	- Pop-up during RP-mode reminding of New-Life Rule - DONE

	- Configurable
		- Respawn timeout (in-code, ideally by define) - DONE
		- On/off (in-code) - DONE

	- Verification of mob-to-be respawned is in a valid state for respawning - DONE
	- Giving a disconnected/reconnected client their Respawn button back - DONE

	- Allow a gamemode to force players to be able to respawn - DONE
	- Make respawning free up the player's job's slot for latejoining - not done

	============
	Future
	============
	- Verification that player does not join as their old character (on pain of death / admin alert)
	- Most respawns done through this controller

*/
#define RESPAWNEE_STATE_WAITING 0
#define RESPAWNEE_STATE_ELIGIBLE 1
#define RESPAWNEE_STATE_ALIVE 2

/datum/respawn_controls
	var/respawn_time = DEFAULT_RESPAWN_TIME
	var/respawns_enabled = RESPAWNS_ENABLED

	var/list/respawnees

	var/rp_alert = 0


	New()
		..()
		respawnees = list()

#ifdef RP_MODE
		rp_alert = 1
		respawns_enabled = 1
#endif

	proc/process()
		if(!respawns_enabled) return
		// Check the ones due to respawn
		for(var/ckey in respawnees)
			var/datum/respawnee/R = respawnees[ckey]
			checkRespawnee(R)


	proc/checkRespawnee(var/datum/respawnee/R)
		switch(R.checkValid())
			if(RESPAWNEE_STATE_WAITING)
				// This could happen if the client disconnects
			if(RESPAWNEE_STATE_ELIGIBLE)
				// They are eligible for respawn
				R.notifyAndGrantVerb()
			if(RESPAWNEE_STATE_ALIVE)
				// They were somehow revived
				unsubscribeRespawnee(R.ckey)

	proc/subscribeNewRespawnee(var/ckey)
		if(ckey && !respawnees.Find(ckey))

			var/datum/respawnee/R = new
			R.initialize(ckey, src)

			respawnees[ckey] = R


	proc/unsubscribeRespawnee(var/ckey)
		if(!ckey) return
		var/datum/respawnee/R = respawnees[ckey]
		respawnees.Remove(ckey)
		if(R)
			R.dispose()
			R = null

	proc/doRespawn(var/ckey, var/just_let_them_respawn)
		if(!ckey) return
		var/datum/respawnee/R = respawnees[ckey]
		if(R) R.doRespawn(just_let_them_respawn)

	proc/giveRespawnVerb(var/ckey)
		if(!ckey) return
		var/datum/respawnee/R = respawnees[ckey]
		if(R) R.notifyAndGrantVerb(1)

/datum/respawnee
	var/ckey
	var/client_processed
	var/died_time
	var/client/the_client

	var/due_for_respawn

	var/datum/respawn_controls/master


	disposing()
		if(the_client)
			the_client.verbs -= /client/proc/respawn_via_controller
		master = null
		..()

	proc/initialize(var/ckey, var/datum/respawn_controls/master)
		src.ckey = ckey
		src.master = master
		src.died_time = world.time

		// Get a reference to the client - this way we would know if they have disconnected or not
		try
			the_client = getClientFromCkey(src.ckey)
		catch


	proc/checkValid()
		// Time check (short-circuit saves some steps)
		if(due_for_respawn || src.died_time + master.respawn_time <= world.time)
			due_for_respawn = 1

			// Try to get a valid client reference
			if(!the_client)
				try
					client_processed = 0
					the_client = getClientFromCkey(src.ckey)
				catch
					return RESPAWNEE_STATE_WAITING

			// Check that the client is currently dead
			if(isobserver(the_client.mob) || isdead(the_client.mob))
				return RESPAWNEE_STATE_ELIGIBLE

		return RESPAWNEE_STATE_WAITING

	proc/notifyAndGrantVerb(var/respawn_anyway = 0)
		if(!client_processed && (checkValid() || respawn_anyway))
			// Send a message to the client
			SPAWN_DBG(0)
				alert(the_client.mob, "You are now eligible for respawn. Check the Commands tab.")

			boutput(the_client.mob, "<h1>You are now eligible for a respawn!</h1>")
			boutput(the_client.mob, "Check the commands tab for \"Respawn As New Character\"")
			if(master.rp_alert)
				boutput(the_client.mob, "<span class='alert'>Remember that you <B>must spawn as a <u>new character</u></B> and <B>have no memory of your past life!</B></span>")

			if(respawn_anyway)
				the_client.verbs |= /client/proc/respawn_via_controller_forced
			else
				the_client.verbs |= /client/proc/respawn_via_controller
			client_processed = 1

	proc/doRespawn(var/just_do_it_anyway = 0)
		if(checkValid() != RESPAWNEE_STATE_ELIGIBLE && !just_do_it_anyway)
			SPAWN_DBG(0)
				alert("You are not eligible for a respawn, bub!")
			return

		logTheThing("diary", usr, null, "used a timed respawn.", "game")

		var/mob/new_player/M = new()
		M.adminspawned = 1
		M.key = the_client.key
		M.Login()
		master.unsubscribeRespawnee(src.ckey)
		if (ticker.minds.Find(M.mind))
			mind_wipe(M)	// Remove job info, antag status, etc
			ticker.minds.Remove(M.mind)	// Update your mindlist entry
			ticker.minds.Add(M.mind)		// So the credits dont pile up

/client/proc/respawn_via_controller()
	set name = "Respawn As New Character"
	set desc = "When you're tired of being dead."

	respawn_controller.doRespawn(src.ckey)

/client/proc/respawn_via_controller_forced()
	set name = "Respawn As New Character"
	set desc = "Hop on the next flight back to the station. Get back to work!"

	respawn_controller.doRespawn(src.ckey, 1)

#undef RESPAWNEE_STATE_WAITING
#undef RESPAWNEE_STATE_ELIGIBLE
#undef RESPAWNEE_STATE_ALIVE
