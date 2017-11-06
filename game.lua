-- chain for vita, by svennd

-- game constants
-- local FIELD = {WIDTH = 700, HEIGHT = 400}
-- local SFX = {RED_TO_YELLOW = 1, YELLOW_TO_RED = 2, GREEN_TO_BLUE = 3, BLUE_TO_GREEN = 4, PURPLE_TO_ORANGE = 5, ORANGE_TO_PURPLE = 6}
local MENU = {MENU = 0, START = 1, HELP = 2, EXIT = 3, MIN = 1, MAX = 3}
local LEVEL = {START = 1, VERIFY = 2, REQUIREMENT = {}, ATOMS = {}, ENTROPY = {}, TEXT = {}}

-- loads
-- img_sfx = Graphics.loadImage("app0:/assets/sfx.png")
local img_background = Graphics.loadImage("app0:/assets/bg.png")
local img_button_1 = Graphics.loadImage("app0:/assets/button_1.png")
local img_button_2 = Graphics.loadImage("app0:/assets/button_2.png")
local img_button_3 = Graphics.loadImage("app0:/assets/button_3.png")
local img_button_4 = Graphics.loadImage("app0:/assets/button_4.png")

-- font
local fnt_main = Font.load("app0:/assets/xolonium.ttf")

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

-- vars
local atoms = {} 

-- game vars
local field_width = 700
local field_height = 400

-- statics
-- local atom_count = {total = 0, init = 0, expanding = 0, explode = 0, merged = 0}
local cnt_atom_total = 0
local cnt_atom_init = 0
local cnt_atom_expand = 0
local cnt_atom_explode = 0
local cnt_atom_merged = 0

-- atom states
-- STATE = {INIT = 1, EXPANDING = 2, EXPLODE = 3, MERGED = 4}
local STATE_INIT = 1
local STATE_EXPAND = 2
local STATE_EXPLODE = 2
local STATE_MERGED = 4

-- ATOM definition
local ATOM = {
			{COLOR = yellow, EXPAND = 5, FX = SFX.RED_TO_YELLOW, SCORE = 10}, 
			{COLOR = red, EXPAND = 4, FX = SFX.YELLOW_TO_RED, SCORE = 15},  
			{COLOR = green, EXPAND = 3.7, FX = SFX.BLUE_TO_GREEN, SCORE = 25}, 
			{COLOR = blue, EXPAND = 3, FX = SFX.GREEN_TO_BLUE, SCORE = 35},  
			{COLOR = purple, EXPAND = 2.7, FX = SFX.ORANGE_TO_PURPLE, SCORE = 50},  
			{COLOR = orange, EXPAND = 2.1, FX = SFX.PURPLE_TO_ORANGE, SCORE = 70}
		}
		
-- game = {play = Timer.new(), last_input = 0, state = 0, fps = 60, step = 10, level = 1, level_box = false, loser = false, succes = false, delay_win = 0, finish = false}
local game_time = Timer.new()
local game_lst_input = 0
local game_state = MENU.START
local game_level = 1
local game_level_box = false
local game_loser = false
local game_succes = false
local game_delay_win = 0
local game_finish = false
local game_break_loop = false
local game_score = 0

-- user 
local user = {x = 0, y = 0, size = 10, state = STATE_INIT, expand = 1, activated = false, implode = 0}
local user_max_expand = 3

-- animate
-- local animation = { implode_start = 100, user_implode = 100 }
local anm_user_implode_delay = 100
local anm_implode_delay = 100

-- atom const
local atom_size = 7

-- temp
store_writes = ""


-- level state
function level(n, step)

	-- can be more complex
	local function target_get(n)
		if (atom_count.merged + atom_count.explode) >= n then
			return true
		else
			return false
		end
	end
	
	if step == LEVEL.VERIFY then
		return target_get(LEVEL.REQUIREMENT[n])
	elseif step == LEVEL.START then
		-- check to see if we still have levels
		if LEVEL.ATOMS[n] == nil then
			-- do subroutine end_game
			game_over()
		else
			-- next level
			game_level_box = true
			populate_atoms(LEVEL.ATOMS[n], LEVEL.ENTROPY[n])
		end
	end
