--!strict
--!native

local Types = require('../Types')

type Codec<T> = Types.Codec<T>

local MAX_CAPACITY = 65_535

local function create_u8(capacity: number): Codec<string>
	local PREFIX_SIZE = 1
	local SIZE = PREFIX_SIZE + capacity

	local function validate(value: string): ()
		if type(value) ~= 'string' then
			error(`Serdes.string({capacity}) expected string, got {typeof(value)}`)
		end

		if #value > capacity then
			error(`Serdes.string({capacity}) expected at most {capacity} bytes, got {#value}`)
		end
	end

	local function write(target: buffer, offset: number, value: string): ()
		local length = #value
		local payload_offset = offset + PREFIX_SIZE

		buffer.writeu8(target, offset, length)

		if length > 0 then
			buffer.writestring(target, payload_offset, value)
		end

		local unused = capacity - length

		if unused > 0 then
			buffer.fill(target, payload_offset + length, 0, unused)
		end
	end

	local function read(source: buffer, offset: number): string
		local length = buffer.readu8(source, offset)

		if length > capacity then
			error(`Serdes.string({capacity}) decoded invalid length {length}`)
		end

		if length == 0 then
			return ''
		end

		return buffer.readstring(source, offset + PREFIX_SIZE, length)
	end

	return table.freeze({
		size = SIZE,

		validate = validate,
		write = write,
		read = read,
	})
end

local function create_u16(capacity: number): Codec<string>
	local PREFIX_SIZE = 2
	local SIZE = PREFIX_SIZE + capacity

	local function validate(value: string): ()
		if type(value) ~= 'string' then
			error(`Serdes.string({capacity}) expected string, got {typeof(value)}`)
		end

		if #value > capacity then
			error(`Serdes.string({capacity}) expected at most {capacity} bytes, got {#value}`)
		end
	end

	local function write(target: buffer, offset: number, value: string): ()
		local length = #value
		local payload_offset = offset + PREFIX_SIZE

		buffer.writeu16(target, offset, length)

		if length > 0 then
			buffer.writestring(target, payload_offset, value)
		end

		local unused = capacity - length

		if unused > 0 then
			buffer.fill(target, payload_offset + length, 0, unused)
		end
	end

	local function read(source: buffer, offset: number): string
		local length = buffer.readu16(source, offset)

		if length > capacity then
			error(`Serdes.string({capacity}) decoded invalid length {length}`)
		end

		if length == 0 then
			return ''
		end

		return buffer.readstring(source, offset + PREFIX_SIZE, length)
	end

	return table.freeze({
		size = SIZE,

		validate = validate,
		write = write,
		read = read,
	})
end

local function create(capacity: number): Codec<string>
	if type(capacity) ~= 'number' or not math.isfinite(capacity) or capacity % 1 ~= 0 or capacity < 1 or capacity > MAX_CAPACITY then
		error(`Serdes.string expected an integer capacity in [1, {MAX_CAPACITY}], got {capacity}`)
	end

	if capacity <= 255 then
		return create_u8(capacity)
	end

	return create_u16(capacity)
end

return create
