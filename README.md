# Load 2 demo

Demoing some features of loading 2 binary executables into BAP.


## Try it

Clone this repo somewhere:

    cd ~/code
    git clone https://github.com/jtpaasch/load2demo.git
    cd load2demo

Mount the code into the latest BAP docker container:

    docker run --rm -ti -v $(pwd):/srv -w /srv binaryanalysisplatform:latest bash

Build the dummy executables:

    make -C resources

Build the demo:

    make

Run it:

    bap load2demo resources/main_1 resources/main_2

This will load the two programs, and print their `main` functions.
If you add a `--merge` flag, BAP will try to merge the two programs:

    bap load2demo resources/main_1 resources/main_2 --merge

When merging, BAP will raise a knowledge-base conflict (error) if it tries
to merge incompatible instructions.


## Commentary

### The programs

There are three programs in `resources`. 

The first one, `main_1.asm`, has a `main` function that looks like this:

```
;;  -----------------------------------------------------------------          
        SECTION .text
;;  -----------------------------------------------------------------          

main:
        mov     rax, 0x5 ; Return 5                                            
        ret
.end:
```

It puts the literal/immediate value `0x5` directly in `rax`, and returns.

The second one, `main_2.asm`, has a `main` function that looks like this:

```
;;  -----------------------------------------------------------------          
        SECTION .text
;;  -----------------------------------------------------------------          

main:
        mov     rax, 0x3 ; Return 3                                            
        ret
.end:
```

It puts the literal/immediate value `0x3` directly in `rax`, and returns.

The third one, `main_3.asm`, has a `main` function that looks like this:

```
;;  -----------------------------------------------------------------          
        SECTION .data
;;  -----------------------------------------------------------------          

loc_1   DB 0x3  ; Store 3 at an address called "loc_1"                         


;;  -----------------------------------------------------------------          
        SECTION .text
;;  -----------------------------------------------------------------          

main:
        mov rax, [loc_1] ; Return 3                                            
        ret
.end:
```

This one puts the value `0x3` in a location in memory (named `loc_1`), and
then it puts the contents of that address into `rax` and returns.

You can build all three from the root of the repo:

    make -C resources

Run each one, to confirm that they produce the expected exit codes:

    > ./resources/main_1
    > echo $? # returns 5

    > ./resources/main_2
    > echo $? # returns 3

    > ./resources/main_3
    > echo $? # returns 3

Semantically, `main_1` and `main_2` are similar, except they put a different
literal/immediate value into `rax` before returning. 

By contrast, `main_2` and `main_3` are similar, except `main_2` puts the value 
`0x3` directly into `rax`, while `main_3` gets that same value from memory.


### Loading again merges

In the plugin (`load2demo.ml`), there is a loader function that loads a
binary executable:

```
let load (filename : string) : Project.t =
  let input = Project.Input.file ~loader ~filename in
  let proj = Project.create input ~package:filename in
  match proj with
  | Ok p -> p
  | Error e -> failwith @@ Error.to_string_hum e
```

Suppose you use this function to load two binary executables `exe_1` and
`exe_`2, one after the other, before you extract the programs from them. 
Like this:

```
let proj_1 = load exe_1 in
let proj_2 = load exe_2 in

let prog_1 = Project.program proj_1 in
let prog_2 = Project.program proj_2 in
...
```

When you run `load` twice like this, it looks like BAP merges the second 
program with the first. It's as if BAP overwrites the first one with 
information it gets from the second one.

Let me try to demonstrate why I think that. First, look at how BAP sees the 
`main` function of the first program, `main_1`:

    bap resources/main_1 -d --print-symbol=main

What I see is this:

```
000007b8: program
000007a6: sub main(main_argc, main_argv, main_result)
000007c8: main_argc :: in u32 = RDI
000007c9: main_argv :: in out u64 = RSI
000007ca: main_result :: out u32 = RAX

000003fc:
00000401: RAX := 5
0000040a: #45 := mem[RSP, el]:u64
0000040d: RSP := RSP + 8
00000411: call #45 with noreturn
```

Notice the statement at TID `401`: 

    RAX := 5

Now look at `main_2`:

    bap resources/main_2 -d --print-symbol=main

What I see is this:

