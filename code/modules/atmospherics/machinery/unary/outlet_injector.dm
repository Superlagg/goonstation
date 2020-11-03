/obj/machinery/atmospherics/unary/outlet_injector
	icon = 'icons/obj/atmospherics/outlet_injector.dmi'
	icon_state = "off"
	layer = PIPE_MACHINE_LAYER
	plane = PLANE_NOSHADOW_BELOW //They're supposed to be embedded in the floor.

	name = "Air Injector"
	desc = "Has a valve and pump attached to it"

	var/injecting = 0

	var/volume_rate = 50
//
	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

	level = 1

	update_icon()
		if(node)
			if(src.flags & THING_IS_ON)
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]on"
			else
				icon_state = "[level == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
		else
			icon_state = "exposed"
			src.flags &= ~THING_IS_ON

		return

	process()
		..()
		injecting = 0

		if(src.flags & ~THING_IS_ON)
			return 0

		if(air_contents.temperature > 0)
			var/transfer_moles = (MIXTURE_PRESSURE(air_contents))*volume_rate/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

			var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

			loc.assume_air(removed)

			if(network)
				network.update = 1

		return 1

	proc/inject()
		if(src.flags & THING_IS_ON || injecting)
			return 0

		injecting = 1

		if(air_contents.temperature > 0)
			var/transfer_moles = (MIXTURE_PRESSURE(air_contents))*volume_rate/(air_contents.temperature * R_IDEAL_GAS_EQUATION)

			var/datum/gas_mixture/removed = air_contents.remove(transfer_moles)

			loc.assume_air(removed)

			if(network)
				network.update = 1

		flick("inject", src)

	proc
		set_frequency(new_frequency)
			radio_controller.remove_object(src, "[frequency]")
			frequency = new_frequency
			if(frequency)
				radio_connection = radio_controller.add_object(src, "[frequency]")

		broadcast_status()
			if(!radio_connection)
				return 0

			var/datum/signal/signal = get_free_signal()
			signal.transmission_method = 1 //radio signal
			signal.source = src

			signal.data["tag"] = id
			signal.data["device"] = "AO"
			signal.data["power"] = src.flags & THING_IS_ON ? 1 : 0
			signal.data["volume_rate"] = volume_rate

			radio_connection.post_signal(src, signal)

			return 1

	initialize()
		..()

		set_frequency(frequency)

	disposing()
		radio_controller.remove_object(src, "[frequency]")
		..()

	receive_signal(datum/signal/signal)
		if(signal.data["tag"] && (signal.data["tag"] != id))
			return 0

		switch(signal.data["command"])
			if("power_on")
				src.flags |= THING_IS_ON

			if("power_off")
				src.flags &= ~THING_IS_ON

			if("power_toggle")
				src.flags ^= THING_IS_ON

			if("inject")
				SPAWN_DBG(0) inject()

			if("set_volume_rate")
				var/number = text2num(signal.data["parameter"])
				number = min(max(number, 0), air_contents.volume)

				volume_rate = number

		if(signal.data["tag"])
			SPAWN_DBG(0.5 SECONDS) broadcast_status()
		update_icon()

	hide(var/i) //to make the little pipe section invisible, the icon changes.
		if(node)
			if(src.flags & THING_IS_ON)
				icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]on"
			else
				icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]off"
		else
			icon_state = "[i == 1 && istype(loc, /turf/simulated) ? "h" : "" ]exposed"
			src.flags &= ~THING_IS_ON
		return
