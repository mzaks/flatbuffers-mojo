# automatically generated by the FlatBuffers compiler, do not modify
import flatbuffers

@value
struct Month(EqualityComparable):
    var value: UInt8

    alias Jan = Month(0)
    alias Feb = Month(1)
    alias Mar = Month(2)
    alias Apr = Month(3)
    alias May = Month(4)
    alias Jun = Month(5)
    alias Jul = Month(6)
    alias Aug = Month(7)
    alias Sep = Month(8)
    alias Oct = Month(9)
    alias Nov = Month(10)
    alias Dec = Month(11)

    fn __eq__(self, other: Month) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Month) -> Bool:
        return self.value != other.value


@value
struct Date:
    var _buf: UnsafePointer[UInt8]
    var _pos: Int

    fn day(self) -> UInt8:
        return flatbuffers.read[DType.uint8](self._buf, int(self._pos) + 0)

    fn month(self) -> Month:
        return flatbuffers.read[DType.uint8](self._buf, int(self._pos) + 1)

    fn year(self) -> UInt16:
        return flatbuffers.read[DType.uint16](self._buf, int(self._pos) + 2)

    @staticmethod
    fn build(
        mut builder: flatbuffers.Builder,
        *,
        day: UInt8,
        month: Month,
        year: UInt16,
    ):
        builder.prep(2, 4)
        builder.prepend[DType.uint16](year)
        builder.prepend[DType.uint8](month.value)
        builder.prepend[DType.uint8](day)

@value
struct DateVO:
    var year: UInt16
    var month: Month
    var day: UInt8

@value
struct PostalAddress:
    var _buf: UnsafePointer[UInt8]
    var _pos: Int

    fn street(self) -> StringRef:
        return flatbuffers.field_string(self._buf, int(self._pos), 4)

    fn zip(self) -> StringRef:
        return flatbuffers.field_string(self._buf, int(self._pos), 6)

    fn city(self) -> StringRef:
        return flatbuffers.field_string(self._buf, int(self._pos), 8)

    fn country(self) -> StringRef:
        return flatbuffers.field_string(self._buf, int(self._pos), 10)

    @staticmethod
    fn as_root(buf: UnsafePointer[UInt8]) -> PostalAddress:
        return PostalAddress(buf, flatbuffers.read_offset_as_int(buf, 0))

    @staticmethod
    fn build(
        mut builder: flatbuffers.Builder,
        *,
        street: Optional[StringRef] = None,
        zip: Optional[StringRef] = None,
        city: Optional[StringRef] = None,
        country: Optional[StringRef] = None,
    ) -> flatbuffers.Offset:
        var _street: Optional[flatbuffers.Offset] = None
        if street is not None:
            _street = builder.prepend(street.value())
        var _zip: Optional[flatbuffers.Offset] = None
        if zip is not None:
            _zip = builder.prepend(zip.value())
        var _city: Optional[flatbuffers.Offset] = None
        if city is not None:
            _city = builder.prepend(city.value())
        var _country: Optional[flatbuffers.Offset] = None
        if country is not None:
            _country = builder.prepend(country.value())
        builder.start_object(4)
        if _street is not None:
            builder.prepend(_street.value())
            builder.slot(0)
        if _zip is not None:
            builder.prepend(_zip.value())
            builder.slot(1)
        if _city is not None:
            builder.prepend(_city.value())
            builder.slot(2)
        if _country is not None:
            builder.prepend(_country.value())
            builder.slot(3)
        return builder.end_object()

@value
struct Person:
    var _buf: UnsafePointer[UInt8]
    var _pos: Int

    fn name(self) -> StringRef:
        return flatbuffers.field_string(self._buf, int(self._pos), 4)

    fn birthday(self) -> Optional[Date]:
        var o = flatbuffers.field_struct(self._buf, int(self._pos), 8)
        if o:
            return Date(self._buf, o.take())
        return None

    fn address(self) -> Optional[PostalAddress]:
        var o = flatbuffers.field_table(self._buf, int(self._pos), 10)
        if o:
            return PostalAddress(self._buf, o.take())
        return None

    fn nicknames(self, i: Int) -> StringRef:
        return flatbuffers.string(self._buf, flatbuffers.field_vector(self._buf, int(self._pos), 12) + i * 4)

    fn nicknames_length(self) -> Int:
        return flatbuffers.field_vector_len(self._buf, int(self._pos), 12)

    @staticmethod
    fn as_root(buf: UnsafePointer[UInt8]) -> Person:
        return Person(buf, flatbuffers.read_offset_as_int(buf, 0))

    @staticmethod
    fn build(
        mut builder: flatbuffers.Builder,
        *,
        name: Optional[StringRef] = None,
        birthday: Optional[DateVO] = None,
        address: Optional[flatbuffers.Offset] = None,
        nicknames: List[flatbuffers.Offset] = List[flatbuffers.Offset](),
    ) -> flatbuffers.Offset:
        var _name: Optional[flatbuffers.Offset] = None
        if name is not None:
            _name = builder.prepend(name.value())
        var _nicknames: Optional[flatbuffers.Offset] = None
        if len(nicknames) > 0:
            builder.start_vector(4, len(nicknames), 4)
            for o in nicknames.__reversed__():
                builder.prepend(o[])
            _nicknames = builder.end_vector(len(nicknames))

        builder.start_object(5)
        if _name is not None:
            builder.prepend(_name.value())
            builder.slot(0)
        if birthday is not None:
            Date.build(
                builder,
                day=birthday.value().day,
                month=birthday.value().month,
                year=birthday.value().year,
            )
            builder.slot(2)
        if address is not None:
            builder.prepend(address.value())
            builder.slot(3)
        if _nicknames is not None:
            builder.prepend(_nicknames.value())
            builder.slot(4)
        return builder.end_object()

