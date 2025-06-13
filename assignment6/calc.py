#!/usr/bin/env python3

import re

from scapy.all import *

class P4grad(Packet):
    name = "P4grad"
    fields_desc = [ StrFixedLenField("P", "P", length=1),
                    StrFixedLenField("Four", "4", length=1),
                    XByteField("version", 0x01),
                    ByteField("op", 0),
                    IntField("gradient_value", 0)]

bind_layers(Ether, P4grad, type=0x1234)

class NumParseError(Exception):
    pass

class OpParseError(Exception):
    pass

class Token:
    def __init__(self,type,value = None):
        self.type = type
        self.value = value

def num_parser(s, i, ts):
    pattern = "^\s*([0-9]+)\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError('Expected number literal.')


def op_parser(s, i, ts):
    pattern = "^\s*([-+&|^])\s*"
    match = re.match(pattern,s[i:])
    if match:
        ts.append(Token('num', match.group(1)))
        return i + match.end(), ts
    raise NumParseError("Expected binary operator '-', '+', '&', '|', or '^'.")


def make_seq(p1, p2):
    def parse(s, i, ts):
        i,ts2 = p1(s,i,ts)
        return p2(s,i,ts2)
    return parse

def get_if():
    ifs=get_if_list()
    iface= "enx0c37965f8a10" # "h1-eth0"
    #for i in get_if_list():
    #    if "eth0" in i:
    #        iface=i
    #        break;
    #if not iface:
    #    print("Cannot find eth0 interface")
    #    exit(1)
    #print(iface)
    return iface

def main():

    p = make_seq(num_parser, make_seq(op_parser,num_parser))
    s = ''
    #iface = get_if()
    iface = "enx0c37965f8a10"

    while True:
        s = input('> ')
        if s == "quit":
            break
        try:
            s = float(s)
            #print(s)
            sign_bit = 1 if s < 0 else 0
            mag = int(abs(s) * (1 << 31))
            if (sign_bit == 1):
                mag = (~mag)  & ((1 << 32) - 1)
            print(mag)
            pkt = Ether(dst='e4:5f:01:87:32:1a', type=0x1234) / P4grad(op=1,
                                              gradient_value = mag)

            pkt = pkt/' '

            pkt.show()
            resp = srp1(pkt, iface=iface,timeout=5, verbose=False)
            resp.show()
            if resp:
                p4grad=resp[P4grad]
                if p4grad:
                    x = p4grad.gradient_value
                    #print(x)
                    if (x & (1 << 31)):
                        x -= 1 << 32
                    #print(x)
                    x = x / (1 << 31)
                    print(x)
                else:
                    print("cannot find P4calc header in the packet")
            else:
                print("Didn't receive response")
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()


