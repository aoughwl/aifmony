# aifmony

**A nimony rewrite on the aoughwl self-owned stack.** One driver that takes a
`.nim` file and runs it through parser → sem → lowering → *your choice of*
native code or interpretation — using aoughwl's own components wherever they
exist, and reusing nimony's for the parts not yet rebuilt.

```
   .nim ──► nifparser (ours) ──► nimony sem + hexer (reused) ──► .s.nif / .c.nif
                                                                    │        │
                              nifi (ours) ◄── interpret ───────────┘        └──► nifc (ours) ──► C ──► gcc ──► native
```

## What's ours vs reused

| stage | tool | owned? |
|---|---|---|
| parse `.nim` → `.p.nif` | **[nifparser](https://github.com/aoughwl/nifparser)** (user modules) | ✅ ours |
| parse stdlib → `.p.nif` | `nifler` | reused (nifparser has `concept`/typed-nil gaps) |
| sem `.p.nif` → `.s.nif` | nimony `nimsem` | reused — **[nifsem](https://github.com/aoughwl/nifsem) not finished yet** |
| lower `.s.nif` → `.c.nif` | nimony `hexer` (ARC, closures, exceptions, mono) | reused — the genuinely hard pass |
| **native** `.c.nif` → binary | **[nifc](https://github.com/aoughwl/nifc)** → gcc | ✅ ours |
| **interpret** `.s.nif` | **[nifi](https://github.com/aoughwl/nifi)** (tree-walk + bytecode VM) | ✅ ours |
| web `.s.nif` → JS | **[nifjs](https://github.com/aoughwl/nifjs)** | ✅ ours |

The honest position (see [the plan](#the-rest-of-the-rewrite--repos-to-create)):
today aifmony proves the **ends** of the pipeline are self-owned (our parser
feeds it, our backends consume it), while the **middle** (sem + hexer) is reused
from nimony exactly as intended until nifsem lands and a self-owned lowering
pass is written.

## The interpreter is first-class

`nifi` is not a fallback — it is a primary execution mode (`aifmony interp`),
and it is the intended answer to the one feature the native path is missing:
**macros / compile-time execution**. nimony today builds each macro into a
*host-native executable* and exec's it at every call site (`macro_plugin.nim`).
The self-owned stack replaces that with the interpreter: evaluate the macro's
`.s.nif` directly with `nifi` at compile time — no per-macro native build, and
the same evaluator that runs `aifmony interp` runs `static:` blocks and constant
folding. (Wiring this into nifsem is the next milestone; nimony's own macro
expansion is used until then.)

## Usage

```sh
aifmony run    prog.nim                          # native: whole module → binary → run
aifmony build  prog.nim -o prog                  # native: emit a binary
aifmony exec   prog.nim --entry fib --arg 20     # native: call one proc, print result (→ 6765)
aifmony interp prog.nim                          # interpret via nifi  (full runtime: strings, echo, seqs)
aifmony vm     prog.nim                          # interpret via nifi's bytecode VM
aifmony parse  prog.nim                          # show OUR nifparser .p.nif
aifmony nif    prog.nim                          # print .p/.s/.c.nif paths + which parser produced each
```

Add `-v` to see provenance (`main module … parsed by nifparser (ours)`).

**native vs interpret today:** the native path (`nifc`) covers the
arithmetic/control-flow core — it does not yet link the 54 KB system runtime, so
`echo`/strings/seqs run under `interp` (nifi has the full runtime) while pure
computation also runs natively. `aifmony exec --entry` bridges the two: it
harnesses any proc to a native binary so you can compare a `gcc`-compiled result
against the interpreter's.

### Tool locations

Resolved from env (`AIFMONY_NIMONY`, `AIFMONY_NIFPARSER`, `AIFMONY_NIFI`,
`AIFMONY_NIFC`, …), then `./aifmony.config.json`, then `~/{nimony,nifparser,nifi,nifc}`
defaults. nifparser also resolves from its `nimcache` build dir if `bin/` is
mid-rebuild.

## The rest of the rewrite — repos to create

aifmony makes the missing pieces concrete. To finish the self-owned rewrite,
create:

1. **`aoughwl/aifmony`** — *this repo*: the unified driver. The thing that *is*
   "the nimony rewrite," dispatching to nifc (native) / nifi (interpret) / nifjs (web).
2. **`aoughwl/niflib`** (or `nifsys`) — the **self-owned system module + runtime**
   (strings, seqs, ARC helpers, GC objects) so `nifc`/`nifjs` link real programs
   without nimony's `system.c.nif`. This is the biggest unlock: it's what lets
   `echo "hello"` compile *natively* through our stack.
3. **`aoughwl/niflower`** (or `nifhexer`) — a **self-owned lowering pass** to
   eventually replace the reused nimony `hexer` (ARC / closures / exceptions /
   monomorphisation), removing the last nimony dependency.

Already existing and slotting in: [nifparser](https://github.com/aoughwl/nifparser)
(finish `concept`/typed-nil so it parses the stdlib too), **nifsem** (finish it →
drop reused `nimsem`), [nifi](https://github.com/aoughwl/nifi) (promote to the
macro/CTFE engine), [nifc](https://github.com/aoughwl/nifc), [nifjs](https://github.com/aoughwl/nifjs).
Per the aoughwl convention (`nifjs` + `nifjs-js`), each hand-written JS component
is a **bootstrap seed & oracle** for a later nimony-native implementation.

## Test

```sh
npm test    # compiles example programs through the stack; asserts native (nifc) results
```

## License

MIT.
