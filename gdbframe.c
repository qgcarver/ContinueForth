#include <stdlib.h>
#include <dlfcn.h>

typedef struct {
    void *framearray;
    size_t frameindex;
    void *hasharr;
    void *stkptr;
} voyctx;

int main(void) {
    void *lib = dlopen("./libcf.so", RTLD_LAZY);
    size_t (*init) (void*);
    init = dlsym(lib, "init");
    size_t (*load) (void*, size_t, voyctx*);
    load = dlsym(lib, "load");
    voyctx ctx; {
        ctx.framearray = malloc(4096*16);
        ctx.frameindex = init(ctx.framearray);
        ctx.hasharr = malloc(4096*16);
        ctx.stkptr = malloc(4096*16);
    }
    size_t cp[] = {0xc000000000000080, 0xc000000000000100};
    load(cp, 2, &ctx);
    dlclose(lib);

    return 0;
}
