--!strict
--!native

local SIZE = 2
local MIN = 0
local MAX = 65_535

local function validate(value: number): ()
	if type(value) ~= 'number' then
		error(`Serdes.u16 expected number, got {typeof(value)}`)
	end

	if value % 1 ~= 0 or value < MIN or value > MAX then
		error(`Serdes.u16 expected integer in [{MIN}, {MAX}], got {value}`)
	end
end

local function write(target: buffer, offset: number, value: number): ()
	buffer.writeu16(target, offset, value)
end

local function read(source: buffer, offset: number): number
	return buffer.readu16(source, offset)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
