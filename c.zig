pub const abl_link = extern struct {
    impl: ?*lib.Link,
};

pub extern "c" fn abl_link_create(bpm: f64) abl_link;
pub extern "c" fn abl_link_destroy(link: abl_link) void;
pub extern "c" fn abl_link_is_enabled(link: abl_link) bool;
pub extern "c" fn abl_link_enable(link: abl_link, enable: bool) void;
pub extern "c" fn abl_link_is_start_stop_sync_enabled(link: abl_link) bool;
pub extern "c" fn abl_link_enable_start_stop_sync(link: abl_link, enabled: bool) void;
pub extern "c" fn abl_link_num_peers(link: abl_link) u64;

pub const abl_link_num_peers_callback = *const fn (num_peers: u64, ctx: ?*anyopaque) callconv(.C) void;
pub extern "c" fn abl_link_set_num_peers_callback(link: abl_link, callback: abl_link_num_peers_callback, context: ?*anyopaque) void;

pub const abl_link_tempo_callback = *const fn (tempo: f64, context: ?*anyopaque) callconv(.C) void;
pub extern "c" fn abl_link_set_tempo_callback(link: abl_link, callback: abl_link_tempo_callback, context: ?*anyopaque) void;

pub const abl_link_start_stop_callback = *const fn (is_playing: bool, context: ?*anyopaque) callconv(.C) void;
pub extern "c" fn abl_link_set_start_stop_callback(link: abl_link, callback: abl_link_start_stop_callback, context: ?*anyopaque) void;

pub extern "c" fn abl_link_clock_micros(link: abl_link) i64;

pub const abl_link_session_state = extern struct {
    impl: ?*lib.SessionState,
};

pub extern "c" fn abl_link_create_session_state() abl_link_session_state;
pub extern "c" fn abl_link_destroy_session_state(state: abl_link_session_state) void;
pub extern "c" fn abl_link_capture_audio_session_state(link: abl_link, state: abl_link_session_state) void;
pub extern "c" fn abl_link_commit_audio_session_state(link: abl_link, state: abl_link_session_state) void;
pub extern "c" fn abl_link_capture_app_session_state(link: abl_link, state: abl_link_session_state) void;
pub extern "c" fn abl_link_commit_app_session_state(link: abl_link, state: abl_link_session_state) void;

pub extern "c" fn abl_link_tempo(state: abl_link_session_state) f64;
pub extern "c" fn abl_link_set_tempo(state: abl_link_session_state, bpm: f64, at_time: i64) void;
pub extern "c" fn abl_link_beat_at_time(state: abl_link_session_state, time: i64, quantum: f64) f64;
pub extern "c" fn abl_link_phase_at_time(state: abl_link_session_state, time: i64, quantum: f64) f64;
pub extern "c" fn abl_link_time_at_beat(state: abl_link_session_state, beat: f64, quantum: f64) i64;
pub extern "c" fn abl_link_request_beat_at_time(state: abl_link_session_state, beat: f64, time: i64, quantum: f64) void;
pub extern "c" fn abl_link_force_beat_at_time(state: abl_link_session_state, beat: f64, time: u64, quantum: f64) void;
pub extern "c" fn abl_link_set_is_playing(state: abl_link_session_state, is_playing: bool, time: u64) void;
pub extern "c" fn abl_link_is_playing(state: abl_link_session_state) bool;
pub extern "c" fn abl_link_time_for_is_playing(state: abl_link_session_state) u64;
pub extern "c" fn abl_link_request_beat_at_start_playing_time(state: abl_link_session_state, beat: f64, quantum: f64) void;
pub extern "c" fn abl_link_set_is_playing_and_request_beat_at_time(
    state: abl_link_session_state,
    is_playing: bool,
    time: u64,
    beat: f64,
    quantum: f64,
) void;

const lib = @import("lib.zig");
