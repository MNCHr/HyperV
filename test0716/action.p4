action set_initial_config (bit<8> progid, bit<8> stageid, bit<3> match_bitmap, bit<3> table_chain) {
    meta.vdp_metadata.inst_id = progid; 
    meta.vdp_metadata.stage_id = stageid;
    meta.vdp_metadata.match_chain_bitmap = match_bitmap;
    meta.vdp_metadata.table_chain = table_chain;        
}

action do_forward(bit<9> port) {
    standard_metadata.egress_spec = port;
}

action do_drop() {
    mark_to_drop();
}

action set_stage_and_bitmap(bit<48> action_bitmap, bit<3> match_bitmap, bit<8> next_stage, bit<8> next_prog) {
    meta.vdp_metadata.action_chain_bitmap = action_bitmap;
    meta.vdp_metadata.match_chain_bitmap = match_bitmap;
    meta.vdp_metadata.stage_id = next_stage;
    meta.vdp_metadata.inst_id = next_prog;
    meta.vdp_metadata.action_chain_id = meta.vdp_metadata.match_chain_result;
    meta.vdp_metadata.match_chain_result = 0;
}
    
action set_match_result(bit<48> match_result) {
    meta.vdp_metadata.match_chain_result = match_result|meta.vdp_metadata.match_chain_result;
}
    
action set_action_id(bit<48> match_result, bit<48> action_bitmap, bit<3> match_bitmap, bit<8> next_stage, bit<8> next_prog) {
    set_match_result(match_result);
    set_stage_and_bitmap(action_bitmap, match_bitmap, next_stage, next_prog);
}

action end(bit<8> next_prog) {
    set_action_id(0,0,0,0,next_prog);
}

action action_do(){

}

/*
-------------------------------------Arp_proxy_head---------------------------
*/
////for ethernet field
action mod_field_with_const_112(bit<112> value_112, bit<112> mask_112) {   
	hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~mask_112))|(value_112&mask_112);
}

action extract_temp_112(bit<112> temp_mask_112) {
    meta.temp_metadata.temp_112 = (hdr.hdr_112.buffer & temp_mask_112);
} //extract from buffer -> temp

action shift_112(bit<112> temp_mask_112, bit<8> l_shift, bit<8> r_shift) {
    meta.temp_metadata.temp_md_mask_112 = temp_mask_112 << l_shift;
    meta.temp_metadata.temp_md_mask_112 = temp_mask_112 >> r_shift;
    meta.temp_metadata.temp_112 = meta.temp_metadata.temp_112 << l_shift;
    meta.temp_metadata.temp_112 = meta.temp_metadata.temp_112 >> r_shift;
}
// shift temp, mask to indicate fields should be modified
// (l_shift, r_shift) = (n, 0) or (0, n)

action mod_field_with_field_112(bit<112> temp_mask_112, bit<8>l_shift, bit<8>r_shift){
    extract_temp_112(temp_mask_112);
    shift_112(temp_mask_112, l_shift, r_shift);
    hdr.hdr_112.buffer = (hdr.hdr_112.buffer & (~meta.temp_metadata.temp_md_mask_112))|(meta.temp_metadata.temp_112&meta.temp_metadata.temp_md_mask_112);    
}
// temp_mask=enabled with 1 to indicate field for extractioin 
//shift=difference between target field for modification and extracted field

////for ipv4 field
action mod_field_with_const_160_1(bit<160> value_160_1, bit<160> mask_160_1){
    hdr.hdr_160[0].buffer = (hdr.hdr_160[0].buffer&~mask_160_1)|(value_160_1&mask_160_1);
}

action extract_temp_160_1(bit<160> temp_mask_160_1) {
    meta.temp_metadata.temp_160_1 = (hdr.hdr_160[0].buffer & temp_mask_160_1);
} //extract from buffer -> temp

action shift_160_1(bit<160> temp_mask_160_1, bit<8> l_shift, bit<8> r_shift) {
    meta.temp_metadata.temp_md_mask_160_1 = temp_mask_160_1 << l_shift;
    meta.temp_metadata.temp_md_mask_160_1 = temp_mask_160_1 >> r_shift;
    meta.temp_metadata.temp_160_1 = meta.temp_metadata.temp_160_1 << l_shift;
    meta.temp_metadata.temp_160_1 = meta.temp_metadata.temp_160_1 >> r_shift;
}
// shift temp, mask to indicate fields should be modified
// (l_shift, r_shift) = (n, 0) or (0, n)

action mod_field_with_field_160_1(bit<160> temp_mask_160_1, bit<8>l_shift, bit<8>r_shift){
    extract_temp_160_1(temp_mask_160_1);
    shift_160_1(temp_mask_160_1, l_shift, r_shift);
    hdr.hdr_160[0].buffer = (hdr.hdr_160[0].buffer & (~meta.temp_metadata.temp_md_mask_160_1))|(meta.temp_metadata.temp_160_1 & meta.temp_metadata.temp_md_mask_160_1);
}
// temp_mask=enabled with 1 to indicate field for extractioin 
//shift=difference between target field for modification and extracted field

