from flatbuffers import *
from schema04_generated import *
from testing import *
from myutils import print_buf


def main():
    var builder = Builder()
    var o_address = PostalAddress.build(
        builder,
        city=StringRef("Berlin"),
        zip=StringRef("12345"),
        country=StringRef("Germany"),
    )
    var nicknames = List[Offset]()
    for nn in List("max", "mzaks", "iceX33"):
        nicknames.append(builder.prepend(StringRef(nn[])))
    
    var o_person = Person.build(
        builder,
        name=StringRef("Maxim"),
        birthday=DateVO(1980, Month.Feb, 23),
        address=o_address,
        nicknames=nicknames
    )
    var result = builder^.finish(o_person)
    print_buf(result, 4)
    var person = Person.as_root(result.unsafe_ptr())
    assert_equal(person.name(), "Maxim")
    var birthday = person.birthday()
    assert_equal(birthday.value().year(), 1980)
    assert_true(birthday.value().month() == Month.Feb)
    assert_equal(birthday.value().day(), 23)

    var address = person.address()
    assert_equal(address.value().city(), "Berlin")
    assert_equal(address.value().zip(), "12345")
    assert_equal(address.value().country(), "Germany")
    assert_equal(address.value().street(), "")

    assert_equal(person.nicknames_length(), 3)
    assert_equal(person.nicknames(0), "max")
    assert_equal(person.nicknames(1), "mzaks")
    assert_equal(person.nicknames(2), "iceX33")
    _ = result^