end

function populate_atoms(n, max_atom)	

	-- we need a 1 or a -1
	local function random_direction()

		local result = math.random(0,1)
		if result == 0 then
			result = -1
		end
		return result
	end
	
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
							x = math.random(30, field_width-30), 
							y = math.random(30, field_height-30),
							dx = field_width / math.random(5, 15) * random_direction(),
							dy = field_height / math.random(5, 15) * random_direction(),
							state = STATE_INIT,
							expand = 1,
							implode = 0,
							animated = 0
							}
		atom_id = atom_id + 1 
	end
end

handle = System.openFile("ux0:/data/file.txt", FCREATE)
function dmsg(msg)
	if string.len(store_writes) < 100 then
		store_writes = store_writes .. msg
	else
		System.writeFile(handle, store_writes .. msg, string.len(store_writes .. msg))
		store_writes = ""
	end
end

function draw()

	-- Starting drawing phase
	Graphics.initBlend()
	
	-- background
	--Graphics.fillRect(0, DISPLAY_WIDTH, 0, DISPLAY_HEIGHT, black)
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
	--draw_animation()
	
	-- if lost or at beginning
	draw_info()
	
	-- Terminating drawing phase
	Graphics.termBlend()
	Screen.flip()
end

function draw_interface()
	-- score
	Font.setPixelSizes(fnt_main, 22)
	if game_succes then
		Font.print(fnt_main, 806, 511, score, green)
	else
		Font.print(fnt_main, 806, 511, score, white)
	end
	
	-- level
	if game_succes then
		Font.print(fnt_main, 50, 511, "LEVEL" .. game_level, green)
	else
		Font.print(fnt_main, 50, 511, "LEVEL" .. game_level, white)
	end
	
	-- atom count
	if game_succes then
		Font.print(fnt_main, 300, 511, (atom_count.merged+atom_count.explode) .. "/" .. atom_count.total .. " (" .. LEVEL.REQUIREMENT[game_level] .. ")", green)
	else
		Font.print(fnt_main, 300, 511, (atom_count.merged+atom_count.explode) .. "/" .. atom_count.total .. " (" .. LEVEL.REQUIREMENT[game_level] .. ")", white)
	end
end

-- draw infoscreen
function draw_info()
	-- poor kid
	if game_loser then	
		-- red background
		Graphics.fillRect(289, 620, 100, 400, Color.new(255, 0, 0, 200))
		
		-- GAME OVER
		Font.setPixelSizes(fnt_main, 36)
		Font.print(fnt_main, 335, 110, "GAME OVER", black)
		
		-- divider
		Graphics.fillRect(310, 600, 160, 165, black)
		
		-- RETRY LEVEL
		-- background
		Graphics.fillRect(310, 600, 190, 260, black)
		Font.setPixelSizes(fnt_main, 26)
		Font.print(fnt_main, 340, 205, "RETRY LEVEL", white)
		
		-- TO MENNU
		-- background
		Graphics.fillRect(310, 600, 300, 370, black)
		Font.setPixelSizes(fnt_main, 26)
		Font.print(fnt_main, 390, 320, "GIVE UP", white)
	end
	
	-- game finished
	if game_finish then
		-- draw level box (green)
		Graphics.fillRect(289, 620, 100, 400, Color.new(0, 255, 0, 200))
		
		-- 
		Font.setPixelSizes(fnt_main, 36)
		Font.print(fnt_main, 335, 110, "GAME OVER", black)
		
		-- divider
		Graphics.fillRect(310, 600, 160, 165, black)
		
		-- level text
		Font.setPixelSizes(fnt_main, 26)
		Font.print(fnt_main, 320, 190, "You won !\nWe now start over.", white)
		
		-- ok button
		Graphics.fillRect(310, 600, 300, 370, black)
		Font.setPixelSizes(fnt_main, 26)
		Font.print(fnt_main, 430, 320, "OK", white)
		
	end
	
	if game_level_box then
		-- draw level box (green)
		Graphics.fillRect(289, 620, 100, 400, Color.new(0, 255, 0, 200))
		
		-- 
		Font.setPixelSizes(fnt_main, 36)
		Font.print(fnt_main, 335, 110, "LEVEL " .. game_level, black)
		
		-- divider
		Graphics.fillRect(310, 600, 160, 165, black)
		
		-- level text
		Font.setPixelSizes(fnt_main, 26)
		Font.print(fnt_main, 320, 190, LEVEL.TEXT[game_level], white)
		
		-- ok button
		Graphics.fillRect(310, 600, 300, 370, black)
		Font.setPixelSizes(fnt_main, 26)
		Font.print(fnt_main, 430, 320, "OK", white)
		
	end
