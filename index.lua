-- chain for vita, by svennd
-- version 0.1

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- application variables
VERSION = "0.1"

-- game constants
FIELD = {WIDTH = 700, HEIGHT = 400}
SFX = {RED_TO_YELLOW = 1, YELLOW_TO_RED = 2, GREEN_TO_BLUE = 3, BLUE_TO_GREEN = 4, PURPLE_TO_ORANGE = 5, ORANGE_TO_PURPLE = 6}
MENU = {MENU = 0, START = 1, HELP = 2, EXIT = 3, MIN = 1, MAX = 3}
LEVEL = {START = 1, VERIFY = 2, REQUIREMENT = {}, ATOMS = {}, ENTROPY = {}}

-- loads
img_sfx = Graphics.loadImage("app0:/assets/sfx.png")
img_background = Graphics.loadImage("app0:/assets/bg.png")
img_button_1 = Graphics.loadImage("app0:/assets/button_1.png")
img_button_2 = Graphics.loadImage("app0:/assets/button_2.png")
img_button_3 = Graphics.loadImage("app0:/assets/button_3.png")
img_button_4 = Graphics.loadImage("app0:/assets/button_4.png")
main_font = Font.load("app0:/assets/xolonium.ttf")

-- color definitions
white 	= Color.new(255, 255, 255)
black 	= Color.new(0, 0, 0)

yellow 	= Color.new(255, 255, 0)
red 	= Color.new(255, 0, 0)
green 	= Color.new(0, 255, 0)
blue 	= Color.new(0, 0, 255)

orange	= Color.new(255, 128, 0)
seablue	= Color.new(0, 255, 255)
purple	= Color.new(255, 0, 255)

-- vars
atoms = {} 

-- statics
atom_count = {total = 0, init = 0, expanding = 0, explode = 0, merged = 0}

-- atom states
STATE = {INIT = 1, EXPANDING = 2, EXPLODE = 3, MERGED = 4}
ATOM = {
			{NAME = "HYDROGEN", SIZE = 7, COLOR = yellow, EXPAND = 4, FX = SFX.RED_TO_YELLOW, SCORE = 10}, 
			{NAME = "HELIUM", SIZE = 7, COLOR = red, EXPAND = 3, FX = SFX.YELLOW_TO_RED, SCORE = 15},  
			{NAME = "LITHIUM", SIZE = 7, COLOR = green, EXPAND = 1.7, FX = SFX.BLUE_TO_GREEN, SCORE = 25}, 
			{NAME = "BERYLLIUM", SIZE = 7, COLOR = blue, EXPAND = 1.5, FX = SFX.GREEN_TO_BLUE, SCORE = 35},  
			{NAME = "BORON", SIZE = 7, COLOR = purple, EXPAND = 1.15, FX = SFX.ORANGE_TO_PURPLE, SCORE = 50},  
			{NAME = "CARBON", SIZE = 7, COLOR = orange, EXPAND = 1.07, FX = SFX.PURPLE_TO_ORANGE, SCORE = 70}
		}
game = {state = 0, fps = 60, start = Timer.new(), last_tick = 0, step = 10, level = 1, loser = false, succes = false}
user = {x = 0, y = 0, size = 10, state = STATE.INIT, expand = 1, tick = 0, activated = false, implode = 0}
MAX_EXPAND = 3
animation = { implode_start = 100, user_implode = 500 }
score = 0

-- wrapper to populate level global
function add_level(lvl_req, lvl_atom, lvl_entropy)
	table.insert(LEVEL.REQUIREMENT, lvl_req)
	table.insert(LEVEL.ATOMS, lvl_atom)
	table.insert(LEVEL.ENTROPY, lvl_entropy)
end

-- level state
function level(n, step)
	if step == LEVEL.START then
		populate_atoms(LEVEL.ATOMS[n], LEVEL.ENTROPY[n])
	elseif step == LEVEL.VERIFY then
		return target_get(LEVEL.REQUIREMENT[n])
	end
end

-- can be more complex
function target_get(n)
	if (atom_count.merged + atom_count.explode) >= n then
		return true
	else
		return false
	end
end

function populate_atoms(n, max_atom)	
	-- seed for selected_atom
	math.randomseed(os.clock()*1000)	
	
	-- prune pre-seed
	math.random(); math.random(); math.random();
	
	-- for n atoms
	local atom_id = 0
	while atom_id < (n+1) do
	
		local selected_atom = math.random(1, max_atom) -- should be #ATOM
		
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
							score = ATOM[selected_atom].SCORE,
							animated = 0,
							fx = ATOM[selected_atom].FX
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
	Graphics.fillRect(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, black)
	Graphics.drawImage(0,0, img_background)
			
	-- draw field
	draw_field()
	
	-- ui
	draw_interface()
	
	-- draw user activation
	draw_user()
	
	-- draw atoms
	draw_atoms()
	
	-- draw animation before leaving view for ever
	draw_animation()
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

