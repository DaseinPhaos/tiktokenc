# tiktokenc - C ffi for [tiktoken](https://github.com/openai/tiktoken)

Exposes C inteface for `count_tokens`, `encode` and `decode`.

The example folder contains a pre-built dll for x86_64-pc-windows-msvc, as well as an example Odin script documenting and demonstrating using the C interface.

This library is hard-coded to load the cl100k encoding, which is used for both gpt3.5 and gpt4.
