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
	set_metadata(HDR, desc_hdr.load_header); //??
    return ingress;
}
/////////////////codemark///////////////#include "include/action.p4"

//***********************************************************
//				       HyperV primitives
//***********************************************************

action noop() {

}

/**
 * Count packets with global register.
 * @param index <> packet counter index.
 */
action packet_count(index) {
	register_read(context_metadata.count, global_register, index);
	register_write(global_register,  // Global register 
				   index, 
				   context_metadata.count + 1);
}

/**
 * Clear packet counter.
 * @param index <> pakcet counter index
 */ 
action packet_count_clear(index) {
	register_write(global_register, index, 0);
}

/**
 * Loop back packets.
 */
action do_loopback() {
	modify_field(standard_metadata.egress_spec, 
		standard_metadata.ingress_port);
}


/**
 * Set the multicast group.
 * @param mcast_grp <> multicast group ID. 
 */
action do_multicast(mcast_grp) {
	modify_field(intrinsic_metadata.mcast_grp, mcast_grp);
}

/**
 * Set the queue id.
 * @param qid <> queue id
 */
//hr-modified
//action do_queue(qid) {
//	modify_field(intrinsic_metadata.qid, qid);
//}

/**
 * Forward packets
 * @param port  destination ports
 */ 
action do_forward(port) {
	modify_field(standard_metadata.egress_spec, port);
}

/**
 * Drop packets.
 */
action do_drop() {
	drop();
} 


/**
 * Generate digest to the CPU receiver.
 * @param receiver
 */
action do_gen_digest(receiver) {
	generate_digest(receiver, digest_list);
}


/**
 * Add header fileds with const integers.
 * @param value1 <header length> value of the const.
 * @param mask1 <header length> value mask.
 */ 
action do_add_header_with_const(value1, mask1) {
	bit_or(HDR, HDR & (~mask1),
		(HDR + value1) & mask1);
}

/**
 * Add user-defined metadata with const integers.
 * @param value1 <metadata length> value of the const.
 * @param mask1 <metadata length> value mask.
 */ 
action do_add_meta_with_const(value1, mask1) {
	bit_or(META, META & (~mask1),
		(META + value1) & mask1);
}

/**
 * Add header with the header values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_add_header_with_header(left1, 
								 right1, 
								 mask1) {
	bit_or(HDR, HDR & (~mask1), 
		(HDR + (((HDR<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Add user defiend metadata with the header values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_add_meta_with_header(left1, 
                               right1, 
                               mask1) {
	bit_or(META, META & (~mask1), 
		(META + (((HDR<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Add header with the metadata values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_add_header_with_meta(left1, 
							   right1, 
							   mask1) {
	bit_or(HDR, HDR & (~mask1), 
		(HDR + (((META<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Add metadata with the metadata values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_add_meta_with_meta(left1, 
							 right1, 
							 mask1) {
	bit_or(META, META & (~mask1), 
		(META + (((META<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Substract header with the const values.
 * @param value1 <header length> the const value
 * @param mask1 <header length> value mask
 */
action do_subtract_const_from_header(value1, mask1) {
	bit_or(HDR, HDR & (~mask1), 
		(HDR - value1) & mask1);
}

/**
 * Substract metadata with the const values.
 * @param value1 <header length> the const value
 * @param mask1 <header length> value mask
 */
action do_subtract_const_from_meta(value1, mask1) {
	bit_or(META, META & (~mask1), 
		(META - value1) & mask1);
}

/**
 * Substract header with the header values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_subtract_header_from_header(left1, 
									  right1, 
									  mask1) {
	bit_or(HDR, HDR & (~mask1), 
		(HDR - (((HDR<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Substract header with the metadata values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_subtract_header_from_meta(left1, 
									right1, 
									mask1) {
	bit_or(META, META & (~mask1), 
		(META - (((HDR<<left1)>>right1)&mask1)) & mask1);
}


/**
 * Substract metadata with the header values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_subtract_meta_from_header(left1, right1, mask1) {
	bit_or(HDR, HDR & (~mask1), 
		(HDR - (((META<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Substract metadata with the metadata values.
 * @param left1 <header length> left shift
 * @param right1 <header length>  right shift
 * @param mask1 <header length> value mask
 */
action do_subtract_meta_from_meta(left1, right1, mask1) {
	bit_or(META, META & (~mask1), 
		(META - (((META<<left1)>>right1)&mask1)) & mask1);
}