function draw_interface()
	-- score
	Font.setPixelSizes(main_font, 20)
	if game.succes then
		Font.print(main_font, 806, 511, score, green)
	else
		Font.print(main_font, 806, 511, score, white)
	end
	
	-- level
	if game.succes then
		Font.print(main_font, 50, 511, game.level, green)
	else
		Font.print(main_font, 50, 511, game.level, white)
	end
	
	-- atom count
	if game.succes then
		Font.print(main_font, 300, 511,  .. "/" .. (atom_count.merged+atom_count.explode) .. "/" .. atom_count.total .. " (" .. LEVEL.REQUIREMENT[game.level] .. ")", green)
	else
		Font.print(main_font, 300, 511,  .. "/" .. (atom_count.merged+atom_count.explode) .. "/" .. atom_count.total .. " (" .. LEVEL.REQUIREMENT[game.level] .. ")", white)
	end
end

-- draw loser
function draw_loser()
	
	-- poor kid
	if game.loser then
		Graphics.fillRect(300, 600, 110, 600, red)	
	end
end

-- draw user
function draw_user()
	if user.activated and user.state ~= STATE.MERGED then
		Graphics.fillCircle(user.x, user.y, user.size*user.expand, white)
	end
end

-- draw atoms
function draw_animation()
	local i = 0
	local count_atoms = #atoms
	while i < count_atoms do
		if atoms[i].expand <= 1 and (atoms[i].state == STATE.EXPLODE or atoms[i].state == STATE.MERGED) then
			if atoms[i].animated < 25 then
				-- 1.5 second ~ 90
				sfx_ending(atoms[i].x, atoms[i].y, atoms[i].fx, math.ceil(atoms[i].animated/5))
				atoms[i].animated = atoms[i].animated + 1
			end
		end 
		i = i + 1
	end
end

-- remove from view with a spark
function draw_atoms()
	local i = 0
	local count_atoms = #atoms
	while i < count_atoms do
		if atoms[i].state ~= STATE.MERGED
		then
			-- apply a channel to color if expanding or imploding
			if atoms[i].expand > 1 or atoms[i].state == STATE.EXPLODE then
				Graphics.fillCircle(atoms[i].x, atoms[i].y, atoms[i].neutrons * atoms[i].expand, Color.new(Color.getR(atoms[i].color), Color.getG(atoms[i].color),Color.getB(atoms[i].color), 150))
			else
				Graphics.fillCircle(atoms[i].x, atoms[i].y, atoms[i].neutrons * atoms[i].expand, atoms[i].color)
			end
		end 
		i = i + 1
	end
end

-- ui + field
function draw_field()
	-- the backfield
	draw_box(10, FIELD.WIDTH, 10, FIELD.HEIGHT, 10, black)
	
	-- level
	Graphics.drawImage(6, 498, img_button_1)
	
	-- merged / free floaters
	Graphics.drawImage(250, 498, img_button_2)
	
	-- target 
	Graphics.drawImage(500, 498, img_button_3)
	
	-- score 
	Graphics.drawImage(750, 498, img_button_4)
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
	
	-- level validation
	keep_score()
	check_level_finished()
end

function keep_score()
	local i = 0
	local count_atoms = #atoms
	local init = 0
	local expanding = 0 
	local explode = 0
	local merged = 0
	
	
	while i < count_atoms do
		if atoms[i].state == STATE.INIT then
			init = init + 1
		elseif atoms[i].state == STATE.EXPANDING then
			expanding = expanding + 1
		elseif atoms[i].state == STATE.EXPLODE then
			explode = explode + 1
		elseif atoms[i].state == STATE.MERGED then
			merged = merged + 1
		end
		i = i + 1
	end
	
	-- dont know why this would change but anyway
	atom_count.total = count_atoms
	
	-- seems globals are slow
	atom_count.init = init
	atom_count.expanding = expanding
	atom_count.explode = explode
	atom_count.merged = merged
	
end

function check_level_finished()
	
	-- user not yet shot then we cant be finished yet
	if not user.activated then
		return false
	end
	
	-- if succesfull finished level up!
	if level(game.level, LEVEL.VERIFY) then
		-- oke next level nothing going on anymore
		if user.state == STATE.MERGED and atom_count.expanding == 0 and atom_count.explode == 0 then
			atoms = {}
			game.level = game.level + 1 
			level(game.level, LEVEL.START)
			user.activated = false
			game.succes = false
		else
			-- succes 
			game.succes = true
		end
	else
		-- in case of failed
			-- user has been shot
			-- no expanding no exploding (merged or init left)
		if user.state == STATE.MERGED and atom_count.expanding == 0 and atom_count.explode == 0 then
			atoms = {}
			game.loser = true
		end
		
		-- in any other case it is still going
	end
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
	level(game.level, LEVEL.START)
	
	game.last_tick = 0 -- drop ticks
	Timer.reset(game.start) -- restart game timer
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
	end
end

