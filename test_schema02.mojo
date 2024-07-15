from flatbuffers import *
from schema02_generated import *
from testing import *

def main():
    var builder = Builder()
    var o_person = Person.build(
        builder, name=str("Maxim"), birthday=DateVO(1980, Month.Feb, 23)
    )
    var result = builder^.finish(o_person)
    var buf = result.get[0, DTypePointer[DType.uint8]]()
    var size = result.get[1, Int]()
    for i in range(size):
        print(buf[i], end=", " if i % 4 != 3 else "\n")
    var person = Person.as_root(buf)
    assert_equal(person.name(), "Maxim")
    var birthday = person.birthday()
    assert_equal(birthday.value().year(), 1980)
    assert_true(birthday.value().month() == Month.Feb)
    assert_equal(birthday.value().day(), 23)