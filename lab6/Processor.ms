import ProcTypes;
import RegisterFile;
import Decode;
import Execute;
import MagicMemory;

module Processor;
    Reg#(Word) pc(0);
    RegisterFile rf;
    MagicMemory iMem; // Memory for loading instructions
    MagicMemory dMem; // Memory for loading and storing data

    rule doSingleCycle;
        // Load the instruction from instruction memory (iMem)
        Word inst = iMem.read(pc); // Use MagicMemory to read program counter

        // Decode the instruction
        DecodedInst dInst = decode(inst); // Decode read from iMem

        // Read the register values used by the instruction
        Word rVal1 = rf.rd1(dInst.src1);  // Get rd1
        Word rVal2 = rf.rd2(dInst.src2);  // Get rd2

        // Compute all outputs of the instruction
        ExecInst eInst = execute(dInst, rVal1, rVal2, pc); // Call execute function on the instance
                                                           // with both inputs and including pc                   

        if (eInst.iType == LOAD) begin // Load from data memory (dMem) if the instruction requires it
            eInst.data = dMem.read(eInst.addr); // Set exec. instance data to reading exec. address
        end 
        else if (eInst.iType == STORE) begin // Store to data memory (dMem) if the instruction requires it
            dMem.write = Valid(                                 // Write to magic mem., data -> address
                MemWriteReq{addr: eInst.addr, data: eInst.data} // Including Valid set
            );                                                 
        end

        if (isValid(eInst.dst)) begin // Write to a register if the instruction requires it
            rf.wr = Valid(                                                     // Valid set
                RegWriteArgs{index: fromMaybe(?, eInst.dst), data: eInst.data} // write data to dest. reg
            );
        end
        else begin
            rf.wr = Invalid; // Set write to invalid since we don't require a register write
        end

        pc <= eInst.nextPc; // Update pc to the next pc

        // If unsupported instruction, stops simulation and print the state of the processor
        // IMPORTANT: Do not modify this code! The microtests check for it.
        if (eInst.iType == Unsupported) begin
            $display("Reached unsupported instruction (0x%x)", inst);
            $display("Dumping the state of the processor");
            $display("pc = 0x%x", pc);
            $display(rf.fshow);
            $display("Quitting simulation.");
            $finish;
        end
    endrule

    // This method exists to make the processor synthesizable: synth removes
    // circuits without outputs, so we need some non-trivial output to avoid
    // removing the processor :)
    method Word getPc = pc;
endmodule
