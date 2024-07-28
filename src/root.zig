const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const Vertex = struct {
    x: i32,
    y: i32,
};

pub const Line = struct {
    start: Vertex,
    end: Vertex,

    pub fn draw(self: *const Line, renderer: *c.SDL_Renderer, color: Color) !void {
        try set_draw_color(renderer, color);
        try draw_line(renderer, self.start.x, self.start.y, self.end.x, self.end.y);
    }
};

pub const Triangle = struct {
    vertices: [3]Vertex,

    pub fn draw(self: *const Triangle, renderer: *c.SDL_Renderer, color: Color) !void {
        const lines = [_]Line{
            Line{ .start = self.vertices[0], .end = self.vertices[1] },
            Line{ .start = self.vertices[1], .end = self.vertices[2] },
            Line{ .start = self.vertices[2], .end = self.vertices[0] },
        };

        for (lines) |line| {
            try line.draw(renderer, color);
        }
    }
};

pub const Circle = struct {
    center: Vertex,
    radius: i32,

    pub fn draw(self: *const Circle, renderer: *c.SDL_Renderer, color: Color) !void {
        try set_draw_color(renderer, color);

        var x: i32 = self.radius - 1;
        var y: i32 = 0;
        var dx: i32 = 1;
        var dy: i32 = 1;
        var err: i32 = dx - (self.radius << 1);

        while (x >= y) {
            try draw_point(renderer, self.center.x + x, self.center.y + y);
            try draw_point(renderer, self.center.x + y, self.center.y + x);
            try draw_point(renderer, self.center.x - y, self.center.y + x);
            try draw_point(renderer, self.center.x - x, self.center.y + y);
            try draw_point(renderer, self.center.x - x, self.center.y - y);
            try draw_point(renderer, self.center.x - y, self.center.y - x);
            try draw_point(renderer, self.center.x + y, self.center.y - x);
            try draw_point(renderer, self.center.x + x, self.center.y - y);

            if (err <= 0) {
                y += 1;
                err += dy;
                dy += 2;
            }

            if (err > 0) {
                x -= 1;
                dx += 2;
                err += dx - (self.radius << 1);
            }
        }
    }
};

pub const Shape = union(enum) {
    triangle: Triangle,
    circle: Circle,

    pub fn draw(self: *const Shape, renderer: *c.SDL_Renderer, color: Color) !void {
        switch (self.*) {
            .triangle => |*triangle| try triangle.draw(renderer, color),
            .circle => |*circle| try circle.draw(renderer, color),
        }
    }
};

pub const World = struct {
    shapes: std.ArrayList(Shape),

    pub fn init(allocator: std.mem.Allocator) World {
        const shape_list = std.ArrayList(Shape).init(allocator);
        return .{ .shapes = shape_list };
    }

    pub fn draw(self: *const World, renderer: *c.SDL_Renderer, color: Color) !void {
        for (self.shapes.items) |shape| {
            try shape.draw(renderer, color);
        }
    }

    pub fn deinit(self: *World) void {
        self.shapes.deinit();
    }
};

pub fn print_sdl_error() void {
    std.debug.print("[SDL]: {s}\n", .{c.SDL_GetError()});
}

pub fn clear(renderer: *c.SDL_Renderer, color: Color) !void {
    try set_draw_color(renderer, color);
    if (c.SDL_RenderClear(renderer) != 0) {
        return error.RenderingError;
    }
}

pub fn set_draw_color(renderer: *c.SDL_Renderer, color: Color) !void {
    if (c.SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a) != 0) {
        return error.RenderingError;
    }
}

pub fn draw_point(renderer: *c.SDL_Renderer, x: i32, y: i32) !void {
    if (c.SDL_RenderDrawPoint(renderer, x, y) != 0) {
        return error.RenderingError;
    }
}

pub fn draw_line(renderer: *c.SDL_Renderer, x1: i32, y1: i32, x2: i32, y2: i32) !void {
    if (c.SDL_RenderDrawLine(renderer, x1, y1, x2, y2) != 0) {
        return error.RenderingError;
    }
}
