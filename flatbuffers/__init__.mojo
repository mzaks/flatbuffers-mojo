from memory import memcmp


@always_inline
fn indirect(buf: DTypePointer[DType.uint8], pos: Int) -> Int32:
    return buf.offset(pos).bitcast[DType.int32]()[0]


@always_inline
fn read[T: DType](buf: DTypePointer[DType.uint8], pos: Int) -> Scalar[T]:
    return buf.offset(pos).bitcast[T]()[0]


fn field[
    T: DType
](
    buf: DTypePointer[DType.uint8],
    pos: Int,
    field_offset: Int,
    default: Scalar[T],
) -> Scalar[T]:
    var relativ_value_offset = _relative_field_offset(buf, pos, field_offset)
    if relativ_value_offset == 0:
        return default
    return buf.offset(int(pos) + relativ_value_offset).bitcast[T]()[0]


fn field_table(
    buf: DTypePointer[DType.uint8], pos: Int, field_offset: Int
) -> Optional[Int32]:
    var relativ_value_offset = _relative_field_offset(buf, pos, field_offset)
    if relativ_value_offset == 0:
        return None
    return (
        pos
        + relativ_value_offset
        + buf.offset(pos + relativ_value_offset).bitcast[DType.int32]()[0]
    )


fn field_struct(
    buf: DTypePointer[DType.uint8], pos: Int, field_offset: Int
) -> Optional[Int32]:
    var relativ_value_offset = _relative_field_offset(buf, pos, field_offset)
    if relativ_value_offset == 0:
        return None
    return pos + relativ_value_offset


fn field_vector(
    buf: DTypePointer[DType.uint8], pos: Int, field_offset: Int
) -> Int:
    var relativ_value_offset = _relative_field_offset(buf, pos, field_offset)
    if relativ_value_offset == 0:
        return 0
    return (
        int(
            pos
            + relativ_value_offset
            + buf.offset(pos + relativ_value_offset).bitcast[DType.int32]()[0]
        )
        + 4
    )


fn field_vector_len(
    buf: DTypePointer[DType.uint8], pos: Int, field_offset: Int
) -> Int:
    var relativ_value_offset = _relative_field_offset(buf, pos, field_offset)
    if relativ_value_offset == 0:
        return 0
    var vec_pos = int(
        pos
        + relativ_value_offset
        + buf.offset(pos + relativ_value_offset).bitcast[DType.int32]()[0]
    )
    return int(buf.offset(vec_pos).bitcast[DType.int32]()[0])


fn field_string(
    buf: DTypePointer[DType.uint8], pos: Int, field_offset: Int
) -> StringRef:
    var relativ_value_offset = _relative_field_offset(buf, pos, field_offset)
    if relativ_value_offset == 0:
        return ""
    var str_pos = int(
        pos
        + relativ_value_offset
        + buf.offset(pos + relativ_value_offset).bitcast[DType.int32]()[0]
    )
    var length = buf.offset(str_pos).bitcast[DType.int32]()[0]
    return StringRef(buf.offset(str_pos + 4), int(length))


@always_inline
fn _relative_field_offset(
    buf: DTypePointer[DType.uint8], pos: Int, field_offset: Int
) -> Int:
    var relativ_vtable_offset = indirect(buf, pos)
    var vtable_pos = pos - relativ_vtable_offset
    return int(buf.offset(vtable_pos + field_offset).bitcast[DType.uint16]()[0])


@value
struct Offset(CollectionElement):
    var value: Int32


