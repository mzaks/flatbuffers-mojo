from flatbuffers import *
from schema02_generated import *
from testing import *

def main():
    var builder = Builder()
    var o_person = Person.build(
        builder, name=StringRef("Maxim"), birthday=DateVO(1980, Month.Feb, 23)
    ) 
    var result = builder^.finish(o_person)
    print(result.__str__())
    var person = Person.as_root(result.unsafe_ptr())
    assert_equal(person.name(), "Maxim")
    var birthday = person.birthday()
    assert_equal(birthday.value().year(), 1980)
    assert_true(birthday.value().month() == Month.Feb)
    assert_equal(birthday.value().day(), 23)
    _=result^