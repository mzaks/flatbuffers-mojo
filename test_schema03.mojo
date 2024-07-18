from flatbuffers import *
from schema03_generated import * 
from testing import *

def main():
    var builder = Builder()
    var o_address = PostalAddress.build(
        builder,
        city=StringRef("Berlin"),
        zip=StringRef("12345"),
        country=StringRef("Germany"),
    )
    var o_person = Person.build(
        builder, 
        name=StringRef("Maxim"), 
        birthday=DateVO(1980, Month.Feb, 23),
        address=o_address,
    )
    var result = builder^.finish(o_person)
    print(result.__str__())
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
    _=result^