--!strict
--!native

local Types = require('@self/Types')

export type Codec<T> = Types.Codec<T>
export type Field<T> = Types.Field<T>

local function field<T>(name: string, codec: Codec<T>): Field<T>
	if type(name) ~= 'string' or name == '' then
		error(`Serdes.field expected a non-empty string name, got {name}`)
	end

	return table.freeze({
		name = name,
		codec = codec,
	})
end

local function encode<T>(codec: Codec<T>, value: T): buffer
	codec.validate(value)

	local target = buffer.create(codec.size)
	codec.write(target, 0, value)

	return target
end

local function unsafe_encode<T>(codec: Codec<T>, value: T): buffer
	local target = buffer.create(codec.size)
	codec.write(target, 0, value)

	return target
end

local function into<T>(codec: Codec<T>, target: buffer, offset: number, value: T): number
	codec.validate(value)
	codec.write(target, offset, value)

	return offset + codec.size
end

local function unsafe_into<T>(codec: Codec<T>, target: buffer, offset: number, value: T): number
	codec.write(target, offset, value)

	return offset + codec.size
end

local function decode<T>(codec: Codec<T>, source: buffer): T
	if type(source) ~= 'buffer' then
		error(`Serdes.decode expected buffer, got {typeof(source)}`)
	end

	local expected = codec.size
	local actual = buffer.len(source)

	if actual ~= expected then
		error(`Serdes.decode expected exactly {expected} bytes, got {actual}`)
	end

	return codec.read(source, 0)
end

local function from<T>(codec: Codec<T>, source: buffer, offset: number): (T, number)
	return codec.read(source, offset), offset + codec.size
end

return table.freeze({
    bool = require('@self/Primitive/bool'),
    u8 = require('@self/Primitive/u8'),
    i8 = require('@self/Primitive/i8'),
    u16 = require('@self/Primitive/u16'),
    i16 = require('@self/Primitive/i16'),
    u32 = require('@self/Primitive/u32'),
    i32 = require('@self/Primitive/i32'),
    f32 = require('@self/Primitive/f32'),
    f64 = require('@self/Primitive/f64'),

    string = require('@self/Composite/string'),
    array = require('@self/Composite/array'),
    object = require('@self/Composite/object'),
    range = require('@self/Composite/range'),
    enum = require('@self/Composite/enum'),
    flags = require('@self/Composite/flags'),
    optional = require('@self/Composite/optional'),
    quantized = require('@self/Composite/quantized'),

    color3_3 = require('@self/Roblox/color3_3'),
    color3_12 = require('@self/Roblox/color3_12'),

    vector2_5 = require('@self/Roblox/vector2_5'),
    vector2_8 = require('@self/Roblox/vector2_8'),
    vector3_8 = require('@self/Roblox/vector3_8'),
    vector3_12 = require('@self/Roblox/vector3_12'),

    cframe_12 = require('@self/Roblox/cframe_12'),
    cframe_28 = require('@self/Roblox/cframe_28'),

    udim_8 = require('@self/Roblox/udim_8'),
    udim2_16 = require('@self/Roblox/udim2_16'),

    field = field,

    encode = encode,
    unsafe_encode = unsafe_encode,

    into = into,
    unsafe_into = unsafe_into,

    decode = decode,
    from = from
})
