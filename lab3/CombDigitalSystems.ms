import Common;

// multiplexer2 code from the pset 3 handout
function Bit#(2) multiplexer2(Bit#(1) sel, Bit#(2) a, Bit#(2) b);
	return {multiplexer1(sel, a[1], b[1]), multiplexer1(sel, a[0], b[0])};
endfunction

// bit_scan_reverse
// TODO: how many of each kind of gates did you use?
// # and1 = 0
// # or1 = 0
// # xor1 = 0
// # not1 = 0
// # multiplexer1 = 6, 3 multiplexer2 means 6 multiplexer1's

function Bit#(2) bit_scan_reverse(Bit#(4) a);
    // Each nested multiplexer2 returns current highest 1 value position
    return multiplexer2(
        a[3], multiplexer2(
            a[2], multiplexer2(
                a[1], 2'b00, 2'b01), 
            2'b10), 
        2'b11);
endfunction


// is_power_of_2
// TODO: how many of each kind of gates did you use?
// # and1 = 12      3 and1 gates for each index check
// # or1 = 0
// # xor1 = 3       3 xor1 gates for each comparison between two places
// # not1 = 12      3 not1 gates for each index check 
// # multiplexer1 = 0

function Bit#(1) is_power_of_2(Bit#(4) a);
    // four index variables, giving 1 if solely that index is 1 and the rest 0, otherwise 0
    Bit#(1) index0 = and1(a[0], and1(and1(not1(a[1]), not1(a[2])), not1(a[3])));
    Bit#(1) index1 = and1(a[1], and1(and1(not1(a[0]), not1(a[2])), not1(a[3])));
    Bit#(1) index2 = and1(a[2], and1(and1(not1(a[0]), not1(a[1])), not1(a[3])));
    Bit#(1) index3 = and1(a[3], and1(and1(not1(a[0]), not1(a[1])), not1(a[2])));
    return xor1(index3, xor1(index2, xor1(index1, index0))); // Nested XORs to determine a single 1
endfunction


// log_of_power_of_2
// TODO: how many of each kind of gates did you use?
// # and1 = ?
// # or1 = ?
// # xor1 = ?
// # not1 = ?
// # multiplexer1 = ?

function Bit#(2) log_of_power_of_2(Bit#(4) a);
    Bit#(1) power_bool = is_power_of_2(a);      // 1 if power of 2, 0 if not
    Bit#(2) high_index = bit_scan_reverse(a); // If it is power of 2, will need highest 1 location
    // Return array is zero if power_bool is 0, otherwise returns index of highest bit with value 1
    return {multiplexer1(power_bool, 0, high_index[1]), multiplexer1(power_bool, 0, high_index[0])};
endfunction


function Bit#(1) equal(Bit#(8) a, Bit#(8) b);
    // 7 nested and1 statements to check to (by pairs) make sure only one 1 exists
    return and1(
                    and1(
                        and1(
                            and1(
                                and1(
                                    and1(
                                        and1(
                                            not1(xor1(a[0], b[0])), 
                                            not1(xor1(a[1], b[1]))
                                        ), 
                                        not1(xor1(a[2], b[2]))
                                    ), 
                                    not1(xor1(a[3], b[3]))
                                ), 
                                not1(xor1(a[4], b[4]))
                            ), 
                            not1(xor1(a[5], b[5]))
                        ), 
                        not1(xor1(a[6], b[6]))
                    ), 
                    not1(xor1(a[7], b[7]))
                );
endfunction


function Bit#(4) vector_equal(Bit#(32) a, Bit#(32) b);
    // Use equal function on 8-bit segments of input vectors
    return {
        equal(a[31:24], b[31:24]), 
        equal(a[23:16], b[23:16]), 
        equal(a[15:8], b[15:8]), 
        equal(a[7:0], b[7:0])
    };
endfunction


function Bit#(7) seven_segment_decoder(Bit#(4) input_binary_number);
    Bit#(7) ret = case (input_binary_number)
        4'b0000: 7'b1111110; // 0
        4'b0001: 7'b0110000; // 1
        4'b0010: 7'b1101101; // 2
        4'b0011: 7'b1111001; // 3
        4'b0100: 7'b0110011; // 4
        4'b0101: 7'b1011011; // 5
        4'b0110: 7'b1011111; // 6
        4'b0111: 7'b1110000; // 7
        4'b1000: 7'b1111111; // 8
        4'b1001: 7'b1111011; // 9
	    default: 7'b1001111; // E
    endcase;
    return ret;
endfunction


function Bit#(2) full_adder(Bit#(1) a, Bit#(1) b, Bit#(1) c_in);
    Bit#(1) s = xor1(xor1(a, b), c_in); // Boolean formula for S from truth table
    Bit#(1) c_out = or1(
                        or1(
                            and1(a, b), and1(a, c_in) // At least one of these and pairs is necessary
                        ), 
                        and1(b, c_in)
                    ); // Boolean formula for C_out from the truth table
    return {c_out, s}; // Return 2 bit array of both values
endfunction

function Bit#(3) population_count(Bit#(4) in);
    // S is 1 XOR the indices are 1, else zero
    // C_out is 1 only if both are 1
    // 0,0->0,0 : 1,0->0,1 : 0,1->0,1 : 1,1->1,0 
    Bit#(2) index_23 = full_adder(in[2], in[3], 0);
    Bit#(2) index_01 = full_adder(in[0], in[1], 0);

    // Accepts S values as input
    // Case 1: 0,0 -> All indices are strictly 1 or 0, COUNT IS EVEN, so output 0,0
    // Case 2: 1,0 -> Index 2 or 3 is 1, Index 0 & 1 are the same, COUNT IS ODD, so output 0,1
    // Case 3: 0,1 -> Index 0 or 1 is 1, Index 2 & 3 are the same, COUNT IS ODD, so output 0,1
    // Case 4: 1,1 -> Exactly two of four indices are 1, COUNT IS EVEN, so output 1,0
    // 0,0->0,0 : 1,0->0,1 : 0,1->0,1 : 1,1->1,0 
    Bit#(2) least = full_adder(index_23[0], index_01[0], 0);

    // Accepts C_out values as input
    // Lower[1] is 0 if we know exactly 2 indices are 1, otherwise 0
    // Case 1: 0,0 -> If C_in=0, we leave count to lower[0], if C_in=1, it must be two (not in same pair)
    // Case 2: 1,0 -> If C_in=0, 2 & 3 are 1 + XOR 0 & 1, C_in=1 won't occur
    // Case 3: 0,1 -> If C_in=0, 1 & 0 are 1 + XOR 2 & 3, C_in=1 won't occur
    // Case 4: 1,1 -> If C_in=0, all four are 1, C_in=1 won't occur
    // C_in = 0 ... 0,0->0,0 : 1,0->0,1 : 0,1->0,1 : 1,1->1,0 
    // C_in = 1 ... 0,0->0,1 : 1,0->1,0 : 0,1->1,0 : 1,1->1,1
    Bit#(2) most = full_adder(index_23[1], index_01[1], least[1]);

    return {most, least[0]}; // Return 3-bit output
endfunction


function Bit#(1) is_geq(Bit#(4) a, Bit#(4) b);
    // Inverse XOR -> 1 if indices are the same, 0 if indices are different
    return multiplexer1(
            not1(xor1(a[3], b[3])), a[3], multiplexer1(
                not1(xor1(a[2], b[2])), a[2], multiplexer1(
                    not1(xor1(a[1], b[1])), a[1], multiplexer1(
                        not1(xor1(a[0], b[0])), a[0], 1) // Lowest level: If same, take 1, else a[0]
                    )
                )
            ); // One-liner, no extra steps necessary
endfunction



// Demo code below here. Do not modify
function Bit#(1) parity4(Bit#(4) n);
    return xor1(xor1(xor1(n[0], n[1]), n[2]), n[3]);
endfunction