end

-- draw user
function draw_user()
	if user.activated and user.state ~= STATE_MERGED then
		Graphics.fillCircle(user.x, user.y, user.size*user.expand, white)
	end
end

-- draw atoms
function draw_animation()
	local i = 0
	local count_atoms = #atoms
	while i < count_atoms do
		if atoms[i].expand <= 1 and (atoms[i].state == STATE_EXPLODE or atoms[i].state == STATE_MERGED) then
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
		if atoms[i].state ~= STATE_MERGED
		then
			-- apply a channel to color if expanding or imploding
			if atoms[i].expand > 1 or atoms[i].state == STATE_EXPLODE then
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
	if game_succes then
		Graphics.fillRect(10, field_width, 10, field_height, Color.new(0, 150, 0, 10))
	else
		Graphics.fillRect(10, field_width, 10, field_height, Color.new(0, 0, 0, 10))
	end
	
	-- the borders
	draw_box(10, field_width, 10, field_height, 10, black)
	
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

	-- set some iterable functions
	local gettime = Timer.getTime
	
	-- determ distance between two points
	local function distanceSquared(x1,y1,x2,y2)
		return ((x2-x1)^2 + (y2-y1)^2)
	end
	
	-- stuff
	local t = gettime(game_time)
	local ts = 0
	local tst = 0
	local move = 0
	local movei = 0
	local sexpand = 0
	local sexpandi = 0
	local simplode = 0
	local simplodei = 0
	local i = 0
	local cnt_init = 0
	local cnt_expand = 0 
	local cnt_explode = 0
	local cnt_merged = 0
	local count_atoms = #atoms
	
	while i < count_atoms do
		local c_atom = atoms[i]
		local c_atom_size = atom_size
		local c_atom_expand = ATOM[c_atom.id].EXPAND
		local c_atom_score = ATOM[c_atom.id].SCORE
		
		if c_atom.state == STATE_INIT then
			
			ts = gettime(game_time)
			
			-- move atom
			c_atom.x, c_atom.y, c_atom.dx, c_atom.dy = move(c_atom.x, c_atom.y, c_atom.dx, c_atom.dy, atom_size, delta)
			
			-- check collision with user
			if user.activated and user.state ~= STATE_MERGED then
				if distanceSquared(user.x, user.y, c_atom.x, c_atom.y) <= (user.size*(user.expand) + atom_size)^2 then
					-- expand and stop motion
					c_atom.state = STATE_EXPAND
					c_atom.dx = 0
					c_atom.dy = 0
				end
			end
			
			-- keep_score
			cnt_init = cnt_init + 1
			
			-- debug
			move = move + (gettime(game_time) - ts)
			-- movei = movei + 1
			
		elseif c_atom.state == STATE_EXPAND then
		
			ts = gettime(game_time)
			
			-- expand untill explode size
			if c_atom.expand < c_atom_expand then
				c_atom.expand = c_atom.expand + (delta*3)
			else
				c_atom.state = STATE_EXPLODE
			end
			
			-- keep_score
			cnt_expand = cnt_expand + 1
			
			-- debug
			sexpand = sexpand + (gettime(game_time) - ts)
			-- sexpandi = sexpandi + 1
			
		elseif c_atom.state == STATE_EXPLODE then
		
			ts = gettime(game_time)
			
			-- implode after an initial stable state
			if c_atom.implode > animation.anm_implode_delay then
				if c_atom.expand > 1 then
					c_atom.expand = c_atom.expand - (delta*5)
				else
					--remove from field
					c_atom.state = STATE_MERGED
					score = score + c_atom_score
				end
			else
				atoms[i].implode = atoms[i].implode + 1
			end
			
			cnt_explode = cnt_explode + 1
			
			simplode = simplode + (gettime(game_time) - ts)
			
		-- state MERGED
		else
			cnt_merged = cnt_merged + 1
		end

		-- check collisions general
		if c_atom.state == STATE_EXPAND or c_atom.state == STATE_EXPLODE then
			
			ts = gettime(game_time)
			
			-- static distance
			local static_size = (atom_size*c_atom.expand + atom_size) ^ 2
			
			-- collision detect all others
			local o = 0
			while o < count_atoms do
				-- only collide with floaters
				if atoms[o].state == STATE_INIT then
					if distanceSquared(c_atom.x, c_atom.y, atoms[o].x, atoms[o].y) <= static_size then
						-- expand and stop motion
						atoms[o].state = STATE_EXPAND
						atoms[o].dx = 0
						atoms[o].dy = 0		
					end
				end
				o = o + 1
			end
			
			
			col = col + (gettime(game_time) - ts)
			
			-- dmsg("col:" .. (d1-d) .."|")
		end
		i = i + 1
	end
			
	-- set globals
	-- dont know why this would change but anyway
	cnt_atom_total = count_atoms
	
	-- seems globals are slow
	cnt_atom_init = init
	cnt_atom_expanding = expanding
	cnt_atom_explode = explode
	cnt_atom_merged = merged
	
	-- write debug
	dmsg("m:" .. (move) .."*e" .. (sexpand) .."*i" .. (simplode) .. "|")
	dmsg("up:" .. (gettime(game_time) - t) .."|")
	
	-- expand collisions
	expand_user(delta)
	
	-- remove items
	implode_user(delta)	
	
	-- level validation
	check_level_finished()
