# ContinueForth
Where we're going, we don't need loops

Currently a work in progress going under heavy changes internally.
The intention is to hand-write a couple ELF binaries that will bootstrap a minimal stack-based language which uses two stacks of pointers, one stack for parameters to combinators/higher-order-functions and another stack that holds the returns/continuation.
Hopefully it will serve as a nice proof-of-concept for an extremely small implementation of a (non-pure) functional language.
