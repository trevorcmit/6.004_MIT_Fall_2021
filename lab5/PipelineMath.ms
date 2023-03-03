import MathFunctions;

// Exercise 4:
// Complete the module below to calculate the mathematical function
// ((abs(in)/3)+10)*7) by calling functions from MathFunction.ms.

module PipelineMath;
  // Pipeline registers (to pass partial results from one stage to the next)
  Reg#(Maybe#(Bit#(16))) stage1(Invalid);
  Reg#(Maybe#(Bit#(16))) stage2(Invalid);
  Reg#(Maybe#(Bit#(16))) result(Invalid);
  // abs = 95ps, add10 = 96 ps, divide3 = 441ps, multiply7 = 286.ps

  input Maybe#(Bit#(16))
    in default = Invalid;

  rule pipeline;
    // EXPLANATION:
    // Stage 1 is solely absolute value, since not enough room for both abs and divide3
    // Stage 2 is just divide3, it takes up almost the entire clock period
    // Result combined multiply7 and add10, since they fit well under 500ps (close to ~380 ps)
    let value = fromMaybe(?, in);
    stage1 <= (isValid(in)) ? Valid((abs(value))) : Invalid;
    stage2 <= (isValid(stage1)) ? Valid(divide3(fromMaybe(?, stage1))) : Invalid;
    result <= (isValid(stage2)) ? Valid(multiply7(add10(fromMaybe(?, stage2)))) : Invalid;
    // From synth: Gates = 589, Area = 772.73 um^2, CPD = 488.45 ps
  endrule

  method Maybe#(Bit#(16)) out = result; // Do not change this line
endmodule
