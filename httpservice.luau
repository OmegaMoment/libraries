-- ts pmo :pensive:
-- written by Omega. / ilmitsasa / noir
-- time spent : around 3-4 hours? not sure....

local http = {}
local httpservice = game:GetService('HttpService') -- sadly, httpservice HAS to be used TwT

-- utility :3
-- a little look up table for common escapes TwT
local common_escapes = {
	['"']  = '\\"',
	['\\'] = '\\\\',
	['\b'] = '\\b',
	['\f'] = '\\f',
	['\n'] = '\\n',
	['\r'] = '\\r',
	['\t'] = '\\t',
}

local function escape_string(str)
	-- i decided to put it all in one line cause i'm cool :3
	local function fetch(c)
		return common_escapes[c] or '\\u' .. ('%04x'):format(c:byte())
	end

	return str:gsub('[%c\\"]', fetch)
end

local function call_with_timeout(timeout, funk)
	assert(typeof(funk) == 'function', 'invalid function')
	timeout = typeof(timeout) == 'number' and timeout or 3

	local thread = coroutine.create(function()
		return pcall(funk)
	end)

	local resumed = false
	local pcall_success, result

	task.defer(function()
		resumed, pcall_success, result = coroutine.resume(thread)
	end)

	local start_time = tick()
	while not resumed and tick() - start_time < timeout do
		task.wait()
	end

	if not resumed then
		return false, 'request timed out after: ' .. timeout
	end

	if not pcall_success then
		return false, result
	end

	return true, result
end

-- conversions (data -> table, table -> data) TwT

