/* -*- P4_16 -*- */

/*
 * P4 Calculator
 *
 * This program implements a simple protocol. It can be carried over Ethernet
 * (Ethertype 0x1234).
 *
 * The Protocol header looks like this:
 *
 *        0                1                  2              3
 * +----------------+----------------+----------------+---------------+
 * |      P         |       4        |     Version    |     Op        |
 * +----------------+----------------+----------------+---------------+
 * |                              gradient-id                         |
 * +----------------+----------------+----------------+---------------+
 * |                             gradient-value                       |
 * +----------------+----------------+----------------+---------------+
 * |                              Result                              |
 * +----------------+----------------+----------------+---------------+
 *
 * P is an ASCII Letter 'P' (0x50)
 * 4 is an ASCII Letter '4' (0x34)
 * Version is currently 0.1 (0x01)
 * Op is an operation to Perform:
 *   '+' (0x2b) Result = OperandA + OperandB
 *   '-' (0x2d) Result = OperandA - OperandB
 *   '&' (0x26) Result = OperandA & OperandB
 *   '|' (0x7c) Result = OperandA | OperandB
 *   '^' (0x5e) Result = OperandA ^ OperandB
 *
 * The device receives a packet, performs the requested operation, fills in the
 * result and sends the packet back out of the same port it came in on, while
 * swapping the source and destination addresses.
 *
 * If an unknown operation is specified or the header is not valid, the packet
 * is dropped
 */


#incldue<core.p4>
#include<v1model.p4>

// Gradient Aggregation + Weight Broadcast with Internal ID (BMv2 P4_16)

// ========== Headers ==========
header ethernet_t {
	bit<48> dstAddr;
	bit<48> srcAddr;
	bit<16> etherType;
}

header form_t {
	bit<8> p;
	bit<8> four;
	bit<8> ver;
	bit<8> op;       // 0 = gradient aggregation, 1 = weight broadcast

}

header gradient_t {
	bit<32> gradient_value;   // Q16.16 encoded gradient or weight
}





const bit<16> P4GRAD_ETYPE = 0x1234;
const bit<8> P4GRAD = 0x47;
const bit<8> P4GRAD_P = 0x50;
const bit<8> P4GRAD_4 = 0x34;
const bit<8> P4GRAD_VER = 0x01;



// ========== Header Struct ==========
struct headers {
	ethernet_t ethernet;
	form_t form;
	gradient_t gradient;
}

// ========== Metadata ==========
struct metadata { }

// ========== Registers ==========
register<bit<32>>(1) gradient_sum;
register<bit<32>>(1)  gradient_count;
register<bit<32>>(1) weights;
//register<bit<1>>(1) init_done;
//register<bit<32>>(1)    packet_index; // Global packet counter

// ========== Parser ==========
parser MyParser(packet_in pkt,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {


	state start {
        	pkt.extract(hdr.ethernet);
		//pkt.extract(hdr.form);
		//pkt.extract(hdr.gradient);
		transition select(hdr.ethernet.etherType) {
			P4GRAD_ETYPE: check_grad;
			default: accept;
		}	
	//	transition accept;
	}


	state check_grad{
		//transition select(pkt.lookahead<form_t>().p,
		pkt.extract(hdr.form);
		pkt.extract(hdr.gradient);
		//pkt.lookahead<form_t>().four,
		//pkt.lookahead<form_t>().ver) {
		//	(P4GRAD_P, P4GRAD_4, P4GRAD_VER): parse_p4grad;
		//gdefault: accept;
		//}
		transition accept;
	
	}


	state parse_p4grad {
		pkt.extract(hdr.form);
		pkt.extract(hdr.gradient);
		transition accept;
	}
}

// ========== Actions ==========


// ========== Tables ==========

// ========== Control Blocks ==========
control MyIngress(inout headers hdr,
                  inout metadata meta,

                  inout standard_metadata_t standard_metadata) {


	action init() {
		gradient_sum.write(0, 0);
		gradient_count.write(0, 0);

	}


	action operation_drop() {
		mark_to_drop(standard_metadata);
	}


	action swap_mac() {
		bit<48> tmp = hdr.ethernet.srcAddr;
		hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
		hdr.ethernet.dstAddr = tmp;			
		standard_metadata.egress_spec = standard_metadata.ingress_port;
	}

	action aggregate_and_emit() {
		//bit<32> id;
		bit<32> count;
		bit<32> current;

		// Read internal packet index as gradient_id
		//packet_index.read(id, 0);

		// Read current state
		gradient_sum.read(current, 0);
		gradient_count.read(count, 0);
		current = current + hdr.gradient.gradient_value;
		count = count + 1;
		hdr.gradient.gradient_value = current;
		gradient_sum.write(0, current);
		gradient_count.write(0, count);
		//packet_index.write(0, id + 1);

	}

	action write_weight() {
		weights.write(0, hdr.gradient.gradient_value);
		//standard_metadata.egress_spec = 0x1; // Broadcast (or multicast group)
	}

	table aggregate_table {

		key = {
			hdr.form.op : exact;
		}

		actions = {
        		aggregate_and_emit;        
			write_weight;
			operation_drop;
    		}

		const default_action = operation_drop();

		const entries = {
		0: aggregate_and_emit();
		1: write_weight(); //init value later
		}
	}

	apply {
		//init();
		if(hdr.form.isValid()) {
			aggregate_table.apply();

		}
		bit<32> count;

		//bit<32> id;
		// bit<1> done;
   		// init_done.read(done, 0);
   		// if (done == 0) {
     		//	 init();
		//	 init_done.write(0, 1);
		//	}
		// Read current state
		//gradient_sum.read(current, 0);
		gradient_count.read(count, 0);

   		if (count == 2 && hdr.form.isValid() && hdr.form.op == 0) {
			swap_mac();
			//hdr.gradient.gradient_value = current;
			gradient_sum.write(0, 0);
			gradient_count.write(0, 0);		
			//standard_metadata.egress_spec = standard_metadata.ingress_port;
   		} else if (hdr.form.isValid() && hdr.form.op == 1) {
			swap_mac();
		} else {
			operation_drop();
    		}
	}

}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { }
}

control MyCompute(inout headers hdr, inout metadata meta) {
	apply{}
}

control MyVerifyCheckSum(inout headers hdr, inout metadata meta) {
	apply {}
}

// ========== Deparser ==========
control MyDeparser(packet_out pkt, in headers hdr) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.form);
	pkt.emit(hdr.gradient);
    }
}

// ========== Main ==========
V1Switch(MyParser(),MyVerifyCheckSum(), MyIngress(), MyEgress(), MyCompute(), MyDeparser()) main;

