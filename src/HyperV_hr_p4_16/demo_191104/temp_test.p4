#include <core.p4>
#include <v1model.p4>
#include "headers.p4"
#include "metadata.p4"
#include "parser.p4"
#include "define.p4"

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) { 

	action set_initial_config (bit<8> inst_id, bit<8> stage_id, bit<3> match_chain_bitmap, bit<4> header_chain_bitmap) { //need-to-check
		meta.vdp_metadata.inst_id = inst_id; //어떤 프로그램이 설치되었는지
		meta.vdp_metadata.stage_id = stage_id;
		meta.vdp_metadata.match_chain_bitmap = match_chain_bitmap; //
		meta.vdp_metadata.header_chain_bitmap = header_chain_bitmap; // related to headers       
	}

    table table_config_at_initial {
        key = {
            hdr.desc_hdr.vdp_id: exact;
        }
        actions = {
            set_initial_config();
        }
        const entries = {
            1 : set_initial_config(1,1,0b100,0b0001);  //1 = l2 forwarding
            2 : set_initial_config(2,2,0b100,0b0010);  //2 = l3 router
            3 : set_initial_config(3,3,0b101,0b0110);  //3 = TCP fw
        }
    }



    // stage entering
    action set_action_id(bit<48> action_bitmap) { 
        meta.vdp_metadata.action_chain_bitmap = action_bitmap;
    }

    table table_header_match_112_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_112.buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        const entries = {
            (1, 112w0x00000000000A0000000000000000 &&& 112w0xFFFFFFFFFFFF0000000000000000) : set_action_id(0x000000000001);
            
        }
    }

    table table_header_match_160_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_160[0].buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        const entries = { 
            (2, 160w0x000000000000000000000000000000000000000A &&& 160w0x00000000000000000000000000000000FFFFFFFF) : set_action_id(0x000000000111);
            
        }
    }

    table table_header_match_160_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_160[0].buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        const entries = { //A면 pass, B면 drop
            (3, 160w0x0000000000000000000000000000000A0000000A &&& 160w0x000000000000000000000000FFFFFFFFFFFFFFFF) : set_action_id(0x000000000000);
            (3, 160w0x0000000000000000000000000000000B0000000B &&& 160w0x000000000000000000000000FFFFFFFFFFFFFFFF) : set_action_id(0x800000000000);
            
        }
    }
    table table_header_match_161_stage3 { //161 : tcp
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_160[1].buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        const entries = { //A 면 pass, B면 drop
            (3, 160w0x000A000A00000000000000000000000000000000 &&& 160w0xFFFFFFFF00000000000000000000000000000000) : set_action_id(0x000000000000);
            (3, 160w0x000B000B00000000000000000000000000000000 &&& 160w0xFFFFFFFF00000000000000000000000000000000) : set_action_id(0x800000000000);
            
        }
    }

    //? escape? 

    table table_std_meta_match_ingress_port_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            standard_metadata.ingress_port : ternary ;
        }
        actions = {
            set_action_id();
        }
        const entries = {
            (3, 3) : set_action_id(0x000000000001);
        }
    }
/////primitive actions + tables + entries /////
//bit mask for each field of each header 
#define def_mask_112_dstAddr  112w0xFFFFFFFFFFFF0000000000000000
#define def_mask_112_srcAddr  112w0x000000000000FFFFFFFFFFFF0000
#define def_mask_112_bothAddr 112w0xFFFFFFFFFFFFFFFFFFFFFFFF0000
/// for ip header
#define def_mask_160_srcAddr 160w0x000000000000000000000000FFFFFFFF00000000
#define def_mask_160_dstAddr 160w0x00000000000000000000000000000000FFFFFFFF
/// for tcp header
#define def_mask_161_srcPort 160w0xFFFF000000000000000000000000000000000000
#define def_mask_161_dstPort 160w0x0000FFFF00000000000000000000000000000000
/// for arp header
#define def_mask_224_opcode  224w0x000000000000FFFF0000000000000000000000000000000000000000

#define def_mask_224_srcMAC  224w0x0000000000000000FFFFFFFFFFFF0000000000000000000000000000
#define def_mask_224_dstMAC  224w0x000000000000000000000000000000000000FFFFFFFFFFFF00000000
#define def_mask_224_bothMAC 224w0x0000000000000000FFFFFFFFFFFF00000000FFFFFFFFFFFF00000000

#define def_mask_224_srcIP   224w0x0000000000000000000000000000FFFFFFFF00000000000000000000
#define def_mask_224_dstIP   224w0x000000000000000000000000000000000000000000000000FFFFFFFF
#define def_mask_224_bothIP  224w0x0000000000000000000000000000FFFFFFFF000000000000FFFFFFFF

