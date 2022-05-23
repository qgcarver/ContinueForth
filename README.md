# ContinueForth
Where we're going, we don't need variables

Currently a work in progress going under heavy changes internally.

This is a reference bootstrapping evaluator for AMD64 processors that will bootstrap a minimal stack-based language which uses two stacks, one stack for quoted programs of combinators/higher-order-functions and another stack that holds the continuation.
Hopefully it will serve as a nice proof-of-concept for an extremely small implementation of a stack-based (non-pure) functional language, which allows for radical self-modification using a stack-based format for data and code which is fully type reconstructed/inferred and a retargetable infrastructure.

The typechecker, optimizations and additional features are made available via powerful self-patching capabilities written in the hosted language itself, with a few built-in primitives for allocating and writing to executable memory and loading libraries written in the aforementioned data format, which can replace built-in functionality.

The interpreter is designed to make it straightforward to re-implement the loader and evaluator via other host languages/operating systems.
