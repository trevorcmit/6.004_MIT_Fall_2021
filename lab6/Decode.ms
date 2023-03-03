import ProcTypes;

////////////////////////////////////////////////////////////////////////////////////////////
/// The following are relevant types and constants for the decoder, copied from ProcTypes.ms
////////////////////////////////////////////////////////////////////////////////////////////
// typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC, Unsupported} IType;

// typedef struct {
//     IType iType;
//     AluFunc aluFunc;
//     BrFunc brFunc;
//     RDst dst;
//     RIndx src1;
//     RIndx src2;
//     Word imm;
// } DecodedInst;

// // Opcode
// Bit#(7) opOpImm  = 7'b0010011;
// Bit#(7) opOp     = 7'b0110011;
// Bit#(7) opLui    = 7'b0110111;
// Bit#(7) opJal    = 7'b1101111;
// Bit#(7) opJalr   = 7'b1100111;
// Bit#(7) opBranch = 7'b1100011;
// Bit#(7) opLoad   = 7'b0000011;
// Bit#(7) opStore  = 7'b0100011;
// Bit#(7) opAuipc  = 7'b0010111;

// // funct3 - ALU
// Bit#(3) fnADD   = 3'b000;
// Bit#(3) fnSLL   = 3'b001;
// Bit#(3) fnSLT   = 3'b010;
// Bit#(3) fnSLTU  = 3'b011;
// Bit#(3) fnXOR   = 3'b100;
// Bit#(3) fnSR    = 3'b101;
// Bit#(3) fnOR    = 3'b110;
// Bit#(3) fnAND   = 3'b111;
// // funct3 - Branch
// Bit#(3) fnBEQ   = 3'b000;
// Bit#(3) fnBNE   = 3'b001;
// Bit#(3) fnBLT   = 3'b100;
// Bit#(3) fnBGE   = 3'b101;
// Bit#(3) fnBLTU  = 3'b110;
// Bit#(3) fnBGEU  = 3'b111;
// // funct3 - Load
// Bit#(3) fnLW    = 3'b010;
// Bit#(3) fnLB    = 3'b000;
// Bit#(3) fnLH    = 3'b001;
// Bit#(3) fnLBU   = 3'b100;
// Bit#(3) fnLHU   = 3'b101;
// // funct3 - Store
// Bit#(3) fnSW    = 3'b010;
// Bit#(3) fnSB    = 3'b000;
// Bit#(3) fnSH    = 3'b001;
// // funct3 - JALR
// Bit#(3) fnJALR  = 3'b000;

