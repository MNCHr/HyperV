#include "define_hr.p4"

/****************************************************
 * description_header_t
 * Descripe packet headers
 ***************************************************/
header_type description_hdr_t {
	fields {
		flag		: 8 ;
		len         : 8 ;
		vdp_id      : 16;
		load_header : * ; //varbit
	}

	length : len;
	max_length : 128;
}

header description_hdr_t desc_hdr;

/****************************************************
 * byte_stack_t
 * Used for add_headers, remove_header, push, and \
 * pop operations
 ***************************************************/
header_type byte_stack_t {
	fields {
		byte : 8;
	}
}

header byte_stack_t byte_stack[64];

#ifndef HYPERV_METADTA_
#define HYPERV_METADTA_

/****************************************************
 * vdp_metadata_t
 * Vritual data plane metadata for control and stage
 ***************************************************/
header_type vdp_metadata_t {
	fields {
		// Identifiers
		vdp_id     : 16; 
		inst_id    : 8 ;
		stage_id   : 8 ;

		// Action block variables
		action_chain_id		: 48; 
		action_chain_bitmap : 48;
		
		// Match block variable
		match_chain_result  : 48;
		match_chain_bitmap  : 3 ;

		recirculation_flag    : 1 ;      
		remove_or_add_flag  : 1 ;
		mod_flag			: 1 ;
	}
}

metadata vdp_metadata_t vdp_metadata;

/****************************************************
 * user_metadata_t
 * Reserved meta-data for programs
 ***************************************************/
header_type user_metadata_t {
	fields {
		meta : 256;
		load_header  : 800;
	}
}

metadata user_metadata_t user_metadata;

/****************************************************
 * context_metadata_t
 * Context data and intermediate variables for \
 * arithmetical logic
 ***************************************************/
header_type context_metadata_t {
	fields {
		r1 : 16;
		r2 : 16;
		r3 : 16;
		r4 : 16;
		r5 : 32;
		op          : 2  ;
		left_expr   : 16 ;
		right_expr  : 16 ;
		count 	    : 32 ;
		hash        : 32 ;
		hash_header : 800;
	}
}

metadata context_metadata_t context_metadata;

#endif

@pragma header_ordering desc_hdr byte_stack

//--------------------------------parser-------------------------
parser start {
	extract(desc_hdr); // Rapid Parsing
	set_metadata(vdp_metadata.vdp_id, desc_hdr.vdp_id); //??
	set_metadata(HDR, desc_hdr.load_header);
    return ingress;
}

/////////////////codemark///////////////#include "include/template.p4"

#ifndef HYPERVISOR_TEMPLATE
#define HYPERVISOR_TEMPLATE

//#include "define_hr.p4"

//---------------------------------------------------------------------------
/*
 * In the match pipeline, we classify the match fields in a standard match-
 * action table into three types: packet header, standard metadata and user-
 * defined matadata. The fourth table maps the combined result to an action
 * bitmap. In this way we avoid using an exceedingly large match filed in one
 * table to reduce TCAM pressure. A match bitmap is also used to indicate whe-
 * ther a table should be executed or skipped in a match pipeline.
 */
#define STAGE(X)															\
control match_action_##X {		                                          	\
	if (vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER    != 0) {     	\
		apply(table_header_match_##X);                                      \
	}                                                                       \
	if (vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META  != 0) {     	\
		apply(table_std_meta_match_##X);                                    \
	}                                                                       \
	if (vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META != 0) {     	\
		apply(table_user_meta_##X);                                         \
	}																		\
	if (MATCH_RESULT != 0) {												\
		apply(table_match_result_##X);										\
	}																		\
	if (ACTION_BITMAP != 0)	{												\
		execute_do_##X();													\
    }						                                                \
}                                                                           \
table table_header_match_##X {                                              \
	reads {                                                                 \
		vdp_metadata.inst_id : exact ;                                		\
		vdp_metadata.stage_id : exact ;                                  	\
		user_metadata.load_header : ternary ;                             	\
	}                                                                       \
	actions { 																\
		set_match_result; 													\
		set_action_id;														\
		set_next_stage_a;													\
		set_action_id_direct;												\
		end;																\
		set_match_result_with_next_stage;									\
	}    									                                \
}                                                                           \
table table_std_meta_match_##X {                                            \
	reads{                                                                  \
		vdp_metadata.inst_id : exact ;                                		\
		vdp_metadata.stage_id : exact ;                                  	\
		standard_metadata.ingress_port : ternary ;                          \
		standard_metadata.egress_spec : ternary ;                           \
		standard_metadata.instance_type : ternary ;                         \
	}                                                                       \
	actions { 																\
		set_match_result; 													\
		set_action_id;														\
		set_next_stage_a;													\
		end;																\
		set_action_id_direct;												\
		set_match_result_with_next_stage;									\
	}									                                    \
}                                                                           \
table table_user_meta_##X {	                                                \
	reads {                             				                    \
		vdp_metadata.inst_id 		: exact ;       				        \
		vdp_metadata.stage_id 		: exact ;   	               			\
		user_metadata.meta 	        : ternary;	            				\
	}                                                       				\
	actions { 																\
		set_match_result;													\
		set_action_id; 														\
		set_action_id_direct;												\
		set_next_stage_a;													\
		set_match_result_with_next_stage;									\
		end;																\
	}                    													\
}                                                           				\
table table_match_result_##X {                                				\
	reads {																	\
		MATCH_RESULT 	: exact;         									\
	}                                                       				\
	actions {																\
		set_action_id_direct; 												\ 
		set_stage_and_bitmap; 												\
		set_next_stage_a;													\
	}                														\
}                                                           				




//--------------------------------ingress--------------------------
control ingress {
	if (PROG_ID == 0) {
		apply(table_config_at_initial);
	}
	if (PROG_ID != 0 and PROG_ID != 0xFF) {
		//--------------------stage 1-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_1) {
			match_action_stage1();
		}
		//--------------------stage 2-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_2) {
			match_action_stage2();
		}

		//--------------------stage 3-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_3) {
			match_action_stage3();
		}

		//--------------------stage 4-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_4) {
			match_action_stage4();
		}

		//--------------------stage 5-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_5) {
			match_action_stage5();
		}
		
		//--------------------stage 6-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_6) {
			match_action_stage6();
		}

		//--------------------stage 7-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_7) {
			match_action_stage7();
		}

		//--------------------stage 8-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_8) {
			match_action_stage8();
		}

		//--------------------stage 8-----------------
		if (((vdp_metadata.stage_id & CONST_NUM_OF_STAGE)) == 
														CONST_STAGE_9) {
			match_action_stage9();
		}
				
		if ((REMOVE_OR_ADD_HEADER == 0) and (PROG_ID != 0xFF)) {
			apply(table_config_at_end);
		}
	}
}

//---------stage 1--------------------------------------
STAGE(stage1)

//---------stage 2--------------------------------------
STAGE(stage2)

//---------stage 3--------------------------------------
STAGE(stage3)

//---------stage 4--------------------------------------
STAGE(stage4)

//---------stage 5--------------------------------------
STAGE(stage5)

//---------stage 6--------------------------------------
STAGE(stage6)

//---------stage 7--------------------------------------
STAGE(stage7)

//---------stage 8--------------------------------------
STAGE(stage8)

//---------stage 9--------------------------------------
STAGE(stage9)

//------------------------egress-----------------------
control egress {
	if (REMOVE_OR_ADD_HEADER == 1) {
		apply(table_config_at_egress);
	} 
	else if (MOD_FLAG == 1) {
		recalculate_checksum();
		apply(dh_deparse);
	}
}