/**
 * Add a header into the packet.
 * @param value <header length> left shift
 * @param mask1  <header length> value mask
 * @param mask2  <header length> value mask
 * @param length1 <header length> header length
 */
 
 //hr-modified
action do_add_header_1(value,
					   mask1, 
					   mask2, 
					   length1) {
	//push(byte_stack, length1*1);hr-modified
	push(byte_stack, 8);

	bit_or(HDR, HDR & mask1, 
		(HDR & (~mask1) )>>(length1*8));
	add_to_field(HEADER_LENGTH, length1);
	do_mod_header_with_const(value, mask2);
	modify_field(desc_hdr.len, HEADER_LENGTH);
	
	modify_field(REMOVE_OR_ADD_FLAG, 1);
	modify_field(MOD_FLAG, 1);
}

/**
 * Remove a header form the packet.
 * @param value1 <header length> left shift
 * @param mask1  <header length> value mask
 * @param mask2  <header length> value mask
 * @param length1 <header length> header length
 */
action do_remove_header_1(mask1, mask2, length1) {
//	push(byte_stack, length1*1); hr-modified
	push(byte_stack, 8);
	subtract_from_field(HEADER_LENGTH, length1);
	
	modify_field(byte_stack[0].byte, HEADER_FLAG);
	modify_field(byte_stack[1].byte, HEADER_LENGTH);
	modify_field(byte_stack[2].byte, (POLICY_ID>>16)&0xFF);
	modify_field(byte_stack[3].byte, (POLICY_ID) & 0xFF);

	remove_header(desc_hdr);

	bit_or(HDR, HDR & mask1, 
		(HDR & mask2)<<(length1*8));
	
	modify_field(REMOVE_OR_ADD_FLAG, 1);
	modify_field(MOD_FLAG, 1);
}

/**
 * Modify header with one const value.
 * @param value <header length> left shift
 * @param mask1  <header length> value mask
 * @param length1 <header length> value mask
 */
action do_mod_header_with_const(value, mask1) {
	bit_or(HDR, (HDR & (~mask1)), (value & mask1));
	modify_field(MOD_FLAG, 1);
}

/**
 * Modify header with one const value, meanwhile re-calculate the checksum (inline).
 * @param value1 <header length> left shift
 * @param mask1  <header length> value mask
 * @param length1 <header length> value mask
 */
action do_mod_header_with_const_and_checksum(value, 
										     mask1, 
										     value1, 
										     value2, 
										     offset1) {
	do_mod_header_with_const(value, mask1);
	do_update_transport_checksum(value1,
		 value2, offset1);
}

/**
 * Modify header with one const value, meanwhile re-calculate the checksum (inline).
 * @param value <header length>  the const value.
 * @param mask1  <header length> value mask
 */
action do_mod_meta_with_const(value, mask1) {
	bit_or(META, (META & ~mask1), 
		(value & mask1));
}

/**
 * Modify standard metadata fields.
 * @param val1  <>
 * @param mask1 <>
 * @param val2  <>
 * @param mask2 <>
 * @param val3  <>
 * @param mask3 <>
 * @param val4  <>
 * @param mask4 <>
 */
action do_mod_std_meta(val1, mask1, 
					   val2, mask2, 
					   val3, mask3, 
					   val4, mask4) {
	bit_or(standard_metadata.egress_spec, 
		standard_metadata.egress_spec & (~mask1), val1 & mask1);
	bit_or(standard_metadata.egress_port, 
		standard_metadata.egress_port & (~mask2), val2 & mask2);
	bit_or(standard_metadata.ingress_port, 
		standard_metadata.ingress_port & (~mask3), val3 & mask3);
	bit_or(standard_metadata.packet_length, 
		standard_metadata.packet_length & (~mask4), val4 & mask4);
}

/**
 * Modify header with the one metadata field.
 * @param value1 <header length> left shift
 * @param mask1  <header length> value mask
 * @param length1 <header length> value mask
 */
action do_mod_header_with_meta_1(left1, 
								 right1, 
								 mask1) {
    bit_or(HDR, (HDR & ~mask1),
		 (((META << left1) >> right1) & mask1));
	modify_field(MOD_FLAG, 1);
}

/**
 * Modify header with the two metadata fields.
 * @param left1  <header length> left shift
 * @param right1   <header length> right shift
 * @param mask1 <header length> value mask
 * @param left2  <header length> left shift
 * @param right2   <header length> right shift
 * @param mask2 <header length> value mask
 */
