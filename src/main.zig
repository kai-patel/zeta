const std = @import("std");
const zeta = @import("root.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub fn main() !void {
    errdefer zeta.print_sdl_error();

    if (c.SDL_Init(c.SDL_INIT_VIDEO) < 0) {
        return error.InitializationError;
    }
    defer c.SDL_Quit();

    const width = 1024;
    const height = 768;

    const window = c.SDL_CreateWindow("zeta", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, width, height, c.SDL_WINDOW_SHOWN) orelse return error.InitializationError;
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse return error.InitializationError;
    defer c.SDL_DestroyRenderer(renderer);

    const triangle = zeta.Shape{ .triangle = zeta.Triangle{ .vertices = [3]zeta.Vertex{
        zeta.Vertex{ .x = 0, .y = 0 },
        zeta.Vertex{ .x = width / 2, .y = height / 2 },
        zeta.Vertex{ .x = width, .y = 0 },
    } } };

    const circle = zeta.Shape{ .circle = zeta.Circle{
        .center = zeta.Vertex{
            .x = width / 2,
            .y = height / 2,
        },
        .radius = width / 4,
    } };

    var gpa = std.heap.GeneralPurposeAllocator(.{
        .safety = true,
        .verbose_log = true,
    }){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            @panic("Memory leak!");
        }
    }

    var world = zeta.World.init(gpa.allocator());
    defer world.deinit();

    try world.shapes.append(triangle);
    try world.shapes.append(circle);

    var scene = zeta.Scene.init(gpa.allocator());
    defer scene.deinit();

    const entity = try scene.spawn();

    const Transform = struct {
        position: zeta.Vertex,
        rotation: zeta.Vertex,
    };

    scene.add_component(Transform, entity);
    scene.remove_component(Transform, entity);

    while (true) {
        var event: c.SDL_Event = undefined;
        if (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => break,
                c.SDL_MOUSEMOTION => std.debug.print("Mouse (x, y): ({}, {})\n", .{ event.motion.x, event.motion.y }),
                else => std.debug.print("Unhandled input: 0x{x}\n", .{event.type}),
            }
        }

        try zeta.clear(renderer, zeta.Color{ .r = 0xFF, .g = 0xFF, .b = 0xFF, .a = 0xFF });
        try world.draw(renderer, zeta.Color{ .r = 0xFF, .g = 0x00, .b = 0xFF, .a = 0xFF });

        c.SDL_RenderPresent(renderer);
    }
}
