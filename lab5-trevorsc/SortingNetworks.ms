// All sorting networks sort unsigned 32-bit words
typedef Bit#(32) Word;

/* Combinational n-element Bitonic Sorting Network
 *
 * The following functions use four built-in functions on vectors:
 * 1.- take() takes elements starting from the front of the vector.
 *     For example, if v is a Vector#(8, Word),
 *        Vector#(2, Word) f = take(v);
 *     will make f have the first two elements of v (v[0] and v[1]).
 * 2.- takeTail() takes element from the back (i.e., tail) of the vector.
 *     For example, if v is a Vector#(8, Word),
 *        Vector#(2, Word) b = takeTail(v);
 *     will make b have the last two elements of v (v[6] and v[7]).
 * 3.- reverse() reverses the elements of a vector.
 *     For example, if v is a Vector#(4, Word),
 *        Vector#(4, Word) r = reverse(v);
 *     will make r have r[0] = v[3], r[1] = v[2], r[2] = v[1], and r[3] = v[0].
 * 4.- append() concatenates two vectors, creating a single vector
 *     with the sum of their lengths.  
 */ 
function Vector#(n, Word) bitonicSort#(Integer n)(Vector#(n, Word) in);
    if (n <= 1) begin
        return in;
    end else begin
    	Vector#(n/2, Word) lower = take(in); // lower = first n/2 elements of in
    	Vector#(n-n/2, Word) upper = takeTail(in); // upper = last n-n/2 elements of in

    	// Sort lower and upper
    	let lower_sorted = bitonicSort#(n/2)(lower);
        let upper_sorted = bitonicSort#(n-n/2)(upper);

        // Reverse the sorted upper half
        let upper_sorted_reversed = reverse(upper_sorted);

        let vector_to_merge = append(lower_sorted, upper_sorted_reversed);
        return bitonicMerge#(n)(vector_to_merge);
    end
endfunction

function Vector#(n, Word) bitonicMerge#(Integer n)(Vector#(n, Word) x);
    if (n <= 1) begin
        return x;
    end else begin
        let s = x;
        for (Integer i = 0; i < n/2; i = i + 1) begin
            Integer j = i + n/2;
            if (x[i] > x[j]) begin
                s[i] = x[j];
                s[j] = x[i];
            end
        end

        Vector#(n/2, Word) lower = take(s); // lower = first n/2 elements of s
    	Vector#(n-n/2, Word) upper = takeTail(s); // upper = last n-n/2 elements of s

    	// Merge lower and upper, then return their concatenation
        let lower_merged = bitonicMerge#(n/2)(lower);
        let upper_merged = bitonicMerge#(n-n/2)(upper);
        return append(lower_merged, upper_merged);
    end
endfunction


// Description: Pipelined 8-element Word sorting network
// TODO: Implement this module in Exercise 4
// NOTE: Depending on which implementation strategy you choose (see
// hints in handout), implementing this module and its submodules
// requires about 40-70 lines of code. Much of this code directly
// corresponds to code in the combinational sorting network.

module BitonicSorter8;
    // Instantiate your submodules here
    BitonicSorter#(8) sort; // Call the recursive helper function

    // When there is a new vector of elements to sort, they will be passed in as a valid vector.
    input Maybe#(Vector#(8, Word)) in default = Invalid;

    // If 6 cycles ago (the number of pipeline stages) the module had
    // a valid input, getOutput should return a valid vector with
    // those input elements in sorted (ascending) order. If 6 cycles
    // ago the input was Invalid, getOutput should return Invalid.
    method Maybe#(Vector#(8, Word)) getOutput;
        return sort.toSort;
    endmethod

    rule tick;
        sort.in =  (isValid(in)) ? in : Invalid; // If there is a valid input, feed to the sort
    endrule
endmodule


