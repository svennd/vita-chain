-- chain for vita, by svennd
-- version 0.1

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- application variables
VERSION = "0.1"

-- game constants
BUTTON = { CROSS = 1, CIRCLE = 2, TRIANGLE = 3, SQUARE = 4, LTRIGGER = 5, RTRIGGER = 6, LEFT = 7, RIGHT = 8, UP = 9, DOWN = 10, ANALOG = 11, START = 12, SELECT = 13 }
FIELD = {WIDTH = 900, HEIGHT = 530}

-- color definitions
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

local yellow 	= Color.new(255, 255, 0)
local red 		= Color.new(255, 0, 0)
local green 	= Color.new(0, 255, 0)
local blue 		= Color.new(0, 0, 255)

local orange	= Color.new(255, 128, 0)
local seablue	= Color.new(0, 255, 255)
local purple	= Color.new(255, 0, 255)

local grey_1	= Color.new(244, 244, 244)
local grey_2	= Color.new(160, 160, 160)
local grey_3	= Color.new(96, 96, 96)

-- vars
atoms = {} 
-- atom states
STATE = {INIT = 1, EXPANDING = 2, EXPLODE = 3, MERGED = 4}
ATOM = {
			{NAME = "HYDROGEN", SIZE = 7, COLOR = yellow, EXPAND = 3, SCORE = 10}, 
			{NAME = "HELIUM", SIZE = 7, COLOR = red, EXPAND = 2, SCORE = 15},  
			{NAME = "LITHIUM", SIZE = 7, COLOR = green, EXPAND = 1.7, SCORE = 25}, 
			{NAME = "BERYLLIUM", SIZE = 7, COLOR = blue, EXPAND = 1.5, SCORE = 35},  
			{NAME = "BORON", SIZE = 7, COLOR = purple, EXPAND = 1.15, SCORE = 50},  
			{NAME = "CARBON", SIZE = 7, COLOR = orange, EXPAND = 1.07, SCORE = 70},  
			{NAME = "NITROGEN", SIZE = 7, COLOR = seablue, EXPAND = 1.01, SCORE = 100}
		}
game = {fps = 60, start = Timer.new(), last_tick = 0, step = 10}
user = {x = 0, y = 0, size = 10, state = STATE.INIT, expand = 1, tick = 0, activated = false, implode = 0}
MAX_EXPAND = 3
animation = { implode_start = 100, user_implode = 500 }
score = 0

