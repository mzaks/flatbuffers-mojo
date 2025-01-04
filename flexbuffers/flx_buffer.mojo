from .data_types import StackValue, ValueBitWidth, padding_size, ValueType
from .cache import _CacheStackValue, Key, _CacheStringOrKey, OffsetAndCount
from memory import memcpy, memset_zero
from memory.unsafe import bitcast

alias BufPointer = UnsafePointer[UInt8]


fn flx_null() -> (BufPointer, Int):
    var buffer = FlxBuffer(16)
    buffer.add_null()
    return finish_ignoring_excetion(buffer^)


fn flx(v: Int) -> (BufPointer, Int):
    var buffer = FlxBuffer(16)
    buffer.add(v)
    return finish_ignoring_excetion(buffer^)


fn flx[D: DType](v: SIMD[D, 1]) -> (BufPointer, Int):
    var buffer = FlxBuffer(16)
    buffer.add(v)
    return finish_ignoring_excetion(buffer^)


fn flx(v: String) -> (BufPointer, Int):
    var buffer = FlxBuffer(len(v) + 16)
    buffer.add(v)
    return finish_ignoring_excetion(buffer^)


fn flx_blob(v: BufPointer, length: Int) -> (BufPointer, Int):
    var buffer = FlxBuffer(length + 32)
    buffer.blob(v, length)
    return finish_ignoring_excetion(buffer^)


fn flx[D: DType](v: UnsafePointer[Scalar[D]], length: Int) -> (BufPointer, Int):
    var buffer = FlxBuffer(length * sizeof[D]() + 1024)
    buffer.add(v, length)
    return finish_ignoring_excetion(buffer^)


