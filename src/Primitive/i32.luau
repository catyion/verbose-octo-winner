--!strict
--!native

local SIZE = 4
local MIN = -2_147_483_648
local MAX = 2_147_483_647

local function validate(value: number): ()
	if type(value) ~= 'number' then
		error(`Serdes.i32 expected number, got {typeof(value)}`)
	end

	if value % 1 ~= 0 or value < MIN or value > MAX then
		error(`Serdes.i32 expected integer in [{MIN}, {MAX}], got {value}`)
	end
end

local function write(target: buffer, offset: number, value: number): ()
	buffer.writei32(target, offset, value)
end

local function read(source: buffer, offset: number): number
	return buffer.readi32(source, offset)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
