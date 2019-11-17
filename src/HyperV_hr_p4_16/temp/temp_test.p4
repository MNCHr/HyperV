    action mod_field_with_const_112(bit<112> value_112, bit<112> mask_112) {   
		hdr.hdr_112.buffer = (hdr.hdr_112.buffer & (~mask_112)) | (value_112 & mask_112);
	}
//////////////////////////////////////////////////////////////////////////////////////////
    action mod_field_with_const_112_1(bit<112> mask_112) {
        md.temp_1 = hdr.hdr_112.buffer & (~mask_112);
        md.temp_value_112 = mask_112;
    }

    action mod_field_with_const_112_2(bit<112> value_112) {
        md.temp_2 = md.temp_value_112 & value_112;
    }

    action mod_field_with_const_112_3 () {
        hdr.hdr_112.buffer = temp_1|temp_2;

    }