struct FlxBuffer[
    dedup_string: Bool = True,
    dedup_key: Bool = True,
    dedup_keys_vec: Bool = True,
](Copyable, Movable):
    var _stack: List[StackValue]
    var _stack_positions: List[Int]
    var _stack_is_vector: List[SIMD[DType.bool, 1]]
    var _bytes: BufPointer
    var _size: UInt64
    var _offset: UInt64
    var _finished: Bool
    var _string_cache: _CacheStringOrKey
    var _key_cache: _CacheStringOrKey
    var _keys_vec_cache: _CacheStackValue
    var _reference_cache: _CacheStackValue

    fn __init__(mut self, size: UInt64 = 1 << 11):
        self._size = size
        self._stack = List[StackValue]()
        self._stack_positions = List[Int]()
        self._stack_is_vector = List[SIMD[DType.bool, 1]]()
        self._bytes = BufPointer.alloc(int(size))
        self._offset = 0
        self._finished = False
        self._string_cache = _CacheStringOrKey()
        self._key_cache = _CacheStringOrKey()
        self._keys_vec_cache = _CacheStackValue()
        self._reference_cache = _CacheStackValue()

    fn __moveinit__(mut self, owned other: Self):
        self._size = other._size
        self._stack = other._stack^
        self._stack_positions = other._stack_positions^
        self._stack_is_vector = other._stack_is_vector^
        self._bytes = other._bytes
        self._offset = other._offset
        self._finished = other._finished
        self._string_cache = other._string_cache^
        self._key_cache = other._key_cache^
        self._keys_vec_cache = other._keys_vec_cache^
        self._reference_cache = other._reference_cache^

    fn __copyinit__(mut self, other: Self):
        self._size = other._size
        self._stack = other._stack
        self._stack_positions = other._stack_positions
        self._stack_is_vector = other._stack_is_vector
        self._bytes = BufPointer.alloc(int(other._size))
        memcpy(self._bytes, other._bytes, int(other._offset))
        self._offset = other._offset
        self._finished = other._finished
        self._string_cache = other._string_cache
        self._key_cache = other._key_cache
        self._keys_vec_cache = other._keys_vec_cache
        self._reference_cache = other._reference_cache

    fn __del__(owned self):
        if not self._finished:
            self._bytes.free()

    fn add_null(mut self):
        self._stack.append(StackValue.Null)

    fn add[D: DType](mut self, value: SIMD[D, 1]):
        self._stack.append(StackValue.of(value))

    fn add(mut self, value: Int):
        self._stack.append(StackValue.of(value))

    fn add(mut self, value: String):
        self._add_string[as_key=False](value)

    fn key(mut self, value: String):
        self._add_string[as_key=True](value)

    fn _add_string[as_key: Bool](mut self, value: String):
        var byte_length = len(value)
        var bit_width = ValueBitWidth.of(byte_length)
        var bytes = value.unsafe_ptr()

        @parameter
        if dedup_string and not as_key:
            var cached_offset = self._string_cache.get(
                (bytes, byte_length), self._bytes
            )
            if cached_offset != -1:
                self._stack.append(
                    StackValue(
                        bitcast[DType.uint64](Int64(cached_offset)),
                        bit_width,
                        ValueType.String,
                    )
                )
                return

        @parameter
        if dedup_key and as_key:
            var cached_offset = self._key_cache.get(
                (bytes, byte_length), self._bytes
            )
            if cached_offset != -1:
                self._stack.append(
                    StackValue(
                        bitcast[DType.uint64](Int64(cached_offset)),
                        bit_width,
                        ValueType.Key,
                    )
                )
                return

        @parameter
        if not as_key:
            var byte_width = self._align(bit_width)
            self._write(byte_length, byte_width)

        var offset = self._offset
        var new_offest = self._new_offset(byte_length)
        memcpy(self._bytes.offset(int(self._offset)), bytes, byte_length)
        self._offset = new_offest
        self._write(0)

        @parameter
        if dedup_string and not as_key:
            self._string_cache.put(
                OffsetAndCount(int(offset), byte_length), self._bytes
            )

        @parameter
        if dedup_key and as_key:
            self._key_cache.put(
                OffsetAndCount(int(offset), byte_length), self._bytes
            )

        @parameter
        if as_key:
            self._stack.append(StackValue(offset, bit_width, ValueType.Key))
        else:
            self._stack.append(StackValue(offset, bit_width, ValueType.String))
        value._strref_keepalive()

    fn blob(mut self, value: BufPointer, length: Int):
        var bit_width = ValueBitWidth.of(length)
        var byte_width = self._align(bit_width)
        self._write(length, byte_width)
        var offset = self._offset
        var new_offest = self._new_offset(length)
        memcpy(self._bytes.offset(int(self._offset)), value, length)
        self._offset = new_offest
        self._stack.append(StackValue(offset, bit_width, ValueType.Blob))

    fn add_indirect[D: DType](mut self, value: SIMD[D, 1]):
        var value_type = ValueType.of[D]()
        if (
            value_type == ValueType.Int
            or value_type == ValueType.UInt
            or value_type == ValueType.Float
        ):
            var bit_width = ValueBitWidth.of(value)
            var byte_width = self._align(bit_width)
            var offset = self._offset
            self._write(StackValue.of(value), byte_width)
            self._stack.append(StackValue(offset, bit_width, value_type + 5))
        else:
            self._stack.append(StackValue.of(value))

    fn add[D: DType](mut self, value: UnsafePointer[Scalar[D]], length: Int):
        var len_bit_width = ValueBitWidth.of(length)
        var elem_bit_width = ValueBitWidth.of(SIMD[D, 1](0))
        if len_bit_width <= elem_bit_width:
            var bit_width = len_bit_width if elem_bit_width < len_bit_width else elem_bit_width
            var byte_width = self._align(bit_width)
            self._write(length, byte_width)
            var offset = self._offset
            var byte_length = sizeof[D]() * length
            var new_offest = self._new_offset(byte_length)
            memcpy(
                self._bytes.offset(int(self._offset)),
                value.bitcast[DType.uint8](),
                byte_length,
            )
            self._offset = new_offest
            self._stack.append(
                StackValue(
                    bitcast[DType.uint64](offset),
                    bit_width,
                    ValueType.of[D]() + ValueType.Vector,
                )
            )
        else:
            self.start_vector()
            for i in range(length):
                self.add[D](value[i])
            try:
                self.end()
            except:
                pass

    fn add_referenced(mut self, reference_key: String) raises:
        var key = Key(reference_key.unsafe_ptr(), len(reference_key))
        var stack_value = self._reference_cache.get(key, StackValue.Null)
        key.pointer.free()
        if stack_value.type == ValueType.Null:
            raise "No value for reference key " + reference_key
        self._stack.append(stack_value)

    fn start_vector(mut self):
        self._stack_positions.append(len(self._stack))
        self._stack_is_vector.append(True)

    fn start_map(mut self):
        self._stack_positions.append(len(self._stack))
        self._stack_is_vector.append(False)

    fn end(mut self, reference_key: String = "") raises:
        var position = self._stack_positions.pop()
        var is_vector = self._stack_is_vector.pop()
        if is_vector:
            self._end_vector(position)
        else:
            self._sort_keys_and_end_map(position)
        if len(reference_key) > 0:
            var key = Key(reference_key.unsafe_ptr(), len(reference_key))
            self._reference_cache.put(key, self._stack[len(self._stack) - 1])

    fn finish(owned self) raises -> (BufPointer, Int):
        return self._finish()

    fn _finish(mut self) raises -> (BufPointer, Int):
        self._finished = True

        while len(self._stack_positions) > 0:
            self.end()

        if len(self._stack) != 1:
            raise "Stack needs to have only one element. Instead of: " + String(
                len(self._stack)
            )

        var value = self._stack.pop()
        var byte_width = self._align(value.element_width(self._offset, 0))
        self._write(value, byte_width)
        self._write(value.stored_packed_type())
        self._write(byte_width.cast[DType.uint8]())
        return self._bytes, int(self._offset)

    fn _align(mut self, bit_width: ValueBitWidth) -> UInt64:
        var byte_width = 1 << int(bit_width.value)
        self._offset += padding_size(self._offset, byte_width)
        return byte_width

    fn _write(mut self, value: StackValue, byte_width: UInt64):
        self._grow_bytes_if_needed(self._offset + byte_width)
        if value.is_offset():
            var rel_offset = self._offset - value.as_uint()
            # Safety check not implemented for now as it is internal call and should be safe
            # if byte_width == 8 or rel_offset < (1 << (byte_width * 8)):
            self._write(rel_offset, byte_width)
        else:
            var new_offset = self._new_offset(byte_width)
            self._bytes[int(self._offset)] = value.to_value(byte_width)
            self._offset = new_offset

    fn _write(mut self, value: UInt64, byte_width: UInt64):
        self._grow_bytes_if_needed(self._offset + byte_width)
        var new_offset = self._new_offset(byte_width)
        self._bytes[int(self._offset)] = bitcast[DType.uint8, 8](value)
        # We write 8 bytes but the offset is still set to byte_width
        self._offset = new_offset

    fn _write(mut self, value: UInt8):
        self._grow_bytes_if_needed(self._offset + 1)
        var new_offset = self._new_offset(1)
        self._bytes[int(self._offset)] = value
        self._offset = new_offset

    fn _new_offset(mut self, byte_width: UInt64) -> UInt64:
        var new_offset = self._offset + byte_width
        var min_size = self._offset + max(byte_width, 8)
        self._grow_bytes_if_needed(min_size)
        return new_offset

    fn _grow_bytes_if_needed(mut self, min_size: UInt64):
        var prev_size = self._size
        while self._size < min_size:
            self._size <<= 1
        if prev_size < self._size:
            var prev_bytes = self._bytes
            self._bytes = BufPointer.alloc(int(self._size))
            memcpy(self._bytes, prev_bytes, int(self._offset))
            prev_bytes.free()

    fn _end_vector(mut self, position: Int) raises:
        var length = len(self._stack) - position
        var vec = self._create_vector(position, length, 1)
        self._stack.resize(position, StackValue.Null)
        self._stack.append(vec)

    fn _sort_keys_and_end_map(mut self, position: Int) raises:
        if (len(self._stack) - position) & 1 == 1:
            raise "The stack needs to hold key value pairs (even number of elements). Check if you combined [key] with [add] method calls properly."
        for i in range(position + 2, len(self._stack), 2):
            var key = self._stack[i]
            var value = self._stack[i + 1]
            var j = i - 2
            while j >= position and self._should_flip(self._stack[j], key):
                self._stack[j + 2] = self._stack[j]
                self._stack[j + 3] = self._stack[j + 1]
                j -= 2
            self._stack[j + 2] = key
            self._stack[j + 3] = value
        self._end_map(position)

    fn _should_flip(self, a: StackValue, b: StackValue) raises -> Bool:
        if a.type != ValueType.Key or b.type != ValueType.Key:
            raise "Stack values are not keys " + str(a.type.value) + " " + str(
                a.type.value
            )
        var index = 0
        while True:
            var c1 = self._bytes[int(a.as_uint()) + index]
            var c2 = self._bytes[int(b.as_uint()) + index]
            if c1 < c2:
                return False
            if c1 > c2:
                return True
            if c1 == 0 and c2 == 0:
                return False
            index += 1

    fn _end_map(mut self, start: Int) raises:
        var length = (len(self._stack) - start) >> 1
        var keys = StackValue.Null

        @parameter
        if dedup_key and dedup_keys_vec:
            var keys_vec = self._create_keys_vec_value(start, length)
            var cached = self._keys_vec_cache.get(keys_vec, StackValue.Null)
            if cached != StackValue.Null:
                keys = cached
                keys_vec.pointer.free()
            else:
                keys = self._create_vector(start, length, 2)
                self._keys_vec_cache.put(keys_vec, keys)
        else:
            keys = self._create_vector(start, length, 2)
        var map = self._create_vector(start + 1, length, 2, keys)
        self._stack.resize(start, StackValue.Null)
        self._stack.append(map)

    fn _create_keys_vec_value(self, start: Int, length: Int) -> Key:
        var size = length * 8
        var result = BufPointer.alloc(size)
        var offset = 0
        memset_zero(result, size)
        for i in range(start, len(self._stack), 2):
            result[offset] = self._stack[i].value
            offset += 8
        var key = Key(result, size)
        result.free()
        return key

    fn _create_vector(
        mut self,
        start: Int,
        length: Int,
        step: Int,
        keys: StackValue = StackValue.Null,
    ) raises -> StackValue:
        var bit_width = ValueBitWidth.of(UInt64(length))
        var prefix_elements = 1
        if keys != StackValue.Null:
            prefix_elements += 2
            var keys_bit_width = keys.element_width(self._offset, 0)
            if bit_width < keys_bit_width:
                bit_width = keys_bit_width

        var typed = False
        var vec_elem_type = ValueType.Null
        if length > 0:
            vec_elem_type = self._stack[start].type
            typed = vec_elem_type.is_typed_vector_element()
            if keys != StackValue.Null:
                typed = False
            for i in range(start, len(self._stack), step):
                var elem_bit_width = self._stack[i].element_width(
                    self._offset, i + prefix_elements
                )
                if bit_width < elem_bit_width:
                    bit_width = elem_bit_width
                if vec_elem_type != self._stack[i].type:
                    typed = False
                if bit_width == ValueBitWidth.width64 and typed == False:
                    break
        var byte_width = self._align(bit_width)
        if keys != StackValue.Null:
            self._write(keys, byte_width)
            self._write(int(1 << keys.width.value), byte_width)
        self._write(UInt64(length), byte_width)
        var offset = self._offset
        for i in range(start, len(self._stack), step):
            self._write(self._stack[i], byte_width)
        if not typed:
            for i in range(start, len(self._stack), step):
                self._write(self._stack[i].stored_packed_type())
            if keys != StackValue.Null:
                return StackValue(offset, bit_width, ValueType.Map)
            return StackValue(offset, bit_width, ValueType.Vector)

        return StackValue(offset, bit_width, ValueType.Vector + vec_elem_type)


fn finish_ignoring_excetion(
    owned flx: FlxBuffer,
) -> (BufPointer, Int):
    try:
        return flx^.finish()
    except e:
        # should never happen
        print("Unexpected error:", e)
        return BufPointer(), -1