action do_mod_header_with_meta_2(left1, right1, mask1, 
								 left2, right2, mask2) {
    do_mod_header_with_meta_1(left1, right1, mask1);
	do_mod_header_with_meta_1(left2, right2, mask2);
}

/**
 * Modify header with the three metadata fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 * @param left3  	<header length> left shift
 * @param right3   	<header length> right shift
 * @param mask3 	<header length> value mask
 */
action do_mod_header_with_meta_3(left1, right1, mask1, 
								 left2, right2, mask2, 
								 left3, right3, mask3) {
    do_mod_header_with_meta_1(left1, right1, mask1);
	do_mod_header_with_meta_1(left2, right2, mask2);
	do_mod_header_with_meta_1(left3, right3, mask3);
}

/**
 * Modify metadata with the one metadata field.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 */
action do_mod_meta_with_meta_1(left1, right1, mask1) {
    bit_or(META, (META & ~mask1), 
		(((META << left1) >> right1) & mask1));
}

/**
 * Modify metadata with the two metadata fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 */
action do_mod_meta_with_meta_2(left1, right1, mask1, 
							   left2, right2, mask2) {
    do_mod_meta_with_meta_1(left1, right1, mask1);
	do_mod_meta_with_meta_1(left2, right2, mask2);
}

/**
 * Modify metadata with the three metadata fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 * @param left3  	<header length> left shift
 * @param right3   	<header length> right shift
 * @param mask3 	<header length> value mask
 */
action do_mod_meta_with_meta_3(left1, right1, mask1, 
							   left2, right2, mask2,
							   left3, right3, mask3) {
	do_mod_meta_with_meta_1(left1, right1, mask1);
	do_mod_meta_with_meta_1(left2, right2, mask2);
	do_mod_meta_with_meta_1(left3, right3, mask3);   
}

/**
 * Modify header with the one header field.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 */
action do_mod_header_with_header_1(left1, right1, mask1) {
    bit_or(META, (HDR & ~mask1), 
		(((HDR << left1) >> right1) & mask1));

	modify_field(MOD_FLAG, 1);
}

/**
 * Modify header with the three header fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 */
action do_mod_header_with_header_2(left1, right1, mask1, 
								   left2, right2, mask2) {
    do_mod_header_with_header_1(left1, right1, mask1);
	do_mod_header_with_header_1(left2, right2, mask2);
}

/**
 * Modify header with the three header fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 * @param left3  	<header length> left shift
 * @param right3   	<header length> right shift
 * @param mask3 	<header length> value mask
 */
action do_mod_header_with_header_3(left1, right1, mask1, 
								   left2, right2, mask2, 
								   left3, right3, mask3) {
    do_mod_header_with_header_1(left1, right1, mask1);
	do_mod_header_with_header_1(left2, right2, mask2);
	do_mod_header_with_header_1(left3, right3, mask3);
}

/**
 * Modify metadata with the one header field.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 */
action do_mod_meta_with_header_1(left1, right1, mask1) {
    bit_or(META, (HDR & ~mask1), 
		(((HDR << left1) >> right1) & mask1));
}

/**
 * Modify metadata with the two header fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 */
action do_mod_meta_with_header_2(left1, right1, mask1, 
								 left2, right2, mask2) {
    do_mod_meta_with_header_1(left1, right1, mask1);
	do_mod_meta_with_header_1(left2, right2, mask2);
}

/**
 * Modify metadata with the three header fields.
 * @param left1  	<header length> left shift
 * @param right1   	<header length> right shift
 * @param mask1 	<header length> value mask
 * @param left2  	<header length> left shift
 * @param right2   	<header length> right shift
 * @param mask2 	<header length> value mask
 * @param left3  	<header length> left shift
 * @param right3   	<header length> right shift
 * @param mask3 	<header length> value mask
 */
action do_mod_meta_with_header_3(left1, right1, mask1, 
				left2, right2, mask2, left3, right3, mask3) {
    do_mod_meta_with_header_1(left1, right1, mask1);
	do_mod_meta_with_header_1(left2, right2, mask2);
	do_mod_meta_with_header_1(left3, right3, mask3);
}


/**
 * Recirculate packets at  the egress pipeline.
 * @param progid Pragram ID
 */
