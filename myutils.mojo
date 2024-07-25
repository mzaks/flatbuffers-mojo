fn print_buf(buf: List[UInt8], bpr: Int = 4):
    for i in range(len(buf)):
        print(str(buf[i]).rjust(3), end=", " if i % bpr != (bpr-1) else "\n")
