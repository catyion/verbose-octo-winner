--!strict
--!native

local SIZE = 16

local MIN_OFFSET = -2_147_483_648
local MAX_OFFSET = 2_147_483_647

local function validate(value: UDim2): ()
	if typeof(value) ~= 'UDim2' then
		error(`Serdes.udim2_16 expected UDim2, got {typeof(value)}`)
	end

	local x = value.X
	local y = value.Y

	if not math.isfinite(x.Scale) or not math.isfinite(y.Scale) or x.Offset % 1 ~= 0 or y.Offset % 1 ~= 0 or x.Offset < MIN_OFFSET or x.Offset > MAX_OFFSET or y.Offset < MIN_OFFSET or y.Offset > MAX_OFFSET then
		error('Serdes.udim2_16 received invalid components')
	end
end

local function write(target: buffer, offset: number, value: UDim2): ()
	local x = value.X
	local y = value.Y

	buffer.writef32(target, offset, x.Scale)
	buffer.writei32(target, offset + 4, x.Offset)

	buffer.writef32(target, offset + 8, y.Scale)
	buffer.writei32(target, offset + 12, y.Offset)
end

local function read(source: buffer, offset: number): UDim2
	local x_scale = buffer.readf32(source, offset)
	local x_offset = buffer.readi32(source, offset + 4)

	local y_scale = buffer.readf32(source, offset + 8)
	local y_offset = buffer.readi32(source, offset + 12)

	if not math.isfinite(x_scale) or not math.isfinite(y_scale) then 
        error('Serdes.udim2_16 decoded non-finite scale')
	end

	return UDim2.new(x_scale, x_offset, y_scale, y_offset)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