-- yeah, i decided to do it like this, i know it takes up a lot of lines but it's easier to edit and read ok shut up TwT
local data_types = {
	['Vector3'] = {
		to_table = function(data)
			return {
				data.X, data.Y, data.Z 
			}
		end,

		to_data = function(data)
			return Vector3.new(unpack(data))
		end,
	},

	['Vector2'] = {
		to_table = function(data)
			return {
				data.X, data.Y
			}
		end,

		to_data = function(data)
			return Vector2.new(unpack(data))
		end,
	},

	['UDim'] = {
		to_table = function(data)
			return {
				data.Scale, data.Offset 
			}
		end,

		to_data = function(data)
			return UDim.new(unpack(data))
		end,
	},

	['UDim2'] = {
		to_table = function(data)
			return {
				{data.X.Scale, data.X.Offset}, 
				{data.Y.Scale, data.Y.Offset} 
			}
		end,

		to_data = function(data)
			return UDim2.new(unpack(data))
		end,
	},

	['Rect'] = {
		to_table = function(data)
			return {
				{data.Min.X, data.Min.Y}, 
				{data.Max.X, data.Max.Y} 
			}
		end,

		to_data = function(data)
			return Rect.new(Vector2.new(data[1][1], data[1][2]), Vector2.new(data[2][1], data[2][2]))
		end,
	},

	['Ray'] = {
		to_table = function(data)
			return {
				{data.Origin.X, data.Origin.Y, data.Origin.Z}, 
				{data.Direction.X, data.Direction.Y, data.Direction.Z} 
			}
		end,

		to_data = function(data)
			return Ray.new(Vector3.new(data[1][1], data[1][2], data[1][3]), Vector3.new(data[2][1], data[2][2], data[2][3]))
		end,
	},

	['PhysicalProperties'] = {
		to_table = function(data)
			return {
				data.Density, data.Friction, data.Elasticity, 
				data.FrictionWeight, data.ElasticityWeight 
			}
		end,

		to_data = function(data)
			return PhysicalProperties.new(unpack(data))
		end,
	},

	['NumberSequence'] = {
		to_table = function(data)
			local result = {}

			for _, keypoint in ipairs(data.Keypoints) do
				table.insert(result, { keypoint.Time, keypoint.Value, keypoint.Envelope })
			end

			return result
		end,

		to_data = function(data)
			local keypoints = {}

			for _, keypoint_data in ipairs(data) do
				table.insert(keypoints, NumberSequenceKeypoint.new(keypoint_data[1], keypoint_data[2], keypoint_data[3]))
			end

			return NumberSequence.new(keypoints)
		end,
	},

	['NumberRange'] = {
		to_table = function(data)
			return {
				data.Min, data.Max 
			}
		end,

		to_data = function(data)
			return NumberRange.new(unpack(data))
		end
	},

	['Faces'] = {
		to_table = function(data)
			return {
				data.Top, data.Bottom, data.Left, data.Right, data.Back, data.Front 
			}
		end,

		to_data = function(data)
			local face_data = {}

			if data[1] then 
				table.insert(face_data, Enum.NormalId.Top) 
			end

			if data[2] then 
				table.insert(face_data, Enum.NormalId.Bottom) 
			end

			if data[3] then 
				table.insert(face_data, Enum.NormalId.Left) 
			end

			if data[4] then 
				table.insert(face_data, Enum.NormalId.Right) 
			end

			if data[5] then 
				table.insert(face_data, Enum.NormalId.Back) 
			end

			if data[6] then 
				table.insert(face_data, Enum.NormalId.Front) 
			end

			return Faces.new(unpack(face_data))
		end,
	},

	['EnumItem'] = {
		to_table = function(data)
			return data.Value
		end,

		to_data = function(data)
			return data -- no conversion needed TwT
		end,
	},

	['Color3'] = {
		to_table = function(data)
			return {
				data.R, data.G, data.B 
			}
		end,

		to_data = function(data)
			return Color3.new(unpack(data))
		end,
	},

	['BrickColor'] = {
		to_table = function(data)
			return {
				data.Number
			}
		end,

		to_data = function(data)
			return BrickColor.new(unpack(data))
		end,
	},

	['ColorSequence'] = {
		to_table = function(data)
			local result = {}

			for index, keypoint in ipairs(data.Keypoints) do
				result[index] = {
					keypoint.Time, keypoint.Value.R, 
					keypoint.Value.G, keypoint.Value.B
				}
			end

			return result
		end,

		to_data = function(data)
			local keypoints = {}

			for index, keypoint_data in ipairs(data) do
				keypoints[index] = ColorSequenceKeypoint.new(
					keypoint_data[1], 
					Color3.new(keypoint_data[2], keypoint_data[3], keypoint_data[4])
				)
			end

			return ColorSequence.new(keypoints)
		end,
	},

	['Axes'] = {
		to_table = function(data)
			return {
				data.X, data.Y, data.Z 
			}
		end,

		to_data = function(data)
			local axes_data = {}

			if data[1] then 
				table.insert(axes_data, Enum.Axis.X) 
			end

			if data[2] then 
				table.insert(axes_data, Enum.Axis.Y) 
			end

			if data[3] then 
				table.insert(axes_data, Enum.Axis.Z) 
			end
			return Axes.new(unpack(axes_data))
		end,
	},

	['CFrame'] = {
		to_table = function(data)
			return {
				data:GetComponents()
			}
		end,

		to_data = function(data)
			return CFrame.new(unpack(data))
		end,
	},
}

--[[ welp, had to remove it due to the properties being shuffled
-- kind of stupid i know but i don't care :sob:
local data_types_order = {}

for name, tbl in ipairs(data_types) do
	table.insert(data_types_order, name)
end
]]

-- i hate myself
-- PLEASE add values to the end of this dict / table (unless you want any previous data to be messed up TwT)
local data_types_order = {
	"Vector3", "Vector2", "UDim", "UDim2", "Rect", "Ray", 
	"PhysicalProperties", "NumberSequence", "NumberRange", 
	"Faces", "EnumItem", "Color3", "BrickColor", 
	"ColorSequence", "Axes", "CFrame"
}

