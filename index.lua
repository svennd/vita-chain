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
LEVEL = {START = 1, VERIFY = 2, REQUIREMENT = {}, ATOMS = {}, ENTROPY = {}, TEXT = {}}

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
			{NAME = "HYDROGEN", SIZE = 7, COLOR = yellow, EXPAND = 5, FX = SFX.RED_TO_YELLOW, SCORE = 10}, 
			{NAME = "HELIUM", SIZE = 7, COLOR = red, EXPAND = 4, FX = SFX.YELLOW_TO_RED, SCORE = 15},  
			{NAME = "LITHIUM", SIZE = 7, COLOR = green, EXPAND = 3.7, FX = SFX.BLUE_TO_GREEN, SCORE = 25}, 
			{NAME = "BERYLLIUM", SIZE = 7, COLOR = blue, EXPAND = 3, FX = SFX.GREEN_TO_BLUE, SCORE = 35},  
			{NAME = "BORON", SIZE = 7, COLOR = purple, EXPAND = 2.7, FX = SFX.ORANGE_TO_PURPLE, SCORE = 50},  
			{NAME = "CARBON", SIZE = 7, COLOR = orange, EXPAND = 2.1, FX = SFX.PURPLE_TO_ORANGE, SCORE = 70}
		}
game = {play = Timer.new(), last_input = 0, state = 0, fps = 60, step = 10, level = 1, level_box = false, loser = false, succes = false, delay_win = 0}
user = {x = 0, y = 0, size = 10, state = STATE.INIT, expand = 1, activated = false, implode = 0}
MAX_EXPAND = 3
animation = { implode_start = 100, user_implode = 100 }
score = 0
break_game_loop = false 
game_finish = false

-- wrapper to populate level global
function add_level(lvl_req, lvl_atom, lvl_entropy, lvl_text)
	table.insert(LEVEL.REQUIREMENT, lvl_req)
	table.insert(LEVEL.ATOMS, lvl_atom)
	table.insert(LEVEL.ENTROPY, lvl_entropy)
	table.insert(LEVEL.TEXT, lvl_text)
end

-- level state
function level(n, step)
	if step == LEVEL.START then
		-- check to see if we still have levels
		if LEVEL.ATOMS[n] == nil then
			-- do subroutine end_game
			game_finish = true
			game.level = 1
			populate_atoms(LEVEL.ATOMS[1], LEVEL.ENTROPY[1])
		else
			-- next level
			game.level_box = true
			populate_atoms(LEVEL.ATOMS[n], LEVEL.ENTROPY[n])
		end
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
							id = selected_atom, 
							neutrons = ATOM[selected_atom].SIZE, -- can be removed
							color = ATOM[selected_atom].COLOR,  -- can be removed
							x = math.random(30, FIELD.WIDTH-30), 
							y = math.random(30, FIELD.HEIGHT-30),
							dx = FIELD.WIDTH / math.random(5, 15) * random_direction(),
							dy = FIELD.HEIGHT / math.random(5, 15) * random_direction(),
							state = STATE.INIT,
							expand = 1,
							implode = 0,
							score = ATOM[selected_atom].SCORE, -- can be removed
							animated = 0,
							fx = ATOM[selected_atom].FX -- can be removed
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
	
	-- if lost or at beginning
	draw_info()
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

function draw_interface()
	-- score
	Font.setPixelSizes(main_font, 22)
	if game.succes then
		Font.print(main_font, 806, 511, score, green)
	else
		Font.print(main_font, 806, 511, score, white)
	end
	
	-- level
	if game.succes then
		Font.print(main_font, 50, 511, "LEVEL" .. game.level, green)
	else
		Font.print(main_font, 50, 511, "LEVEL" .. game.level, white)
	end
	
	-- atom count
	if game.succes then
		Font.print(main_font, 300, 511, (atom_count.merged+atom_count.explode) .. "/" .. atom_count.total .. " (" .. LEVEL.REQUIREMENT[game.level] .. ")", green)
	else
		Font.print(main_font, 300, 511, (atom_count.merged+atom_count.explode) .. "/" .. atom_count.total .. " (" .. LEVEL.REQUIREMENT[game.level] .. ")", white)
	end
end

