from bit import bit_width, byte_swap
from memory.unsafe import bitcast
from sys.info import is_big_endian

alias is_be = is_big_endian()

@value
@register_passable("trivial")
struct ValueBitWidth:
    alias width8 = ValueBitWidth(0)
    alias width16 = ValueBitWidth(1)
    alias width32 = ValueBitWidth(2)
    alias width64 = ValueBitWidth(3)

    var value: UInt8

    @always_inline
    fn __lt__(self, other: ValueBitWidth) -> Bool:
        return self.value < other.value

    @always_inline
    fn __le__(self, other: ValueBitWidth) -> Bool:
        return self.value <= other.value

    @always_inline
    fn __eq__(self, other: ValueBitWidth) -> Bool:
        return self.value == other.value

    @always_inline
    @staticmethod
    fn of[D: DType](n: SIMD[D, 1]) -> ValueBitWidth:
        @parameter
        if D == DType.uint8 or D == DType.int8 or D == DType.bool:
            return ValueBitWidth.width8
        elif D == DType.uint16 or D == DType.int16 or D == DType.float16:
            return ValueBitWidth.width16
        elif D == DType.uint32 or D == DType.int32 or D == DType.float32:
            return ValueBitWidth.width32
        else:
            return ValueBitWidth.width64

    @always_inline
    @staticmethod
    fn of(n: Int) -> ValueBitWidth:
        return ValueBitWidth(int(bit_width(Int64(n)) >> 3))
    
    @always_inline
    @staticmethod
    fn of(n: UInt64) -> ValueBitWidth:
        return ValueBitWidth(int(bit_width(n) >> 3))

@always_inline
fn padding_size(buffer_size: UInt64, scalar_size: UInt64) -> UInt64:
    return (~buffer_size + 1) & (scalar_size - 1)

