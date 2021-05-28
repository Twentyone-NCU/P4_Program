#include <core.p4>
#include <v1model.p4>
typedef bit<48> macAddr_t;
typedef bit<9> egressSpec_t;

const bit<4> MAX_PORT = 15;

 //define header for ethernet
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

//define header for ipv4
header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct metadata {	
    bit<8> nhop_index;	
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
    @name(".ipv4") 
    ipv4_t     ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

// parser, jump to "state start"
parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
   //2
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4; //make sure it's ipv4(0800) or not
            //16w0x806: parse_arp;
            default: accept;
        }
    }//3
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4); 
	      //header in packet would match to ipv4 header(define above)
        transition accept;
    }//1
    @name(".start") state start {
        transition parse_ethernet;
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    register<bit<19>>(10) qdepth;  
    action do_add_qdepth() {
        qdepth.write((bit<32>)standard_metadata.egress_port, standard_metadata.deq_qdepth);
    }      
    apply {
        do_add_qdepth();
    }
}
 
/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action to_cpu(egressSpec_t port) {
        standard_metadata.egress_spec = port;
    }

    action set_nhop_index(bit<8> index){
        meta.nhop_index = index;
    }

    action _forward(macAddr_t dstAddr, egressSpec_t port) {

        //set the src mac address as the previous dst, this is not correct right?
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;

       //set the destination mac address that we got from the match in the table
        hdr.ethernet.dstAddr = dstAddr;

        //set the output port that we also get from the table
        standard_metadata.egress_spec = port;

        //decrease ttl by 1
        hdr.ipv4.ttl = hdr.ipv4.ttl -1;

    }

    // define a table lpm for action
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;  // match by subnet mask
        }
        actions = {
            set_nhop_index; //action 1: jump to destination
            to_cpu;
            drop;  // action 2
            NoAction;  // action 3
        }
        size = 1024;
        default_action = NoAction();
    }

    table forward {
        key = {   //how to match : "exact" way
            meta.nhop_index: exact;
        }
        actions = {
            _forward;
            NoAction;
        }
        size = 64;
        default_action = NoAction();
    }
    apply {
        if (hdr.ipv4.isValid()){
	   //Muiti Queue Priority
           if (hdr.ipv4.srcAddr == 0x0a000101){   //!!NEED TO WRITE H1 MAC ADDRESS
                standard_metadata.priority = (bit<3>)7;
             }
            if (ipv4_lpm.apply().hit) {
                forward.apply();
            }
        }
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        //packet.emit(hdr.arp);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

