-- the compression algorithm that touches kids :boom:
-- made in 2 days (18.05.2025, 19.05.2025) in liek 4 hours or smth idk (due to research TwT)
-- made by yours truly, omeag :3

local puffman = {}

-- functions that i just don't wanna repeat / might be used as utility TwT

puffman.create_node = function(character, frequency, left, right)
	-- funny fact : i used to struggle with my lefts and rights TwT :sob:
	return {
		character = character,
		frequency = frequency, -- literally what the whole algorithm is based on
		right = right,
		left = left
	}
end

-- needed, as i stated before this is literally the base of this algorithm TwT
puffman.create_frequency_list = function(input)
	local frequency = {}

    for index = 1, #input do
        local character = input:sub(index, index)
        frequency[character] = (frequency[character] or 0) + 1
    end

    return frequency
end

puffman.build_tree = function(frequency)
	local nodes = {}

	-- create a child for each character (probally the last remants of non-S- code TwT)
	for character, count in pairs(frequency) do
		table.insert(nodes, puffman.create_node(character, count))
	end

	-- build the table by combining the nodes, we need L, R yk :3
	while #nodes > 1 do
		-- again an algorithm base. the algorithm requires me to sort these (least to most frequent) thank you wikipedia :3
		table.sort(nodes, function(a, b)
			return a.frequency < b.frequency
		end)

		-- L, R
		local left = table.remove(nodes, 1)
		local right = table.remove(nodes, 1)

		table.insert(nodes, puffman.create_node(nil, left.frequency + right.frequency, left, right))
	end

	return nodes[1]
end

-- nooo! don't cut our trees!! they make oxygennnn!! :pensive:
puffman.build_codes = function(tree)
	local codes = {}

	local function traverse(node, code)
        if node.character then
            codes[node.character] = code
        else
            if node.left then
				traverse(node.left, code .. 0)
			end

            if node.right then
				traverse(node.right, code .. 1)
			end
        end
    end

	traverse(tree, '')
	return codes
end

-- serialize the tree cause we need it to decode TwT
puffman.serialize_tree = function(node)
    if node.character then
        return '\1' .. node.character
    else
        return '\0' .. puffman.serialize_tree(node.left) .. puffman.serialize_tree(node.right)
    end
end

-- required for the aproach i am using
puffman.estimate_compression_size = function(input, codes, tree_size)
	if typeof(tree_size) == 'table' then -- if somehow i manage to enter the tabe here TwT
		tree_size = #puffman.serialize_tree(tree_size)
	elseif typeof(tree_size) == 'string' then
		tree_size = #tree_size -- i. forgot. to. get. the. size.
	end

	local bit_length = 0

	for index = 1, #input do
        local character = input:sub(index, index)
        bit_length += #codes[character]
    end

	-- calculate data size, rounded tho cuz i felt like that'd be better TwT
	local data_size = math.ceil(bit_length / 8)

	-- the tree is needed to decode the huffman encoding :3
	return tree_size + data_size
end

-- compression start :3

