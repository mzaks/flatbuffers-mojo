fn print_buf(buf: List[UInt8], bpr: Int = 4):
    for i in range(len(buf)):
        print(buf[i], end=", " if i % bpr != (bpr-1) else "\n")
