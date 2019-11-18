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
            hdr.hdr_160.buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        const entries = { 
            (2, 160w0x000000000000000000000000000000000000000A &&& 160w0x00000000000000000000000000000000FFFFFFFF) : set_action_id(0x000000000111);
            
        }
    }

/////primitive actions + tables + entries /////

	action action_forward(bit<9> port) { // 1st primitive
		standard_metadata.egress_spec = port;
	}

    table table_action_forward {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        const entries = {
            1 : action_forward(2); //daechung
            2 : action_forward(3); //daechung
        }
    }

#define def_mask_112_dstAddr 112w0xFFFFFFFFFFFF0000000000000000
#define def_mask_112_srcAddr 112w0x000000000000FFFFFFFFFFFF0000
#define def_mask_160_dstAddr 160w0x00000000000000000000000000000000FFFFFFFF
#define BIT_MASK_DO_FORWARD 1
#define BIT_MASK_MOD_112_DSTADDR 1<<2
#define BIT_MASK_MOD_112_SRCADDR 1<<3

    action action_mod_112_dstAddr(bit<112> value_112_dstAddr) {
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_dstAddr))|(value_112_dstAddr&def_mask_112_dstAddr);
    }
    table table_action_mod_112_dstAddr {
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

    action action_mod_112_srcAddr(bit<112> value_112_srcAddr) {
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_srcAddr))|(value_112_srcAddr&def_mask_112_srcAddr);
    }
    table table_action_mod_112_srcAddr {
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
		            table_action_forward.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr.apply();						
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
