local M = {}

-- all users of the module will share this table
local newGameState = {
	CurrentState="Pitch",
	LastPitch = 0,
	Players=2,
	Player=1,
	Inning=1,
	Strikes=0,
	Balls=0,
	Outs=0,
	BaseStatus={0,0,0},
	Scores={0,0}
}
local state = {
	CurrentState="Pitch",
	LastPitch = 0,
	Players=2,
	Player=1,
	Inning=1,
	Strikes=0,
	Balls=0,
	Outs=0,
	BaseStatus={0,0,0},
	Scores={0,0}
}
local labelText = ""

local function setStatus(text)
	labelText=text
	label.set_text("#Status", text)
end

local function changeBase()
	local animation = "red"
	if state["Player"] == 1 then
		animation = "blue"
	end
	local bases = state["BaseStatus"]
	if bases[1] ==0 then
		msg.post("1b#sprite","disable")
	else
		msg.post("1b#sprite","enable")
		msg.post("1b#sprite", "play_animation", {id = hash(animation)})
	end
	if bases[2] ==0 then
		msg.post("2b#sprite","disable")
	else
		msg.post("2b#sprite","enable")
		msg.post("2b#sprite", "play_animation", {id = hash(animation)})
	end
	if bases[3] ==0 then
		msg.post("3b#sprite","disable")
	else
		msg.post("3b#sprite","enable")
		msg.post("3b#sprite", "play_animation", {id = hash(animation)})
	end

end
function M.GetState()
	return state
end

local function throw()
	msg.post("go#dicescript", "single", {player = state["Player"]})
end
function M.otherPlayer()
	if state["Player"] == 1 then
		return 2
	else
		return 1
	end
end
local function clearCount()
	state["Balls"] = 0;
	state["Strikes"] = 0;
	label.set_text("scoreboard#balls", "0")
	label.set_text("scoreboard#strikes", "0")
end

local function score(points)
	state["Scores"][state["Player"]] = state["Scores"][state["Player"]]+points
	label.set_text("scoreboard#p1score", state["Scores"][1])
	label.set_text("scoreboard#p2score", state["Scores"][2])
end

local function walk()
	setStatus( "Walk")
	state["CurrentState"] = "Pitch"
	clearCount()
	local bases = state["BaseStatus"];
	if bases[1] == 0 then
		bases[1] = 1
	elseif bases[2] == 0 then
		bases[2] = 1
	elseif bases[3] == 0 then
		bases [3] = 1
	else
		score(1)
	end
	changeBase()
end

local function threeOuts()
	state["CurrentState"] = "Pitch"
	state["BaseStatus"] = {0,0,0}
	changeBase()
	state["Outs"] = 0;
	label.set_text("scoreboard#outs", 0)
	if state["Player"] == 2 then
		state["Inning"] = state["Inning"] + 1
		label.set_text("scoreboard#inning", state["Inning"])
	end
	if state["Inning"] == 2 then
		state["CurrentState"] = "Done"
		if state["Scores"][1] > state["Scores"][2] then
			setStatus("Guest Wins")
		elseif state["Scores"][2] > state["Scores"][1] then
			setStatus("Home Wins")
		else
			setStatus("Tie!")
		end
	end
	state["Player"] = M.otherPlayer();
	if state["Player"] == 1 then
		msg.post("#field", "play_animation", {id = hash("baseballBlueBat")})
	else
		msg.post("#field", "play_animation", {id = hash("baseballRedBat")})
	end
end

local function out()
	setStatus(labelText .. " " .. "Out!")
	state["CurrentState"] = "Pitch"
	state["Outs"] = state["Outs"] + 1;
	label.set_text("scoreboard#outs", state["Outs"])
	clearCount()
	if state["Outs"] == 3 then
		threeOuts();
	end
	throw()
end
local function strike()
	state["Strikes"] = state["Strikes"] + 1
	setStatus( "Strike ".. state["Strikes"])
	state["CurrentState"] = "Pitch"

	label.set_text("scoreboard#strikes", state["Strikes"])
	if state["Strikes"] == 3 then
		out();
	else
		throw()
	end
end

local function homerun()
	setStatus( "HomeRun!")
	state["CurrentState"] = "Pitch"
	clearCount()
	local bases = state["BaseStatus"];
	local points = bases[1] + bases[2] + bases[3] + 1;
	score(points)
	state["BaseStatus"] = {0,0,0}
	changeBase()
	throw()
end

local function single()
	setStatus( "Single")
	state["CurrentState"] = "Pitch"
	clearCount()
	local bases = state["BaseStatus"];
	if bases[3] == 1 then
		score(1)
	end
	bases[3] = bases[2]
	bases[2] = bases[1]
	bases[1] = 1
	changeBase()
	throw()
end

local function double()
	setStatus( "Double")
	state["CurrentState"] = "Pitch"
	clearCount()
	local bases = state["BaseStatus"];
	score( bases[3] + bases[2])
	bases[3] = bases[1]
	bases[2] = 1
	bases[1] = 0
	changeBase()
	throw()