@value
@register_passable("trivial")
struct ValueType:
    alias Null = ValueType(0)
    alias Int = ValueType(1)
    alias UInt = ValueType(2)
    alias Float = ValueType(3)
    alias Key = ValueType(4)
    alias String = ValueType(5)
    alias IndirectInt = ValueType(6)
    alias IndirectUInt = ValueType(7)
    alias IndirectFloat = ValueType(8)
    alias Map = ValueType(9)
    alias Vector = ValueType(10)
    alias VectorInt = ValueType(11)
    alias VectorUInt = ValueType(12)
    alias VectorFloat = ValueType(13)
    alias VectorKey = ValueType(14)
    alias VectorString = ValueType(15)
    alias VectorInt2 = ValueType(16)
    alias VectorUInt2 = ValueType(17)
    alias VectorFloat2 = ValueType(18)
    alias VectorInt3 = ValueType(19)
    alias VectorUInt3 = ValueType(20)
    alias VectorFloat3 = ValueType(21)
    alias VectorInt4 = ValueType(22)
    alias VectorUInt4 = ValueType(23)
    alias VectorFloat4 = ValueType(24)
    alias Blob = ValueType(25)
    alias Bool = ValueType(26)
    alias VectorBool = ValueType(36)

    alias NullPackedType = 0

    var value: UInt8

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value
    
    @always_inline
    fn __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    @always_inline
    fn __le__(self, other: Self) -> Bool:
        return self.value <= other.value

    @always_inline
    fn __sub__(self, other: Self) -> Self:
        return Self(self.value - other.value)

    @always_inline
    fn __add__(self, other: Self) -> Self:
        return Self(self.value + other.value)

    @always_inline
    fn __add__(self, other: UInt8) -> Self:
        return Self(self.value + other.value)

    @always_inline
    fn __mod__(self, other: UInt8) -> Self:
        return Self(self.value % other)

    @always_inline
    fn __floordiv__(self, other: UInt8) -> Self:
        return Self(self.value // other)

    @always_inline
    fn __lshift__(self, other: UInt8) -> Self:
        return Self(self.value << other)

    @always_inline
    fn is_inline(self) -> Bool:
        return self == ValueType.Bool or self <= ValueType.Float
    
    @always_inline
    fn is_typed_vector_element(self) -> Bool:
        return self == ValueType.Bool or ValueType.Int <= self <= ValueType.String

    @always_inline
    fn is_typed_vector(self) -> Bool:
        return self == ValueType.VectorBool or ValueType.VectorInt <= self <= ValueType.VectorString
    
    @always_inline
    fn is_fixed_typed_vector(self) -> Bool:
        return ValueType.VectorInt2 <= self <= ValueType.VectorFloat4

    @always_inline
    fn is_a_vector(self) -> Bool:
        return self == ValueType.VectorBool or ValueType.Vector <= self <= ValueType.VectorFloat4

    @always_inline
    fn to_typed_vector(self, length: UInt8) raises -> ValueType:
        if length == 0:
            return self - ValueType.Int + ValueType.VectorInt
        if length == 2:
            return self - ValueType.Int + ValueType.VectorInt2
        if length == 3:
            return self - ValueType.Int + ValueType.VectorInt3
        if length == 4:
            return self - ValueType.Int + ValueType.VectorInt4
        raise "Unexpected length " + str(length)

    @always_inline
    fn typed_vector_element_type(self) -> ValueType:
        return self - ValueType.VectorInt + ValueType.Int

    @always_inline
    fn fixed_typed_vector_element_type(self) -> ValueType:
        return ((self - ValueType.VectorInt2) % 3) + ValueType.Int

    @always_inline
    fn fixed_typed_vector_element_size(self) -> Int:
        return int(((self - ValueType.VectorInt2) // 3).value) + 2

    @always_inline
    fn packed_type(self, bit_width: ValueBitWidth) -> UInt8:
        return (self << 2).value | bit_width.value

    @staticmethod
    @always_inline
    fn of[D: DType]() -> Self:
        @parameter
        if D == DType.uint8 or D == DType.uint16 or D == DType.uint32 or D == DType.uint64:
            return ValueType.UInt
        elif D == DType.float16 or D == DType.float32 or D == DType.float64:
            return ValueType.Float
        elif D == DType.bool:
            return ValueType.Bool
        else:
            return ValueType.Int
        

@value
@register_passable("trivial")
struct StackValue(CollectionElement):
    var value: UInt64
    var width: ValueBitWidth
    var type: ValueType

    alias Null = StackValue(0, ValueBitWidth.width8, ValueType.Null)

    @staticmethod
    @always_inline
    fn of[D: DType](v: Scalar[D]) -> Self:
        @parameter
        if D == DType.bool or D == DType.int8:
            var value = v.cast[DType.uint64]()
            return StackValue(value, ValueBitWidth.of(v), ValueType.of[D]())
        elif D == DType.uint8 or D == DType.int8:
            var value = bitcast[DType.uint8, 1](v).cast[DType.uint64]()
            return StackValue(value, ValueBitWidth.of(v), ValueType.of[D]())
        elif D == DType.uint16 or D == DType.int16 or D == DType.float16:
            var value = bitcast[DType.uint16](v)
            return StackValue(value.cast[DType.uint64](), ValueBitWidth.of(v), ValueType.of[D]())
        elif D == DType.uint32 or D == DType.int32 or D == DType.float32:
            var value = bitcast[DType.uint32](v)
            return StackValue(value.cast[DType.uint64](), ValueBitWidth.of(v), ValueType.of[D]())
        else:
            var v1 = bitcast[DType.uint64](v)
            return StackValue(v1, ValueBitWidth.of(v), ValueType.of[D]())

    @staticmethod
    @always_inline
    fn of(v: Int) -> Self:
        var value = bitcast[DType.uint64](Int64(v))
        return StackValue(value, ValueBitWidth.of(v), ValueType.Int)

    @always_inline
    fn stored_width(self, bit_width: ValueBitWidth = ValueBitWidth.width8) -> ValueBitWidth:
        if self.type.is_inline():
            return bit_width if self.width < bit_width else self.width
        return self.width

    @always_inline
    fn stored_packed_type(self, bit_width: ValueBitWidth = ValueBitWidth.width8) -> UInt8:
        return self.type.packed_type(self.stored_width(bit_width))

    @always_inline
    fn element_width(self, size: UInt64, index: Int) raises -> ValueBitWidth:
        if self.type.is_inline():
            return self.width
        for i in range(4):
            var width = UInt64(1 << i)
            var offset_loc = size + padding_size(size, width) + UInt64(index * width)
            var offset = offset_loc - self.as_uint()
            var bit_width = ValueBitWidth.of(int(offset))
            if (1 << bit_width.value).cast[DType.uint64]()[0] == width:
                return bit_width

        raise "Element with size " + String(size) + " and index " + String(index) + " is of unknown width"

    @always_inline
    fn as_float(self) -> Float64:
        return bitcast[DType.float64, 1](self.value)

    @always_inline
    fn as_int(self) -> Int64:
        return bitcast[DType.int64, 1](self.value)

    @always_inline
    fn as_uint(self) -> UInt64:
        return bitcast[DType.uint64, 1](self.value)

    fn to_value(self, byte_width: UInt64) -> SIMD[DType.uint8, 8]:
        var self_byte_width = (1 << self.width.value).cast[DType.uint64]()
        if self.type == ValueType.Float and self_byte_width != byte_width:
            if self_byte_width == 2:
                var v = bitcast[DType.float16](self.value.cast[DType.uint16]())
                if byte_width == 4:
                    return bitcast[DType.uint8, 8](bitcast[DType.uint32](v.cast[DType.float32]()).cast[DType.uint64]())
                else:
                    return bitcast[DType.uint8, 8](bitcast[DType.uint64](v.cast[DType.float64]()))
            elif self_byte_width == 4:
                var v = bitcast[DType.float32](self.value.cast[DType.uint32]())
                if byte_width == 2:
                    return bitcast[DType.uint8, 8](bitcast[DType.uint16](v.cast[DType.float16]()).cast[DType.uint64]())
                else:
                    return bitcast[DType.uint8, 8](bitcast[DType.uint64](v.cast[DType.float64]()))
            else:
                var v =  bitcast[DType.float64](self.value)
                if byte_width == 2:
                    return bitcast[DType.uint8, 8](bitcast[DType.uint16](v.cast[DType.float16]()).cast[DType.uint64]())
                else:
                    return bitcast[DType.uint8, 8](bitcast[DType.uint32](v.cast[DType.float32]()).cast[DType.uint64]())
        else:
            return bitcast[DType.uint8, 8](self.value)

    @always_inline
    fn is_float32(self) -> Bool:
        return self.type == ValueType.Float and self.width == ValueBitWidth.width32

    @always_inline
    fn is_offset(self) -> Bool:
        return not self.type.is_inline()

    fn __ne__(self, other: Self) -> Bool:
        return self.value != other.value 
            or self.width.value != other.width.value
            or self.type != other.type 
