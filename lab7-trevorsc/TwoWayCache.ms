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

// TODO: Complete the implementation of TwoWayCache
// NOTE: Implementing this module requires about 20 new lines of code from DirectMappedCache
module TwoWayCache(MainMemory mainMem);
    // SRAM arrays, one element per way (e.g., dataArrays[0] is the data array of way 0).
    Vector#(2, SRAM#(logCacheSets, Line)) dataArrays;
    Vector#(2, SRAM#(logCacheSets, CacheTag)) tagArrays;
    Vector#(2, SRAM#(logCacheSets, CacheStatus)) statusArrays;

    // LRU bits, one per set. We implement it as registers instead of an SRAM
    // array, because with small caches this is just a few bits (e.g., 64), and
    // SRAMs make sense only for larger memories. This also makes the code
    // simpler, and will make the cache easier to pipeline in the future.
    Vector#(cacheSets, RegU#(Bit#(1))) lru;

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
        if (state == Ready && isValid(req)) begin
            curReq <= fromMaybe(?, req);           // Store current state of cache
            let now = fromMaybe(?, req);

            // Setup SRAM arrays prior to Lookup, do it twice for the parallel setup
            dataArrays[0].req = Valid(DataReq{addr: getIndex(now.addr), write: False, data: ?});
            tagArrays[0].req = Valid(TagReq{addr: getIndex(now.addr), write: False, data: ?});
            statusArrays[0].req = Valid(StatusReq{addr: getIndex(now.addr), write: False, data: ?});
            dataArrays[1].req = Valid(DataReq{addr: getIndex(now.addr), write: False, data: ?});
            tagArrays[1].req = Valid(TagReq{addr: getIndex(now.addr), write: False, data: ?});
            statusArrays[1].req = Valid(StatusReq{addr: getIndex(now.addr), write: False, data: ?});
            state <= Lookup; // Switch to Lookup state since request was Valid
        end 
        

        else if (state == Lookup) begin
            let tag1 = fromMaybe(?, tagArrays[0].data); // Perform lookup in parallel, initialize for both locations
            let tag2 = fromMaybe(?, tagArrays[1].data);
            let data1 = fromMaybe(?, dataArrays[0].data);
            let data2 = fromMaybe(?, dataArrays[1].data);
            let status1 = fromMaybe(?, statusArrays[0].data);
            let status2 = fromMaybe(?, statusArrays[1].data);

            if (tag1 == getTag(curReq.addr) && status1 != NotValid) begin // Hit in way 1
                hits <= hits + 1;
                lru[getIndex(curReq.addr)] <= 1; // push 1 to lru next cycle since way 1 more recent

                if (curReq.op == St) begin
                    let line = fromMaybe(?, dataArrays[0].data); // Get line
                    let wordOffset = getWordOffset(curReq.addr); // Get offset
                    line[wordOffset] = curReq.data;              // Store data

                    // Storing, so label dirty
                    dataArrays[0].req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: line});
                    statusArrays[0].req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
                end
                state <= Ready;
            end
            
            else if (tag2 == getTag(curReq.addr) && status2 != NotValid) begin // Hit in way 2
                hits <= hits + 1;
                lru[getIndex(curReq.addr)] <= 0; // push 0 to lru next cycle since way 2 more recent

                if (curReq.op == St) begin
                    let line = fromMaybe(?, dataArrays[1].data); // Get line
                    let wordOffset = getWordOffset(curReq.addr); // Get offset
                    line[wordOffset] = curReq.data;              // Store data
    
                    // Storing, so label dirty
                    dataArrays[1].req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: line});
                    statusArrays[1].req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
                end
                state <= Ready;
            end 
            
            else if (lru[getIndex(curReq.addr)] == 0) begin      // Miss case, LRU says replace in way 1
                misses <= misses + 1;
                let status = fromMaybe(?, statusArrays[0].data); // Get status

                if (status == Clean || status == NotValid) begin // Clean case
                    // Request missing line from main memory
                    mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});
                    state <= Fill; // After main memory request, must perform Fill, change FSM state here
                end 
                
                else if (status == Dirty) begin                  // Dirty case
                    // Write back replaced line to memory
                    mainMem.req = Valid(LineReq{op: St, lineAddr: {tag1, getIndex(curReq.addr)}, data: data1});
                    state <= Writeback; // If dirty, we need to write to main memory, so transition to Writeback
                end
            end 
            
            else begin                                     // Miss case, LRU says replace in way 2
                misses <= misses + 1;
                let status = fromMaybe(?, statusArrays[1].data);
        
                if (status == Clean || status == NotValid) begin // Clean case
                    // Request missing line from main memory
                    mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});
                    state <= Fill; // After main memory request, must perform Fill, change FSM state here
                end 

                else if (status == Dirty) begin                  // Dirty case
                    // Write back replaced line to memory
                    mainMem.req = Valid(LineReq{op: St, lineAddr: {tag2, getIndex(curReq.addr)}, data: data2});
                    state <= Writeback; // If dirty, we need to write to main memory, so transition to Writeback
                end
            end
        end 


        // Writeback state of FSM
        else if (state == Writeback && mainMem.reqEnabled) begin // Same writeback state as DirectMappedCache
            // Request missing line from main memory
            mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?}); 
            state <= Fill; // When main memory is ready, we go to Fill state per FSM diagram
        end 


        // Fill state of FSM
        else if (state == Fill && isValid(mainMem.data)) begin
            let a = lru[getIndex(curReq.addr)];    // Get lru value to determine where to write over
            let line = fromMaybe(?, mainMem.data); 

            if (curReq.op == Ld) begin // Load operation has status marked clean after fill since not changing
                statusArrays[a].req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Clean});
            end 
            
            else begin                // Store request becomes dirty since we changed data
                let wordOffset = getWordOffset(curReq.addr);
                line[wordOffset] = curReq.data;
                statusArrays[a].req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
            end

            tagArrays[a].req = Valid(TagReq{addr: getIndex(curReq.addr), write: True, data: getTag(curReq.addr)});
            dataArrays[a].req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: line});
            
            lru[getIndex(curReq.addr)] <= ~lru[getIndex(curReq.addr)]; // Switch LRU to other way since it is less recent
            mainMem.req = Invalid;
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

        // This function should take about 5-20 lines of code to implement.
        let data1 = fromMaybe(?, dataArrays[0].data);
        let data2 = fromMaybe(?, dataArrays[1].data);
        let status1 = fromMaybe(?, statusArrays[0].data);
        let status2 = fromMaybe(?, statusArrays[1].data);
        let wordOffset = getWordOffset(curReq.addr);
        let isCurReqOpLd = (curReq.op == Ld);
        let valid1 = tagArrays[0].data == Valid(getTag(curReq.addr)) && status1 != NotValid;
        let valid2 = tagArrays[1].data == Valid(getTag(curReq.addr)) && status2 != NotValid;

        if (state == Lookup && isCurReqOpLd && valid1) begin
            return Valid(data1[wordOffset]);
        end 
        else if (state == Lookup && isCurReqOpLd && valid2) begin
            return Valid(data2[wordOffset]);
        end 
        else if (state == Fill && isValid(mainMem.data) && isCurReqOpLd) begin
            return Valid(fromMaybe(?, mainMem.data)[wordOffset]);
        end 
        else return Invalid;
    endmethod

    method Bit#(32) getHits = hits;
    method Bit#(32) getMisses = misses;
endmodule