-- determ distance between two points
function distance(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- read user_input
function user_input()
	if not user.activated then

		local x, y = Controls.readTouch()

		-- FIELD = {WIDTH = 700, HEIGHT = 400}

		-- first input only
		if x ~= nil then
		
			-- within field
			if x < FIELD.WIDTH and y < FIELD.HEIGHT then
				user.x = x
				user.y = y
				user.state = STATE.EXPANDING
				user.activated = true
			end
		end
	end
	
	-- exit
	-- if Controls.check(pad, SCE_CTRL_SELECT) then
		-- clean_exit()
	-- end
end

function load_levels()
	-- level 1-5
	add_level(1, 5, 3) -- 20%
	add_level(2, 10, 3) -- 20%
	add_level(4, 15, 3) -- 26%
	add_level(4, 15, 4) -- 26% -- complexity
	add_level(6, 20, 3) -- 30%
	
	-- level 6-10
	add_level(7, 20, 4) -- 35%
	add_level(7, 25, 5) -- 28%-- complexity
	add_level(10, 25, 4) -- 40%
	add_level(10, 25, 5) -- 40%
	add_level(15, 30, 4) -- 50%
	
	-- level 11-15
	add_level(20, 35, 4) -- 57%
	add_level(26, 40, 4) -- 65%
	add_level(26, 40, 5) -- 65%
	add_level(30, 45, 6) -- 66%
	add_level(38, 50, 5) -- 76%
	
	-- level 16-
	add_level(38, 50, 6) -- 76%
	add_level(43, 53, 6) -- 81%
	add_level(48, 55, 6) -- 87%
end

-- main function
function main()
	-- during loading screen
	load_levels()
	
	-- try to get out, I dare you.
	while true do
		if game.state == MENU.MENU then
			-- loading screen
			-- menu
			-- adapts game.state
			dofile("app0:/menu.lua")
			
		elseif game.state == MENU.START then
			-- game start
			game_start()
		
		elseif game.state == MENU.HELP then
			-- help returns to game.state = 0
			dofile("app0:/help.lua")
			
		elseif game.state == MENU.EXIT then
			-- exit
			clean_exit()
		end	
	end
	
	-- end of execution
	-- fuck restarting the goddamn app.
	clean_exit()
end

-- animate the ending
function sfx_ending(x, y, transition, state)
	-- size of effect
	local size_x = 70
	local size_y = 70
	local transition_choise = 0
	local move_x = size_x / 2 -- circle are from center
	local move_y = size_y / 2 -- this is a square
	local state = state - 1
	
	-- determ y position
	if transition == SFX.RED_TO_YELLOW or transition == SFX.YELLOW_TO_RED then transition_choise = 0
	elseif transition == SFX.GREEN_TO_BLUE or transition == SFX.BLUE_TO_GREEN then transition_choise = 1
	elseif transition == SFX.PURPLE_TO_ORANGE or transition == SFX.ORANGE_TO_PURPLE then transition_choise = 2
	end
	
	-- left to right animations
	if transition == SFX.RED_TO_YELLOW or transition == SFX.GREEN_TO_BLUE or transition == SFX.PURPLE_TO_ORANGE then
		-- draw the right sprite and expand
		Graphics.drawImageExtended(
								x, -- draw position
								y, 
								img_sfx, -- images
								(state*size_x),  -- image start
								(transition_choise*size_y), 
								size_x,  -- dimensions
								size_y, 
								0, 		-- rotation
								1.3+(state*4/10),  -- scale, increase every step (explode)
								1.3+(state*4/10), 
								Color.new(255,255,255,150-(state*10)) -- increase alpha
								)
		
	-- right to left animations
	elseif transition == SFX.YELLOW_TO_RED or transition == SFX.BLUE_TO_GREEN or transition == SFX.ORANGE_TO_PURPLE then

		-- keep original state for expansion
		local original_state = state
		
		-- rotate order for color
		state = math.abs(state - 6)
		
		Graphics.drawImageExtended(
								x, -- draw position
								y, 
								img_sfx, -- images
								(state*size_x),  -- image start
								(transition_choise*size_y), 
								size_x,  -- dimensions
								size_y, 
								0, 		-- rotation
								1.3+(original_state*4/10),  -- scale, increase every step (explode)
								1.3+(original_state*4/10), 
								Color.new(255,255,255,150-(original_state*10)) -- increase alpha
								)
	end
	
end

-- close all resources
-- while not strictly necessary, its clean
function clean_exit()

	-- free images
	Graphics.freeImage(img_sfx)
	Graphics.freeImage(img_background)
	Graphics.freeImage(img_button_1)
	Graphics.freeImage(img_button_2)
	Graphics.freeImage(img_button_3)
	Graphics.freeImage(img_button_4)
	
	-- close music files
	-- Sound.close(snd_background)
	
	-- kill app
	System.exit()
	
end

-- debug_file = System.openFile("ux0:/data/chain_debug", FWRITE)
function debug_log(msg)
	System.writeFile(debug_file, msg, string.len(msg))
end

-- run the code
main()