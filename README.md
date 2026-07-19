# Serdes

A static, schema-based binary serialization library for Roblox Luau.

Serdes uses fixed-size schemas, composite codecs with compiled field offsets, and direct buffer reads/writes. It is designed for networking, snapshots, rollback state, and other performance-sensitive systems.

## Features

* Fixed-size binary schemas
* Exact buffer allocation
* Checked and unchecked encoding
* Encoding into existing buffers
* Objects, arrays, strings, ranges, enums, flags, optionals, and quantized numbers
* Compact Roblox datatype codecs
* Strict Luau types
* Native compilation support

## Basic Usage

```luau
local Serdes = require('@game/ReplicatedStorage/Serdes')

local encoded = Serdes.encode(Serdes.u16, 50_000)
local decoded = Serdes.decode(Serdes.u16, encoded)

print(decoded)
print(buffer.len(encoded))
```

## Object Schemas

Object field order determines the binary layout.

```luau
type player_state = {
	id: number,
	health: number,
	alive: boolean,
	position: Vector3,
}

local player_state = Serdes.object({
	Serdes.field('id', Serdes.u32),
	Serdes.field('health', Serdes.u8),
	Serdes.field('alive', Serdes.bool),
	Serdes.field('position', Serdes.vector3_8),
})

local encoded = Serdes.encode(player_state, {
	id = 12_345,
	health = 100,
	alive = true,
	position = Vector3.new(100, 25, -50),
})

local decoded = Serdes.decode(player_state, encoded)
```

Construct schemas once and reuse them. Do not construct codecs inside frequently called functions.

## Checked and Unsafe Encoding

`Serdes.encode` validates before writing:

```luau
local encoded = Serdes.encode(Serdes.u8, 200)
```

`Serdes.unsafe_encode` skips validation:

```luau
local encoded = Serdes.unsafe_encode(Serdes.u8, 200)
```

Unsafe functions should only be used when the surrounding code already guarantees valid values.

## Existing Buffers

Write multiple values into one buffer with `into`:

```luau
local target = buffer.create(4)
local offset = 0

offset = Serdes.into(Serdes.u16, target, offset, 500)
offset = Serdes.into(Serdes.u8, target, offset, 100)
offset = Serdes.into(Serdes.bool, target, offset, true)
```

Read them back with `from`:

```luau
local id
id, offset = Serdes.from(Serdes.u16, target, 0)
```

`unsafe_into` skips validation.

## Primitive Codecs

| Codec               |    Size |
| ------------------- | ------: |
| `bool`              |  1 byte |
| `u8`, `i8`          |  1 byte |
| `u16`, `i16`        | 2 bytes |
| `u32`, `i32`, `f32` | 4 bytes |
| `f64`               | 8 bytes |

## Composite Codecs

### Fixed-capacity strings

```luau
local username = Serdes.string(20)
```

The value may contain up to 20 bytes, but the encoded size is always fixed.

### Fixed arrays

```luau
local inventory = Serdes.array(Serdes.u16, 8)
```

The array must contain exactly eight values.

### Ranges

```luau
local health = Serdes.range(0, 100)
```

Ranges use the smallest supported integer width for the configured interval.

### Enums

```luau
local state = Serdes.enum({
	'Idle',
	'Walking',
	'Running',
	'Falling',
})
```

Enum order determines the wire identifiers.

### Flags

```luau
local character_flags = Serdes.flags({
	'grounded',
	'sprinting',
	'blocking',
	'stunned',
})
```

Flags pack multiple booleans into bits.

### Optional values

```luau
local optional_target = Serdes.optional(Serdes.u16)
```

Optional codecs retain a fixed size by reserving the child payload.

### Quantized numbers

```luau
local unit_value = Serdes.quantized(0, 1, 16)
```

Quantization reduces size at the cost of controlled precision loss.

## Roblox Codecs

| Codec        |     Size | Description        |
| ------------ | -------: | ------------------ |
| `color3_3`   |  3 bytes | Compact RGB        |
| `color3_12`  | 12 bytes | Precise f32 RGB    |
| `vector2_5`  |  5 bytes | Aggressive Vector2 |
| `vector2_8`  |  8 bytes | Precise Vector2    |
| `vector3_8`  |  8 bytes | Aggressive Vector3 |
| `vector3_12` | 12 bytes | Precise Vector3    |
| `cframe_12`  | 12 bytes | Aggressive CFrame  |
| `cframe_28`  | 28 bytes | Precise CFrame     |
| `udim_8`     |  8 bytes | UDim               |
| `udim2_16`   | 16 bytes | UDim2              |

Example:

```luau
local encoded = Serdes.encode(Serdes.cframe_12, CFrame.new(100, 25, -50) * CFrame.Angles(0, math.rad(45), 0))
```

## Complete Packet Example

```luau
type snapshot = {
	tick: number,
	entity_id: number,
	position: Vector3,
	health: number,
	flags: {
		grounded: boolean,
		sprinting: boolean,
	},
}

local flags = Serdes.flags({
	'grounded',
	'sprinting',
})

local snapshot = Serdes.object({
	Serdes.field('tick', Serdes.u16),
	Serdes.field('entity_id', Serdes.u16),
	Serdes.field('position', Serdes.vector3_8),
	Serdes.field('health', Serdes.range(0, 100)),
	Serdes.field('flags', flags),
})

local packet = Serdes.unsafe_encode(snapshot, {
	tick = 120,
	entity_id = 5,
	position = Vector3.new(10, 20, -30),
	health = 80,
	flags = {
		grounded = true,
		sprinting = false,
	},
})
```

## Wire Compatibility

Schema layouts are binary protocols. Changing field order, field codecs, string capacities, array counts, enum order, flag order, or quantization settings breaks compatibility.

Create a new schema version for breaking changes.

## Performance Notes

* Construct codecs once and reuse them.
* Use unsafe encoding only for trusted values.
* Prefer ranges and flags for compact packets.
* Use aggressive Vector and CFrame codecs for frequent snapshots.
* Keep fixed string capacities small.
* Use `into` when batching multiple values into one buffer.
