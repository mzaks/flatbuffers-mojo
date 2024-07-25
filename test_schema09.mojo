from flatbuffers import *
from schema09_generated import *
from testing import *
from myutils import print_buf


def main():
    var builder = Builder()
    var o_t2 = T2.build(builder)
    var o_t1 = T1.build(
        builder, 
        name=StringRef("Max"),
        sibling=o_t2,
    )
    var result = builder^.finish(o_t1)
    print_buf(result, 4)
    var t1 = T1.as_root(result.unsafe_ptr())
    
    assert_equal(t1.name(), "Max")
    assert_equal(t1.sibling().value(), 0)
    assert_equal(t1.sibling().has_flags(), False)
    assert_equal(t1.optinal_sibling() is None, True)
    assert_equal(t1.nickname(), "")

    _ = result^
