--!strict
--!native

local Types = require('../Types')

type Array<T> = Types.Array<T>
type Dictionary<K, V> = Types.Dictionary<K, V>
type Codec<T> = Types.Codec<T>
type Flags = Types.Flags

local function create(names: Array<string>): Codec<Flags>
	local count = #names

	if count == 0 then
		error('Serdes.flags expected at least one flag')
	end

	local compiled = table.create(count) :: Array<string>
	local seen: Dictionary<string, boolean> = {}

	for index = 1, count do
		local name = names[index]

		if type(name) ~= 'string' or name == '' then
			error(`Serdes.flags received invalid name at index {index}`)
		end

		if seen[name] then
			error(`Serdes.flags received duplicate flag '{name}'`)
		end

		seen[name] = true
		compiled[index] = name
	end

	local SIZE = (count + 7) // 8
	local bits = count % 8
	local max = if bits == 0 then 255 else 2 ^ bits - 1

	local function validate(value: Flags): ()
		if type(value) ~= 'table' then
			error(`Serdes.flags expected table, got {typeof(value)}`)
		end

		for index = 1, count do
			local flag = value[compiled[index]]

			if type(flag) ~= 'boolean' then
				error(`Serdes.flags expected boolean field '{compiled[index]}', got {typeof(flag)}`)
			end
		end
	end

	local function write(target: buffer, offset: number, value: Flags): ()
		for byte = 0, SIZE - 1 do
			local first = byte * 8 + 1
			local last = math.min(first + 7, count)

			local packed = 0
			local mask = 1

			for index = first, last do
				if value[compiled[index]] then
					packed += mask
				end

				mask *= 2
			end

			buffer.writeu8(target, offset + byte, packed)
		end
	end

	local function read(source: buffer, offset: number): Flags
		if bits ~= 0 then
			local byte = buffer.readu8(source, offset + SIZE - 1)

			if byte > max then
				error(`Serdes.flags decoded noncanonical final byte {byte}`)
			end
		end

		local result: Flags = {}

		for byte = 0, SIZE - 1 do
			local packed = buffer.readu8(source, offset + byte)

			local first = byte * 8 + 1
			local last = math.min(first + 7, count)

			for index = first, last do
				result[compiled[index]] = bit32.extract(packed, index - first, 1) == 1
			end
		end

		return result
	end

	return table.freeze({
		size = SIZE,

		validate = validate,
		write = write,
		read = read,
	})
end

return create
