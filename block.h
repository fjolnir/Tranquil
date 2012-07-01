#ifdef _TQ_BLOCK_H_
#define _TQ_BLOCK_H_

struct Block_literal_1;

#pragma mark - Block ABI
struct Block_literal_1 {
	void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
	int flags;
	int reserved; 
	void (*invoke)(void *, ...);
	struct Block_descriptor_1 {
		unsigned long int reserved;                    // NULL
		unsigned long int size;                        // sizeof(struct Block_literal_1)
		// optional helper functions
		void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
		void (*dispose_helper)(void *src);             // IFF (1<<25)
		// required ABI.2010.3.16
		const char *signature;                         // IFF (1<<30)
	} *descriptor;
	// imported variables are appended
};
// Signature flags
enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30), 
};
extern const struct __Block_literal_1 _NSConcreteGlobalBlock;

#endif
