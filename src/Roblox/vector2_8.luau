--!strict
--!native

local SIZE = 8

local function validate(value: Vector2): ()
	if typeof(value) ~= 'Vector2' then
		error(`Serdes.vector2_8 expected Vector2, got {typeof(value)}`)
	end

	if not math.isfinite(value.X) or not math.isfinite(value.Y) then
		error('Serdes.vector2_8 expected finite components')
	end
end

local function write(target: buffer, offset: number, value: Vector2): ()
	buffer.writef32(target, offset, value.X)
	buffer.writef32(target, offset + 4, value.Y)
end

local function read(source: buffer, offset: number): Vector2
	local x = buffer.readf32(source, offset)
	local y = buffer.readf32(source, offset + 4)

	if not math.isfinite(x) or not math.isfinite(y) then
		error('Serdes.vector2_8 decoded non-finite component')
	end

	return Vector2.new(x, y)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