////for tcp field
action mod_field_with_const_160_2(bit<160> value_160_2, bit<160> mask_160_2){
    hdr.hdr_160[1].buffer = (hdr.hdr_160[1].buffer & ~mask_160_2)|(value_160_2 & mask_160_2);
}

action extract_temp_160_2(bit<160> temp_mask_160_2) {
    meta.temp_metadata.temp_160_2 = (hdr.hdr_160[1].buffer & temp_mask_160_2);
} //extract from buffer -> temp

action shift_160_2(bit<160> temp_mask_160_2, bit<8> l_shift, bit<8> r_shift) {
    meta.temp_metadata.temp_md_mask_160_2 = temp_mask_160_2 << l_shift;
    meta.temp_metadata.temp_md_mask_160_2 = temp_mask_160_2 >> r_shift;
    meta.temp_metadata.temp_160_2 = meta.temp_metadata.temp_160_2 << l_shift;
    meta.temp_metadata.temp_160_2 = meta.temp_metadata.temp_160_2 >> r_shift;
}
// shift temp, mask to indicate fields should be modified
// (l_shift, r_shift) = (n, 0) or (0, n)

action mod_field_with_field_160_2(bit<160> temp_mask_160_2, bit<8>l_shift, bit<8>r_shift){
    extract_temp_160_2(temp_mask_160_2);
    shift_160_2(temp_mask_160_2, l_shift, r_shift);
    hdr.hdr_160[1].buffer = (hdr.hdr_160[1].buffer & (~meta.temp_metadata.temp_md_mask_160_2))|(meta.temp_metadata.temp_160_2 & meta.temp_metadata.temp_md_mask_160_2);
}
// temp_mask=enabled with 1 to indicate field for extractioin 
//shift=difference between target field for modification and extracted field

////for arp field
action mod_field_with_const_224(bit<224> value_224, bit<224> mask_224){
    hdr.hdr_224.buffer = (hdr.hdr_224.buffer & (~mask_224))|(value_224 & mask_224);
}

action extract_temp_224(bit<224> temp_mask_224) {
    meta.temp_metadata.temp_224 = (hdr.hdr_224.buffer & temp_mask_224);
} 
//extract from buffer, put to temp

action shift_224(bit<224> temp_mask_224, bit<8> l_shift, bit<8> r_shift) {
    meta.temp_metadata.temp_md_mask_224 = temp_mask_224 << l_shift;
    meta.temp_metadata.temp_md_mask_224 = temp_mask_224 >> r_shift;
    meta.temp_metadata.temp_224 = meta.temp_metadata.temp_224 << l_shift;
    meta.temp_metadata.temp_224 = meta.temp_metadata.temp_224 >> r_shift;
} 
// shift temp, mask to indicate fields should be modified
// (l_shift, r_shift) = (n, 0) or (0, n)

action mod_field_with_field_224(bit<224> temp_mask_224, bit<8>l_shift, bit<8>r_shift){
    extract_temp_224(temp_mask_224);
    shift_224(temp_mask_224, l_shift, r_shift);
    hdr.hdr_224.buffer = (hdr.hdr_224.buffer & (~meta.temp_metadata.temp_md_mask_224))|(meta.temp_metadata.temp_224 & meta.temp_metadata.temp_md_mask_224);
} 
//temp_mask=enabled with 1 to indicate field for extraction 
//shift=difference between target field for modification and extracted field

action response(){
    standard_metadata.egress_spec = standard_metadata.ingress_port;
}

action arp_reply(   bit<224> mask_arp_sender_MAC, bit<8> l_shift_arp_sender_MAC, bit<8> r_shift_arp_sender_MAC, 
                    bit<224> mask_arp_send_ip , bit<8> l_shift_arp_send_ip, bit<8> r_shift_arp_send_ip,
                    bit<112> mask_ethernet_src, bit<8> l_shift_ethernet_src, bit<8> r_shift_ethernet_src,
                    bit<224> value_arp_sender_MAC,
                    bit<224> value_arp_sender_IP,
                    bit<112> value_ethernet_src,
                    bit<224> mask_arp_opcode ) {
    response();
    mod_field_with_field_224(mask_arp_sender_MAC, l_shift_arp_sender_MAC, r_shift_arp_sender_MAC);
    mod_field_with_field_224(mask_arp_send_ip, l_shift_arp_send_ip, r_shift_arp_send_ip);
    mod_field_with_field_112(mask_ethernet_src, l_shift_ethernet_src, r_shift_ethernet_src);
    mod_field_with_const_224(value_arp_sender_MAC, mask_arp_sender_MAC);
    mod_field_with_const_224(value_arp_sender_IP, mask_arp_send_ip);
    mod_field_with_const_112(value_ethernet_src, mask_ethernet_src);
    mod_field_with_const_224(2, mask_arp_opcode);
}
/*
-------------------------------------Arp_proxy_tail-------------------------
*/