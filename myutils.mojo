fn print_buf(buf: List[UInt8]):
    for i in range(len(buf)):
        print(buf[i], end=", " if i % 4 != 3 else "\n")
