--!strict
--!native

local Types = require('../Types')

type Codec<T> = Types.Codec<T>

local MAX_U32 = 4_294_967_295
local MAX_EXACT_INTEGER = 9_007_199_254_740_991

local function create(minimum: number, maximum: number): Codec<number>
	if type(minimum) ~= 'number' or not math.isfinite(minimum) or minimum % 1 ~= 0 or math.abs(minimum) > MAX_EXACT_INTEGER then
		error(`Serdes.range expected an exact integer minimum, got {minimum}`)
	end

	if type(maximum) ~= 'number' or not math.isfinite(maximum) or maximum % 1 ~= 0 or math.abs(maximum) > MAX_EXACT_INTEGER then
		error(`Serdes.range expected an exact integer maximum, got {maximum}`)
	end

	if minimum > maximum then
		error(`Serdes.range expected minimum <= maximum, got [{minimum}, {maximum}]`)
	end

	local span = maximum - minimum

	if span > MAX_U32 then
		error(`Serdes.range span cannot exceed {MAX_U32}, got {span}`)
	end

	local function validate(value: number): ()
		if type(value) ~= 'number' then
			error(`Serdes.range expected number, got {typeof(value)}`)
		end

		if value % 1 ~= 0 or value < minimum or value > maximum then
			error(  `Serdes.range expected integer in [{minimum}, {maximum}], got {value}`)
		end
	end

	if span <= 255 then
		local function write(target: buffer, offset: number, value: number): ()
			buffer.writeu8(target, offset, value - minimum)
		end

		local function read(source: buffer, offset: number): number
			local encoded = buffer.readu8(source, offset)

			if encoded > span then
				error(`Serdes.range decoded invalid value {encoded}`)
			end

			return encoded + minimum
		end

		return table.freeze({
			size = 1,

			validate = validate,
			write = write,
			read = read,
		})
	elseif span <= 65_535 then
		local function write(target: buffer, offset: number, value: number): ()
			buffer.writeu16(target, offset, value - minimum)
		end

		local function read(source: buffer, offset: number): number
			local encoded = buffer.readu16(source, offset)

			if encoded > span then
				error(`Serdes.range decoded invalid value {encoded}`)
			end

			return encoded + minimum
		end

		return table.freeze({
			size = 2,

			validate = validate,
			write = write,
			read = read,
		})
	else
		local function write(target: buffer, offset: number, value: number): ()
			buffer.writeu32(target, offset, value - minimum)
		end

		local function read(source: buffer, offset: number): number
			local encoded = buffer.readu32(source, offset)

			if encoded > span then
				error(`Serdes.range decoded invalid value {encoded}`)
			end

			return encoded + minimum
		end

		return table.freeze({
			size = 4,

			validate = validate,
			write = write,
			read = read,
		})
	end
end

return create