module BitonicSorter#(Integer n);   // Recursive helper so we can use arbtrary amount of bits
    BitonicSorter#(n-n/2) top;      // Recursive call to upper half
    BitonicSorter#(n/2) bot;        // Recursive call to lower half
    BitonicMerger#(n) m;        // Initialization of merge

    input Maybe#(Vector#(n, Word)) in default = Invalid; // Set default input as Invali

    rule sort;
        if (isValid(in)) begin                // Check validity of input
            let input1 = fromMaybe(?, in);    // If valid, get input
            bot.in = Valid(take(input1));     // take -> first n/2 elements
            top.in = Valid(takeTail(input1)); // taketail -> last n/2 elements
        end else begin
            bot.in = Invalid; // Set to invalid if input is not valid
            top.in = Invalid;
        end

        m.in = (isValid(bot.toSort) && isValid(top.toSort)) ? // Both top and bottom half are valid
            Valid(
                append( // Append together
                    fromMaybe(?, bot.toSort), reverse(fromMaybe(?, top.toSort)) // SOrted top + reverse sorted bot
                )
            )
            : Invalid; // If both aren't valid, set to Invalid
    endrule

    method Maybe#(Vector#(n, Word)) toSort; // Call merge
	    return m.toMerge;
    endmethod
endmodule


module BitonicSorter#(2); // 2-bit base case function for recursive sorting
    RegU#(Maybe#(Vector#(2, Word))) ret;                 // Declare register without initial value
    input Maybe#(Vector#(2, Word)) in default = Invalid; // Setup input 

    rule sort;
        if (isValid(in)) begin                 // Check validity of input
            let input_2 = fromMaybe(?, in);   
            Vector#(2, Word) temp = input_2;
            if (input_2[1] < input_2[0]) begin // Swap if higher bit less than lower bit
                temp[0] = input_2[1];
                temp[1] = input_2[0];             // Place in temp swapped vector
            end
            ret <= Valid(temp);  // Set ret to the swapped input vector
        end else ret <= Invalid; // If invalid input, set return to Invalid
    endrule

    method Maybe#(Vector#(2, Word)) toSort;
	    return ret;
    endmethod
endmodule


module BitonicMerger#(Integer n);
    Reg#(Maybe#(Vector#(n, Word))) stage(Invalid);
    BitonicMerger#(n/2) bot;   // Recurse merge on bottom n/2 units
    BitonicMerger#(n-n/2) top; // Recurse merge on top n/2 units

    input Maybe#(Vector#(n, Word)) in default = Invalid; // Default invalid input

    rule merge;
        if (isValid(in)) begin                            // Immediately check validity of input
            let vector_to_merge = fromMaybe(?, in);       // Call from maybe
            Vector#(n, Word) temp = vector_to_merge;      // Create new temporary vector of same size
            for (Integer i = 0; i < n/2; i = i+1) begin   // Iterate over half indicies to compare both halves
                Integer j = i + n/2;
                if (vector_to_merge[j] < vector_to_merge[i]) begin // If second half index < first half index, swap
                    temp[i] = vector_to_merge[j];
                    temp[j] = vector_to_merge[i];
                end
            end
            stage <= Valid(temp); // Set stage to temp vector
        end 
        else stage <= Invalid; // If invalid input, then set output of stage to invalid

        if (isValid(stage)) begin
            bot.in = Valid(take(fromMaybe(?, stage)));      // If valid value in stage, separate top and bot
            top.in = Valid(takeTail(fromMaybe(?, stage)));
        end 
        else begin
            bot.in = Invalid; // If no valid in from stage, then set both recursions to Invalid
            top.in = Invalid;
        end
    endrule

    method Maybe#(Vector#(n, Word)) toMerge;
	return (isValid(bot.toMerge) && isValid(top.toMerge)) ?  // Return on valid inputs
		Valid(
            append(
                fromMaybe(?, bot.toMerge), fromMaybe(?, top.toMerge) // Append Valid merge recursion together
            )
        )
		: Invalid; // If both are not valid, return Invalid
    endmethod
endmodule

module BitonicMerger#(2);
    BitonicSorter#(2) ret; // Initialize size 2 result

    input Maybe#(Vector#(2, Word)) in default = Invalid; // Initialize input

    rule merge;
	    ret.in = (isValid(in)) ? in : Invalid; // Set to in if valid, otherwise Invalid
    endrule

    method Maybe#(Vector#(2, Word)) toMerge; // Call sort, to merge sorted values
	    return ret.toSort;
    endmethod
endmodule