-- draw infoscreen
function draw_info()
	-- poor kid
	if game.loser then	
		-- red background
		Graphics.fillRect(289, 620, 100, 400, Color.new(255, 0, 0, 200))
		
		-- GAME OVER
		Font.setPixelSizes(main_font, 36)
		Font.print(main_font, 335, 110, "GAME OVER", black)
		
		-- divider
		Graphics.fillRect(310, 600, 160, 165, black)
		
		-- RETRY LEVEL
		-- background
		Graphics.fillRect(310, 600, 190, 260, black)
		Font.setPixelSizes(main_font, 26)
		Font.print(main_font, 340, 205, "RETRY LEVEL", white)
		
		-- TO MENNU
		-- background
		Graphics.fillRect(310, 600, 300, 370, black)
		Font.setPixelSizes(main_font, 26)
		Font.print(main_font, 390, 320, "GIVE UP", white)
	end
	
	if game.level_box then
		-- draw level box (green)
		Graphics.fillRect(289, 620, 100, 400, Color.new(0, 255, 0, 200))
		
		-- 
		Font.setPixelSizes(main_font, 36)
		Font.print(main_font, 335, 110, "LEVEL " .. game.level, black)
		
		-- divider
		Graphics.fillRect(310, 600, 160, 165, black)
		
		-- level text
		Font.setPixelSizes(main_font, 26)
		Font.print(main_font, 320, 190, LEVEL.TEXT[game.level], white)
		
		-- ok button
		Graphics.fillRect(310, 600, 300, 370, black)
		Font.setPixelSizes(main_font, 26)
		Font.print(main_font, 430, 320, "OK", white)
		
	end
	
	-- game finished
	if game_finish then
		-- draw level box (green)
		Graphics.fillRect(289, 620, 100, 400, Color.new(0, 255, 0, 200))
		
		-- 
		Font.setPixelSizes(main_font, 36)
		Font.print(main_font, 335, 110, "LEVEL " .. game.level, black)
		
		-- divider
		Graphics.fillRect(310, 600, 160, 165, black)
		
		-- level text
		Font.setPixelSizes(main_font, 26)
		Font.print(main_font, 320, 190, LEVEL.TEXT[game.level], white)
		
		-- ok button
		Graphics.fillRect(310, 600, 300, 370, black)
		Font.setPixelSizes(main_font, 26)
		Font.print(main_font, 430, 320, "OK", white)
		
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
	
	-- bg
	if game.succes then
		Graphics.fillRect(10, FIELD.WIDTH, 10, FIELD.HEIGHT, Color.new(0, 150, 0, 50))
	else
		Graphics.fillRect(10, FIELD.WIDTH, 10, FIELD.HEIGHT, Color.new(0, 0, 0, 50))
	end
	
	-- the borders
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
	-- or user is already lost
	if not user.activated or game.loser then
		return false
	end
	
	-- if succesfull finished level up!
	if level(game.level, LEVEL.VERIFY) then
		-- oke next level nothing going on anymore
		-- delay win for slowing down game after last animation
		if user.state == STATE.MERGED and atom_count.expanding == 0 and atom_count.explode == 0 and game.delay_win > 100 then
			reset_game(game.level + 1)
			level(game.level, LEVEL.START)
		else
			-- succes 
			game.succes = true
			game.delay_win = game.delay_win + 1
		end
	else
		-- in case of failed
			-- user has been shot
			-- no expanding no exploding (merged or init left)
		if user.state == STATE.MERGED and atom_count.expanding == 0 and atom_count.explode == 0 then
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
		local c_atom = atoms[i]
		-- only for expanding
		if c_atom.state == STATE.EXPANDING then
			if c_atom.expand < ATOM[c_atom.id].EXPAND then
				c_atom.expand = c_atom.expand + (delta*3)
			else
				c_atom.state = STATE.EXPLODE
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
		local c_atom = atoms[i]
		-- only move when no reaction has happened
		if c_atom.state == STATE.INIT then
			-- current location
			local current_x = c_atom.x
			local current_y = c_atom.y
			local dir_x = c_atom.dx
			local dir_y = c_atom.dy
			local atom_size = ATOM[c_atom.id].SIZE
			
			-- determ new location
			local new_x = current_x + dir_x*delta --this should take into account the time passed
			local new_y = current_y + dir_y*delta --this should take into account the time passed
			
			-- check if the atom does not hit the boundry
			-- if it does switch direction
			-- 20 = field border + field offset
			if new_x-atom_size < 20 or new_x+atom_size > FIELD.WIDTH then
				dir_x = -dir_x
			end
			
			if new_y-atom_size < 20 or new_y+atom_size > FIELD.HEIGHT then
				dir_y = -dir_y
			end
			
			c_atom.x = new_x
			c_atom.y = new_y
			c_atom.dx = dir_x
			c_atom.dy = dir_y
		end
		i = i + 1
	end
