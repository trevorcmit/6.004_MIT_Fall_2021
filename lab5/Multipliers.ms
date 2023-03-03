// Two inputs to an n-bit multiplier.
typedef struct {
    Bit#(n) a;
    Bit#(n) b; 
} MultiplierInput#( Integer n ); 


// Reference functions that use the '*' operator
function Bit#(2*n) multiply_unsigned#(Integer n)(Bit#(n) a, Bit#(n) b);
    return zeroExtend(a) * zeroExtend(b);
endfunction


function Bit#(2*n) multiply_signed#(Integer n)(Bit#(n) a, Bit#(n) b);
    Int#(n) a_int = unpack(a);
    Int#(n) b_int = unpack(b);
    Int#(2*n) product_int = signExtend(a_int) * signExtend(b_int);
    return pack(product_int);
endfunction


// Multiplication by repeated addition
function Bit#(2*n) multiply_by_adding#(Integer n)(Bit#(n) a, Bit#(n) b);
    // TODO: Implement this in Exercise 1
    Bit#(n) high = 0; // Initialize higher half of bits in output which will help calculate ongoing sum
    Bit#(n) low = 0;  // Initialize lower half of bits in output which will be added onto bit by bit
    for (Integer i = 0; i < n; i = i + 1) begin
        // If value of a is 1, we extend high which contains ongoing carry and add b so it is adjusted by current sum
        Bit#(n + 1) sum = (a[i] == 1) ? zeroExtend(high) + zeroExtend(b) : zeroExtend(high); // referenced as mi in lecture
        low[i] = sum[0]; // Set current low bit to result from summation
        high = sum[n:1]; // Set high to current sum value except first bit
        // ^ equivalent to shift which drops the first bit
    end 
    return {high, low}; // Attach lower bits to higher bits for 2n bit output
endfunction


// Folded multiplier by repeated addition
module FoldedMultiplier#(Integer n);

    RegU#(Bit#(n)) a;               // Initialize a
    RegU#(Bit#(n)) b;               // Initialize b
    RegU#(Bit#(2*n)) prod_reg;      // Initialize where product will be stored
    RegU#(Bit#(log2(n)+1)) i;       // Initialize counter i for iteration
    Reg#(Bool) in_progress(False);  // Initialize Boolean to handle start/end

    // When there is a new pair of numbers to multiply, they will be passed in as a valid MultiplierInput.
    input Maybe#(MultiplierInput#(n)) in default = Invalid;

    rule mulStep;
        // TODO: Implement this in Exercise 2: This rule can be implemented in about 15 lines of code
        if (!in_progress && isValid(in)) begin
            a <= fromMaybe(?, in).a; // If valid input, get a and b from input n
            b <= fromMaybe(?, in).b;
            prod_reg <= 0;           // Product set to zero
            in_progress <= True;     // Set in_progress to True since valid input has been found
            i <= 0;                  // Start counter at i
        end 
        else if (i < n && in_progress) begin
            Bit#(2*n) m = {0, a} & signExtend(b[i]);        // & current b index with a number
            prod_reg <= prod_reg + (m << i);                // Shift m and add to outcome product
            i <= i  + 1;                                    // Increase iteration counter
            in_progress <= (i < n-1) ? in_progress : False; // If iterations less than length, continue
        end
    endrule

    // getResult should return the most recent multiplication result,
    // or Invalid if the multiplier is calculating the next result.
    // If no input has been given yet, the result should be Invalid.
    method Maybe#(Bit#(2*n)) getResult; // getResult method
        // TODO: Implement this in Exercise 2
        // NOTE: This method can be implemented in about 1 line of code
        return (i == n) ? Valid(prod_reg) : Invalid; 
    endmethod
endmodule


// Fast folded multiplier by repeated addition
module FastFoldedMultiplier#( Integer n );
    // You can use these registers or create your own if you want
    // RegU#(Bit#(n)) a;
    // RegU#(Bit#(n)) b;
    // RegU#(Bit#(n)) prod;
    // RegU#(Bit#(n)) tp;
    // Reg#(Maybe#(Bit#(log2(n)+1))) i(Invalid); // This is a Maybe type

    RegU#(Bit#(n)) a;               // Initialize a
    RegU#(Bit#(n)) b;               // Initialize b
    RegU#(Bit#(2*n)) prod_reg;      // Initialize where product will be stored
    RegU#(Bit#(log2(n)+1)) i;       // Initialize counter i for iteration
    Reg#(Bool) in_progress(False);  // Initialize Boolean to handle start/end

    RegU#(Bit#(2*n)) test;
    RegU#(Bit#(1)) zero_carry;

    // When there is a new pair of numbers to multiply, they
    // will be passed in as a valid MultiplierInput.
    input Maybe#(MultiplierInput#(n)) in default = Invalid;

    rule mulStep;
        // TODO: Implement this in Exercise 3
        if (!in_progress && isValid(in)) begin
            zero_carry <= 0;
            a <= fromMaybe(?, in).a; // If valid input, get a and b from input n
            b <= fromMaybe(?, in).b;
            prod_reg <= 0;               // Product set to zero
            in_progress <= True;     // Set in_progress to True since valid input has been found
            i <= 0;                  // Start iteration counter at i
        end 
        else if (i < n && in_progress) begin
            Bit#(2*n) m = {0, a} & signExtend(b[i]);        // & current b index with a number
            // prod_reg <= prod_reg + (m << i);                // Shift m and add to outcome product
            test <= m << i;
            // prog_reg <= fastAdd(prod_reg, test, zero_carry);
            i <= i  + 1;                                    // Increase iteration counter
            in_progress <= (i < n-1) ? in_progress : False; // If iterations less than length, continue
        end
    endrule

    // getResult should return the most recent multiplication result,
    // or Invalid if the multiplier is calculating the next result.
    // If no input has been given yet, the result should be Invalid.
    method Maybe#(Bit#(2*n)) getResult;
        // TODO: Implement this in Exercise 3
        // NOTE: This method can be implemented in about 1 line of code
        // return Invalid;
        return (i == n) ? Valid(prod_reg) : Invalid; 
    endmethod
endmodule


// FastAdder code from previous PSET, recommended to use by the PSET handout
function Bit#(n) fastAdd#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    Bit#(n+1) ret = fastAdd_recursion#(n)(a, b, carryIn); // Call recursive function on n+1 bits
    return ret[n-1:0]; // Return chopped version of ret array
endfunction


function Bit#(n+1) fastAdd_recursion#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);

    Bit#(n+1) ret = 0; // Use n+1 bits to store carry value for checking it

    if (n == 1) begin
        ret = fullAdder(a, b, carryIn); // Base case: utilize fullAdder for 1 bit addition
    end
        else begin // Else case, recurse onto carry-select implementation

        Bit#(n/2+1) low = fastAdd_recursion#(n/2)(a[(n/2-1):0], b[(n/2-1):0], carryIn); // Lower section
        Bit#(n/2+1) high_zer = fastAdd_recursion#(n/2)(a[n-1:n/2], b[n-1:n/2], 0); // If carry zero
        Bit#(n/2+1) high_one = fastAdd_recursion#(n/2)(a[n-1:n/2], b[n-1:n/2], 1); // If carry one

        if (low[n/2] == 0) begin
            ret = {high_zer, low[(n/2-1):0]}; // If low has carry zero, utilize high_zero
        end
        else begin
            ret = {high_one, low[(n/2-1):0]}; // If low has carry one, utilize high_one
        end
    end

    return ret; 
endfunction
