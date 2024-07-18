from flatbuffers import *
from schema01_generated import *
from testing import *
from myutils import print_buf


def main():
    var builder = Builder()
    var o_person = Person.build(builder, name=StringRef("Maxim"), age=43)
    var result = builder^.finish(o_person)
    print_buf(result)
    var person = Person.as_root(result.unsafe_ptr())
    assert_equal(person.name(), "Maxim")
    assert_equal(person.age(), 43)
    _ = result^
