--!strict
--!native

local SIZE = 12

local function validate(value: Vector3): ()
	if typeof(value) ~= 'Vector3' then
		error(`Serdes.vector3_12 expected Vector3, got {typeof(value)}`)
	end

	if not math.isfinite(value.X) or not math.isfinite(value.Y) or not math.isfinite(value.Z) then
		error('Serdes.vector3_12 expected finite components')
	end
end

local function write(target: buffer, offset: number, value: Vector3): ()
	buffer.writef32(target, offset, value.X)
	buffer.writef32(target, offset + 4, value.Y)
	buffer.writef32(target, offset + 8, value.Z)
end

local function read(source: buffer, offset: number): Vector3
	local x = buffer.readf32(source, offset)
	local y = buffer.readf32(source, offset + 4)
	local z = buffer.readf32(source, offset + 8)

	if not math.isfinite(x) or not math.isfinite(y) or not math.isfinite(z) then
		error('Serdes.vector3_12 decoded non-finite component')
	end

	return Vector3.new(x, y, z)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})  
