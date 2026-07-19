--!strict
--!native

local SIZE = 8

local MIN_OFFSET = -2_147_483_648
local MAX_OFFSET = 2_147_483_647

local function validate(value: UDim): ()
	if typeof(value) ~= 'UDim' then
		error(`Serdes.udim_8 expected UDim, got {typeof(value)}`)
	end

	if not math.isfinite(value.Scale) or value.Offset % 1 ~= 0 or value.Offset < MIN_OFFSET or value.Offset > MAX_OFFSET then
		error('Serdes.udim_8 received invalid components')
	end
end

local function write(target: buffer, offset: number, value: UDim): ()
	buffer.writef32(target, offset, value.Scale)
	buffer.writei32(target, offset + 4, value.Offset)
end

local function read(source: buffer, offset: number): UDim
	local scale = buffer.readf32(source, offset)
	local pixel_offset = buffer.readi32(source, offset + 4)

	if not math.isfinite(scale) then
		error('Serdes.udim_8 decoded non-finite scale')
	end

	return UDim.new(scale, pixel_offset)
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
