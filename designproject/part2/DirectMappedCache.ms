import CacheTypes;
import CacheHelpers;
import MainMemory;

// ReqStatus (defined in CacheTypes.ms) is used to keep track of the state of the current request
//typedef enum {
//    Ready,         // The cache is ready for a new request
//    Lookup,        // Issued a lookup to tag/data arrays
//    Writeback,     // In main memory access for dirty writeback
//    Fill           // In main memory access for requested data
//} ReqStatus;
//
// Possible flows:
//   HIT: Ready -> Lookup -> Ready
//   MISS, line is clean: Ready -> Lookup -> Fill
//   MISS, line is dirty: Ready -> Lookup -> Writeback -> Fill

// Cache SRAM Synonyms (defined in CacheTypes.ms)
// You may find the following type synonyms helpful to access the tag/data/status arrays
// typedef SRAMReq#(logCacheSets, CacheTag) TagReq;
// typedef SRAMReq#(logCacheSets, Line) DataReq;
// typedef SRAMReq#(logCacheSets, CacheStatus) StatusReq;

// TODO: Complete the implementation of DirectMappedCache
// NOTE: Implementing this module requires about 50 lines of additional code
// (~40 lines in the rule, ~5-10 lines in the data method, and 1 line in the reqEnabled method)
module DirectMappedCache(MainMemory mainMem);
    // SRAM arrays. Note that, for a direct-mapped cache,
    // number of cache sets == number of cache lines
    SRAM#(logCacheSets, Line) dataArray;
    SRAM#(logCacheSets, CacheTag) tagArray;
    SRAM#(logCacheSets, CacheStatus) statusArray;
    
    // Registers for holding the current state of the cache and how far along it is in processing a request.
    RegU#(MemReq) curReq;
    Reg#(ReqStatus) state(Ready);
    
    // Hit/miss counters
    Reg#(Word) hits(0);
    Reg#(Word) misses(0);

    input Maybe#(MemReq) req default = Invalid;
    
    // Return True if the cache can accept a new request
    method Bool reqEnabled = (state == Ready); 

    rule tick;
        if (state == Ready && isValid(req)) begin // Ready state of FSM, can begin work since req is Valid
            curReq <= fromMaybe(?, req);          // Store current state of cache
            let now = fromMaybe(?, req);

            // Fill SRAM arrays prior to Lookup
            dataArray.req = Valid(DataReq{addr: getIndex(now.addr), write: False, data: ?});
            tagArray.req = Valid(TagReq{addr: getIndex(now.addr), write: False, data: ?});
            statusArray.req = Valid(StatusReq{addr: getIndex(now.addr), write: False, data: ?});
            state <= Lookup; // Switch to Lookup state since request was Valid
        end 


        else if (state == Lookup) begin                   // Lookup state of FSM
            let data = fromMaybe(?, dataArray.data);      // Call arrays to get necessary data 
            let tag = fromMaybe(?, tagArray.data);
            let status = fromMaybe(?, statusArray.data);

            if (tag == getTag(curReq.addr) && status != NotValid) begin // Hit, have tag and valid Status
                hits <= hits + 1;
                    
                if (curReq.op == St) begin                       // Store request
                    let line = fromMaybe(?, dataArray.data); // Get line
                    let wordOffset = getWordOffset(curReq.addr); // Get offset based on address
                    line[wordOffset] = curReq.data;

                    // Change data and status SRAM with requested data and set write to True
                    dataArray.req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: line});
                    statusArray.req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
                end
                state <= Ready; // Return to Ready state of FSM
            end 

            else if (status == Clean || status == NotValid) begin // Clean miss state
                mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});
                misses <= misses + 1;
                state <= Fill;           // After main memory request, must perform Fill, change FSM state here
            end 

            else if (status == Dirty) begin // Dirty miss state, must write back to main memory then request missing line
                mainMem.req = Valid(LineReq{op: St, lineAddr: {tag, getIndex(curReq.addr)}, data: data});
                misses <= misses + 1;
                state <= Writeback;      // If dirty, we need to write to main memory, so transition to Writeback
            end      
        end 

        
        else if (state == Writeback && mainMem.reqEnabled) begin // reqEnabled returns true if mainMem can accept new request
            mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});
            state <= Fill;   // When main memory is ready, we go to Fill state per FSM diagram
        end

        
        else if (state == Fill && isValid(mainMem.data)) begin // Fill state of FSM
            let line = fromMaybe(?, mainMem.data);

            if (curReq.op == Ld) begin // Clean miss case, set status with data : Clean for main memory load 
                statusArray.req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Clean});
            end 
            
            else if (curReq.op == St) begin // Dirty miss case, data : Dirty, get new line from memory
                let wordOffset = getWordOffset(curReq.addr);
                line[wordOffset] = curReq.data;
                statusArray.req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
            end
            
            mainMem.req = Invalid;
            tagArray.req = Valid(TagReq{addr: getIndex(curReq.addr), write: True, data: getTag(curReq.addr)});
            dataArray.req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: line});
            state <= Ready; // Return to Ready state since valid main memory data
        end
    endrule

    method Maybe#(Word) data;
        // This method should return a Valid output in only two cases:
        // 1. On a load hit (we're in the Lookup state, there's a hit, and
        //    curReq.op == Ld).
        // 2. On a fill for a load request (we're in the Fill state,
        //    mainMem.data is valid, and curReq.op == Ld).
        // In all other cases, the output should be Invalid
        //
        // NOTE: You should be checking the above conditions explicitly in
        //    THIS method so you can return data as soon as possible.
        //    DO NOT place your output into a register in the rule and then
        //    simply return that register here.

        // This function should take about 4-8 lines of code to implement.

        let status = fromMaybe(?, statusArray.data);
        let wordOffset = getWordOffset(curReq.addr);
        let oper = curReq.op;

        // Lookup state, tag hits, and Ld operation
        if (state == Lookup && tagArray.data == Valid(getTag(curReq.addr)) && oper == Ld) begin
            let cacheData = fromMaybe(?, dataArray.data);
            return Valid(cacheData[wordOffset]);
        end 
        
        // Fill state, main memory is valid, and Ld operation
        else if (state == Fill && isValid(mainMem.data) && oper == Ld) begin
            return Valid(fromMaybe(?, mainMem.data)[wordOffset]);
        end 
        
        // Otherwise, Invalid
        else begin
            return Invalid;
        end  
    endmethod

    method Bit#(32) getHits = hits;
    method Bit#(32) getMisses = misses;
endmodule