```
000007ac: program
000007a6: sub main(main_argc, main_argv, main_result)
000007bc: main_argc :: in u32 = RDI
000007bd: main_argv :: in out u64 = RSI
000007be: main_result :: out u32 = RAX

000003fc:
00000401: RAX := 3
0000040a: #45 := mem[RSP, el]:u64
0000040d: RSP := RSP + 8
00000411: call #45 with noreturn
```

Notice the statement at TID `401`:

    RAX := 3

Now run the `load2demo` plugin, and let it load `main_1` and `main_2`,
and merge them:

    bap load2demo resources/main_1 resources/main_2 --merge

When it's done, the plugin prints the BIR of the two `main` functions that it
has loaded:

```
=== MAIN (First EXE) ============================
00000f2b: sub main()


00000b81:
00000b86: RAX := 3
00000b8f: #45 := mem[RSP, el]:u64
00000b92: RSP := RSP + 8
00000b96: call #45 with noreturn

=== MAIN (Second EXE) ===========================
00000f2b: sub main()


00000b81:
00000b86: RAX := 3
00000b8f: #45 := mem[RSP, el]:u64
00000b92: RSP := RSP + 8
00000b96: call #45 with noreturn
```

Notice that the TIDs are different from when we used `bap -d` to look at
the `main` functions a moment ago. This time, the relevant statement
occurs at TID `b86`. This tells me the TIDs are assigned on the fly,
when BAP extracts the program. 

Second, notice that in both programs, the relevant statement is the same.
At TID `b86`, it is this:

    RAX := 3

That's not what one might expect. One might have expected that the first
program had `RAX := 5`, while the second had `RAX := 3`. 

So, it would appear from this that BAP has loaded the second program right
over the top of the first program (or rather, has merged the second one
over the first one, and in this case, taken `RAX := 3` as the most 
authoritative version of that statement, since it was loaded second).


### Loading without merging

In the previous examples, I caused BAP to merge the two programs by loadeing 
the two executables back to back, like this:

```
let proj_1 = load exe_1 in
let proj_2 = load exe_2 in

let prog_1 = Project.program proj_1 in
let prog_2 = Project.program proj_2 in
...
``` 

Notice that I didn't _extract_ the programs from the projects until after
I loaded the two projects first.

Let's do it differently. Let's load the first project and extract its program
_before_ loading the second project and extracting its program. Like this:

```
let proj_1 = load exe_1 in
let prog_1 = Project.program proj_1 in

let proj_2 = load exe_2 in
let prog_2 = Project.program proj_2 in
...
``` 

When doing things this way, BAP doesn't appear to merge the programs.

To confirm, run the `load2demo` plugin on `main_1` and `main_2` without using
the `--merge` flag:

    bap load2demo resources/main_1 resources/main_2 

When it's finished, the plugin prints the two `main` functions it's loaded:

```
=== MAIN (First EXE) ============================
000007a6: sub main()


000003fc:
00000401: RAX := 5
0000040a: #45 := mem[RSP, el]:u64
0000040d: RSP := RSP + 8
00000411: call #45 with noreturn

=== MAIN (Second EXE) ===========================
00000f4b: sub main()


00000ba1:
00000ba6: RAX := 3
00000baf: #45 := mem[RSP, el]:u64
00000bb2: RSP := RSP + 8
00000bb6: call #45 with noreturn
```

This time, the two programs are as one might expect. The first one has
`RAX := 5`, and the second one has `RAX := 3`, just as it should be. 

Also, notice that the TIDs are different. The second program has its own
set of TIDs, whereas before, the two `main` functions had the same TIDs.

It would appear from this that, if you extract the program using
`Project.program foo` before calling `load` again, things work as expected.

It also appears from this that the TIDs are generated at the time that
BAP extracts the program, rather than at the time it loads the project.
That is, the TIDs seem to be generated when you call `Project.program`,
rather than when you call `Project.create`. 


### Conflicts

When merging `main_1` and `main_2` before, recall that BAP did not see
any conflict in the values `5` and `3`, and it merged the second program
into the first one, letting `3` overwrite `5` without any complaint.

Perhaps BAP thinks the semantics of `RAX := 5` and `RAX := 3` are equivalent, 
or at least it does not see a conflict? Perhaps what BAP really sees is 
something like this: `RAX := Some constant`?