function populate_atoms(n)	
	-- seed for selected_atom
	math.randomseed(os.clock()*1000)	
	
	-- prune pre-seed
	math.random(); math.random(); math.random();
	
	-- for n atoms
	local atom_id = 0
	while atom_id < (n+1) do
	
		local selected_atom = math.random(1, #ATOM) -- should be #ATOM
		
		-- dx, dy = 1-3% of the field per step
		atoms[atom_id] = {
							name = ATOM[selected_atom].NAME, 
							neutrons = ATOM[selected_atom].SIZE, 
							color = ATOM[selected_atom].COLOR, 
							x = math.random(30, FIELD.WIDTH-30), 
							y = math.random(30, FIELD.HEIGHT-30),
							dx = FIELD.WIDTH / math.random(5, 15) * random_direction(),
							dy = FIELD.HEIGHT / math.random(5, 15) * random_direction(),
							state = STATE.INIT,
							expand = 1,
							implode = 0,
							score = ATOM[selected_atom].SCORE
						}
		atom_id = atom_id + 1 
	end
end

-- we need a 1 or a -1
function random_direction()

	local result = math.random(0,1)
	if result == 0 then
		result = -1
	end
	return result
end

function draw()

	-- Starting drawing phase
	Graphics.initBlend()
	
	-- background
	Graphics.fillRect(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, grey_3)
	
	Graphics.debugPrint(500, 30, game.fps, red)
	Graphics.debugPrint(500, 90, score, red)
	
	-- local i = 0
	-- local count_atoms = #atoms
	-- while i < count_atoms do
		-- Graphics.debugPrint(10,200+(i*20), atoms[i].x .. "  " .. atoms[i].y, Color.new(255, 255, 255))
		-- Graphics.debugPrint(10,200+(i*20), atoms[i].name, Color.new(255, 255, 255))
		-- i = i + 1
	-- end

	-- draw field
	draw_field()
	
	-- draw user activation
	draw_user()
	
	-- draw atoms
	draw_atoms()
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

-- draw user
function draw_user()
	if user.activated and user.state ~= STATE.MERGED then
		Graphics.fillCircle(user.x, user.y, user.size*user.expand, white)
	end
end

-- draw atoms
function draw_atoms()
	local i = 0
	local count_atoms = #atoms
	while i < count_atoms do
		if atoms[i].state ~= STATE.MERGED
		then
			-- apply a channel to color if expanding
			if atoms[i].expand > 1 then
				Graphics.fillCircle(atoms[i].x, atoms[i].y, atoms[i].neutrons * atoms[i].expand, Color.new(Color.getR(atoms[i].color), Color.getG(atoms[i].color),Color.getB(atoms[i].color), 150))
			else
				Graphics.fillCircle(atoms[i].x, atoms[i].y, atoms[i].neutrons * atoms[i].expand, atoms[i].color)
			end
		end 
		i = i + 1
	end
end

debug_file = System.openFile("ux0:/data/chain_debug", FWRITE)
function debug_log(msg)
	System.writeFile(debug_file, msg, string.len(msg))
end
 
function draw_field()
	draw_box(10, FIELD.WIDTH, 10, FIELD.HEIGHT, 10, white)
end

-- draw a box
-- untill fillEmptyRect is fixed
function draw_box(x1, x2, y1, y2, width, color)

	-- top line
	Graphics.fillRect(x1, x2+width, y1, y1+width, color)
	
	-- bot line
	Graphics.fillRect(x1, x2+width, y2, y2+width, color)
	
	-- left line
	Graphics.fillRect(x1, x1+width, y1, y2, color)
	
	-- right line
	Graphics.fillRect(x2, x2+width, y1, y2, color)
	
end

function update(delta)
	-- determ new position of atoms
	-- local current = Timer.getTime(game.start)
	-- local elapsed = current - game.last_tick
	
	-- chaos
	move_atoms(delta)
	
	-- determ collisions
	collision_detect()
	
	-- expand collisions
	expand_user(delta)
	expand_atoms(delta)
	
	-- remove items
	implode_atoms(delta)
	implode_user(delta)	
	

	-- update tick
	-- game.last_tick = current
end

-- collision detection
function collision_detect()

	-- first check user
	if user.activated and user.state ~= STATE.MERGED then
		-- user is still active
		local i = 0
		local count_atoms = #atoms
		
		while i < count_atoms do
			-- only for floaters
			if atoms[i].state == STATE.INIT then
				-- distance should be smaller then user_size*expand + atom.neutrons (atom cannot have expansion but maybe later)
				if distance(user.x, user.y, atoms[i].x, atoms[i].y) <= (user.size*(user.expand) + atoms[i].neutrons) then
					-- expand and stop motion
					atoms[i].state = STATE.EXPANDING
					atoms[i].dx = 0
					atoms[i].dy = 0
				end
			end
			i = i + 1
		end
	end
	
	-- now do all the other atoms this is heavy
	local i = 0
	local count_atoms = #atoms
	
	while i < count_atoms do
		-- for expanding or exploding
		if atoms[i].state == STATE.EXPANDING or atoms[i].state == STATE.EXPLODE then
			local x_collision = atoms[i].x
			local y_collision = atoms[i].y
			local static_size = atoms[i].neutrons*atoms[i].expand
			
			-- collision detect all others
			local o = 0
			while o < count_atoms do
				-- only collide with floaters
				if atoms[o].state == STATE.INIT then
					if distance(x_collision, y_collision, atoms[o].x, atoms[o].y) <= (static_size + atoms[o].neutrons) then
						-- expand and stop motion
						atoms[o].state = STATE.EXPANDING
						atoms[o].dx = 0
						atoms[o].dy = 0		
					end
				end
				o = o + 1
			end
		end
		i = i + 1
	end
	
end

-- expand user
-- need to take dt in this increase
function expand_user(delta)
	if user.state == STATE.INIT or user.state == STATE.EXPANDING then
		if user.activated then
			-- expand when needed
			if user.expand < MAX_EXPAND then
				user.expand = user.expand + (delta*5)
			else
				user.state = STATE.EXPLODE
			end
		end
	end
end

-- expand all activated atoms
-- need to take dt in this increase
function expand_atoms(delta)
	local i = 0
	local count_atoms = #atoms
	
	while i < count_atoms do
		-- only for expanding
		if atoms[i].state == STATE.EXPANDING then
			if atoms[i].expand < MAX_EXPAND then
				atoms[i].expand = atoms[i].expand + (delta*3)
			else
				atoms[i].state = STATE.EXPLODE
			end
		end
		i = i + 1
	end
end

-- implode atoms if needed
function implode_atoms(delta)
	local i = 0
	local count_atoms = #atoms
	
	while i < count_atoms do
		-- only for EXPLODED
		if atoms[i].state == STATE.EXPLODE then
			if atoms[i].implode > animation.implode_start then
				if atoms[i].expand > 1 then
					atoms[i].expand = atoms[i].expand - (delta*5)
				else
					--remove from field
					atoms[i].state = STATE.MERGED
					score = score + atoms[i].score
				end
			else
				atoms[i].implode = atoms[i].implode + 1
			end
		end
		i = i + 1
	end
end

-- implode atoms if needed
function implode_user(delta)	
	if user.state == STATE.EXPLODE then
		-- give ticks
		if user.implode > animation.user_implode then
			if user.expand > 1 then
				user.expand = user.expand - (delta*5)
			else
				--remove from field
				user.state = STATE.MERGED
			end
		else
			user.implode = user.implode + 1
		end
	end
end

-- move the atoms around
function move_atoms(delta)
	local i = 0
	local count_atoms = #atoms
	while i < count_atoms do
	
		-- only move when no reaction has happened
		if atoms[i].state == STATE.INIT then
			-- current location
			local current_x = atoms[i].x
			local current_y = atoms[i].y
			local dir_x = atoms[i].dx
			local dir_y = atoms[i].dy
			
			-- determ new location
			local new_x = current_x + dir_x*delta --this should take into account the time passed
			local new_y = current_y + dir_y*delta --this should take into account the time passed
			
			-- check if the atom does not hit the boundry
			-- if it does switch direction
			-- 20 = field border + field offset
			if new_x-atoms[i].neutrons < 20 or new_x+atoms[i].neutrons > FIELD.WIDTH then
				dir_x = -dir_x
			end
			
			if new_y-atoms[i].neutrons < 20 or new_y+atoms[i].neutrons > FIELD.HEIGHT then
				dir_y = -dir_y
			end
			
			atoms[i].x = new_x
			atoms[i].y = new_y
			atoms[i].dx = dir_x
			atoms[i].dy = dir_y
		end
		i = i + 1
	end
end

function game_start()
	populate_atoms(30)
	
	game.last_tick = 0 -- drop ticks
	Timer.reset(game.start) -- restart game timer
end

-- determ distance between two points
function distance(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- read user_input
function user_input()
	local pad = Controls.read()
	
	if not user.activated then

		local x, y = Controls.readTouch()

		-- first input only
		if x ~= nil then
			user.x = x
			user.y = y
			user.state = STATE.EXPANDING
			user.activated = true
		end
	end
	
	-- exit
	if Controls.check(pad, SCE_CTRL_SELECT) then
		clean_exit()
	end
end

-- main function
function main()
	
	-- initiate game variables
	game_start()
	
	local timestep = 1000/60 -- 60 fps target
	local delta = 0
	local start = Timer.new()
	local last_frame = 0
	local fps_second = 0
	local fps_update = 0
	
	-- loop
	while true do
		now = Timer.getTime(start)
		
		-- determ fps as exponential moving avg fps
		if now > fps_update + 1000 then
			game.fps = math.floor(0.25 * fps_second + (1-0.25) * game.fps) -- calculate fps
			fps_update = now
			fps_second = 0
		end
		
		-- throttle frame rate
		--if now > last_frame + timestep then
			
		delta = delta + (now - last_frame)
		last_frame = now			
		
		-- update game procs
		local update_step = 0
		while delta >= timestep do
			user_input()
			
			-- do update(delta)
			-- movement : pos = velocity * delta
			update(delta/1000)
			delta = delta - timestep
			
			-- escape spiral of death, should not occur
			update_step = update_step + 1
			if update_step > 250 then
				-- cannot update fast enough
				-- perhaps store this as an error
				delta = 0
				break
			end
		end
		
		-- draw game
		draw()
		fps_second = fps_second + 1
			
		--end
	end
	
end

-- close all resources
-- while not strictly necessary, its clean
function clean_exit()

	-- free images
	-- Graphics.freeImage(control)
	
	-- close music files
	-- Sound.close(snd_background)
	
	-- kill app
	System.exit()
	
end

-- run the code
main()