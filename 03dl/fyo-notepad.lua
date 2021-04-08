-- Imports
local samp = require 'SA-MP API.init'
local imgui = require 'imgui'

local encoding = require 'encoding'
local u8 = encoding.UTF8
encoding.default = 'cp1251'


-- Constants
local CONFIG_FILE_PATH = getWorkingDirectory() .. [[\fyo-notepad.json]]

local MAX_NOTES = 9
local MAX_NAME_LEN = 64
local MAX_TEXT_LEN = 40000

local DEFAULT_MAX_LINE_LENGTH = 40
local ENTERED_CHARACTER_TO_SPLIT = '/'

local DELAY_TO_CONFIG_SAVE = 60000


-- Variables
local config = {}
if not doesFileExist(CONFIG_FILE_PATH) then
	local defaultNotesConfig = {}
	for idx = 1, MAX_NOTES do
		defaultNotesConfig[idx] = {}

		defaultNotesConfig[idx]['name'] = 'Название заметки'

		defaultNotesConfig[idx]['text'] = 'Введите текст заметки'

		defaultNotesConfig[idx]['position'] = {}
		local width, height = getScreenResolution()
		defaultNotesConfig[idx]['position']['x'] = width / 2
		defaultNotesConfig[idx]['position']['y'] = height / 2
	end

	config = {
		['notes'] = defaultNotesConfig,
		['other'] = {
			['maxLineLength'] = DEFAULT_MAX_LINE_LENGTH
		}
	}
else
	local file = io.open(CONFIG_FILE_PATH, 'r')
	config = decodeJson(file:read('*a'))
	io.close(file)
end

local menuState = imgui.ImBool(false)

local maxLineLength = imgui.ImBuffer(tostring(config['other']['maxLineLength']), 32)

local noteStates, noteNames, noteTexts = {}, {}, {}
for idx = 1, MAX_NOTES do
	table.insert(noteStates, imgui.ImBool(false))
	noteNames[idx] = imgui.ImBuffer(u8(config['notes'][idx]['name']), MAX_NAME_LEN)
	noteTexts[idx] = imgui.ImBuffer(u8(config['notes'][idx]['text']), MAX_TEXT_LEN)
end

local isConfigSaved = false


-- Functions
function main()
	while not samp.GetIsAvailable() do
		wait(0)
	end

	applyCustomImguiStyle()

	samp._RegisterClientCommand('note', openScriptMenu)
	
	samp._RegisterClientCommand('note-1', function() noteStates[1].v = not noteStates[1].v end)
	samp._RegisterClientCommand('note-2', function() noteStates[2].v = not noteStates[2].v end)
	samp._RegisterClientCommand('note-3', function() noteStates[3].v = not noteStates[3].v end)
	samp._RegisterClientCommand('note-4', function() noteStates[4].v = not noteStates[4].v end)
	samp._RegisterClientCommand('note-5', function() noteStates[5].v = not noteStates[5].v end)
	samp._RegisterClientCommand('note-6', function() noteStates[6].v = not noteStates[6].v end)
	samp._RegisterClientCommand('note-7', function() noteStates[7].v = not noteStates[7].v end)
	samp._RegisterClientCommand('note-8', function() noteStates[8].v = not noteStates[8].v end)
	samp._RegisterClientCommand('note-9', function() noteStates[9].v = not noteStates[9].v end)

	while true do
		wait(0)

		local isNeedToProcess = false
		if menuState.v then
			isNeedToProcess = true
		end
		for idx = 1, MAX_NOTES do
			if noteStates[idx].v then
				isNeedToProcess = true
			end
		end
		imgui.Process = isNeedToProcess

		if not isConfigSaved then
			saveConfig(false)
		end
	end
end

