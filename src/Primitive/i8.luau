--!strict
--!native

local SIZE = 1
local MIN = -128
local MAX = 127

local function validate(value: number): ()
	if type(value) ~= 'number' then
		error(`Serdes.i8 expected number, got {typeof(value)}`)
	end

	if value % 1 ~= 0 or value < MIN or value > MAX then
		error(`Serdes.i8 expected integer in [{MIN}, {MAX}], got {value}`)
	end
end

local function write(target: buffer, offset: number, value: number): ()
	buffer.writei8(target, offset, value)
end

local function read(source: buffer, offset: number): number
	return buffer.readi8(source, offset)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