end

function check_level_finished()
	
	-- user not yet shot then we cant be finished yet
	-- or user is already lost
	if not user.activated or game_loser then
		return false
	end
	
	-- if succesfull finished level up!
	if level(game_level, LEVEL.VERIFY) then
		-- oke next level nothing going on anymore
		-- delay win for slowing down game after last animation
		if user.state == STATE_MERGED and atom_count.expanding == 0 and atom_count.explode == 0 and game_delay_win > 100 then
			reset_game(game_level + 1)
			level(game_level, LEVEL.START)
		else
			-- succes 
			game_succes = true
			game_delay_win = game_delay_win + 1
		end
	else
		-- in case of failed
			-- user has been shot
			-- no expanding no exploding (merged or init left)
		if user.state == STATE_MERGED and atom_count.expanding == 0 and atom_count.explode == 0 then
			game_loser = true
		end
		
		-- in any other case it is still going
	end
end

-- expand user
-- need to take dt in this increase
function expand_user(delta)
	if user.state == STATE_INIT or user.state == STATE_EXPAND then
		if user.activated then
			-- expand when needed
			if user.expand < user_max_expand then
				user.expand = user.expand + (delta*5)
			else
				user.state = STATE_EXPLODE
			end
		end
	end
end

-- implode atoms if needed
function implode_user(delta)	
	if user.state == STATE_EXPLODE then
		-- give ticks
		if user.implode > animation.user_implode then
			if user.expand > 1 then
				user.expand = user.expand - (delta*5)
			else
				--remove from field
				user.state = STATE_MERGED
			end
		else
			user.implode = user.implode + 1
		end
	end
end


