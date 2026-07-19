--!strict
--!native

local SIZE = 8

local function validate(value: number): ()
	if type(value) ~= 'number' then
		error(`Serdes.f64 expected number, got {typeof(value)}`)
	end

	if not math.isfinite(value) then
		error(`Serdes.f64 expected finite number, got {value}`)
	end
end

local function write(target: buffer, offset: number, value: number): ()
	buffer.writef64(target, offset, value)
end

local function read(source: buffer, offset: number): number
	local value = buffer.readf64(source, offset)

	if not math.isfinite(value) then
		error(`Serdes.f64 decoded non-finite value {value}`)
	end

	return value
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