struct Builder:
    var buf: DTypePointer[DType.uint8]
    var capacity: Int
    var head: Int
    var minalign: Int
    var object_end: Int
    var current_vtable: List[Int]
    var vtables: List[Int]
    var nested: Bool

    fn __init__(inout self, capacity: Int = 1024):
        self.buf = DTypePointer[DType.uint8].alloc(capacity)
        self.capacity = capacity
        self.head = 0
        self.minalign = 1
        self.object_end = 0
        self.current_vtable = List[Int]()
        self.vtables = List[Int]()
        self.nested = False

    fn __del__(owned self):
        self.buf.free()

    @always_inline
    fn start(self) -> Int:
        return self.capacity - self.head

    @always_inline
    fn offset(self) -> Offset:
        return Offset(self.head)

    fn sized_copy(self) -> Tuple[DTypePointer[DType.uint8], Int]:
        var result = DTypePointer[DType.uint8].alloc(self.head)
        memcpy(result, self.buf.offset(self.start()), self.head)
        return result, self.head

    fn start_nesting(inout self):
        debug_assert(not self.nested, "double nesting")
        self.nested = True

    fn end_nesting(inout self):
        debug_assert(self.nested, "not nested")
        self.nested = False

    fn start_object(inout self, num_fields: Int):
        self.start_nesting()
        self.current_vtable = List[Int](0) * num_fields
        self.object_end = self.head
        self.minalign = 1

    fn slot(inout self, index: Int):
        debug_assert(self.nested, "should be nested")
        self.current_vtable[index] = self.head

    fn pad(inout self, bytes: Int):
        var start = self.start()
        for _ in range(bytes):
            start -= 1
            self.buf.offset(start)[0] = 0
        self.head += bytes

    fn prep(inout self, size: Int, additional_bytes: Int):
        if size > self.minalign:
            self.minalign = size
        var align_size = ((~(self.head + additional_bytes)) + 1) & (size - 1)
        if self.capacity <= self.head + additional_bytes + size + align_size:
            var new_capacity = 2 * self.capacity
            while (
                new_capacity <= self.head + additional_bytes + size + align_size
            ):
                new_capacity *= 2
            var old_buf = self.buf
            self.buf = DTypePointer[DType.uint8].alloc(new_capacity)
            memcpy(
                self.buf.offset(new_capacity - self.head),
                old_buf.offset(self.capacity - self.head),
                self.head,
            )
            old_buf.free()
            self.capacity = new_capacity
        self.pad(align_size)

    fn prepend[dt: DType](inout self, value: Scalar[dt]):
        self.prep(dt.sizeof(), 0)
        self.head += dt.sizeof()
        self.buf.offset(self.start()).bitcast[dt]()[0] = value

    fn prepend(inout self, offset: Offset):
        self.prep(4, 0)
        debug_assert(
            offset.value <= self.head, "offset points outside of the buffer"
        )
        self.prepend(self.head - offset.value + 4)

    fn start_vector(
        inout self, elem_size: Int, num_elements: Int, alignment: Int
    ):
        self.start_nesting()
        self.prep(max(4, alignment), elem_size * num_elements)

    fn end_vector(inout self, num_elements: Int) -> Offset:
        self.end_nesting()
        self.prepend(Int32(num_elements))
        return self.offset()

    fn prepend(inout self, s: String) -> Offset:
        self.start_nesting()
        var bytes = s.byte_length()
        self.prep(4, bytes + 1)
        self.head += bytes + 1
        memcpy(self.buf.offset(self.start()), s.unsafe_ptr(), bytes)
        self.buf[self.start() + bytes] = 0
        _ = s
        return self.end_vector(bytes)

    fn end_object(inout self) -> Offset:
        self.end_nesting()
        self.prepend(Int32(0))
        var object_offset = self.head
        var vtable_size = Int16(len(self.current_vtable) + 4)
        while len(self.current_vtable):
            var o = self.current_vtable.pop()
            self.prepend(Int16(object_offset - o if o else 0))
        self.prepend(Int16(object_offset - self.object_end))
        self.prepend(vtable_size)
        var existing_vtable = 0
        for vt2_offset in self.vtables.__reversed__():
            var vt2_start = self.capacity - vt2_offset[]
            var vt2_len = self.buf.offset(vt2_start).bitcast[DType.int16]()[0]
            if (
                vtable_size == vt2_len
                and memcmp(
                    self.buf.offset(self.start() + 2),
                    self.buf.offset(vt2_start + 2),
                    int(vt2_len),
                )
                == 0
            ):
                existing_vtable = vt2_offset[]
                break
        if existing_vtable:
            self.head = object_offset
            self.buf.offset(self.start()).bitcast[DType.int32]()[0] = (
                existing_vtable - object_offset
            )
        else:
            self.buf.offset(self.capacity - object_offset).bitcast[
                DType.int32
            ]()[0] = (self.head - object_offset)
            self.vtables.append(self.head)
        return Offset(object_offset)

    fn finish(
        owned self,
        root_table: Offset,
        /,
        size_prefixed: Bool = False,
        file_identifier: Optional[String] = None,
    ) -> Tuple[DTypePointer[DType.uint8], Int]:
        debug_assert(not self.nested, "should not be nested")
        var prep_size = 4
        if file_identifier:
            prep_size += 4
        if size_prefixed:
            prep_size += 4
        self.prep(self.minalign, prep_size)
        if file_identifier:
            var fid = file_identifier.or_else("    ")
            debug_assert(len(fid) == 4, "file identifier should be of size 4")
            self.head += 4
            memcpy(self.buf.offset(self.start()), fid.unsafe_ptr(), 4)
            _ = fid
        self.prepend(root_table)
        if size_prefixed:
            self.prepend(Int32(self.head))
        return self.sized_copy()
