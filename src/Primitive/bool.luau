--!strict
--!native

local SIZE = 1

local function validate(value: boolean): ()
	if type(value) ~= 'boolean' then
		error(`Serdes.bool expected boolean, got {typeof(value)}`)
	end
end

local function write(target: buffer, offset: number, value: boolean): ()
	buffer.writeu8(target, offset, if value then 1 else 0)
end

local function read(source: buffer, offset: number): boolean
	local encoded = buffer.readu8(source, offset)

	if encoded > 1 then
		error(`Serdes.bool decoded invalid byte {encoded}; expected 0 or 1`)
	end

	return encoded == 1
end

return table.freeze({
	size = SIZE,

	validate = validate,
	write = write,
	read = read,
})
