from flatbuffers import *
from schema08_generated import *
from testing import *
from myutils import print_buf


def main():
    var builder = Builder()
    var o_scalar_stuff = ScalarStuff.build(
        builder, 
        just_i8 = -13,
        just_u8 = 13,
        just_i16 = -345,
        just_u16 = 456,
        just_i32 = -45678,
        just_u32  = 123456,
        just_i64 = -1234567,
        just_u64 = 3456789,
        just_f32 = 0.1,
        just_f64 = 0.3,
        just_bool = True,
        just_enum = OptionalByte(1),
        maybe_f32 = Float32(0.7),
    )
    var result = builder^.finish(o_scalar_stuff)
    print_buf(result, 4)
    var scalar_stuff = ScalarStuff.as_root(result.unsafe_ptr())
    
    assert_equal(scalar_stuff.default_bool(), True)
    assert_equal(scalar_stuff.default_enum().value, 1)
    assert_equal(scalar_stuff.default_f32(), 42)
    assert_equal(scalar_stuff.default_f64(), 42)
    assert_equal(scalar_stuff.default_i16(), 42)
    assert_equal(scalar_stuff.default_i32(), 42)
    assert_equal(scalar_stuff.default_i64(), 42)
    assert_equal(scalar_stuff.default_i8(), 42)
    assert_equal(scalar_stuff.default_u16(), 42)
    assert_equal(scalar_stuff.default_u32(), 42)
    assert_equal(scalar_stuff.default_u64(), 42)
    assert_equal(scalar_stuff.default_u8(), 42)
    assert_equal(scalar_stuff.just_bool(), True)
    assert_equal(scalar_stuff.just_enum().value, 1)
    assert_equal(scalar_stuff.just_f32(), 0.1)
    assert_equal(scalar_stuff.just_f64(), 0.3)
    assert_equal(scalar_stuff.just_i16(), -345)
    assert_equal(scalar_stuff.just_i32(), -45678)
    assert_equal(scalar_stuff.just_i64(), -1234567)
    assert_equal(scalar_stuff.just_i8(), -13)
    assert_equal(scalar_stuff.just_u16(), 456)
    assert_equal(scalar_stuff.just_u32(), 123456)
    assert_equal(scalar_stuff.just_u64(), 3456789)
    assert_equal(scalar_stuff.just_u8(), 13)
    assert_true(scalar_stuff.maybe_bool() is None)
    assert_true(scalar_stuff.maybe_enum() is None)
    assert_true(scalar_stuff.maybe_f32().value() == Float32(0.7))
    assert_true(scalar_stuff.maybe_f64() is None)
    assert_true(scalar_stuff.maybe_i16() is None)
    assert_true(scalar_stuff.maybe_i32() is None)
    assert_true(scalar_stuff.maybe_i64() is None)
    assert_true(scalar_stuff.maybe_i8() is None)
    assert_true(scalar_stuff.maybe_u16() is None)
    assert_true(scalar_stuff.maybe_u32() is None)
    assert_true(scalar_stuff.maybe_u64() is None)
    assert_true(scalar_stuff.maybe_u8() is None)


    _ = result^
