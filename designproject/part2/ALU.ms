// Don't change signature of existing functions. You may write additional helper functions if you want.

// Description: 32-bit right barrel shifter
// Arguments: in (value to be shifted); sftSz (shift size); sft_in (the bit shifted in)
// Return: {sft_in's, in[31:sftSz]}
function Bit#(32) barrelRShift(Bit#(32) in, Bit#(5) sftSz, Bit#(1) sft_in);
    Bit #(32) ret = in;                          // Initialize value to be shifted
    Integer pow_two = 0;                         // Initialize integer to determine power of 2 at specific point in time
    for (Integer i = 0; i < 5; i = i + 1) begin  // Iterate over indices in sftSz
	    pow_two = 1 << i;                        // Calculate number of bits we'd need to shift in this loop
   	    ret = (sftSz[i] == 1) ? {signExtend(sft_in), ret[31:pow_two]} : ret; // Check if shift necessary
    end
    return ret; // Return final value as the result of all the shifts
endfunction

// Description: 32-bit arithmetic/logic right shifter
// Arguments: in (value to be shifted); sftSz (shift size); arith (1 = arithmetic, 0 = logic)
// Return: in >> sftSz
function Bit#(32) sr32(Bit#(32) in, Bit#(5) sftSz, Bit#(1) arith);
    Bit #(1) msb = (arith == 1) ? in[31] : 0; // Check arith vs log to pick MSB value to shift in
    return barrelRShift(in, sftSz, msb);      // Perform barrel shift using chosen MSB value
endfunction


// Description: 32-bit logic left shifter
// Arguments: in (values to be shifted); sftSz (shift size)
// Return: a << b
function Bit#(32) sll32(Bit#(32) in, Bit#(5) sftSz);
    return reverseBits(
        barrelRShift(
            reverseBits(in), sftSz, 0 // Right shift zeros on reverse of input, then reverse back
        )
    );
endfunction


// Description: 32-bit FULL shifter
// Arguments: in (value to be shifted); sftSz (shift size); 
// ShiftTypes:
// LogicalRightShift 
// ArithmeticRightShift
// LeftShift
// Return: in >> sftSz when right shift; in << sftSz otherwise
typedef enum {LogicalRightShift, ArithmeticRightShift, LeftShift} ShiftType;

function Bit#(32) sft32(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
    Bit #(32) right_in = (shiftType == LeftShift) ? reverseBits(in) : in; // Make input right direction
    Bit #(1) msb = (shiftType == ArithmeticRightShift) ? in[31] : 0;      // Choose bit to shift if arithmetic
    Bit #(32) shifted = barrelRShift(right_in, sftSz, msb);               // Perform barrel shift
    return (shiftType == LeftShift) ? reverseBits(shifted) : shifted;     // Reverse back if left shift   
endfunction


// Description: one-bit less-than comparator
// Arguments: a, b (1-bit values), eq, lt (eq and lt from previous comparator)
// Return: {eq_i, lt_i}
function Bit#(2) cmp(Bit#(1) a, Bit#(1) b, Bit#(1) eq, Bit#(1) lt);
    // eq_i = 1 IF a=b and eq=1 (equal up until i) and lt=0 (a<b up until i)
    Bit#(1) eq_i = eq & ~lt & ((~a & ~b) | (a & b));
    // If lt already 1, a<b and that cannot change, otherwise check if even up until now and a<b
    Bit#(1) lt_i = lt | (eq & ~a & b);
    return {eq_i, lt_i}; // Return list of both eq_i and lt_i
endfunction

// Description: unsigned 32-bit less-than comparator
// Arguments: a, b unsigned 32-bit values
// Return: 1 if a < b 
function Bit#(1) ltu32(Bit#(32) a, Bit#(32) b); 
    Bit#(1) eq = 1; // Input 1 and 0, since no comparisons made yet (PSET tells us to start with these)
    Bit#(1) lt = 0;
    for (Integer i = 31; i >= 0; i = i - 1) begin // Iterate over all bits in the 32-bit inputs
        Bit #(2) cmp_i = cmp(a[i], b[i], eq, lt);
        lt = cmp_i[0];
        eq = cmp_i[1]; // Update lt_i and eq_i for next iteration
    end
    return lt; // If final lt is 1 a<b, otherwise a>=b and lt=0
endfunction

