header_type total_header_t {
    fields {
        hdr1 : 112;
    }
}

parser start {
    return toheader;
}

header total_header_t theader;

parser toheader {
    extract(theader);
    return ingress;
}

action do_forward(port) {
    modify_field(standard_metadata.egress_spec, port);
}

action do_drop() {
    drop();
}

action do_mod_hdr(nheader) {
    modify_field(theader.hdr1, nheader);
}
/////////////
action do_compound(port, nheader) {
    do_forward(port);
    do_mod_hdr(nheader);
}

table MA1 {
    reads {
        standard_metadata.ingress_port : exact;
        theader.hdr1 : ternary;
    }
    actions {
   do_forward;
   do_drop;
   do_mod_hdr;
   do_compound;
    }
}

control ingress{
    apply(MA1);
}

control egress{

    