//bit mask for primitive action
#define BIT_MASK_DO_FORWARD 1 // 1st
#define BIT_MASK_MOD_112_DSTADDR 1<<1
#define BIT_MASK_MOD_112_SRCADDR 1<<2
#define BIT_MASK_MOD_160_DSTADDR 1<<3 //unused
#define BIT_MASK_MOD_160_SRCADDR 1<<4 //unused
#define BIT_MASK_MOD_161_DSTADDR 1<<5 //unused
#define BIT_MASK_MOD_161_SRCADDR 1<<6 //unused

#define BIT_MASK_MOD_224_OPCODE_n_RESPONSE 1<< // arp

#define BIT_MASK_EXTRACT_n_SHIFT_112_SRCADDR 1<< //Extract from src & Shift to dst
#define BIT_MASK_MOD_112_BOTHADDR 1<<
#define BIT_MASK_EXTRACT_n_SHIFT_224_SRCMAC 1<<
#define BIT_MASK_MOD_224_BOTHMAC 1<<
#define BIT_MASK_EXTRACT_n_SHIFT_224_SRCIP 1<<
#define BIT_MASK_MOD_224_BOTHIP 1<<


#define BIT_MASK_DROP 1<<47

	action action_forward(bit<9> port) { // 1st primitive
		standard_metadata.egress_spec = port;
	}

    table table_action_forward_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        const entries = {
            1 : action_forward(1); //daechung
        }
    }
    table table_action_forward_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        const entries = {
            2 : action_forward(2); //daechung
        }
    }
    table table_action_forward_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        const entries = {
            3 : action_forward(3); //daechung
        }
    }

    action action_mod_112_dstAddr(bit<112> value_112_dstAddr) { // 2nd primitive , error-prone?
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_dstAddr))|(value_112_dstAddr&def_mask_112_dstAddr);
    }
    table table_action_mod_112_dstAddr_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        const entries = {
            2 : action_mod_112_dstAddr (0x00000000010000000000000000);
        }
    }
    table table_action_mod_112_dstAddr_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        const entries = {
            2 : action_mod_112_dstAddr (0x00000000020000000000000000);
        }
    }
    table table_action_mod_112_dstAddr_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        const entries = {
            3 : action_mod_112_dstAddr (0x00000000030000000000000000);
        }
    }

    action action_mod_112_srcAddr(bit<112> value_112_srcAddr) { // 3rd primitive, error-prone?
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_srcAddr))|(value_112_srcAddr&def_mask_112_srcAddr);
    }
    table table_action_mod_112_srcAddr_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        const entries = {
            2 : action_mod_112_srcAddr(0x0000000000000000000000010000);
        }
    }
    table table_action_mod_112_srcAddr_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        const entries = {
            2 : action_mod_112_srcAddr(0x0000000000000000000000010000);
        }
    }
    table table_action_mod_112_srcAddr_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        const entries = {
            2 : action_mod_112_srcAddr(0x0000000000000000000000010000);
        }
    }
    
    action action_mod_224_opcode_n_response(bit<224> value_224_opcode) {
        hdr.hdr_224.buffer = (hdr.hdr_224.buffer&(~def_mask_224_opcode))|(value_224_opcode&def_mask_224_opcode);
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
    table table_action_response {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_224_opcode_n_response();
        }
        const entries = {
            4 : action_mod_224_opcode_n_response();
        }
    }

bit<112> temp_extract_112 // variable, is this possible ?
    action action_extract_n_shift_112_srcAddr() { // is this possible ?
        temp_112 = (hdr.hdr_112.buffer & def_mask_112_srcAddr);
        temp_112 = temp_112 << 48;
        meta.temp_mdetadata.temp_112 = temp_112;
    }
    table table_action_extract_n_shift_112_srcAddr {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_extract_n_shift_112_srcAddr();
        }
        const entries = {
            4 : action_extract_n_shift_112_srcAddr();
        }
    }    //cont'//
    action action_mod_112_bothAddr (bit<112> value_112_srcAddr) { // -th primitive, error-prone?
        meta.temp_mdetadata.temp_112 = 0;
        meta.temp_mdetadata.temp_112 = (meta.temp_mdetadata.temp_112 | value_112_srcAddr); //(pre-process) merge to md
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_bothAddr))| meta.temp_mdetadata.temp_112;
    }
    table table_action_mod_112_bothAddr_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_bothAddr();
        }
        const entries = { 
            // #define def_mask_112_srcAddr  112w0x000000000000FFFFFFFFFFFF0000
            4 : action_mod_112_bothAddr(0x00000000000000000000000A0000);
        }
    }

