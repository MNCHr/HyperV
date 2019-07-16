#include <core.p4>
#include <v1model.p4>
#include "headers.p4"
#include "metadata.p4"
#include "parser.p4"
#include "define.p4"
#include "action.p4"

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

////////////////////////////////////////////////////////////TABLES//////////////////////////////////////////////////////////////////////                

	table table_config_at_initial {
		key = {
			hdr.desc_hdr.vdp_id: exact;        //At initial state, 1,2,3,4  
			meta.vdp_metadata.inst_id: exact;  //At initial state, it should be 0
			meta.vdp_metadata.stage_id: exact; //At initial state, it should be 0
		}
		actions = {
			set_initial_config();
		}
	}    

	table table_header_match_112_stage1 {                                          
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_112.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}

	table table_header_match_112_stage2 {                                          
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_112.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}       
	table table_header_match_112_stage3 {                                          
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_112.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}       
	table table_header_match_112_stage4 {                                          
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_112.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}


	table table_header_match_160_1_stage1 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[0].buffer : ternary ;                                 	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}
	table table_header_match_160_1_stage2 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[0].buffer : ternary ;                                 	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}
	table table_header_match_160_1_stage3 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[0].buffer : ternary ;                                 	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	} 
	table table_header_match_160_1_stage4 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[0].buffer : ternary ;                                 	
		}                                                                       
		actions = { 																
			set_action_id;                                                        
			end;							                                    
		}    									                                
	}

	table table_header_match_160_2_stage1 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[1].buffer : ternary ;                                  	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	}
	table table_header_match_160_2_stage2 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[1].buffer : ternary ;                                  	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	}
	table table_header_match_160_2_stage3 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[1].buffer : ternary ;                                  	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	} 
	table table_header_match_160_2_stage4 {                                        
		key = {                                                                 
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			hdr.hdr_160[1].buffer : ternary ;                                  	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	}

	table table_header_match_224_stage1 {                                          
		key = {                                                                
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                
			hdr.hdr_224.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	} 
	table table_header_match_224_stage2 {                                          
		key = {                                                                
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                
			hdr.hdr_224.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	}
	table table_header_match_224_stage3 {                                          
		key = {                                                                
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                
			hdr.hdr_224.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	} 
	table table_header_match_224_stage4 {                                          
		key = {                                                                
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                
			hdr.hdr_224.buffer : ternary ;                                   	
		}                                                                       
		actions = { 																
			set_action_id;                                                          
			end;							                                    
		}    									                                
	}                                                                            
	table table_std_meta_match_stage1 {                                            
		key = {                                                                  
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			standard_metadata.ingress_port : ternary ;                          
			standard_metadata.egress_spec : ternary ;                           
			standard_metadata.instance_type : ternary ;                         
		}                                                                       
		actions = { 																
			set_action_id;														
			end;                                                                        
		}									                                    
	}
	table table_std_meta_match_stage2 {                                            
		key = {                                                                  
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			standard_metadata.ingress_port : ternary ;                          
			standard_metadata.egress_spec : ternary ;                           
			standard_metadata.instance_type : ternary ;                         
		}                                                                       
		actions = { 																
			set_action_id;														
			end;                                                                        
		}									                                    
	}
	table table_std_meta_match_stage3 {                                            
		key = {                                                                  
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			standard_metadata.ingress_port : ternary ;                          
			standard_metadata.egress_spec : ternary ;                           
			standard_metadata.instance_type : ternary ;                         
		}                                                                       
		actions = { 																
			set_action_id;														
			end;                                                                        
		}									                                    
	}
	table table_std_meta_match_stage4 {                                            
		key = {                                                                  
			meta.vdp_metadata.inst_id : exact ;                                		
			meta.vdp_metadata.stage_id : exact ;                                  	
			standard_metadata.ingress_port : ternary ;                          
			standard_metadata.egress_spec : ternary ;                           
			standard_metadata.instance_type : ternary ;                         
		}                                                                       
		actions = { 																
			set_action_id;														
			end;                                                                        
		}									                                    
	}                                                                              
	table table_user_meta_stage1 {	                                                
		key = {                             				                    
			meta.vdp_metadata.inst_id 		: exact ;       				        
			meta.vdp_metadata.stage_id 		: exact ;   	               			
			meta.user_metadata.meta 	        : ternary;	            				
		}                                                       				
		actions = { 																
			set_action_id;                                                      
			end;																
		}                    													
	}
	table table_user_meta_stage2 {	                                                
		key = {                             				                    
			meta.vdp_metadata.inst_id 		: exact ;       				        
			meta.vdp_metadata.stage_id 		: exact ;   	               			
			meta.user_metadata.meta 	        : ternary;	            				
		}                                                       				
		actions = { 																
			set_action_id;                                                      
			end;																
		}                    													
	}
	table table_user_meta_stage3 {	                                                
		key = {                             				                    
			meta.vdp_metadata.inst_id 		: exact ;       				        
			meta.vdp_metadata.stage_id 		: exact ;   	               			
			meta.user_metadata.meta 	        : ternary;	            				
		}                                                       				
		actions = { 																
			set_action_id;                                                      
			end;																
		}                    													
	}
	table table_user_meta_stage4 {	                                                
		key = {                             				                    
			meta.vdp_metadata.inst_id 		: exact ;       				        
			meta.vdp_metadata.stage_id 		: exact ;   	               			
			meta.user_metadata.meta 	        : ternary;	            				
		}                                                       				
		actions = { 																
			set_action_id;                                                      
			end;																
		}                    													
	}                                                                           
    apply {
        if (PROG_ID == 0) { // TBD-define
            table_config_at_initial.apply(); 
        }
        
        if (PROG_ID != 0) {
            ////////////////////////////////////////STAGE1/////////////////////////////////////////
            if((meta.vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == CONST_STAGE_1){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.table_chain&1 != 0)
                      table_header_match_112_stage1.apply();
                    else if(meta.vdp_metadata.table_chain&2 != 0)
                      table_header_match_160_1_stage1.apply();
                    else if(meta.vdp_metadata.table_chain&3 != 0)
                      table_header_match_160_2_stage1.apply();
                    else if(meta.vdp_metadata.table_chain&4 != 0)
                      table_header_match_224_stage1.apply();
                }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
                      table_std_meta_match_stage1.apply();
            }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
                      table_user_meta_stage1.apply();
            }
            if (ACTION_BITMAP != 0){
                action_do();
            }                               
            }
            ////////////////////////////////////////STAGE2/////////////////////////////////////////
            if((meta.vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == CONST_STAGE_2){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.table_chain&1 != 0)
                      table_header_match_112_stage2.apply();
                    else if(meta.vdp_metadata.table_chain&2 != 0)
                      table_header_match_160_1_stage2.apply();
                    else if(meta.vdp_metadata.table_chain&3 != 0)
                      table_header_match_160_2_stage2.apply();
                    else if(meta.vdp_metadata.table_chain&4 != 0)
                      table_header_match_224_stage2.apply();
                }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
                      table_std_meta_match_stage2.apply();
            }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
                      table_user_meta_stage2.apply();
            }
            if (ACTION_BITMAP != 0){
                action_do();
            }
            }
            ////////////////////////////////////////STAGE3/////////////////////////////////////////

            if((meta.vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == CONST_STAGE_3){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.table_chain&1 != 0)
                      table_header_match_112_stage3.apply();
                    else if(meta.vdp_metadata.table_chain&2 != 0)
                      table_header_match_160_1_stage3.apply();
                    else if(meta.vdp_metadata.table_chain&3 != 0)
                      table_header_match_160_2_stage3.apply();
                    else if(meta.vdp_metadata.table_chain&4 != 0)
                      table_header_match_224_stage3.apply();
                }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
                      table_std_meta_match_stage3.apply();
            }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
                      table_user_meta_stage3.apply();
            }
            if (ACTION_BITMAP != 0){
                action_do();
            }                               
            }
            ////////////////////////////////////////STAGE4/////////////////////////////////////////
            if((meta.vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == CONST_STAGE_4){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.table_chain&1 != 0)
                      table_header_match_112_stage4.apply();
                    else if(meta.vdp_metadata.table_chain&2 != 0)
                      table_header_match_160_1_stage4.apply();
                    else if(meta.vdp_metadata.table_chain&3 != 0)
                      table_header_match_160_2_stage4.apply();
                    else if(meta.vdp_metadata.table_chain&4 != 0)
                      table_header_match_224_stage4.apply();
                }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
                      table_std_meta_match_stage4.apply();
            }
            if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
                      table_user_meta_stage4.apply();
            }
            if (ACTION_BITMAP != 0){
                action_do();
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
