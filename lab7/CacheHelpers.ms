import CacheTypes;

// Address Helper Functions
// NOTE: Each of these functions can be implemented with a single line.
// Use the constants logCacheSets and logWordsPerLine, defined in CacheTypes.ms
////////////////////////////////////////

// Extract the Cache Line Index from a given memory address
function CacheIndex getIndex(Word byteAddress);
    // In context of PSET with logCacheSets = 6 and logWordsPerLine=4, the
    // indices become [11:6]. Reading left to right this function returns
    // six bits after the first four, those first four being the tag bits.
    // In summary, function gets a logCacheSets-sized set of bits that follow
    // the leading tag bits, the line index bits.
    return byteAddress[logWordsPerLine + 1 + logCacheSets : logWordsPerLine + 2];
endfunction

// Extract the Cache Line Tag from a given memory address
function CacheTag getTag(Word byteAddress);
    // The higher index slice value is just 31, since we will start from the
    // beginning of an input byteAddress. The right index slice is all of the
    // bits following the tag bits. This would be the index bits 
    // (logCacheSets), then line offset bits (logWordsPerLine) plus the
    // two remaining bits in the 0 and 1 index, the byte offset bits. 
    return byteAddress[31 : logWordsPerLine + 2 + logCacheSets];
endfunction

// Extract the Cache Line Word Offset from a given memory address
function WordOffset getWordOffset(Word byteAddress);
    // Last bits prior to the byte offset bits, so our right index slive is
    // 2, and we use logWordsPerLine to +1 to get our total logWordsPerLine
    // length word offset value. 
    return byteAddress[logWordsPerLine + 1 : 2];
endfunction

//Extract the line address (tag + index) from a given memory address
function LineAddr getLineAddr(Word byteAddress);
    // Stop before line offset bits but take all leading bits including the
    // index bits following the tag bits.
    return byteAddress[31 : logWordsPerLine + 2];
endfunction
