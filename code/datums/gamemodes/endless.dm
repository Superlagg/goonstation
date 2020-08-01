/datum/game_mode/endless
	name = "Endless"
	config_tag = "endless"
	crew_shortage_enabled = 0
	var/list/enabled_jobs = list()
	var/list/milestones = list()
	var/list/assigned_areas = list()
	var/starttime = null
	var/human_time_left = ""
	var/round_length = 0
	var/next_progress_check_at

/datum/game_mode/endless/check_finished()
	if(emergency_shuttle.location == SHUTTLE_LOC_RETURNED)
		return 2 // We aint finished.

	if (no_automatic_ending)
		return 0
	return 0

/datum/game_mode/endless/declare_completion()
	boutput(world, "<b><span color='red'>It aint over yet.</span></b>")

/datum/game_mode/endless/post_setup()
	wagesystem.station_budget = 0
	wagesystem.shipping_budget = 7000
	wagesystem.research_budget = 0
	random_events.events_enabled = 0
	random_events.minor_events_enabled = 0

/datum/game_mode/endless/post_post_setup()
	machines_may_use_wired_power = 1
	makepowernets()