// Description: Signed/Unsigned 32-bit less-than comparator
// Arguments: a b (32-bit values); isSigned (signed comparator when 1, unsigned otherwise)
// Return: 1 if a < b
function Bit#(1) lt32(Bit#(32) a, Bit#(32) b, Bit#(1) isSigned);
    // If number is signed, changing MSB allows comparison to occur
    // If not signed, compare a and b normally
    // If signed, flip MSB's:
        // - MSB = 1 means negative, so make first digit zero so if other value is positive
        //   it won't have highest possible bit value. If both negative, it's normal comparison.
        // - MSB = 0 means positive, so make it 1 so it has highest possible bit value, and comparison
        //   occurs on the remaining 31 bits. If both positive it's normal comparison.
    return ltu32(
        (isSigned == 1) ? {~a[31], a[30:0]} : a, 
        (isSigned == 1) ? {~b[31], b[30:0]} : b
    );
endfunction

// Description: one-bit full adder
// Arguments: a, b, carry in
// Return: {carry out, sum}
function Bit#(2) fullAdder(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
    // Code from fullAdder from Lab 3
    // Bit#(1) s = xor1(xor1(a, b), carryIn); // Boolean formula for S from truth table
    // Bit#(1) carryOut = or1(
    //                     or1(
    //                         and1(a, b), and1(a, carryIn) // At least one of these and pairs is necessary
    //                     ), 
    //                     and1(b, carryIn)
    //                 ); // Boolean formula for C_out from the truth table
    // return {carryOut, sum}; // Return 2 bit array of both values
    return {
        (a & b) | (a & carryIn) | (b & carryIn), // carryOut
        a ^ b ^ carryIn                          // sum
    }; // Return 2 bit array of both values
endfunction

// Description: n-bit ripple-carry adder with a carry-in
// Arguments: a, b, carryIn
// Return: sum of a, b, and carryIn
function Bit#(n) rca#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    Bit#(n) sum = 0;         // Initialize sum to zero
    Bit#(n + 1) carry = 0;   // Initialize carry, add input carryIn to it
    carry[0] = carryIn;
    for (Integer i = 0; i < n; i = i + 1) begin        // Loop over all bits
        Bit#(2) add = fullAdder(a[i], b[i], carry[i]); // Perform full adder on current bit with indexed carry
        sum[i] = add[0];                               // Set sum bit to output of adder
        carry[i + 1] = add[1];                         // Add to carry from output of adder
    end
    return sum; // Return final sum
endfunction

// Description: n-bit ripple-carry adder/subractor
// Arguments: a, b (n-bit operands); isSub (1 => subtract, 0 => add)
// Return: isSub == 0 ? a + b : a - b
function Bit#(n) addSub#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) isSub);
    // Utilize RCA, if isSub==1 then we reverse b and add 1 (making b negative)
    return rca#(n) (a, (isSub == 1) ? ~b : b, isSub);
endfunction


// Alu Functions:
// Add: 32-bit Addition         (a + b)
// Sub: 32-bit Subtraction      (a - b)
// And: 32-bit Bitwise And      (a & b)
// Or: 32-bit Bitwise Or        (a | b)
// Xor: 32-bit Bitwise Xor      (a ^ b)
// Slt: Set less than           (a <u b ? 1 : 0)
// Sltu: Set less than unsigned (a <s b ? 1:0)
// Sll: Left logic shfit        (a << b)
// Srl: Right logic shift       (a >>u b)
// Sra: Right arithmetic shift  (a >>s b)
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc;

// Description: Arithmetic Logic Unit (ALU)
// Arguments: a, operand a; b, operand b; func, ALU operation
// Return: output of ALU
function Bit#(32) alu(Bit#(32) a, Bit#(32) b, AluFunc func);
    Bit #(32) ret = 0; // Initialize 32 bit output

    if (func == And) ret = a & b; // Check for boolean inputs
    if (func == Or)  ret = a | b;
    if (func == Xor) ret = a ^ b;

    if (func == Sub || func == Add) ret = addSub#(32) (a, b, (func == Sub) ? 1 : 0); // Adds and Subs

    if (func == Slt || func == Sltu) ret = zeroExtend(lt32(a, b, (func == Slt) ? 1 : 0)); // Less than functions

    ShiftType shift_type = LeftShift; // If else statement for deciding shifts
    if (func == Srl) shift_type = LogicalRightShift;
    else if (func == Sra) shift_type = ArithmeticRightShift;
    if (func == Sll || func == Srl || func == Sra) ret = sft32(a, b[4:0], shift_type);
    
    return ret; // Finally return if none of the conditionals pass (one should), but function must return always
endfunction


// Description: Alternative shifter implementation (Discussion Question)
function Bit#(32) sft32_alt(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
    return (shiftType == LeftShift) ? sft32(in, sftSz, LeftShift) : ((shiftType == ArithmeticRightShift)? sft32(in, sftSz, ArithmeticRightShift) : sft32(in, sftSz, LogicalRightShift));
endfunction


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
