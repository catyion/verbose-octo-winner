--!strict
--!native

local Types = require('../Types')

type Codec<T> = Types.Codec<T>

local function create(minimum: number, maximum: number, bits: number): Codec<number>
	if type(minimum) ~= 'number' or not math.isfinite(minimum) then
		error(`Serdes.quantized expected finite minimum, got {minimum}`)
	end

	if type(maximum) ~= 'number' or not math.isfinite(maximum) then error(`Serdes.quantized expected finite maximum, got {maximum}`)
	end

	if minimum >= maximum then
		error(`Serdes.quantized expected minimum < maximum, got [{minimum}, {maximum}]`)
	end

	if bits ~= 8 and bits ~= 16 and bits ~= 32 then
		error(`Serdes.quantized expected 8, 16, or 32 bits, got {bits}`)
	end

	local quantized_maximum = if bits == 8 then 255 elseif bits == 16 then 65_535 else 4_294_967_295
	local encode_scale = quantized_maximum / (maximum - minimum)
	local decode_scale = (maximum - minimum) / quantized_maximum

	local function validate(value: number): ()
		if type(value) ~= 'number' then
			error(`Serdes.quantized expected number, got {typeof(value)}`)
		end

		if not math.isfinite(value) or value < minimum or value > maximum then
			error(`Serdes.quantized expected finite value in [{minimum}, {maximum}], got {value}`)
		end
	end

	if bits == 8 then
		local function write(target: buffer, offset: number, value: number): ()
			buffer.writeu8(target, offset, math.round((value - minimum) * encode_scale))
		end

		local function read(source: buffer, offset: number): number
			return minimum + buffer.readu8(source, offset) * decode_scale
		end

		return table.freeze({
			size = 1,

			validate = validate,
			write = write,
			read = read,
		})
	elseif bits == 16 then
		local function write(target: buffer, offset: number, value: number): ()
			buffer.writeu16(target, offset, math.round((value - minimum) * encode_scale))
		end

		local function read(source: buffer, offset: number): number
			return minimum + buffer.readu16(source, offset) * decode_scale
		end

		return table.freeze({
			size = 2,

			validate = validate,
			write = write,
			read = read,
		})
	else
		local function write(target: buffer, offset: number, value: number): ()
			buffer.writeu32(target, offset, math.round((value - minimum) * encode_scale))
		end

		local function read(source: buffer, offset: number): number
			return minimum + buffer.readu32(source, offset) * decode_scale
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