-- the main deal (sadly TwT)
puffman.encode = function(input)
	assert(typeof(input) == 'string', 'invalid input type "'.. typeof(input) .. '" was inputted but the function needed a "string"')

	local data = {
		output = '\001' .. input, -- basically means raw data, i decided to use these like tags for ex : \002 is huffman
		time_elapsed = 0,
		start_time = os.clock(),
		compression_difference = 0,
		method = 'raw' -- if you catch my drift :3 (wink wink)
	}

	-- just in case (tm)
	if rawlen(input) <= 0 then
		data.time_elapsed = os.clock() - data.start_time
		return data
	end

	-- needed variables for the puffy man :boom:
	local frequency = puffman.create_frequency_list(input)
	local tree = puffman.build_tree(frequency)
	local codes = puffman.build_codes(tree)
	local serialized_tree = puffman.serialize_tree(tree) -- pre-serialized for decompression :3

	-- my idea was to attempt to estimate the size of the huffman with the variables we have found :3
	-- this aproach might be good considering basically all compression algorithms make short strings longer when compressed TwT

	local estimated_data_size = puffman.estimate_compression_size(input, codes, #serialized_tree)

	-- return the raw data :3
	if estimated_data_size >= rawlen(input) then
		data.compression_difference = #input - estimated_data_size
		data.time_elapsed = os.clock() - data.start_time
		return data
	end

	-- the puffman encoding starts here
	local binary_string = ''

	for index = 1, #input do
		binary_string ..= codes[input:sub(index, index)]
	end

	-- packing time :^3

	local packed_string = ''
	local byte = 0
	local bit_count = 0

	for index = 1, #binary_string do
		local bit = binary_string:sub(index, index) == '1' and 1 or 0

		-- update our variables
		byte = byte * 2 + bit
		bit_count += 1

		-- basically converting a set amount of bits into bytes (literally why we have the variables)
		if bit_count == 8 then
			packed_string ..= string.char(byte)

			-- reset the variables cause we just processed 8
			byte = 0
			bit_count = 0
		end
	end

	-- if we have any remaining bits left, we'll add them :3
	if bit_count > 0 then
		byte = byte * (2 ^ (8 - bit_count))
		packed_string ..= string.char(byte)
		packed_string ..= string.char(8 - bit_count) -- literally needed to store the bitcount which i somehow forgot (im pissed >:c)
	end

	-- update the data :3
	data.output = '\002' .. serialized_tree .. packed_string
	data.compression_difference = #input - #packed_string
	data.method = 'huffman'
	data.time_elapsed = os.clock() - data.start_time
	return data
end

-- time to decode >:3
puffman.decode = function(input)
	assert(typeof(input) == 'string', 'invalid input type "'.. typeof(input) .. '" was inputted but the function needed a "string"')

    local data = {
        output = input,
        time_elapsed = 0,
        start_time = os.clock(),
        method = 'unknown'
    }

	-- just in case pt.2 (tm)
	if #input <= 0 then
		data.time_elapsed = os.clock() - data.start_time
		return data
	end

	-- weows, such good idenifying system omega
	local compression_type = input:sub(1, 1)

	-- if you somehow forgot, we called \001 the raw data tag :3
	if compression_type == '\001' then
		data.time_elapsed = os.clock() - data.start_time
        data.output = input:sub(2) -- sub(2) due to the tag
        data.method = 'raw'
        return data
    end

	-- added incase a non-supported data gets in here >:c
	if compression_type ~= '\002' then
		error('encountered unsupported compression type : ' .. compression_type .. '\n while trying to compress : ' .. input)
	end

	-- well, time for the main deal TwT
	data.method = 'huffman'
	local position = 2 -- again, to skip the tag :3
	data.output = '' -- reset the output cause yk

	-- we need the raw tree data to rebuild the string properly
	local function deserialize_tree()
		-- if this somehow manages to happen
		if position > #input then
			error('string ended unexpectedly at : ' .. position .. '\n while trying to decompress : ' .. input)
		end

		local marker = input:sub(position, position)
		position += 1

		-- we need to check for marker type here due \1 being characters etc...
		if marker == '\1' then -- character
			local character = input:sub(position, position)
			position += 1

			return puffman.create_node(character, 0)
		elseif marker == '\0' then
			return puffman.create_node(nil, 0, deserialize_tree(), deserialize_tree())
		else
			error('invalid tree marker at : ' .. position .. '\n marker : ' .. marker .. '\n while trying to decompress : ' .. input)
		end
	end

	local deserialized_tree = deserialize_tree()

	-- now that we have the fully deserialized data we need to read it and convert it into normal data
	local current_node = deserialized_tree
	local bit_position = 7 -- start of the most significant bit TwT
	local current_byte = string.byte(input, position)
	local bit_count = string.byte(input, #input)
	local data_end = #input - 1 -- skips the count at the end
	position += 1

	-- as many of you already know, i can't stand while loops but i seriously need to use it here... TwT
	while position <= #input do -- changed this to kill any potential inf loops TwT
		if position > data_end then
			if bit_position < bit_count then
				break
			end
		end

		local bit = bit32.band(bit32.rshift(current_byte, bit_position), 1) -- get the next bit
		bit_position += -1

		-- we need to navigate trough the tree we have
		current_node = (bit == 0) and current_node.left or current_node.right

		-- basically build the output :pensive:
		if current_node.character then
			data.output ..= current_node.character
			current_node = deserialized_tree
		end

		-- check if we need another byte :3
		if bit_position < 0 then
			if position > data_end then
				-- free, at last.
				break
			end

			-- time to skip to the next, basically repeat until done
			current_byte = string.byte(input, position)
			position += 1
			bit_position = 7 -- on every skip we have to return to the most significant bit :3
		end
	end

	-- anddd tada! done :3
	data.time_elapsed = os.clock() - data.start_time
	return data
end

return puffman
