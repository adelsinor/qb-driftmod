local QBCore = exports["qb-core"]:GetCoreObject()

-- default (old) drift system
if not Config.AlternateDrift then
	local kmh = 3.6
	local mph = 2.23693629
	-----------------
	--   E D I T   --
	-----------------
	local driftmode = false -- open / close drift
	local speed = kmh -- It can also be set to mph
	local drift_speed_limit = 100.0
	local reduced_grip = nil -- use to counter the glitch
	local carspeed = 0
	local playerPed = 0

	-- command to toggle drift mdoe
	local toggle = "NUMPAD9" -- 118 -- Numpad 9
	RegisterKeyMapping("+dr1ft-m0d3", "Toggle Drift Mode", "keyboard", toggle)
	RegisterCommand("+dr1ft-m0d3", function()
		playerPed = PlayerPedId()

		-- not in any vehicle?
		if not IsPedInAnyVehicle(playerPed, false) then
			driftmode = false -- reset it
			return
		end

		if driftmode then
			if reduced_grip then return end
			driftmode = false
			QBCore.Functions.Notify("Drift Mode : OFF", "error", 2000)
		elseif carspeed <= drift_speed_limit then
			driftmode = true
			QBCore.Functions.Notify("Drift Mode : ON", "success", 2000)
		end
	end, false)

	CreateThread(function()
		while not LocalPlayer.state.isLoggedIn do
			Wait(2000)
		end

		local counter = 0
		local vehicle = 0
		local sleep = 1000
		while true do
			playerPed, sleep = PlayerPedId(), 1000

			if IsPedInAnyVehicle(playerPed, false) then
				vehicle = GetVehiclePedIsIn(playerPed, false)
				carspeed = GetEntitySpeed(vehicle) * speed

				if GetPedInVehicleSeat(vehicle, -1) == playerPed then
					if driftmode and carspeed > 10.0 then
						if carspeed <= drift_speed_limit then
							sleep, counter = 5, 0
							reduced_grip = (IsControlPressed(1, 21) == true)
							SetVehicleReduceGrip(vehicle, reduced_grip)
						else
							counter = counter + 1
							if counter >= 3 then
								driftmode, counter = false, 0
								QBCore.Functions.Notify("Drift Mode : OFF", "error", 2000)
							end
						end
					elseif reduced_grip then
						reduced_grip = false
						SetVehicleReduceGrip(vehicle, false)
					end
				elseif reduced_grip then
					SetVehicleReduceGrip(vehicle, false)
				end
			elseif driftmode then
				driftmode = false
			end

			Wait(sleep)
		end
	end)

	return -- no need to go further
end

-- alternative (new) drift system
local driftmode = false -- open / close drift
local handleMods = {
	fInitialDragCoeff = 90.22,
	fDriveInertia = .31,
	fSteeringLock = 22,
	fTractionCurveMax = -1.1,
	fTractionCurveMin = -.4,
	fTractionCurveLateral = 2.5,
	fLowSpeedTractionLossMult = -.57
}

RegisterNetEvent("qb-smallresources:client:drifmode", function()
	local ped = PlayerPedId()
	if not IsPedInAnyVehicle(ped) then return end

	local veh = GetVehiclePedIsIn(ped, false)
	if GetPedInVehicleSeat(veh, -1) ~= ped then return end

	driftmode = (GetVehicleHandlingFloat(veh, "CHandlingData", "fInitialDragCoeff") > 90)
	local modif = driftmode and -1 or 1

	for k, v in pairs(handleMods) do
		SetVehicleHandlingFloat(veh, "CHandlingData", k, GetVehicleHandlingFloat(veh, "CHandlingData", k) + v * modif)
	end

	if driftmode then
		QBCore.Functions.Notify("Drift Mode : OFF", "error", 2000)
	else
		QBCore.Functions.Notify("Drift Mode : ON", "success", 2000)
	end

	if GetVehicleHandlingFloat(veh, "CHandlingData", "fInitialDragCoeff") < 90 then
		SetVehicleEnginePowerMultiplier(veh, 0.0)
	elseif GetVehicleHandlingFloat(veh, "CHandlingData", "fDriveBiasFront") == 0 then
		SetVehicleEnginePowerMultiplier(veh, 190.0)
	else
		SetVehicleEnginePowerMultiplier(veh, 100.0)
	end
end)

-- command to toggle drift mdoe
local toggle = "NUMPAD9" -- 118 -- Numpad 9
RegisterKeyMapping("+dr1ft-m0d3", "Toggle Drift Mode", "keyboard", toggle)
RegisterCommand("+dr1ft-m0d3", function()
	TriggerEvent("qb-smallresources:client:drifmode")
end, false)