end

local function ball()
	msg.post("go#dicescript", "clearDice", {player = M.otherPlayer()})
	label.set_text("scoreboard#balls", state["Balls"])
	setStatus( "Ball" .. state["Balls"])
	state["Balls"] = state["Balls"] + 1
	
	if state["Balls"] == 4 then
		walk()
	end
	throw()
end

function M.stateChange(changeType)
	local inningmessage;
	if state["Player"] == 1 then
		inningmessage = "Top of the "
	else
		inningmessage = "Bottom of the "
	end
	if state["Inning"] == 1 then
		inningmessage = inningmessage .. "first"
	elseif state["Inning"] == 2 then
		inningmessage = inningmessage .. "second"
	elseif state["Inning"] == 3 then
		inningmessage = inningmessage .. "third"
	else
		inningmessage = "Uh Oh."
	end
	inningmessage = inningmessage .. ". " .. state["Outs"] .. " outs. " .. state["Balls"] .. " balls and " .. state["Strikes"] .. " strikes."
	print(inningmessage)
	print("The score is " .. state["Scores"][1] .. " to " .. state["Scores"][2])
	if state["BaseStatus"][1] == 1 then
		print("Man on first")
	end
	if state["BaseStatus"][2] == 1 then
		print("Man on second")
	end
	if state["BaseStatus"][3] == 1 then
		print("Man on third")
	end
	print(state["CurrentState"] .. " rolled a " .. changeType)

	if state["CurrentState"] == "Pitch" then
		if changeType == 1 or changeType == 2 then
			ball()
		elseif changeType == 6 then
			strike()
		else
			--Other player Roll to hit.
			state["CurrentState"] = "MaybeHit"
			setStatus( "Good Pitch")
			state["LastPitch"] = changeType;
			msg.post("go#dicescript", "single", {player = M.otherPlayer()})
		end
	elseif state["CurrentState"] == "MaybeHit" then
		if changeType < state["LastPitch"] then
			strike()
		else
			state["CurrentState"] = "Angle"
			setStatus( "Hitting")
			msg.post("go#dicescript", "double", {player = M.otherPlayer()})
		end

	elseif state["CurrentState"] == "Angle" then
		if changeType <= 2 or  changeType >= 10 then
			homerun()
		else
			state["HitX"] = changeType;
			state["CurrentState"] = "Distance"
			setStatus( "Hitting")
			msg.post("go#dicescript", "single", {player = M.otherPlayer()})
		end
	elseif state["CurrentState"] == "Distance" then
		local hitX = state["HitX"];
		setStatus( "Fielding")
		if changeType == 6 then
			homerun()
		elseif changeType == 5 then
			if hitX == 6 or hitX == 5 or hitX == 4 then
				setStatus( "Caught")
				out()
			elseif hitX == 7 or hitX == 3 then
				state["CurrentState"] = "Throw"
				throw()
			elseif hitX == 8 then
				single()
			else
				double()
			end

		elseif changeType == 4 then
			if hitX == 5 then
				setStatus( "Caught")
				out()
			elseif  hitX == 3 or hitX == 4 or hitX == 6 or hitX == 7 then
				state["CurrentState"] = "Throw"
				setStatus( "Fielding")
				throw()
			elseif hitX == 8 then
				single()
			else
				double()
			end
		elseif changeType == 3 then
			if hitX == 3 or hitX == 4 or hitX == 6 or hitX == 7 then
				setStatus( "Caught")
				out()
			elseif  hitX == 5 or hitX == 8 then
				state["CurrentState"] = "Throw"
				throw()
			elseif hitX == 9 then
				single()
			end
		elseif changeType == 2 then
			if  hitX == 3 or hitX == 4 or hitX == 5  or hitX == 6 or hitX == 7 then
				state["CurrentState"] = "Throw"
				throw()
			elseif hitX == 8 then
				single()
			else
				double()
			end
		elseif changeType == 1 then
			if hitX == 5 then
				out()
			elseif  hitX == 4 or hitX == 6 then
				state["CurrentState"] = "Throw"
				throw()
			elseif hitX == 4 or hitX == 7 then
				single()
			else
				double()
			end
		end

	elseif  state["CurrentState"] == "Throw" then
		if changeType >= 4 then
			setStatus( "Thrown")
			out()
		else
			single()
		end
		--TODO
	elseif  state["CurrentState"] == "Done" then
		state = newGameState;
		label.set_text("scoreboard#balls", "0")
		label.set_text("scoreboard#strikes", "0")
		label.set_text("scoreboard#inning", "1")
		label.set_text("scoreboard#p1score", "0")
		label.set_text("scoreboard#p2score", "0")
		label.set_text("scoreboard#outs", "0")
		throw()
	end
	label.set_text("#Todo", "Roll for " .. state["CurrentState"])
end

return M