# Load 2 demo

Demoing some features of loading 2 binary executables into BAP.

I'm using the following BAP version (via the docker container):

    bap --version
    > 2.2.0-alpha+25d1eb6


## Build and run

Clone this repo somewhere:

    cd ~/code
    git clone https://github.com/jtpaasch/load2demo.git
    cd load2demo

Mount the code into the BAP docker container:

    docker run --rm -ti -v $(pwd):/srv -w /srv binaryanalysisplatform:latest bash

Build the dummy executables:

    make -C resources

Build the demo:

    make

Run it:

    bap load2demo resources/main_1 resources/main_2

This will load the two programs, and print their `main` functions.
The way it load these programs is roughly that it loads the first exe and
calls `Project.program`, then it repeats that for the second exe:

```
let proj_1 = Project.create exe_1 in
let prog_1 = Project.program proj_1 in

let proj_2 = Project.create exe_2 in
let prog_2 = Project.program proj_2 in
``` 

``` 

Alternatively, you can add a `--merge` flag when you call `load2demo`:

    bap load2demo resources/main_1 resources/main_2 --merge

This will also load the two programs and print their `main` functions, but
the loading happens differently. With the `--merge` flag, the two exes are
first loaded, and then `Project.program` is called on them. Like this:

```
let proj_1 = Project.create exe_1 in
let proj_2 = Project.create exe_2 in

let prog_1 = Project.program proj_1 in
let prog_2 = Project.program proj_2 in
...


## The examples

Load `resources/main_1` and `resources/main_2`:

    bap load2demo resources/main_1 resources/main_2

In the printed result, you'll see that the two functions each have their
own set of TIDs, and `main_1` returns `RAX := 3` while `main_2` returns
`RAX := 5`, just as in the assembly `resources/main_1.asm` and
`resources/main_2.asm`.

Now try it with the `--merge` flag:

    bap load2demo resources/main_1 resources/main_2 --merge

This time, the two functions look exactly alike. They have the same TIDs,
and both have `RAX := 3`. It's as if the second program overwrites the first.

(It's not clear to me why there's no conflict between `RAX := 3` and
`RAX := 5`. Should that result in a KB conflict?)

Now load `resources/main_2` and `resources/main_3`:

    bap load2demo resources/main_2 resources/main_3

In the printed result, the two functions each have their own set of TIDs,
and `main_2` returns `RAX := 3` while `main_3` returns
`RAX := mem[0x601030, el]:u64`, just as in the assembly `resources/main_2.asm`
and `resources/main_3.asm`. 

Now try it with the `--merge` flag:

    bap load2demo resources/main_2 resources/main_3 --merge

This time, BAP throws a conflict error, saying that the instructions conflict.
Again, it as if BAP is trying to merge the second program over the top of
the first one.
