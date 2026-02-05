// zot - minimal screenshot utility
const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("png.h");
    @cInclude("stdio.h");
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();
    var out: []const u8 = "zot.png";
    var q: u8 = 9;
    var args = try std.process.argsWithAllocator(a);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-o")) {
            out = args.next() orelse return error.BadArgs;
        } else if (std.mem.eql(u8, arg, "-q")) {
            q = try std.fmt.parseInt(u8, args.next() orelse return error.BadArgs, 10);
            if (q > 9) return error.BadArgs;
        } else return error.BadArgs;
    }
    const d = c.XOpenDisplay(null) orelse return error.NoDisplay;
    defer _ = c.XCloseDisplay(d);
    const s = c.DefaultScreen(d);
    const r = c.RootWindow(d, s);
    const w = c.DisplayWidth(d, s);
    const h = c.DisplayHeight(d, s);
    const img = c.XGetImage(d, r, 0, 0, @intCast(w), @intCast(h), c.AllPlanes, c.ZPixmap) orelse return error.CaptureFailed;
    defer _ = img.*.f.destroy_image.?(img);
    const ww: usize = @intCast(w);
    const hh: usize = @intCast(h);
    const px = try a.alloc(u8, ww * hh * 4);
    defer a.free(px);
    var i: usize = 0;
    while (i < ww * hh) : (i += 1) {
        const p = img.*.f.get_pixel.?(img, @intCast(@mod(i, ww)), @intCast(@divFloor(i, ww)));
        px[i * 4] = @intCast((p >> 16) & 0xFF);
        px[i * 4 + 1] = @intCast((p >> 8) & 0xFF);
        px[i * 4 + 2] = @intCast(p & 0xFF);
        px[i * 4 + 3] = 255;
    }
    const f = try std.fs.cwd().createFile(out, .{});
    defer f.close();
    const fp = c.fdopen(f.handle, "wb") orelse return error.PngFailed;
    defer _ = c.fclose(fp);
    var png = c.png_create_write_struct(c.PNG_LIBPNG_VER_STRING, null, null, null);
    if (png == null) return error.PngFailed;
    defer c.png_destroy_write_struct(&png, null);
    const info = c.png_create_info_struct(png) orelse return error.PngFailed;
    if (c.setjmp(@ptrCast(@constCast(&c.png_jmpbuf(png.?)[0]))) != 0) return error.PngFailed;
    c.png_init_io(png.?, fp);
    c.png_set_compression_level(png.?, q);
    c.png_set_IHDR(png.?, info, @intCast(w), @intCast(h), 8, c.PNG_COLOR_TYPE_RGBA, c.PNG_INTERLACE_NONE, c.PNG_COMPRESSION_TYPE_DEFAULT, c.PNG_FILTER_TYPE_DEFAULT);
    c.png_write_info(png.?, info);
    var y: c_int = 0;
    while (y < h) : (y += 1) c.png_write_row(png.?, @constCast(@ptrCast(&px[@intCast(y * w * 4)])));
    c.png_write_end(png.?, null);
}