-- easy now cause of the dict :3
local convert_to_table = function(value, mark)
	local value_type = typeof(value)

	-- now find in data_types_order TwT
	local value_index = table.find(data_types_order, value_type)

	-- unsupported, return nil TwT
	if not value_index then
		return nil
	end

	local _, converted = pcall(function()
		return data_types[value_type].to_table(value)
	end)

	-- again, if it somehow fails TwT
	if typeof(converted) ~= 'table' then
		return nil
	end

	-- attach the data_type index in the table :3 (to the end cuz i don't want it to mess with anything)
	if mark then
		converted[#converted + 1] = value_index
	end

	return converted
end

local convert_to_data = function(value)
	-- gotta check if we get a correct type of valueeee (if it somehow fails TwT)
	if type(value) ~= 'table' then
		return nil
	end

	local value_index = value[#value]

	-- if serialised data somehow doesn't have an idenifier TwT
	if not value_index then
		return nil
	end

	local value_type = data_types_order[value_index]

	-- invalid index (like if it's out of bounds) TwT
	if not value_type then
		return nil
	end

	-- remove the type name (i know this is probally inefficent but idccc :sob:)
	local data = table.clone(value)
	data[#data] = nil

	local _, converted = pcall(function()
		return data_types[value_type].to_data(data)
	end)

	-- again, if it somehow fails TwT
	if converted == nil then
		return nil
	end

	return converted
end

-- jsoncore :3

-- auto_convert_data (converts data vector3 etc into a table), float_amount (only gets the given amount of integers) TwT
function http:JSONencode(value, auto_convert_data, float_amount)
	local data = {
		output = nil,
		time_elapsed = 0,
		start_time = os.clock()
	}

	auto_convert_data = typeof(auto_convert_data) == 'boolean' and auto_convert_data or false
	float_amount = typeof(float_amount) == 'number' and float_amount or math.huge

	local encode = nil
	encode = function(value)
		local value_type = typeof(value)

		-- yup, a huge elseif block, i'm sorry TwT
		if data_types[value_type] then
			return encode(convert_to_table(value), auto_convert_data)
		elseif value_type == 'string' then
			return '"' .. escape_string(value) .. '"'
		elseif value_type == 'number' then
			if value ~= value then
				return '"NaN"'
			elseif value == math.huge then
				return '"Infinity"'
			elseif value == -math.huge then
				return '"-Infinity"'
			elseif float_amount ~= math.huge then
				return string.format("%."..float_amount.."g", value)
			else
				return tostring(value)
			end
		elseif value_type == 'boolean' then -- i can't put down the cup!!
			return tostring(value)
		elseif value_type == 'nil' then
			return 'null' -- NULL FROM MINECRAFT???
		elseif value_type == 'table' then
			-- oh boy, this isn't going to be fun...

			local is_table = true
			local max_index = 0 -- i didn't have an name ideas ok don't judge me TwT
			local items = {} -- minecraft (god i am resissting the urgeee to call this inventoryy)

			-- gotta check for roblox data types yk TwT
			if auto_convert_data then
				for property_name, property_value in pairs(value) do
					local property_type = typeof(property_value)

					if data_types[property_type] then
						value[property_name] = convert_to_table(property_value)

					elseif property_type == 'table' then
						value[property_name] = encode(property_value)
					end
				end

			end

			-- gotta check if it's a table somehow :shrug:
			for index, _ in pairs(value) do
				max_index += 1

				if type(index) ~= "number" then
					is_table = false
				end
			end

			-- yay more elseif TwT (gosh i hate this)
			if is_table then
				for i = 1, max_index do
					table.insert(items, encode(value[i]))
				end

				return '[' .. table.concat(items, ',') .. ']'
			else
				local pairs = {}

				for index, val in next, value do
					if type(index) == 'string' or type(index) == 'number' then
						table.insert(pairs, '"' .. escape_string(tostring(index)) .. '":' .. encode(val))
					end
				end

				return '{' .. table.concat(pairs, ',') .. '}'
			end
		else
			error('unsupported type: ' .. value_type)
		end
	end

	data.time_elapsed = os.clock() - data.start_time
	data.output = encode(value)
	return data
end

-- auto_convert_data (converts data tables back into normal data)
function http:JSONDecode(str, auto_convert_data)
	local data = {
		output = nil,
		time_elapsed = 0,
		start_time = os.clock()
	}

	auto_convert_data = typeof(auto_convert_data) == 'boolean' and auto_convert_data or false

	-- great, letter by letter aproach again. i have ptsd of this TwT
	local index = 1
	local length = #str

	-- little utility TwT
	local skip_whitespace = function()
		local str, ind = str:find("^%s*", index)
		index = ind + 1
	end

	-- gotta predefine em cause yk TwT
	local parse_string, parse_unicode, parse_number, parse_generic, parse_array, parse_dict

	-- pain.
	parse_unicode = function()
		if str:sub(index + 1, index + 1) ~= 'u' then
			error("expected 'u' after '\\' at " .. index)
		end

		local hex1 = str:sub(index + 2, index + 5)
		if #hex1 ~= 4 or not hex1:match("^[0-9a-fA-F]+$") then
			error('invalid unicode escape at : ' .. index)
		end

		local code1 = tonumber(hex1, 16)

		if not code1 then
			error('invalid unicode number at : ' .. index)
		end

		index += 6 -- skip \u----

		-- check if this is a high surrogate (THANK YOU TO WHOEVER I BASICALLY STOLE THIS FROM TWT)
		if code1 >= 0xD800 and code1 <= 0xDBFF then
			-- try to read the low surrogate tWt
			if str:sub(index, index) == '\\' and str:sub(index + 1, index + 1) == 'u' then
				local hex2 = str:sub(index + 2, index + 5)

				if #hex2 ~= 4 or not hex2:match("^[0-9a-fA-F]+$") then
					error('invalid low surrogate unicode escape at : ' .. index)
				end

				local code2 = tonumber(hex2, 16)

				if not code2 or code2 < 0xDC00 or code2 > 0xDFFF then
					error('invalid low surrogate value at : ' .. index)
				end

				index += 6 -- skip \u---- low surrogate

				-- combine surrogate pair into one unicode
				local combined = 0x10000 + ((code1 - 0xD800) * 0x400) + (code2 - 0xDC00)
				return utf8.char(combined)
			else
				error('expected low surrogate after high surrogate at : ' .. index)
			end
		end

		-- if its not a surrogate pair return as normal TwT
		return utf8.char(code1)
	end

	parse_string = function()
		index += 1 -- skip start "
		local output = ''

		-- sadly a while loop, i am kind of forced to tho TwT
		while index <= length do
			local character = str:sub(index, index)

			if character == '"' then -- ending "
				index += 1
				return output

			elseif character == '\\' then -- escape sequence hell begins here TwT
				local next_character = str:sub(index + 1, index + 1)

				if next_character == 'u' then -- unicode escape
					output ..= parse_unicode()
				elseif next_character == '"' then -- escaped "
					output ..= '"'
					index += 2

				elseif next_character == '\\' then -- escaped \
					output ..= '\\'
					index += 2

				elseif next_character == '/' then -- escaped /
					output ..= '/'
					index += 2

				elseif next_character == 'b' then -- backspace
					output ..= '\b'
					index += 2

				elseif next_character == 'f' then -- form feed
					output ..= '\f'
					index += 2

				elseif next_character == 'n' then -- newline
					output ..= '\n'
					index += 2

				elseif next_character == 'r' then -- carriage return
					output ..= '\r'
					index += 2

				elseif next_character == 't' then -- tab
					output ..= '\t'
					index += 2

				else -- invalid sequence TwT
					error('invalid escape sequence at : ' .. index)
				end

			else -- just a normal character :3
				output ..= character
				index += 1
			end
		end

		-- the string wasn't closed (HOWWW TWTTT)
		error('unterminated string at : ' .. index)
	end

	-- yup, gotta parse numbers too due to stuff like inf etc...
	parse_number = function()
		local start_index = index

		-- first gotta check special number stuff cause rbx TwT
		if str:sub(index, index + 2) == "NaN" then
			index += 3
			return 0 / 0
		elseif str:sub(index, index + 7) == "Infinity" then
			index += 8
			return math.huge
		elseif str:sub(index, index + 8) == "-Infinity" then
			index += 9
			return -math.huge
		end

		-- parse normal numbers manually (sadly i have to use a while here again TwT)
		while index <= length and str:sub(index, index):match("[%d%.eE%+%-]") do
			index += 1
		end

		local number_string = str:sub(start_index, index - 1)
		local number = tonumber(number_string)

		if not number then
			error('invalid number at ' .. start_index .. ' : ' .. number_string)
		end

		return number
	end

	-- generic, just like this whole thing TwT
	parse_generic = function()
		skip_whitespace() -- gotta skip dem lil nasty spaces here :3

		local character = str:sub(index, index)

		if character == '"' then -- a classic.
			return parse_string()

		elseif character == '{' then -- those damn dicts! >:c
			return parse_dict()

		elseif character == '[' then -- arrays, my beloved :3
			return parse_array()

		elseif character:match("[%d%-]") then -- another classic, number :3
			return parse_number()

		elseif str:sub(index, index + 3) == "null" then -- it's just generic from now on so no more commentary TwT
			index += 4
			return nil

		elseif str:sub(index, index + 3) == "true" then
			index += 4
			return true

		elseif str:sub(index, index + 4) == "false" then
			index += 5
			return false
		else
			error("unexpected character at " .. index .. " : " .. character)
		end
	end

	-- gosh i can smell the pain from here (we will be using the skip_whitespace a lot here TwT)
	parse_array = function()
		index += 1 -- skip [

		local result = {}
		skip_whitespace()

		if str:sub(index, index) == ']' then
			index += 1
			return result
		end

		while index <= length do
			table.insert(result, parse_generic())
			skip_whitespace()

			local character = str:sub(index, index)
			if character == ']' then
				index += 1

				-- check for custom data types :3
				if auto_convert_data and typeof(result[#result]) == 'number' then
					if data_types_order[result[#result]] == nil then
						return nil
					end

					local converted = convert_to_data(result)

					if converted ~= nil then
						return converted
					end
				end

				return result -- return the whole thingy :3
			elseif character == ',' then
				index += 1
				skip_whitespace()
			else
				error('expected , or ] at : ' .. index)
			end
		end

		error('unterminated array at : ' .. index)
	end

	-- these are always good to have you know :3 (side note, this will be very similar to array stuff :3)
	parse_dict = function()
		index += 1 -- skip start {

		local result = {} -- the constructed thingy TwT

		skip_whitespace()

		-- yay!! the end :3
		if str:sub(index, index) == '}' then
			index += 1
			return result
		end

		-- yup, another DAMN while loop... TwT
		while true do
			local key = nil
			local character = str:sub(index, index)

			if character == '"' then
				key = parse_string()
			else
				error('expected string key at : ' .. index)
			end

			skip_whitespace()

			-- gotta check for the : after the key TwT
			if str:sub(index, index) ~= ':' then
				error('expected : after key at : ' .. index)
			end

			index += 1 -- skip :
			skip_whitespace()

			-- parse the value :3
			local value = parse_generic()

			-- again, roblox stuff TwT
			if auto_convert_data and type(value) == 'table' and value[#value] then
				local converted = convert_to_data(value)

				if converted ~= nil then
					value = converted
				end
			end

			result[key] = value

			skip_whitespace()
			character = str:sub(index, index)

			-- check for end TwT
			if character == '}' then
				index += 1

				-- check for roblox datatypes :3
				if auto_convert_data then
					for property_name, property_value in pairs(result) do
						if type(property_value) == 'table' and typeof(property_value[#property_value]) == 'number' then
							local converted_value = convert_to_data(property_value)

							if converted_value ~= nil then
								result[property_name] = converted_value
							end
						end
					end
				end

				return result
			elseif character == ',' then
				index += 1
				skip_whitespace()
			else
				error('expected , or } at : ' .. index)
			end
		end
	end

	-- yup the end, and yes we are ending w whitespace skips TwT
	skip_whitespace()
	data.output = parse_generic()
	skip_whitespace()

	-- make sure we parsed the entire string, i don't want any funny business TwT
	if index <= length then
		error('unexpected trailing characters at : ' .. index)
	end

	data.time_elapsed = os.clock() - data.start_time
	return data
end

function http:GenerateGUID(add_curly_braces)
	add_curly_braces = typeof(add_curly_braces) == 'boolean' and add_curly_braces or false

	-- we need this since we are tryna gen UUIDS :3
	local function random_hex(length)
		local characters = '0123456789abcdef'
		local result = table.create(length)

		for i = 1, length do
			local index = math.random(1, 16)
			result[i] = string.sub(characters, index, index)
		end

		return table.concat(result)
	end

	-- gotta randomize :3
	math.randomseed(tick() * 1e6 % 1e9)

	-- a little note, roblox structured this func to return a string that is like 8-4-4-4-12 :3
	-- example : 94b717b2-d54f-4340-a504-bd809ef5bf5c

	-- ew.
	local part1 = random_hex(8)
	local part2 = random_hex(4)

	local part3_number = math.random(0, 0x0fff)
	local part3 = string.format("%04x", bit32.bor(part3_number, 0x4000))

	local part4_number = math.random(0, 0x3fff)
	local part4 = string.format("%04x", bit32.bor(part4_number, 0x8000))

	local part5 = random_hex(12)

	-- the finished product :3
	local uuid = string.format("%s-%s-%s-%s-%s", part1, part2, part3, part4, part5)
	uuid = add_curly_braces and '{' .. uuid .. '}' or uuid

	return uuid
end

-- i honestly have no clue how this one works cause i never used it so imma just do it like dis TwT
function http:GetSecret(key)
	return httpservice:GetSecret(key)
end

function http:UrlEncode(input)
	-- this is how roblox handles this sooo :3
	return (input:gsub("[^%w]", function(char)
		return string.format("%%%02X", string.byte(char))
	end))
end

-- roblox doesn't have dis soo i wanted to add it :3
function http:UrlDecode(input)
	-- taym to reverse :3
	input = input:gsub("+", " ")

	-- decode %XX stuff TwT
	return (input:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

-- I DON'T WNA COMMENT THESEEE TwT
function http:GetAsync(url, cache, headers, retry_amount, timeout)
	assert(typeof(url) == 'string', 'invalid URL provided')

	retry_amount = tonumber(retry_amount) or 1
	cache = cache == nil and true or cache
	timeout = tonumber(timeout) or 10

	for attempt = 1, retry_amount do
		local success, result = call_with_timeout(timeout, function()
			return httpservice:GetAsync(url, cache, headers)
		end)

		if success then
			return result
			
		elseif attempt == retry_amount then
			error('GetAsync failed after ' .. retry_amount .. ' attempts : ' .. tostring(result))
		end
	end
end

function http:PostAsync(url, data, content_type, compress, headers, retry_amount, timeout)
	assert(typeof(url) == 'string', 'invalid URL provided')
	
	retry_amount = typeof(retry_amount) == 'number' and retry_amount or 3
	timeout = typeof(timeout) == 'number' and timeout or 10
	content_type = content_type or Enum.HttpContentType.ApplicationJson
	compress = typeof(compress) == 'boolean' and compress or false
	headers = typeof(headers) == 'table' and headers or {}

	for attempt = 1, retry_amount do
		local success, result = call_with_timeout(timeout, function()
			return httpservice:PostAsync(url, data, content_type, compress, headers)
		end)
		
		if success then
			return result
			
		elseif attempt == retry_amount then
			error('PostAsync failed after ' .. retry_amount .. ' attempts : ' .. tostring(result))
		end
	end
end

-- only gonna comment dis cause yk TwT
function http:RequestAsync(options, retry_amount)
	assert(typeof(options) == 'table', 'expected options table')
	assert(typeof(options.Url) == 'string', 'missing URL in options')

	retry_amount = typeof(retry_amount) == 'number' and retry_amount or 3

	local defaults = {
		Method = 'GET',
		Headers = {},
		Body = '',
		Compress = false,
		Timeout = 10,
	}

	-- fill missing fields with defaults TwT (just like always, i don't want any funy business :3)
	for k, v in pairs(defaults) do
		if options[k] == nil then
			options[k] = v
		end
	end

	-- classic attempt stuff TwT
	for attempt = 1, retry_amount do
		local success, result = call_with_timeout(options.Timeout, function()
			return httpservice:RequestAsync({
				Url = options.Url,
				Method = options.Method,
				Headers = options.Headers,
				Body = options.Body,
				Compress = options.Compress,
			})
		end)

		if success then
			return result
			
		elseif attempt == retry_amount then
			error('RequestAsync failed after ' .. retry_amount .. ' attempts : ' .. tostring(result))
		end
	end
end

http.convert_to_table = convert_to_table
http.convert_to_data = convert_to_data

return http
