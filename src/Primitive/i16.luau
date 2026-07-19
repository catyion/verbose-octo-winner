--!strict
--!native

local SIZE = 2
local MIN = -32_768
local MAX = 32_767

local function validate(value: number): ()
	if type(value) ~= 'number' then
		error(`Serdes.i16 expected number, got {typeof(value)}`)
	end

	if value % 1 ~= 0 or value < MIN or value > MAX then
		error(`Serdes.i16 expected integer in [{MIN}, {MAX}], got {value}`)
	end
end

local function write(target: buffer, offset: number, value: number): ()
	buffer.writei16(target, offset, value)
end

local function read(source: buffer, offset: number): number
	return buffer.readi16(source, offset)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
