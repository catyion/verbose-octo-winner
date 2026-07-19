--!strict
--!native

local SIZE = 4
local MAX = 3.4028234663852886e38

local function validate(value: number): ()
	if type(value) ~= 'number' then
		error(`Serdes.f32 expected number, got {typeof(value)}`)
	end

	if not math.isfinite(value) or value < -MAX or value > MAX then
		error(`Serdes.f32 expected finite f32 value, got {value}`)
	end
end

local function write(target: buffer, offset: number, value: number): ()
	buffer.writef32(target, offset, value)
end

local function read(source: buffer, offset: number): number
	local value = buffer.readf32(source, offset)

	if not math.isfinite(value) then
		error(`Serdes.f32 decoded non-finite value {value}`)
	end

	return value
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
