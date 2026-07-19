--!strict
--!native

local SIZE = 12

local function validate(value: Color3): ()
	if typeof(value) ~= 'Color3' then
		error(`Serdes.color3_12 expected Color3, got {typeof(value)}`)
	end

	local r = value.R
	local g = value.G
	local b = value.B

	if not math.isfinite(r) or not math.isfinite(g) or not math.isfinite(b) then
		error('Serdes.color3_12 expected finite components')
	end
end

local function write(target: buffer, offset: number, value: Color3): ()
	buffer.writef32(target, offset, value.R)
	buffer.writef32(target, offset + 4, value.G)
	buffer.writef32(target, offset + 8, value.B)
end

local function read(source: buffer, offset: number): Color3
	local r = buffer.readf32(source, offset)
	local g = buffer.readf32(source, offset + 4)
	local b = buffer.readf32(source, offset + 8)

	if not math.isfinite(r) or not math.isfinite(g) or not math.isfinite(b) then
		error('Serdes.color3_12 decoded non-finite component')
	end

	return Color3.new(r, g, b)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
