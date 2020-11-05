# Load 2 demo

Demo: loading 2 binary executables into BAP.

Clone this repo somewhere:

    cd ~/code
    git clone https://github.com/jtpaasch/load2demo...
    cd load2demo

Mount the code into the latest BAP docker container:

    docker run --rm -ti -v $(pwd):/srv -w /srv binaryanalysisplatform:latest bash

Build the dummy executables:

    make -C resources

Build the demo:

    make

Run it:

    bap load2demo resources/main_1 resources/main_2
