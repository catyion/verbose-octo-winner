--!strict
--!native

local Types = require('../Types')

type Array<T> = Types.Array<T>
type Codec<T> = Types.Codec<T>

local function create<T>(element: Codec<T>, count: number): Codec<Array<T>>
	if type(count) ~= 'number' or not math.isfinite(count) or count % 1 ~= 0 or count < 0 then
		error(`Serdes.array expected a non-negative integer count, got {count}`)
	end

	local element_size = element.size

	if not math.isfinite(element_size) or element_size % 1 ~= 0 or element_size < 0 then
		error(`Serdes.array received codec with invalid size {element_size}`)
	end

	local SIZE = element_size * count

	if not math.isfinite(SIZE) then
		error('Serdes.array encoded size overflowed')
	end

	local element_validate = element.validate
	local element_write = element.write
	local element_read = element.read

	local function validate(value: Array<T>): ()
		if type(value) ~= 'table' then
			error(`Serdes.array expected table, got {typeof(value)}`)
		end

		local actual_count = #value

		if actual_count ~= count then
			error(`Serdes.array expected exactly {count} elements, got {actual_count}`)
		end

		for index = 1, count do
			element_validate(value[index])
		end
	end

	local function write(target: buffer, offset: number, value: Array<T>): ()
		local element_offset = offset

		for index = 1, count do
			element_write(target, element_offset, value[index])
			element_offset += element_size
		end
	end

	local function read(source: buffer, offset: number): Array<T>
		local result = table.create(count) :: Array<T>
		local element_offset = offset

		for index = 1, count do
			result[index] = element_read(source, element_offset)
			element_offset += element_size
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
