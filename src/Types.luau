--!strict

export type Array<T = number> = {T}
export type Dictionary<K = string, V = number> = {[K]: V}

export type Codec<T> = {
	read size: number,

	read validate: (value: T) -> (),
	read write: (target: buffer, offset: number, value: T) -> (),
	read read: (source: buffer, offset: number) -> T,
}

export type Field<T> = {
	read name: string,
	read codec: Codec<T>,
}

export type Flags = {
	[string]: boolean,
}

return table.freeze({})
