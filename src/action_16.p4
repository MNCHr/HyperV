#ifndef _ACTIONS_
#define _ACTIONS_

action do_forward(bit<9> port) {
    standard_metadata.egress_spec = port;
}

action do_drop() {
    mark_to_drop();
}

/////////////////////////need to declare/////////////////////
struct temp_metadata_t {
    bit<112> temp_112;
    bit<160> temp_160;
    bit<224> temp_224;
}
struct metadata {
    temp_metadata_t temp_metadata;
}
/////////////////////////////////////////////////////////////

///is 'hdr' load header ?

action extract_112(bit<112> temp_112) {
    temp_metadata.temp_112 = (hdr.hdr_112.buffer & mask_112);
}
action shift_112(bit<7> l_shift, bit<7> r_shift) {
    temp_metadata.temp_112<<l_shift;
    temp_metadata.temp_112>>r_shift;
}
//for ethernet field
action mod_field_with_const_112(bit<112> value_112, bit<112> mask_112){
    (hdr.hdr_112.buffer & ~mask_112) | value_112;
}
action mod_field_with_field_112(bit<112> value_112, bit<112> mask_112, bit<112> temp_112, bit<112> temp_mask_112){
    extract_112(temp_112, temp_mask_112);

}

//for ipv4 field
action mod_field_160_1(bit<160> value_160_1, bit<160> mask_160_1){
    (hdr.hdr_160[0].buffer & ~mask_160_1) | value_160_1;
}
//for tcp field
action mod_field_160_2(bit<160> value_160_2, bit<160> mask_160_2){
    (hdr.hdr_160[1].buffer & ~mask_160_2) | value_160_2;
}
//for arp field
action mod_field_224(bit<224> value_224, bit<224> mask_224) {
    (hdr.hdr_224.buffer & ~mask_224) | value_224;
}

action response(){
    standard_metadata.egress_spec = standard_metadata.ingress_port;
}

action arp_reply(bit<224> value_arp_sender_MAC ) {
    reponse();
    mod_field_224(value_arp_sender_MAC,mask_arp_target_MAC);
    mod_field_224(value_arp_send_IP,mask_arp_target_IP);
    mod_field_112(value_ethernet_src,mask_ethernet_dest);
    mod_field_224(value_arp_MAC,mask_arp_sender_MAC);
    mod_field_224(value_IP,mask_arp_sender_IP);
    mod_field_112(value_etheernet_MAC,mask_ethernet_src);
    mod_field_224(2,mask_arp_opcode);
}
/*

*/



 action set_initial_config(bit<8> progid, bit<8> stageid, bit<3> match_bitmap, bit<3> table_chain) {
    meta.vdp_metadata.inst_id = progid; 
    meta.vdp_metadata.stage_id = stageid;
    meta.vdp_metadata.match_chain_bitmap = match_bitmap;
    meta.vdp_metadata.table_chain = table_chain;        
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

#endif