end

function game_start()
	
	local timestep = 1000/60 -- 60 fps target
	local delta = 0
	local start = Timer.new()
	local last_frame = 0
	local fps_second = 0
	local fps_update = 0
	
	-- set first level
	level(game.level, LEVEL.START)
	
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
		
		-- if we need to go to menu
		if break_game_loop then
			break_game_loop = false
			break
		end
	end
end

-- determ distance between two points
function distance(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

-- reset game
function reset_game(level)
	atoms = {}
	atom_count = {total = 0, init = 0, expanding = 0, explode = 0, merged = 0}
	user = {x = 0, y = 0, size = 10, state = STATE.INIT, expand = 1, activated = false, implode = 0}
	game.level = level
	game.loser = false
	game.succes = false
	game.delay_win = 0 -- should be 0 
end

-- read user_input
function user_input()

	local x, y = Controls.readTouch()
	local now = Timer.getTime(game.play)
	local dt = now - game.last_input 
	
	-- first input only
	if dt > 100 and x ~= nil then
	
		-- ingame
		if not user.activated and not game.level_box then
			-- within field
			if x < FIELD.WIDTH and y < FIELD.HEIGHT then
				user.x = x
				user.y = y
				user.state = STATE.EXPANDING
				user.activated = true
			end
		end
		
		-- level box is active
		if game.level_box then
			if x > 310 and x < 600 then
				if y > 300 and y < 370 then
					game.level_box = false
					game.last_input = now
				end
			end
		end
		
		if game.loser then
			if x > 310 and  x < 600 then
				if y > 190 and y < 260 then
					-- retry level
					reset_game(game.level)
					level(game.level, LEVEL.START)
					game.last_input = now
				elseif y > 300 and y < 370 then
					-- back to menu
					reset_game(1)
					break_game_loop = true
					game.state = MENU.MENU
				end
			end
		end
	end
	
	-- emergency exit
	local pad = Controls.read()
	if Controls.check(pad, SCE_CTRL_SELECT) then
		clean_exit()
	end
end

function load_levels()
	-- level 1-5
	add_level(1, 5, 3, "Get you're first \nexplosion going !\nGET 1 out of 5") -- 20%
	add_level(2, 10, 3, "Too easy !\nGET 2 out of 10") -- 20%
	add_level(4, 15, 3, "Still here ? Now we \nget real !\nGET 4 out of 15") -- 26%
	add_level(4, 15, 4, "Watch out, blue ones\nare smaller then others!\nGET 4 out of 15") -- 26% -- complexity
	add_level(6, 20, 3, "Still not hard,\nlet's add more !\nGET 6 out of 20") -- 30%
	
	-- level 6-10
	add_level(7, 20, 4, "The blue ones\nare back.\nGET 7 out of 20") -- 35%
	add_level(7, 25, 5, "Purple ones !\nGET 7 out of 25") -- 28%-- complexity
	add_level(10, 25, 4, "Increase and repeat.\n10 out of 25") -- 40%
	add_level(10, 25, 5, "bad_pun.exe\nnot found.\nGET 10 out of 25") -- 40%
	add_level(15, 30, 4, "is this\nthe end?\nGET 15 out of 30") -- 50%
	
	-- level 11-15
	add_level(20, 35, 4, "gota catch\n'm all?\nGET20 out of 30") -- 57%
	add_level(26, 40, 4, "this is crazy\nGET26 out of 40") -- 65%
	add_level(26, 40, 5, "ready for the\nsecret msg?\nGET26 out of 40") -- 65%
	add_level(22, 40, 6, "the message is\nGET26out of 40") -- 65%
	add_level(35, 40, 6, "impossible is\njust an opinion\nGET 35 out of 40")
	
	-- after this perfomance is laggy
	-- add_level(30, 45, 6) -- 66%
	-- add_level(38, 50, 5) -- 76%
	
	-- level 16-
	-- add_level(38, 50, 6) -- 76%
	-- add_level(43, 53, 6) -- 81%
	-- add_level(48, 55, 6) -- 87%
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

-- run the code
main()