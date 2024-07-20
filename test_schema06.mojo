from flatbuffers import *
from schema06_generated import *
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
    
    var o_alex = Person.build(builder, name=StringRef("Alex"))
    var o_leo = Person.build(builder, name=StringRef("Leo"))

    var o_person = Person.build(
        builder,
        name=StringRef("Maxim"),
        birthday=DateVO(1980, Month.Feb, 23),
        address=o_address,
        nicknames=nicknames, 
        important_dates=List(DateVO(2020, Month.Jan, 13), DateVO(2012, Month.Oct, 15)),
        important_months=List(Month.May, Month.Sep, Month.Nov, Month.Jun),
        lucky_numbers=List[Int32](1, 2, 3, 7, 89),
        friends=List(o_alex, o_leo)
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

    assert_equal(person.important_dates_length(), 2)
    assert_equal(person.important_dates(0).year(), 2020)
    assert_equal(person.important_dates(0).month() == Month.Jan, True)
    assert_equal(person.important_dates(0).day(), 13)
    assert_equal(person.important_dates(1).year(), 2012)
    assert_equal(person.important_dates(1).month() == Month.Oct, True)
    assert_equal(person.important_dates(1).day(), 15)

    assert_equal(person.important_months_length(), 4)
    assert_equal(person.important_months(0) == Month.May, True)
    assert_equal(person.important_months(1) == Month.Sep, True)
    assert_equal(person.important_months(2) == Month.Nov, True)
    assert_equal(person.important_months(3) == Month.Jun, True)

    assert_equal(person.lucky_numbers_length(), 5)
    assert_equal(person.lucky_numbers(0), 1)
    assert_equal(person.lucky_numbers(1), 2)
    assert_equal(person.lucky_numbers(2), 3)
    assert_equal(person.lucky_numbers(3), 7)
    assert_equal(person.lucky_numbers(4), 89)

    assert_equal(person.friends_length(), 2)
    assert_equal(person.friends(0).name(), "Alex")
    assert_equal(person.friends(1).name(), "Leo")
    _ = result^