function applyCustomImguiStyle()
	imgui.SwitchContext()

	imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImColor(0, 0, 0, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImColor(33, 33, 33, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImColor(33, 33, 33, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImColor(33, 33, 33, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImColor(33, 33, 33, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImColor(50, 50, 50, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImColor(33, 33, 33, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.CloseButton] = imgui.ImColor(60, 60, 60, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.CloseButtonHovered] = imgui.ImColor(77, 77, 77, 255):GetVec4()
	imgui.GetStyle().Colors[imgui.Col.CloseButtonActive] = imgui.ImColor(60, 60, 60, 255):GetVec4()
end

function openScriptMenu()
	menuState.v = not menuState.v
end

function splitStringIntoParts(str, characterToSplit)
	local parts = {}
	for part in string.gmatch(str, string.format('[^%s]+', characterToSplit)) do
		table.insert(parts, part)
	end
	return parts
end

function saveConfig(isScriptTerminated)
	isConfigSaved = true

	local file = io.open(CONFIG_FILE_PATH, 'w')
	file:write(encodeJson(config))
	io.close(file)

	if not isScriptTerminated then
		lua_thread.create(
			function()
				wait(DELAY_TO_CONFIG_SAVE)
				isConfigSaved = false
			end
		)
	end
end

function imgui.OnDrawFrame()
	imgui.ShowCursor = menuState.v
	
	if not imgui.ShowCursor then
		imgui.SetMouseCursor(-1)
	end

	if menuState.v then
		local width, height = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))

		imgui.Begin(u8('Меню'), menuState, imgui.WindowFlags.AlwaysAutoResize)

		for idx = 1, MAX_NOTES do
			useCustomInputText(string.format('##%d', idx), noteNames[idx], string.format('%d', idx))
			imgui.Text('  ')
			imgui.SameLine()
			if imgui.Button(u8(string.format('%s##%d', not noteStates[idx].v and 'Открыть' or 'Закрыть', idx))) then
				noteStates[idx].v = not noteStates[idx].v
			end

			config['notes'][idx]['name'] = u8:decode(noteNames[idx].v)
		end
			
		imgui.Separator()
		useCustomInputText('##maxLineLength', maxLineLength, u8('Макс. длина строки:'))

		local newMaxLength = tonumber(maxLineLength.v)
		if newMaxLength ~= nil then
			config['other']['maxLineLength'] = newMaxLength
		end

		imgui.End()
	end

	for idx = 1, MAX_NOTES do
		if noteStates[idx].v then
			imgui.SetNextWindowPos(imgui.ImVec2(config['notes'][idx]['position']['x'], 
					                            config['notes'][idx]['position']['y']),
			                       imgui.Cond.FirstUseEver)
			
			imgui.Begin(string.format('%s##%d', noteNames[idx].v, idx), 
				        noteStates[idx], imgui.WindowFlags.AlwaysAutoResize)

			imgui.InputText('##input', noteTexts[idx])
			for _, part in ipairs(splitStringIntoParts(noteTexts[idx].v, ENTERED_CHARACTER_TO_SPLIT)) do
				imgui.Text(addLineBreaks(part))
			end

			config['notes'][idx]['text'] = u8:decode(noteTexts[idx].v)
			config['notes'][idx]['position']['x'] = imgui.GetWindowPos()['x']
			config['notes'][idx]['position']['y'] = imgui.GetWindowPos()['y']
			
			imgui.End()
		end
	end
end

function useCustomInputText(defaultName, buffer, customName)
	imgui.Text(customName)
	imgui.SameLine()
	imgui.InputText(defaultName, buffer)
end

function addLineBreaks(str)
	local lines = {''}
	for _, word in ipairs(splitStringIntoParts(str, ' ')) do
		if #(u8:decode(lines[#lines] .. word)) >= config['other']['maxLineLength'] then
			table.insert(lines, '')
		end 
		lines[#lines] = lines[#lines] .. word .. ' '
	end

	local result = ''
	for idx, line in ipairs(lines) do
		result = result .. line
		if idx ~= #lines then
			result = result .. '\n'
		end
	end
	return result
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		saveConfig(true)
	end
end