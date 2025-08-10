const std = @import("std");
const avahi = @import("avahi-client");

pub fn create_services() void {
}

pub fn avahi_client_callback(c: *avahi.AvahiClient, state: avahi.AvahiClientState, userdata: ?*anyopaque) void {
    switch (state) {
        avahi.AVAHI_CLIENT_S_RUNNING => {
            create_services(c);
        },
        avahi.AVAHI_CLIENT_S_REGISTERING => {

        },
        avahi.AVAHI_CLIENT_S_COLLISION => {

        },
        avahi.AVAHI_CLIENT_FAILURE => {

        },
        avahi.AVAHI_CLIENT_CONNECTING => {}
    }
}

pub fn main() !void {
    
    var avahi_simple_poll: *avahi.AvahiSimplePoll = null;

    var avahi_client = avahi.avahi_client_new(
        avahi.avahi_simple_poll_get(avahi_simple_poll), 
        0, 
        avahi_client_callback, 
        userdata: ?*anyopaque, 
        @"error": [*c]c_int
    );
}
