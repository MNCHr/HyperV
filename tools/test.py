#!/usr/bin/python
import sys
import os

if len(sys.argv)==1:
    print "Enter the filename you want to convert. Example: python test.py ~/mnc/rule.txt"
    exit(1)

in_f=open(sys.argv[1], 'r')
out_f=open('commandnew.txt', 'a')

lines = in_f.readlines()
for line in lines:
    item = line.split(" ")
    read_dmac = item[item.index("forward")+1]
    e_dmac=read_dmac[-4:]
    a_id=read_dmac[-1:]
    w_data="table_add table_config_at_initial set_initial_config 0 0 0 => 1 0 4\ntable_add table_header_match_stage1 set_action_id 1 0 0x%s00000000000000000000000000000000000000000000000000000000&&&0xFFFF00000000000000000000000000000000000000000000000000000000 => 0x%s00000000 0x2000000000 0 0 0xFF 1\ntable_add table_mod_std_meta_stage1 do_forward 0x200000000 => 2" %(e_dmac, a_id)
    out_f.write(w_data)

in_f.close()
out_f.close()
