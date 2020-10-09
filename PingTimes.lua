local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Postie = require(script:WaitForChild("Postie"))

if RunService:IsClient() then
	
	-- Handle client end of ping logic
	
	Postie.SetCallback("RequestPing", function(GUID)
		-- We force the player to return a GUID to validate the ping, since
		-- any exploiter cannot have known the GUID in advance to fake it
		return GUID
	end)
	
	return nil
	
else
	
	-- Handle server side of ping logic, and expose data
	
	local UPDATE_FREQUENCY = 3
	
	local Http = game:GetService("HttpService")
	local PingTimes = {}
	
	local function PingFunc(Player)
		local GUID = Http:GenerateGUID(false)
		
		local StartClock = os.clock()
		
		local isSuccessful, returnedGUID = Postie.InvokeClient("RequestPing", Player, 3, GUID)
		
		if isSuccessful and (GUID == returnedGUID) then -- Validate
			PingTimes[Player] = os.clock()-StartClock
		end
	end
	
	local PingingThread = coroutine.create(function()
		while wait(UPDATE_FREQUENCY) do
			
			for _, Player in pairs(Players:GetPlayers()) do
				
				local PlayerThread = coroutine.create(PingFunc)
				coroutine.resume(PlayerThread, Player)
				
			end
			
		end
	end)
	coroutine.resume(PingingThread)
	
	Players.PlayerRemoving:Connect(function(Player)
		PingTimes[Player] = nil
	end)
	Players.PlayerAdded:Connect(function(Player)
		wait(1) -- let player load in and get stable connectivity
		PingFunc(Player)
	end)

	
	return setmetatable({}, {
		__index = function(tab, key)
			if typeof(key) == "Instance" and key:IsA("Player") then
				return PingTimes[key] or 0.075
			else
				return nil
			end
		end;
		
		__newindex = function(tab, key,value)
			warn("Cannot set PingTime manually")
		end;
	})
	
end
