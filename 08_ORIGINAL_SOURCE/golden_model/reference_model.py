def step(count, rst_n, enable, up):
    if not rst_n:
        return 0
    if not enable:
        return count
    return (count + 1) & 0xff if up else (count - 1) & 0xff


def run():
    assert step(123,0,1,1) == 0
    assert step(123,1,0,1) == 123
    assert step(10,1,1,1) == 11
    assert step(10,1,1,0) == 9
    assert step(255,1,1,1) == 0
    assert step(0,1,1,0) == 255
    for c in range(256):
        for en in (0,1):
            for up in (0,1):
                expected = c if not en else ((c+1)&255 if up else (c-1)&255)
                assert step(c,1,en,up) == expected
    print('D01 reference model PASS')

if __name__ == '__main__': run()
