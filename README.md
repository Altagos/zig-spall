# zig-spall

Zig library for generating [spall-web](gravitymoth.com/spall) profiling reports.

## Installation

First add it as dependencie to your `build.zig.zon` file:

```zig
.dependencies = .{
    .spall = .{
        .url = "https://github.com/altagos/zig-spall/archive/{{COMMIT}}.tar.gz"
        .hash = "{{HASH}}"
    },
}
```

Replace `{{COMMIT}}` with the latest commit, and `{{HASH}}` will get generated during the next build (and displayed for you to copy and replace).

Then in `build.zig` add it to your Compile step like this:

```zig
const spall = b.dependency("spall", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("spall", spall.module("spall"));
```

## Usage

In your program:

```zig
const std = @import("std");
const spall = @import("spall");

pub fn main() !void {
    try spall.init("./trace/example.spall");
    defer spall.deinit();

    while (true) {
        try spall.init_thread();
        defer spall.deinit_thread();

        const span = spall.trace(@src(), "Hello World", .{});
        std.debug.print("Hello World!\n");
        span.end();
    }
}
```

An example with threads is in the [example folder](https://github.com/altagos/zig-spall/blob/main/example).

## Similar libraries & other profiling libraries

- [zig-tracer](https://github.com/nektro/zig-tracer/): Generic tracing library for Zig, supports multiple backends.

  zig-spall is based on [zig-tracer](https://github.com/nektro/zig-tracer/)'s design.

- [zig-tracy](https://github.com/cipharius/zig-tracy/tree/master): Easy to use bindings for the tracy client C API.
- [ztracy](https://github.com/michal-z/zig-gamedev/tree/main/libs/ztracy): performance markers for Tracy 0.10

  > part of [michal-z/zig-gamedev](https://github.com/michal-z/zig-gamedev)

## TODO

- [ ] add enable and disable options
- [ ] add compatibility with [zig-tracer](https://github.com/nektro/zig-tracer/)
- [ ] add documentation

## License

MIT, see [LICENSE](https://github.com/altagos/zig-spall/blob/main/LICENSE)
