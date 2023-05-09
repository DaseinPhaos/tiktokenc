package tokenizerc
import "core:dynlib"
import "core:runtime"
import "core:strings"
import "core:fmt"
import "core:log"

//! odin run tokenizerc.odin -file

TokenizercHandle :: distinct rawptr

Tokenizerc :: struct {
    _lib : dynlib.Library,
    create_tokenizer : proc "c"() -> TokenizercHandle,
    count_tokens : proc "c"(tokenizer: TokenizercHandle, p_str: ^u8, str_len: uint) -> uint,
    encode : proc "c"(tokenizer: TokenizercHandle, p_str: ^u8, str_len: uint, p_encoded_len: ^uint) -> [^]uint,
    destroy_encoded : proc "c"(ptr: [^]uint, len: uint),
    decode : proc "c"(tokenizer: TokenizercHandle, p_encoded: ^uint, encoded_len: uint, p_decoded_len: ^uint) -> [^]u8,
    destroy_decoded : proc "c"(ptr: [^]u8, len: uint),
    destroy_tokenizer : proc "c"(tokenizer: TokenizercHandle),
}

load_dynamic_lib :: proc(path: string) -> (ret: Tokenizerc, ok: bool) {
    ret._lib, ok = dynlib.load_library(path)
    if !ok {
        log.errorf("failed to load dynamic library at %s", path)
        return
    }
    tis, tis_ok := runtime.type_info_base(type_info_of(Tokenizerc)).variant.(runtime.Type_Info_Struct)
    assert(tis_ok)
    for i in 0..<len(tis.names) {
        fname := tis.names[i]
        if fname == "_lib" do continue
        fptr, found := dynlib.symbol_address(ret._lib, fname)
        if !found {
            ok = false
            log.errorf("failed to find symbol [%s] from the loaded lib, destroying", fname)
            dynlib.unload_library(ret._lib)
            ret = {}
            return
        }
        foffset := tis.offsets[i]
        pfield := uintptr(&ret) + foffset
        ((^rawptr)(pfield))^ = fptr
    }
    return
}

unload_dynamic_lib :: proc(dyn_lib: Tokenizerc) {
    dynlib.unload_library(dyn_lib._lib)
}

main :: proc() {
    tc, ok := load_dynamic_lib("./tiktokenc.dll")
    assert(ok)
    tk := tc.create_tokenizer()
    defer tc.destroy_tokenizer(tk)
    story := "Once upon a time...Hey there!!!~~"
    count := tc.count_tokens(tk, strings.ptr_from_string(story), len(story))
    encoded_len := uint(0)
    p_encoded := tc.encode(tk, strings.ptr_from_string(story), len(story), &encoded_len)
    defer tc.destroy_encoded(p_encoded, encoded_len)
    assert(encoded_len == count)
    decoded_len := uint(0)
    p_decoded := tc.decode(tk, p_encoded, encoded_len, &decoded_len)
    decoded_str := strings.string_from_ptr(p_decoded, int(decoded_len))
    assert(decoded_str == story)
    fmt.printf("done! token count: %d\n", count)
}