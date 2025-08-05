const std = @import("std");
const print = std.debug.print;

const xml = @import("xml");

const Server = struct {
    addr: std.net.Address,

    pub fn listen(self: *Server) !void {
        const srv = self.interface.listen(self.addr);
        defer srv.deinit();

        std.debug.print("TCP server listening on {s}:{d}\n", .{ self.interface.fmt(), self.interface.port });

        while (true) {
            var conn = try srv.accept();
            defer conn.stream.close();

            try self.open_xml_stream(&conn);
        }
    }

    // RFC 6120 Section 4.2
    pub fn open_xml_stream(self: *Server, conn: *std.net.Server.Connection) !void {
        self.*;
        conn.*;
    }
};

pub const Encoding = enum { XML };

pub const Errors = error{LibXMLError};

pub const LibXMLError = error{UnexpectedNullFromFunc};

pub const StreamHeader = struct {
    xml_version: []const u8,

    pub fn foo() !xml.xmlBufferPtr {
        const buf = xml.xmlBufferCreate() orelse return LibXMLError.UnexpectedNullFromFunc;
        const writer = xml.xmlNewTextWriterMemory(buf, 0) orelse return LibXMLError.UnexpectedNullFromFunc;
        _ = xml.xmlTextWriterStartElement(writer, "DOC");
        _ = xml.xmlTextWriterEndElement(writer);
        _ = xml.xmlTextWriterFlush(writer);

        const buf_size = buf.*.size;
        const content = buf.*.content[0..buf_size];
        std.debug.print("BUF CONTENT: {s}", .{content});

        return buf;
    }
};

test "libxml2 links and is usable" {
    _ = try StreamHeader.foo();
}
