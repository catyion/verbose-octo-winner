--!strict
--!native

local Types = require('../Types')

type Array<T> = Types.Array<T>
type Dictionary<K, V> = Types.Dictionary<K, V>
type Codec<T> = Types.Codec<T>

local MAX_COUNT = 4_294_967_296

local function create<T>(values: Array<T>): Codec<T>
	local count = #values

	if count == 0 then
		error('Serdes.enum expected at least one value')
	end

	if count > MAX_COUNT then
		error(`Serdes.enum cannot contain more than {MAX_COUNT} values`)
	end

	local to_id: Dictionary<T, number> = {}
	local to_value = table.create(count) :: Array<T>

	for index = 1, count do
		local value = values[index]

		if value == nil then
			error(`Serdes.enum value {index} cannot be nil`)
		end

		if type(value) == 'number' and value ~= value then
			error(`Serdes.enum value {index} cannot be NaN`)
		end

		if to_id[value] ~= nil then
			error(`Serdes.enum received duplicate value at index {index}`)
		end

		local id = index - 1

		to_id[value] = id
		to_value[index] = value
	end

	local max_id = count - 1

	local function validate(value: T): ()
		if to_id[value] == nil then
			error(`Serdes.enum received unknown value {tostring(value)}`)
		end
	end

	if max_id <= 255 then
		local function write(target: buffer, offset: number, value: T): ()
			buffer.writeu8(target, offset, to_id[value])
		end

		local function read(source: buffer, offset: number): T
			local id = buffer.readu8(source, offset)
			local value = to_value[id + 1]

			if value == nil then
				error(`Serdes.enum decoded unknown id {id}`)
			end

			return value
		end

		return table.freeze({
			size = 1,

			validate = validate,
			write = write,
			read = read,
		})
	elseif max_id <= 65_535 then
		local function write(target: buffer, offset: number, value: T): ()
			buffer.writeu16(target, offset, to_id[value])
		end

		local function read(source: buffer, offset: number): T
			local id = buffer.readu16(source, offset)
			local value = to_value[id + 1]

			if value == nil then
				error(`Serdes.enum decoded unknown id {id}`)
			end

			return value
		end

		return table.freeze({
			size = 2,

			validate = validate,
			write = write,
			read = read,
		})
	else
		local function write(target: buffer, offset: number, value: T): ()
			buffer.writeu32(target, offset, to_id[value])
		end

		local function read(source: buffer, offset: number): T
			local id = buffer.readu32(source, offset)
			local value = to_value[id + 1]

			if value == nil then
				error(`Serdes.enum decoded unknown id {id}`)
			end

			return value
		end

		return table.freeze({
			size = 4,

			validate = validate,
			write = write,
			read = read,
		})
	end
end

return create