bit<224> temp_extract_224 // variable, is this possible ?
    action action_extract_n_shift_224_srcMAC() { // is this possible ?
        temp_224 = (hdr.hdr_224.buffer & def_mask_224_srcMAC);
        temp_224 = temp_224 >> 80;
        meta.temp_mdetadata.temp_224 = temp_224;
    }
    table table_action_extract_n_shift_224_srcMAC {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_extract_n_shift_224_srcMAC();
        }
        const entries = {
            4 : action_extract_n_shift_224_srcMAC();
        }
    }    //cont'//
    action action_mod_224_bothMAC (bit<224> value_224_srcMAC) { // -th primitive, error-prone?
        meta.temp_mdetadata.temp_224 = 0
        meta.temp_mdetadata.temp_224 = (meta.temp_mdetadata.temp_224 | value_224_srcMAC); //(pre-process) merge to md
        hdr.hdr_224.buffer = (hdr.hdr_224.buffer&(~def_mask_224_bothMAC))| meta.temp_mdetadata.temp_224;
    }
    table table_action_mod_224_bothMAC_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_224_bothMAC();
        }
        const entries = { 
            // #define def_mask_224_bothMAC 224w0x0000000000000000FFFFFFFFFFFF00000000FFFFFFFFFFFF00000000
            4 : action_mod_224_bothMAC(0x000000000000000000000000000A0000000000000000000000000000);
        }
    }

    action action_extract_n_shift_224_srcIP() { // is this possible ?
        temp_224 = (hdr.hdr_224.buffer & def_mask_224_srcIP);
        temp_224 = temp_224 >> 80;
        meta.temp_mdetadata.temp_224 = temp_224;
    }
    table table_action_extract_n_shift_224_srcIP {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_extract_n_shift_224_srcIP();
        }
        const entries = {
            4 : action_extract_n_shift_224_srcIP();
        }
    }    //cont'//
    action action_mod_224_bothIP (bit<224> value_224_srcIP) { // -th primitive, error-prone?
        meta.temp_mdetadata.temp_224 = 0
        meta.temp_mdetadata.temp_224 = (meta.temp_mdetadata.temp_224 | value_224_srcIP); //(pre-process) merge to md
        hdr.hdr_224.buffer = (hdr.hdr_224.buffer&(~def_mask_224_bothIP))| meta.temp_mdetadata.temp_224;
    }
    table table_action_mod_224_bothIP_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_224_bothIP();
        }
        const entries = { 
            // #define def_mask_224_bothIP  224w0x0000000000000000000000000000FFFFFFFF000000000000FFFFFFFF
            4 : action_mod_224_bothIP(0x00000000000000000000000000000000000A00000000000000000000);
        }
    }


    action action_drop() { //48th primitive
		mark_to_drop(standard_metadata);
	}
    
    table table_action_drop_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            3 : action_drop();
        }
    }
    table table_action_drop_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            3 : action_drop();
        }
    }
    table table_action_drop_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            3 : action_drop();
        }
    }
    

/////////////////////////////////////////////////////////////////
    apply {
        if (PROG_ID ==0) {
            table_config_at_initial.apply();
        }
        if (PROG_ID !=0) {
            if(meta.vdp_metadata.stage_id == CONST_STAGE_1){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&1 != 0)
                        table_header_match_112_stage1.apply();
                    //   table_header_match_112_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&2 != 0)
                    //   table_header_match_160_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&4 != 0)
                    //   table_header_match_160_2_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&8 != 0)
                    //   table_header_match_224_1_stage1.apply();
                }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
				// 		table_std_meta_match_stage1.apply();
				// }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
				// 		table_user_meta_stage1.apply();
				// }
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage1.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage1.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage1.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage1.apply();						
	            }
                
            }

            if(meta.vdp_metadata.stage_id == CONST_STAGE_2){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&2 != 0)
                        table_header_match_160_stage2.apply();
                    //   table_header_match_112_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&2 != 0)
                    //   table_header_match_160_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&4 != 0)
                    //   table_header_match_160_2_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&8 != 0)
                    //   table_header_match_224_1_stage1.apply();
                }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
				// 		table_std_meta_match_stage1.apply();
				// }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
				// 		table_user_meta_stage1.apply();
				// }
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage2.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage2.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage2.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage2.apply();						
	            }
            }

            if(meta.vdp_metadata.stage_id == CONST_STAGE_3){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&2 != 0)
                        table_header_match_160_stage3.apply();
                    if(meta.vdp_metadata.header_chain_bitmap&4 != 0)
                        table_header_match_161_stage3.apply();
                    //   table_header_match_112_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&2 != 0)
                    //   table_header_match_160_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&4 != 0)
                    //   table_header_match_160_2_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&8 != 0)
                    //   table_header_match_224_1_stage1.apply();
                }
				if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
						table_std_meta_match_ingress_port_stage3.apply();
				}
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
				// 		table_user_meta_stage1.apply();
				// }
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage3.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage3.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage3.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage3.apply();						
	            }
            }
        }
    }

    
}


control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { 
        
    }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.hdr_112);
        packet.emit(hdr.desc_hdr);
        packet.emit(hdr.hdr_224);
        packet.emit(hdr.hdr_160[0]);
        packet.emit(hdr.hdr_160[1]);
        packet.emit(hdr.hdr_64);
    }
}

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;


    
///////////////////////////////////////////////////////////////// 