function DecodedInst decode(Bit#(32) inst);
    let opcode = inst[6:0];
    let funct3 = inst[14:12];
    let funct7 = inst[31:25];
    let dst    = inst[11:7];
    let src1   = inst[19:15];
    let src2   = inst[24:20];

    Maybe#(RIndx) validDst = Valid(dst);
    Maybe#(RIndx) dDst = Invalid; // default value
    RIndx dSrc = 5'b0;

    // DEFAULT VALUES - Use the following for your default values:

    // dst: dDst
    // src1: dSrc
    // src2: dSrc
    // imm: immD
    // BrFunc: Dbr
    // AluFunc: ?

    // Since many groups of instructions use the same immediate constructed
    // from the same pattern of bits of the instruction (corresponding to the
    // "type", i.e. I-type, S-type, B-type, U-type, or J-type, described in the
    // RISC-V reference), we construct all the immediates first so we can use
    // them in multiple places. We can do this in two steps for each pattern:
    // (1) Concatenate all the immediate bits from the instruction.
    // (2) Sign-extend and/or pad with 0s on the right to produce a 32-bit word.

    // We have provided a default value and done immB for you.
    Word immD32 = signExtend(1'b0); // default value

    Bit#(12) immB = {inst[31], inst[7], inst[30:25], inst[11:8]};
    Word immB32 = signExtend({immB, 1'b0});

    // Consult the RISC-V reference and fill in the correct value for the other
    // immediates (these are provided in the order the microtests test them):
    Bit#(20) immU = inst[31:12];
    Word immU32 = signExtend({immU, 12'b0});

    Bit#(12) immI = inst[31:20];
    Word immI32 = signExtend(immI);

    Bit#(20) immJ = {inst[31], inst[19:12], inst[20], inst[30:21]};
    Word immJ32 = signExtend({immJ, 1'b0});

    Bit#(12) immS = {inst[31:25], inst[11:7]};
    Word immS32 = signExtend(immS);

    DecodedInst dInst = unpack(0);
    dInst.iType = Unsupported; // unsupported by default

    case (opcode)
        opAuipc: begin
            // There are two ways you might want to construct the DecodedInst.
            // One is to create a complete DecodedInst all at once, which you
            // can do with this syntax: the name of the struct "DecodedInst"
            // followed by curly braces. Inside the braces, each field is
            // specified by fieldName: fieldValue, separated by commas.

            // NOTE: this will only work after you've correctly filled in immU/immU32
            // above!
            dInst = DecodedInst {
                iType: AUIPC, 
                dst: validDst, 
                src1: dSrc, 
                src2: dSrc, 
                imm: immU32, 
                brFunc: Dbr, 
                aluFunc: ?
            };
        end

        opLui: begin
            // Decode instructions of type LUI here
            dInst = DecodedInst { // Same setup as opAuipc but with iType LUI
                iType: LUI, 
                dst: validDst, 
                src1: dSrc, 
                src2: dSrc, 
                imm: immU32, 
                brFunc: Dbr,  
                aluFunc: ?
            };
        end // Should pass microtest 1

        opOpImm: begin
            dInst.iType = OPIMM;    // Assign iType, src1, and dest since 
            dInst.src1  = src1;     // they all have the same ones
            dInst.imm   = immI32;
            dInst.dst   = validDst;

            // However, note that even if opcode == opOpImm, it's still
            // possible that the instruction we're decoding is invalid, for
            // example if funct3 (i.e. inst[14:12]) corresponds to SLLI, but
            // funct7 (i.e. inst[31:25]) is not all 0s. (If you consult the
            // RISC-V reference you'll see that valid SLLI instructions must
            // start with seven 0 bits.) In those cases we have to say that the
            // instruction is invalid by setting dInst.iType back to
            // Unsupported.

            case (funct3)
                fnAND :  dInst.aluFunc = And; // Decode ANDI instructions
                fnOR :   dInst.aluFunc = Or;
                fnXOR :  dInst.aluFunc = Xor;
                fnADD :  dInst.aluFunc = Add;
                fnSLT :  dInst.aluFunc = Slt;
                fnSLTU : dInst.aluFunc = Sltu; 
                fnSLL : case (funct7)
                    7'b0000000: dInst.aluFunc = Sll;       // If all zero, set aluFunc to Sll
                    default:    dInst.iType = Unsupported; // Otherwise we must say the instruction is invalid:
                endcase
                fnSR : case (funct7)
                    7'b0000000: dInst.aluFunc = Srl;       // Logical 
                    7'b0100000: dInst.aluFunc = Sra;       // Arithmetic
                    default:    dInst.iType = Unsupported;
                endcase
                default: dInst.iType = Unsupported;        // Default for funct3 overarching case
            endcase
        end // Should pass microtest 2

        opOp: begin
            // Decode instructions of type OP here (i.e. ADD, SUB, AND, OR, XOR, SLT, SLTU, SLL, SRL, and SRA)
            dInst.iType = OP;     // Grab instruction, src values, imm, and destination
            dInst.src1 = src1;
            dInst.src2 = src2;
            dInst.imm = immD32;
            dInst.dst = validDst;

            case (funct3)
                fnAND: case (funct7)
                    7'b0000000: dInst.aluFunc = And;       // Verify funct7's have no ones
                    default:    dInst.iType = Unsupported;
                endcase
                fnOR: case (funct7)
                    7'b0000000: dInst.aluFunc = Or;
                    default:    dInst.iType = Unsupported;
                endcase
                fnXOR: case (funct7)
                    7'b0000000: dInst.aluFunc = Xor;
                    default:    dInst.iType = Unsupported;
                endcase
		        fnSLT: case (funct7)
                    7'b0000000: dInst.aluFunc = Slt;
                    default:    dInst.iType = Unsupported;
                endcase
                fnSLTU: case (funct7)
                    7'b0000000: dInst.aluFunc = Sltu;
                    default:    dInst.iType = Unsupported;
                endcase
                fnADD: case (funct7)
                    7'b0000000: dInst.aluFunc = Add;       // Use func7 to distinguish Adding/Subtracting
                    7'b0100000: dInst.aluFunc = Sub;
                    default:    dInst.iType = Unsupported;
		        endcase
                fnSLL: case (funct7)
                    7'b0000000: dInst.aluFunc = Sll;       // Check for logical left
                    default: 	dInst.iType = Unsupported;
                endcase
                fnSR: case (funct7)
                    7'b0000000: dInst.aluFunc = Srl;       // Distinguish logical/arithmetic
                    7'b0100000: dInst.aluFunc = Sra;
                    default:    dInst.iType = Unsupported;
                endcase
            default: dInst.iType = Unsupported;
            endcase
        end

        opBranch: begin // Decode instructions of type BRANCH here (i.e. BEQ, BNE, BLT, BGE, BLTU, and BGEU)
            dInst.iType = BRANCH; // Set dInst variables
            dInst.src1 = src1;
            dInst.src2 = src2;
            dInst.imm = immB32;

            case (funct3)
                fnBEQ:   dInst.brFunc = Eq;  // Set dInst's brFunc based on cases
                fnBNE:   dInst.brFunc = Neq;
                fnBLT:   dInst.brFunc = Lt;
                fnBGE:   dInst.brFunc = Ge;
                fnBLTU:  dInst.brFunc = Ltu;
                fnBGEU:  dInst.brFunc = Geu;
                default: dInst.iType = Unsupported;
            endcase
        end // Should pass microtest 4.

        opJal: begin // Decode instructions of type JAL here
            dInst.iType = JAL;    // Setup dInst for a link
            dInst.src1 = src1;
            dInst.src2 = src2;
            dInst.imm = immJ32;
            dInst.dst = validDst;
        end // Should pass microtest 5.

        opLoad: begin // Decode instructions of type LOAD here (i.e. LW)
            dInst.src1 = src1;
            dInst.imm = immI32;
            dInst.dst = validDst;

            case (funct3)
                3'b010:  dInst.iType = LOAD;         // fnLW
                default: dInst.iType = Unsupported; // Rest of funct3 - Load ProcTypes
            endcase  
        end // Should pass microtest 7 (skip 6 since it tests AUIPC but requires JAL)

        opStore: begin // Decode instructions of type STORE here (i.e. SW)
            dInst.src1 = src1;
            dInst.src2 = src2;
            dInst.imm = immS32;

            case (funct3)
                3'b010:  dInst.iType = STORE;        // fnSW
                default: dInst.iType = Unsupported; // Rest of funct3 - Store ProcTypes
            endcase
        end // Should pass microtest 8

        opJalr: begin // Decode instructions of type JALR here
            dInst.src1 = src1;
            dInst.imm = immI32;
            dInst.dst = validDst;

            case (funct3)
                3'b000:  dInst.iType = JALR;         // Only JALR supported
                default: dInst.iType = Unsupported;
            endcase
        end // Should pass microtest 9

    endcase
    return dInst; // Return the instance to be executed
endfunction
