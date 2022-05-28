(local ffi (require :ffi))
;(local bit (require :bit))
(local fnl (require :fennel))
(local lm (require :lume))
(ffi.cdef "
void *malloc(size_t size);
typedef struct {
  void *framearray;
  size_t frameindex;
  void *hasharr;
  void *stkptr;
} voyctx;
size_t init(void *a);
size_t load(void *arr, size_t len, voyctx *ctx);
")
(local ctx (ffi.new "voyctx"))
(local cf (ffi.load "./libcf.so"))
(set ctx.framearray (ffi.C.malloc (* 4096 16)))
(set ctx.frameindex (cf.init ctx.framearray))
[ctx.frameindex]
(set ctx.hasharr (ffi.C.malloc (* 4096 16)))
(set ctx.stkptr (ffi.C.malloc (* 4096 16)))
(fn quot [x] (lm.map x #(-> (ffi.new "size_t" 3) (bit.lshift 62) (bit.bor $1))))
(bit.tohex (. (quot [1]) 1))
(local qts (ffi.new "size_t[2]" (quot [0x80 0x100])))
(bit.tohex (. qts 1))
(bit.tohex (cf.load qts 2 ctx))
(set ctx.stkptr (ffi.cast "void*" (cf.load qts 2 ctx)))
(bit.tohex (ffi.cast "size_t" ctx.stkptr))
;(cf.load [cat dup 2])
(lm.reduce [1 2 3 4 5 6] #(+ $1 $2))
(collectgarbage)

