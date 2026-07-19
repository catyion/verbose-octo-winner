--!strict
--!native

local Types = require('../Types')

type Codec<T> = Types.Codec<T>

local function create<T>(codec: Codec<T>): Codec<T?>
	local payload_size = codec.size
	local SIZE = payload_size + 1

	local child_validate = codec.validate
	local child_write = codec.write
	local child_read = codec.read

	local function validate(value: T?): ()
		if value ~= nil then
			child_validate(value)
		end
	end

	local function write(target: buffer, offset: number, value: T?): ()
		local payload_offset = offset + 1

		if value == nil then
			buffer.writeu8(target, offset, 0)

			if payload_size > 0 then
				buffer.fill(target, payload_offset, 0, payload_size)
			end

			return
		end

		buffer.writeu8(target, offset, 1)
		child_write(target, payload_offset, value)
	end

	local function read(source: buffer, offset: number): T?
		local present = buffer.readu8(source, offset)

		if present == 0 then
			return nil
		elseif present ~= 1 then
			error(`Serdes.optional decoded invalid presence byte {present}`)
		end

		return child_read(source, offset + 1)
	end

	return table.freeze({
		size = SIZE,

		validate = validate,
		write = write,
		read = read,
	})
end

return create
