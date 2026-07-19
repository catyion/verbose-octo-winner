--!strict
--!native

local Types = require('../Types')

type Array<T> = Types.Array<T>
type Dictionary<K, V> = Types.Dictionary<K, V>
type Codec<T> = Types.Codec<T>
type Field<T> = Types.Field<T>
type Validator<T> = (value: T) -> ()
type Writer<T> = (target: buffer, offset: number, value: T) -> ()
type Reader<T> = (source: buffer, offset: number) -> T

local function compile_validator<T>(names: Array<string>, validators: Array<Validator<T>>, count: number): (value: T) -> ()
	return function(value: T): ()
		if type(value) ~= 'table' then
			error(`Serdes.object expected table, got {typeof(value)}`)
		end

		local record: Dictionary<string, Array<number>> = value

		for index = 1, count do
			validators[index](record[names[index]])
		end
	end
end

local function compile_writer<T>(names: Array<string>, offsets: Array<number>, writers: Array<Writer<T>>, count: number): (target: buffer, offset: number, value: T) -> ()
	return function(target: buffer, offset: number, value: T): ()
		local record: Dictionary<string, Array<number>> = value

		for index = 1, count do
			writers[index](target, offset + offsets[index], record[names[index]])
		end
	end
end

local function compile_reader<T>(names: Array<string>, offsets: Array<number>, readers: Array<Reader<T>>, count: number): (source: buffer, offset: number) -> T
	return function(source: buffer, offset: number): T
		local result = {}

		for index = 1, count do
			result[names[index]] = readers[index](source, offset + offsets[index])
		end

		return result
	end
end

local function object<T>(fields: Array<Field<T>>): Codec<T>
	local count = #fields

	if count == 0 then
		error('Serdes.object expected at least one field')
	end

	local names = table.create(count) :: Array<string>
	local offsets = table.create(count) :: Array<number>

	local validators = table.create(count) :: Array<Validator<T>>
	local writers = table.create(count) :: Array<Writer<T>>
	local readers = table.create(count) :: Array<Reader<T>>

	local seen: Dictionary<string, boolean> = {}
	local size = 0

	for index = 1, count do
		local field = fields[index]
		local name = field.name
		local codec = field.codec
		local length = codec.size

		if type(name) ~= 'string' or name == '' then
			error(`Serdes.object field {index} has an invalid name`)
		end

		if seen[name] then
			error(`Serdes.object received duplicate field '{name}'`)
		end

		if not math.isfinite(length) or length % 1 ~= 0 or length < 0 then
			error(`Serdes.object field '{name}' has invalid codec size {length}`)
		end

		seen[name] = true

		names[index] = name
		offsets[index] = size

		validators[index] = codec.validate
		writers[index] = codec.write
		readers[index] = codec.read

		size += length

		if not math.isfinite(size) then
			error('Serdes.object encoded size overflowed')
		end
	end

	return table.freeze({
		size = size,

		validate = compile_validator<<T>>(names, validators, count),
		write = compile_writer<<T>>(names, offsets, writers, count),
		read = compile_reader<<T>>(names, offsets, readers, count),
	})
end

return object
