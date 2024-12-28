# zpt

zpt is an offline path tracer written in Zig.

Currently, only output to PPM files is supported.

<img src="example-images/example1.png" alt="example1" width=300 height=300>

## Building from source
1. Download and install Zig. This project has only been tested with version 0.13.0.
2. Clone this repository.
3. Choose a scene to render by modifying the switch statement in the main function in main.zig.
4. Use this command in the root folder: `zig build run > image.ppm`

## References
- *Ray Tracing in One Weekend* and *Ray Tracing: The Next Week* by Peter Shirley, Trevor David Black, and Steve Hollasch