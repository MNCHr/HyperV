#ifndef _METADATA_
#define _METADATA_


struct vdp_metadata_t {
    bit<8> inst_id; //program id
    bit<8> stage_id; //indicate where programs are installed
    bit<3> match_chain_bitmap; //3 options/ 100:header, 010:user md, 001: std md
    bit<48> match_chain_result; //temp to make chain for action_chain_id
    bit<48> action_chain_bitmap; //call defined actions, next stage =0
    bit<48> action_chain_id; //save match_chain_result
    bit<4>  table_chain_bitmap; //bitmap enabling tables for each header. 4options. 0001:112, 0010:160_1, 0100:160_2, 1000:224
    bit<4> header_chain_bitmap;
}

struct user_metadata_t {
    bit<256> meta;

}

struct temp_metadata_t {
    bit<112> temp_112;
    bit<112> temp_md_mask_112;
    bit<160> temp_160_1;
    bit<160> temp_md_mask_160_1;
    bit<160> temp_160_2;
    bit<160> temp_md_mask_160_2;
    bit<224> temp_224;
    bit<224> temp_md_mask_224;
}

struct metadata {
    vdp_metadata_t vdp_metadata;
    user_metadata_t user_metadata;
    temp_metadata_t temp_metadata;
}


#endif