action do_recirculate(progid) {
	modify_field(vdp_metadata.recirculation_flag, 1);
	modify_field(vdp_metadata.remove_or_add_flag, 0);
	modify_field(vdp_metadata.inst_id, progid); 
	recirculate( flInstance_with_umeta );
}

/**
 * Resubmit packet at the ingress pipeline.
 * @param progid Pragram ID
 */
action do_resubmit(progid) {
	modify_field(vdp_metadata.recirculation_flag, 1);
	modify_field(vdp_metadata.inst_id, progid);
	resubmit(flInstance_with_umeta);
}

/**
 * Load register value into the header.
 * @param index register index
 * @param left1 
 * @param mask1
 */
action do_load_register_into_header(index, 
 								    left1, 
 								    mask1) {
	register_read(context_metadata.r5, global_register, index);
	bit_or(HDR, HDR & (~mask1), 
		(context_metadata.r5<<left1) & mask1);

	modify_field(MOD_FLAG, 1);
}

/**
 * Load register value into the metadata.
 * @param index register index
 * @param left1 
 * @param mask1
 */
action do_load_register_into_meta(index, 
								  left1, 
								  mask1) {
	register_read(context_metadata.r5,  
	              global_register, 
	              index);
	bit_or(META, META & (~mask1), 
		(context_metadata.r5<<left1) & mask1);
}


/**
 * Load the header field into the register.
 * @param index register index
 * @param right1 
 * @param mask1
 */
action do_write_header_into_register(index, 
								     right1, 
								     mask1) {
	register_write(global_register, index, 
		(HDR>>right1) & mask1);
}

/**
 * Load the metadata field into the register.
 * @param index register index
 * @param left1 
 * @param mask1
 */
action do_wirte_meta_into_register(index, right1, mask1) {
	register_write(global_register, index, 
		(META>>right1) & mask1);
}

/**
 * Load the const value into the register.
 * @param index register index
 * @param value the const value to load
 */
action do_wirte_const_into_register(index, value) {
	register_write(global_register, index, value);
}

/**
 * Return the hash header.
 */
field_list hash_field_list {
	context_metadata.hash_header;
}

/**
 * Calculate the field list with CRC16 hash.
 */
field_list_calculation hash_crc16 {
    input {
        hash_field_list;
    }
    algorithm : crc16;
    output_width : 16;
}

/**
 * Calculate the field list with CRC32 hash.
 */
field_list_calculation hash_crc32 {
    input {
        hash_field_list;
    }
    algorithm : crc32;
    output_width : 32;
}

/**
 * Set the hash header.
 * @param hdr_mask 
 */
action do_set_hash_hdr(hdr_mask) {
	modify_field(context_metadata.hash_header, HDR & hdr_mask);
}


/**
 * Calculate CRC16.
 */
action do_hash_crc16(hdr_mask) {
	do_set_hash_hdr(hdr_mask);
	modify_field_with_hash_based_offset(context_metadata.hash, 0,
                                        hash_crc16, 65536);
}

/**
 * Calculate CRC32.
 */
action do_hash_crc32(hdr_mask) {
	do_set_hash_hdr(hdr_mask);
	modify_field_with_hash_based_offset(context_metadata.hash, 0,
                                        hash_crc32, 0xFFFFFFFF);
}

/**
 * Select hash profile.
 */
action_profile hash_profile {
	actions {
		do_forward;
		noop;
	}

	dynamic_action_selection : hash_action_selector;
}

/**
 * Perform hash calculation.
 */
field_list_calculation hash_calculation { 
	input {	
		hash_field_list; 
	}
	algorithm : crc16; 
	output_width : 16;
}

/**
 * Select hash action.
 */
action_selector hash_action_selector {
	selection_key : hash_calculation;
}


/////////////////codemark///////////////#include "include/template.p4"

#ifndef HYPERVISOR_TEMPLATE
#define HYPERVISOR_TEMPLATE

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


//-----------------------------------------------------------------------
/* 
 * 
 */