-- move atom
function move(x, y, dx, dy, size, delta)
	
	-- new location
	local new_x = x + dx*delta
	local new_y = y + dy*delta
	
	-- left or right boundry
	if new_x-size < 20 or new_x+size > field_width then
		dx = -dx
		
		-- we need to calculate the bounce size instead
		-- this is temp
		if new_x+size > field_width then
			new_x = field_width
		else
			-- its going under
			new_x = 20
		end
	end
	
	-- up or down boundry
	if new_y-size < 20 or new_y+size > field_height then
		dy = -dy
		
		-- this is temp
		if new_y+size > field_height then
			new_y = field_height
		else
			-- its going under
			new_y = 20
		end
	end
	
	-- return result
	return new_x, new_y, dx, dy
end

function game_start()
	

end

-- reset game
function reset_game(level)
	atoms = {}
	atom_count = {total = 0, init = 0, expanding = 0, explode = 0, merged = 0}
	user = {x = 0, y = 0, size = 10, state = STATE_INIT, expand = 1, activated = false, implode = 0}
	game_level = level
	game_loser = false
	game_succes = false
	game_delay_win = 0 -- should be 0 
end


-- game finished
function game_over()
	game_finish = true
	game_level = 1
end

-- read user_input
function user_input()

	local x, y = Controls.readTouch()
	local now = Timer.getTime(game_time)
	local dt = now - game_lst_input
	
	-- first input only
	if dt > 100 and x ~= nil then
	
		-- ingame
		if not user.activated and not game_level_box then
			-- within field
			if x < field_width and y < field_height then
				user.x = x
				user.y = y
				user.state = STATE_EXPAND
				user.activated = true
			end
		end
		
		-- level box is active
		if game_level_box then
			if x > 310 and x < 600 then
				if y > 300 and y < 370 then
					game_level_box = false
					game_lst_input = now
				end
			end
		end
		
		--lost
		if game_loser then
			if x > 310 and  x < 600 then
				if y > 190 and y < 260 then
					-- retry level
					reset_game(game_level)
					level(game_level, LEVEL.START)
					game_lst_input = now
				elseif y > 300 and y < 370 then
					-- back to menu
					reset_game(1)
					game_break_loop = true
					game_state = MENU.MENU
				end
			end
		end
		
		if game_finish then
			if x > 310 and  x < 600 then
				if y > 300 and y < 370 then
					-- back to menu
					reset_game(game_level)
					level(game_level, LEVEL.START)
					game_finish = false
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
	add_level(1, 50, 3, "Get your first \nexplosion going !\nGET 1 out of 5") -- 20%
	add_level(1, 100, 3, "Get your first \nexplosion going !\nGET 1 out of 5") -- 20%
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


-- wrapper to populate level global
function add_level(lvl_req, lvl_atom, lvl_entropy, lvl_text)
	table.insert(LEVEL.REQUIREMENT, lvl_req)
	table.insert(LEVEL.ATOMS, lvl_atom)
	table.insert(LEVEL.ENTROPY, lvl_entropy)
	table.insert(LEVEL.TEXT, lvl_text)
end

-- main function
function main()
	-- during loading screen
	load_levels()
	
	-- try to get out, I dare you.
	local timestep = 1000/60 -- 60 fps target
	local delta = 0
	local start = Timer.new()
	local last_frame = 0

	-- set first level
	level(game_level, LEVEL.START)
	
	-- set some iterable functions
	local gettime = Timer.getTime
	
	-- loop
	while true do
		now = gettime(start)
		
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
				delta = 1
				break
			end
		end
		
		-- draw game
		draw()
		-- fps_second = fps_second + 1
		
		-- if we need to go to menu
		if game_break_loop then
			game_break_loop = false
			break
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
	
	-- font
	Font.unload(fnt_main)
	
	-- close music files
	-- Sound.close(snd_background)
	
	-- kill app
	-- System.exit()
	
end

-- run the code
main()

-- return to menu
state = MENU.MENU 