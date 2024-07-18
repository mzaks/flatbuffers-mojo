from flexbuffers.data_types import StackValue


fn main():
    # var sv = StackValue.of(Float16(0.1))
    # print(hex(sv.value))

    # sv = StackValue.of(Float32(0.1))
    # print(hex(sv.value))

    # sv = StackValue.of(Float64(0.1))
    # print(sv.to_value(4))

    var sv = StackValue.of(Float16(0.5))
    print(hex(sv.value))
    print(sv.to_value(8))

    sv = StackValue.of(Float32(0.5))
    print(hex(sv.value))
    print(sv.to_value(8))

    sv = StackValue.of(Float64(0.5))
    print(hex(sv.value))
    print(sv.to_value(8))