In any case, let's try the same thing with `main_2` and `main_3`. These two
programs return the same value (`RAX` ends up with `3` stashed in it), but
they get that value in different ways: `main_2` puts that value in `RAX`
directly, and `main_3` pulls it from a location in memory.

Check how BAP sees the `main` function from `main_2` again:

    bap resources/main_2 -d --print-symbol=main

Which prints:

```
000007b8: program
000007a6: sub main(main_argc, main_argv, main_result)
000007c8: main_argc :: in u32 = RDI
000007c9: main_argv :: in out u64 = RSI
000007ca: main_result :: out u32 = RAX

000003fc:
00000401: RAX := 3
0000040a: #45 := mem[RSP, el]:u64
0000040d: RSP := RSP + 8
00000411: call #45 with noreturn
```

And now look at how BAP sees the `main` function of `main_3`:

    bap resources/main_3 -d --print-symbol=main

Which prints:

```
000007ac: program
000007a6: sub main(main_argc, main_argv, main_result)
000007bc: main_argc :: in u32 = RDI
000007bd: main_argv :: in out u64 = RSI
000007be: main_result :: out u32 = RAX

000003fc:
00000401: RAX := mem[0x601030, el]:u64
0000040a: #45 := mem[RSP, el]:u64
0000040d: RSP := RSP + 8
00000411: call #45 with noreturn
```

Notice the statement at TID `401`: it loads the value from memory location
(`0x601030`) into `RAX`. If you look at the data section of the executable:

    objdump -Ds resources/main_3

You can see that address `0x601030` has the value `3` in it:

```
0000000000601030 <loc_1>:
  601030:	03                   	.byte 0x3
```

Now load the programs, and let BAP try to merge them:

    bap load2demo resources/main_2 resources/main_3 --merge

This time, BAP complains that it can't join (merge) the information it gets
from the second program with the information it has about the first:

```
Uncaught exception:
  
  Unable to update the slot bap:mem of 0x4004e0,
Domain mem doesn't have a join for values (4004e0 8 LittleEndian) and 
(4004e0 5 LittleEndian)`
```

I'm not sure I totally understand the error here, but it is saying it cannot
merge the instructions from the two versions of the program at address
`0x4004e0`. If I look at the programs, for example `main_3`:

    objdump -Ds resources/main_3

I see that address `0x4004e0` contains the instruction to insert
the value from memory into `RAX`:

```
00000000004004e0 <main>:
  4004e0:	48 8b 04 25 30 10 60 	mov    0x601030,%rax
```

But if I look at the `main_2`:

    objdump -Ds resources/main_2

I see at the same address the instruction to insert the immediate value 3
into `RAX`:

```
00000000004004e0 <main>:
  4004e0:	b8 03 00 00 00       	mov    $0x3,%eax
```

And BAP sees these two versions of the instruction as conflicting. That makes
sense. The semantics of assigning a literal value to a register is presumably
seen by BAP as different from the semantics of taking a value from a location
in memory and putting it there.


### No conflicts

Now try loading `main_2` and `main_3` without merging (i.e., without using
the `--merge` flag):

    bap load2demo resources/main_2 resources/main_3 

When it's finished, the plugin prints the two `main` functions it's loaded:

```
=== MAIN (First EXE) ============================
000007a6: sub main()


000003fc:
00000401: RAX := 3
0000040a: #45 := mem[RSP, el]:u64
0000040d: RSP := RSP + 8
00000411: call #45 with noreturn

=== MAIN (Second EXE) ===========================
00000f4b: sub main()


00000ba1:
00000ba6: RAX := mem[0x601030, el]:u64
00000baf: #45 := mem[RSP, el]:u64
00000bb2: RSP := RSP + 8
00000bb6: call #45 with noreturn
```

Here we see that the two programs are different, with distinct TIDs.


### TL;DR

Loading two binaries one right after the other tells BAP to merge the
info from the later loads into the info it has about the earlier loads.

Extracting a program from a loaded project (i.e., when you call
`Project.program`) appears to be the moment when BAP sets up the program as 
a distinct entity in its internal memory. It's then that it assigns TIDs to 
the terms, and so on. Any loads after that appear to be considered by BAP to
be loading a new, different program.
