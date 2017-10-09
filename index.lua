-- tetrinomi for vita, by svennd
-- version 0.6.1

-- vita constants
DISPLAY_WIDTH = 960
DISPLAY_HEIGHT = 544

-- application variables
VERSION = "0.6.1"

-- screen bg
-- background = Graphics.loadImage("app0:/assets/background.png")

-- font
-- main_font = Font.load("app0:/assets/xolonium.ttf")

-- sound
-- this seems to be required outside to load the pieces
-- Sound.init()

-- load sound
-- snd_background = Sound.open("app0:/assets/bg.ogg")

-- game constants
BUTTON = { CROSS = 1, CIRCLE = 2, TRIANGLE = 3, SQUARE = 4, LTRIGGER = 5, RTRIGGER = 6, LEFT = 7, RIGHT = 8, UP = 9, DOWN = 10, ANALOG = 11, START = 12, SELECT = 13 }

-- color definitions
local white 	= Color.new(255, 255, 255)
local black 	= Color.new(0, 0, 0)

local yellow 	= Color.new(255, 255, 0)
local red 		= Color.new(255, 0, 0)
local green 	= Color.new(0, 255, 0)
local blue 		= Color.new(0, 0, 255)

local pink 		= Color.new(255, 204, 204)
local orange	= Color.new(255, 128, 0)
local seablue	= Color.new(0, 255, 255)
local purple	= Color.new(255, 0, 255)

local grey_1	= Color.new(244, 244, 244)
local grey_2	= Color.new(160, 160, 160)
local grey_3	= Color.new(96, 96, 96)

-- vars
atoms = {} 
ATOM = {HYDROGEN = 1, HELIUM = 2, LITHIUM = 3, BERYLLIUM = 4, BORON = 5, CARBON = 6, NITROGEN = 7, OXIGEN = 8, FLUOR = 9, NEON = 10}
FIELD = {WIDTH = 250, HEIGHT = 250}

function populate_atoms(n)
	-- seed random
	math.randomseed(os.time())	
	
	-- for n atoms
	local atom_id = 1
	for local i = 0, n do
		atom = math.random(ATOM.HYDROGEN, ATOM.LITHIUM)
		atoms[atom_id] = {neutrons = atom, color = red, x = math.random(0, FIELD.WIDTH), y = math.random(0, FIELD.HEIGHT)}
		atom_id = atom_id + 1 
	end
end

function draw()
	-- draw atoms
	-- draw field
end

function update()
	-- do user_input
end

function game_start()
	populate_atoms(10)
end

-- main function
function main()

	-- start sound
	-- Sound.play(snd_background, LOOP)
		
	-- initiate game variables
	game_start()
	
	-- gameloop
	while true do
	
		-- update game procs
		update()
		
		-- draw game
		draw_frame()
		
		-- wait for black start
		Screen.waitVblankStart()
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