This project contains a number of demo scripts and applications along
with the containers that are used to implement those demos.

# Demo Scripts

In the `demo_scripts` folder you will find scripts that can be run to
setup and run a demo. Each demo resides in a named folder.

Each demo will have one or more corresponding applications (see
`apps`) which in turn will consist of one ore more Docker Containers
(see `containers`).

## Writing Demo Scripts

At the very least a demo script consists of a script.md file. This
will contain both descriptinve text and command blocks describing the
commands that need to be run. 

Ideally script directories will also contain a `setup.sh` and
`cleanup.sh` files. These are intended to be run to configure the demo
environment and to cleanup after the demo is complete.

