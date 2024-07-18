# automatically generated by the FlatBuffers compiler, do not modify
import flatbuffers


@value
struct Person:
    var _buf: UnsafePointer[UInt8]
    var _pos: Int

    fn name(self) -> StringRef:
        return flatbuffers.field_string(self._buf, int(self._pos), 4)

    fn age(self) -> Int32:
        return flatbuffers.field[DType.int32](self._buf, int(self._pos), 6, 0)

    @staticmethod
    fn as_root(buf: UnsafePointer[UInt8]) -> Person:
        return Person(buf, flatbuffers.read_offset_as_int(buf, 0))

    @staticmethod
    fn build(
        inout builder: flatbuffers.Builder,
        *,
        name: Optional[StringRef] = None,
        age: Int32 = 0,
    ) -> flatbuffers.Offset:
        var _name: Optional[flatbuffers.Offset] = None
        if name is not None:
            _name = builder.prepend(name.value())
        builder.start_object(2)
        if _name is not None:
            builder.prepend(_name.value())
            builder.slot(0)
        if age != 0:
            builder.prepend(age)
            builder.slot(1)
        return builder.end_object()
