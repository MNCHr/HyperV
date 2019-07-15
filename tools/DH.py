from scapy.all import *
import sys, os
class DH(Packet):
    name = "DH_n"
    fields_desc = [
        BitField("a",0,2)
    ]
