
table table_config_at_initial {
    key = {
        hdr.desc_hdr.vdp_id: exact;
    }
    actions = {
        set_initial_config();
    }
    const entries = {
        1 : set_initial_config(1,1,0b100,0b0001) ;  //1 = l2 forwarding
        2 : set_initial_config() 
    }
}

	action set_initial_config (bit<8> inst_id, bit<8> stage_id, bit<3> match_chain_bitmap, bit<4> header_chain_bitmap) { //need-to-check
		meta.vdp_metadata.inst_id = inst_id; //어떤 프로그램이 설치되었는지
		meta.vdp_metadata.stage_id = stage_id;
		meta.vdp_metadata.match_chain_bitmap = match_chain_bitmap; //
		meta.vdp_metadata.header_chain_bitmap = header_chain_bitmap; // related to headers       
	}

    // stage entering

table table_header_match_112_stage1 {
    key = {
        meta.vdp_metadata.inst_id : exact ;
        hdr.hdr_112.buffer : ternary ; // should include mask field
    }
    actions = {
        set_action_id(); // enabling primitive actions
    }
    const entries = {
        (1, 112w0x00000000000A0000000000000000 &&& 112w0xFFFFFFFFFFFF0000000000000000 : set_action_id()
    }
}

/// chamgo ++
	action set_stage_and_bitmap(bit<48> action_bitmap, bit<3> match_bitmap, bit<8> next_stage, bit<8> next_prog) { //need-to-check
		meta.vdp_metadata.action_chain_bitmap = action_bitmap;
		meta.vdp_metadata.match_chain_bitmap = match_bitmap;
		meta.vdp_metadata.stage_id = next_stage;
		meta.vdp_metadata.inst_id = next_prog;
		meta.vdp_metadata.action_chain_id = meta.vdp_metadata.match_chain_result;
		meta.vdp_metadata.match_chain_result = 0;
	}
	/*	
	action set_match_result(bit<48> match_result) {
		meta.vdp_metadata.match_chain_result = match_result|meta.vdp_metadata.match_chain_result;
	}
	*/	
	action set_action_id(bit<48> match_result, bit<48> action_bitmap, bit<3> match_bitmap, bit<8> next_stage, bit<8> next_prog) { //need-to-check
		//set_match_result(match_result);
		meta.vdp_metadata.match_chain_result = match_result ;
		set_stage_and_bitmap(action_bitmap, match_bitmap, next_stage, next_prog);
	}
/// chamgo ++

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

#define def_mask_112_dstAddr 0xFFFFFFFFFFFF0000000000000000
#define def_mask_112_srcAddr 0x000000000000FFFFFFFFFFFF0000

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
            1 : action_mod_112_dstAddr
        }
    }

    action action_mod_112_srcAddr(bit<112> value_112_srcAddr) {
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_srcAddr))|(value_112_srcAddr&def_mask_112_srcAddr);
    }
    table table_action_mod_112_srcAddr {
        key = {

        }
        actions = {
            action_mod_112_srcAddr();
        }
        const entries = {
            
        }
    }

/////////////////////////////////////////////////////////////////
    if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		apply(table_action_forward);						
	}
    if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		apply(table_action_mod_112_dstAddr);						
	}
    if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		apply(table_action_mod_112_srcAddr);						
	}
///////////////////////////////////////////////////////////////// 
#define BIT_MASK_DO_FORWARD (1)
#define BIT_MASK_MOD_112_DSTADDR (1<<2)
#define BIT_MASK_MOD_112_SRCADDR (1<<3)