#define EXECUTE_ACTION(X)												\
control execute_do_##X {												\
	if ((ACTION_BITMAP & BIT_MASK_MOD_HEADER_WITH_META) != 0) {			\
		apply(table_mod_header_with_meta_##X);							\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_MOD_META_WITH_META) != 0) {			\
		apply(table_mod_meta_with_meta_##X);							\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_MOD_HEADER_WITH_HEADER) != 0) {		\
		apply(table_mod_header_with_header_##X);						\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_MOD_META_WITH_HEADER) != 0) {			\
		apply(table_mod_meta_with_header_##X);							\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_MOD_HEADER_WITH_CONST) != 0) {		\
		apply(table_mod_header_with_const_##X);							\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_MOD_META_WITH_CONST) != 0) {			\
		apply(table_mod_meta_with_const_##X);							\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_ADD_HEDAER) != 0) {					\
		apply(table_add_header_##X);									\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_REMOVE_HEADER) != 0) {				\
		apply(table_remove_header_##X);									\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_MOD_STD_META) != 0) {					\
		apply(table_mod_std_meta_##X);									\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_GENERATE_DIGIST) != 0) {			    \
		apply(table_generate_digest_##X);								\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_ADD ) != 0) {							\
		apply(table_add_##X);											\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_SUBTRACT ) != 0) {					\
		apply(table_subtract_##X);										\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_REGISTER) != 0) {						\
		apply(table_register_##X);										\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_COUNTER) != 0) {						\
		apply(table_counter_##X);										\
	}																	\
	if ((ACTION_BITMAP & BIT_MASK_HASH) != 0) {							\
	    apply(table_hash_##X);											\
	}																	\				
	if ((ACTION_BITMAP & BIT_MASK_PROFILE) != 0) {						\
	    apply(table_action_profile_##X);								\
	}																	\
}																		\
table table_add_##X {													\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_add_header_with_const;							    		\
		do_add_meta_with_const;									    	\
		do_add_header_with_header;									    \
		do_add_meta_with_header;									    \   
		do_add_header_with_meta;									    \
		do_add_meta_with_meta;										    \
	}																	\
}																		\
table table_generate_digest_##X {										\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_gen_digest;											    	\
	}																	\
}																		\
table table_subtract_##X {												\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_subtract_const_from_header;									\
		do_subtract_const_from_meta;									\
		do_subtract_header_from_header;									\
		do_subtract_header_from_meta;									\
		do_subtract_meta_from_header;									\
		do_subtract_meta_from_meta;										\
	}																	\
}																		\
table table_mod_std_meta_##X {											\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_std_meta;												\
		do_loopback;													\
		do_forward;														\
		do_drop;														\
		do_multicast;													\
	}																	\
}																		\
table table_mod_header_with_const_##X {									\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_header_with_const;									    \
		do_mod_header_with_const_and_checksum;					    	\
	}																	\
}																		\
table table_mod_meta_with_const_##X {									\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_meta_with_const;										    \
	}																	\
}																		\
table table_mod_header_with_meta_##X {									\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_header_with_meta_1;								    	\
		do_mod_header_with_meta_2;									    \
		do_mod_header_with_meta_3;								    	\
	}																	\
}																		\
table table_mod_meta_with_meta_##X {									\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_meta_with_meta_1;				    					\
		do_mod_meta_with_meta_2;					    				\
		do_mod_meta_with_meta_3;						    			\
	}																	\
}																		\
table table_mod_header_with_header_##X {								\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_header_with_header_1;					    			\
		do_mod_header_with_header_2;						    		\
		do_mod_header_with_header_3;							    	\
	}																	\
}																		\
table table_mod_meta_with_header_##X {									\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_mod_meta_with_header_1;						    			\
		do_mod_meta_with_header_2;							    		\
		do_mod_meta_with_header_3;								    	\
	}																	\
}																		\
table table_add_header_##X {											\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_add_header_1;									    		\
	}																	\
}																		\	
table table_remove_header_##X {											\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_remove_header_1;												\
	}																	\
}																		\
table table_hash_##X {													\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_hash_crc16;													\
		do_hash_crc32;													\	
	}																	\
}																		\
table table_action_profile_##X {   										\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	action_profile : hash_profile;  									\
}																		\
table table_counter_##X {												\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		packet_count;													\
		packet_count_clear;												\
	}																	\
}																		\
table table_register_##X {												\
	reads {																\
		ACTION_ID : exact;												\
	}																	\
	actions {															\
		do_load_register_into_header;									\
		do_load_register_into_meta;										\
		do_write_header_into_register;									\
		do_wirte_meta_into_register;									\
		do_wirte_const_into_register;									\
	}																	\
}																		\
counter counter_##X {													\
 	type : packets_and_bytes;											\
	direct : table_counter_##X;											\
}																		


#endif


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