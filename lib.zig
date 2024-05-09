//! Comments in this file are drawn from abl_link.h
//! Copyright 2021, Ableton AG, Berlin. All rights reserved.
//!
//! This program is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 2 of the License, or
//! (at your option) any later version.
//!
//! This program is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with this program.  If not, see <http://www.gnu.org/licenses/>.
//!
//! If you would like to incorporate Link into a proprietary software application,
//! please contact <link-devs@ableton.com>.

/// The representation of a Link instance
///
/// Each Link instance has its own session state which
/// represents a beat timeline and a transport start/stop state. The
/// timeline starts running from beat 0 at the initial tempo when
/// constructed. The timeline always advances at a speed defined by
/// its current tempo, even if transport is stopped. Synchronizing to the
/// transport start/stop state of Link is optional for every peer.
/// The transport start/stop state is only shared with other peers when
/// start/stop synchronization is enabled.
///
/// A Link instance is initially disabled after construction, which
/// means that it will not communicate on the network. Once enabled,
/// a Link instance initiates network communication in an effort to
/// discover other peers. When peers are discovered, they immediately
/// become part of a shared Link session.
///
/// Each function documents its thread-safety and
/// realtime-safety properties. When a function is marked thread-safe,
/// it means it is safe to call from multiple threads
/// concurrently. When a function is marked realtime-safe, it means that
/// it does not block and is appropriate for use in the thread that
/// performs audio IO.
///
/// One session state capture/commit function pair for use
/// in the audio thread and one for all other application contexts is provided.
/// In general, modifying the session state should be done in the audio
/// thread for the most accurate timing results. The ability to modify
/// the session state from application threads should only be used in
/// cases where an application's audio thread is not actively running
/// or if it doesn't generate audio at all. Modifying the Link session
/// state from both the audio thread and an application thread
/// concurrently is not advised and will potentially lead to unexpected
/// behavior.
pub const Link = opaque {
    /// Construct a new Link instance with an initial tempo.
    /// Thread-safe: yes
    /// Realtime-safe: no
    pub fn create(bpm: f64) ?*Link {
        return c.abl_link_create(bpm).impl;
    }

    /// Delete a Link instance.
    /// Thread-safe: yes
    //// Realtime-safe: no
    pub fn destroy(self: *Link) void {
        c.abl_link_destroy(.{ .impl = self });
    }

    /// Is Link currently enabled?
    /// Thread-safe: yes
    /// Realtime-safe: yes
    pub fn isEnabled(self: *Link) bool {
        return c.abl_link_is_enabled(.{ .impl = self });
    }

    /// Enable/disable Link.
    /// Thread-safe: yes
    /// Realtime-safe: no
    pub fn enable(self: *Link, enabled: bool) void {
        c.abl_link_enable(.{ .impl = self }, enabled);
    }

    /// Is start/stop synchronization enabled?
    /// Thread-safe: yes
    /// Realtime-safe: no
    pub fn isStartStopSyncEnabled(self: *Link) bool {
        return c.abl_link_is_start_stop_sync_enabled(.{ .impl = self });
    }

    /// Enable start/stop synchronization.
    /// Thread-safe: yes
    /// Realtime-safe: no
    pub fn enableStartStopSync(self: *Link, enabled: bool) void {
        c.abl_link_enable_start_stop_sync(.{ .impl = self }, enabled);
    }

    /// How many peers are currently connected in a Link session?
    /// Thread-safe: yes
    /// Realtime-safe: yes
    pub fn numPeers(self: *Link) u64 {
        return c.abl_link_num_peers(.{ .impl = self });
    }

    /// Register a callback to be notified when the number of peers in the Link session changes.
    /// Thread-safe: yes
    /// Realtime-safe: no
    ///
    /// The callback is invoked on a Link-managed thread.
    pub fn setNumPeersCallback(self: *Link, comptime callback: fn (u64, ?*anyopaque) void, context: ?*anyopaque) void {
        const inner = struct {
            fn f(num_peers: u64, ctx: ?*anyopaque) callconv(.C) void {
                @call(.always_inline, callback, .{ num_peers, ctx });
            }
        };
        c.abl_link_set_num_peers_callback(.{ .impl = self }, inner.f, context);
    }

    /// Register a callback to be notified when the session tempo changes.
    /// Thread-safe: yes
    /// Realtime-safe: no
    ///
    /// The callback is invoked on a Link-managed thread
    pub fn setTempoCallback(self: *Link, comptime callback: fn (f64, ?*anyopaque) void, context: ?*anyopaque) void {
        const inner = struct {
            fn f(tempo: f64, ctx: ?*anyopaque) callconv(.C) void {
                @call(.always_inline, callback, .{ tempo, ctx });
            }
        };
        c.abl_link_set_tempo_callback(.{ .impl = self }, inner.f, context);
    }

    /// Register a callback to be notified when the state of start/stop changes
    /// Thread-safe: yes
    /// Realtime-safe: no
    ///
    /// The callback is invoked on a Link-managed thread.
    pub fn setStartStopCallback(self: *Link, comptime callback: fn (bool, ?*anyopaque) void, context: ?*anyopaque) void {
        const inner = struct {
            fn f(is_playing: bool, ctx: ?*anyopaque) callconv(.C) void {
                @call(.always_inline, callback, .{ is_playing, ctx });
            }
        };
        c.abl_link_set_start_stop_callback(.{ .impl = self }, inner.f, context);
    }

    /// Get the current link clock time in microseconds
    /// Thread-safe: yes
    /// Realtime-safe: yes
    pub fn clockMicros(self: *Link) i64 {
        return c.abl_link_clock_micros(.{ .impl = self });
    }
};

/// The representation of the current local state of a client in a Link Session
///
///  A session state represents a timeline and the start/stop
///  state. The timeline is a representation of a mapping between time and
///  beats for varying quanta. The start/stop state represents the user
///  intention to start or stop transport at a specific time. Start stop
///  synchronization is an optional feature that allows to share the user
///  request to start or stop transport between a subgroup of peers in a
///  Link session. When observing a change of start/stop state, audio
///  playback of a peer should be started or stopped the same way it would
///  have happened if the user had requested that change at the according
///  time locally. The start/stop state can only be changed by the user.
///  This means that the current local start/stop state persists when
///  joining or leaving a Link session. After joining a Link session
///  start/stop change requests will be communicated to all connected peers.
pub const SessionState = opaque {
    /// Create a new SessionState instance
    /// Thread-safe: yes
    /// Realtime-safe: no
    ///
    /// The SessionState is to be used with the capture and commit functions
    /// to capture snapshots of the current link state and pass changes to the link session.
    pub fn create() ?*SessionState {
        return c.abl_link_create_session_state().impl;
    }

    /// Delete a SessionState instance
    /// Thread-safe: yes
    /// Realtime-safe: no
    pub fn destroy(state: *SessionState) void {
        c.abl_link_destroy_session_state(.{ .impl = state });
    }

    /// Capture the current Link Session State from the audio thread.
    /// Thread-safe: no
    /// Realtime-safe: yes
    ///
    /// This function should ONLY be called in the audio thread and must not be
    /// accessed from any other threads. After capturing the SessionState holds a snapshot
    /// of the current Link Session State, so it should be used in a local scope.
    /// The SessionState should not be created on the audio thread.
    pub fn captureFromAudioThread(self: *SessionState, link: *Link) void {
        c.abl_link_capture_audio_session_state(.{ .impl = link }, .{ .impl = self });
    }

    /// Commit the given Session State to the Link sesion from the audio thread.
    /// Thread-safe: no
    /// Realtime-safe: yes
    ///
    /// This function should ONLY be called in the audio thread.
    /// The given Session State will replace the current Link state.
    /// Modifications will be communicated to other peers in the session.
    pub fn commitFromAudioThread(self: *SessionState, link: *Link) void {
        c.abl_link_commit_audio_session_state(.{ .impl = link }, .{ .impl = self });
    }

    /// Capture the current Link Session State from an application thread.
    /// Thread-safe: no
    /// Realtime-safe: yes
    ///
    /// Provides a mechanism for capturing the Link Session State from an application thread
    /// (other than the audio thread). After capturing the Session State
    /// contains a snapshot of the current Link state, so it should be used in a local scope.
    pub fn captureFromApplicationThread(self: *SessionState, link: *Link) void {
        c.abl_link_capture_app_session_state(.{ .impl = link }, .{ .impl = self });
    }

    /// Commit the given Session State to the Link session from an application thread.
    /// Thread-safe: yes
    /// Realtime-safe: no
    ///
    /// The given Session State will replace the current Link Session State.
    /// Modifications of the Session State will be communicated to other peers in the session.
    pub fn commitFromApplicationThread(self: *SessionState, link: *Link) void {
        c.abl_link_commit_app_session_state(.{ .impl = link }, .{ .impl = self });
    }

    /// The tempo of the timeline in BPM
    /// This is a stable value that is appropriate for display to the user.
    /// Beat time progress will not necessarily match this tempo exactly because of clock drift compensation
    pub fn tempo(self: *SessionState) f64 {
        return c.abl_link_tempo(.{ .impl = self });
    }

    /// Set the timeline tempo to the given BPM value, taking effect at the given time.
    pub fn setTempo(self: *SessionState, bpm: f64, at_time_us: i64) void {
        c.abl_link_set_tempo(.{ .impl = self }, bpm, at_time_us);
    }

    /// Get the beat value corresponding to the given time for the given quantum
    /// The magnitude of the resulting beat value is unique to this Link client,
    /// but its phase with respect to the provided quantum is shared among
    /// all session peers. For non-negative beat values, the following proprety holds:
    /// @mod(beatAtTime(t, q), q) == phaseAtTime(t, q)
    pub fn beatAtTime(self: *SessionState, at_time_us: i64, quantum: f64) f64 {
        return c.abl_link_beat_at_time(.{ .impl = self }, at_time_us, quantum);
    }

    /// Get the session phase at the given time for the given quantum
    ///
    /// The result is in the interval [0, quanum). The result is equivalent to
    /// @mod(beatAtTime(t, q), q) for non-negative beat values. This function is convenient
    /// if the client application is only interested in the phase and not the beat magnitude.
    /// Also, unlike fmod, it handles negative beat values correctly.
    pub fn phaseAtTime(self: *SessionState, at_time_us: i64, quantum: f64) f64 {
        return c.abl_link_phase_at_time(.{ .impl = self }, at_time_us, quantum);
    }

    /// Get the time at which the given beat occurs for the given quantum
    ///
    /// The inverse of beatAtTime, assuming a constant tempo.
    /// beatAtTime(timeAtBeat(b, q), q) == b
    pub fn timeAtBeat(self: *SessionState, beat: f64, quantum: f64) i64 {
        return c.abl_link_time_at_beat(.{ .impl = self }, beat, quantum);
    }

    /// Attempt to map the given beat to the given time in the context of the given quantum.
    ///
    /// This function behaves differently depending on the state of the session.
    /// If no other peers are connected, then this Link instance is in a session by itself
    /// and is free to remap the beat/time relationship whenever it pleases.
    /// In this case, beatAtTime(t, q) == b after this function has been called.
    ///
    /// If there are other peers in this session, this Link instance should not abruptly
    /// remap the beat/time relationship in the session because that would lead
    /// to beat discontinuities among the other peers.
    /// In this case, the given beat will be mapped to the next time value graeter than the given time
    /// with the same phase as the given beat.
    ///
    /// This function is specifically designed to enable the concept of "quantized launch"
    /// in client applications. If there are no other peers in the session, then an event
    /// (such as starting transport) happens immediately when it is requested. If there are other peers,
    /// however, we wait until the next time at which the session phase matches the phase of the event,
    /// thereby executing the event in-phase with the other peers in the session.
    /// The client application only needs to invoke this function to achieve this behavior
    /// and should not need to explicitly check the number of peers.
    pub fn requestBeatAtTime(self: *SessionState, beat: f64, at_time_us: i64, quantum: f64) void {
        c.abl_link_request_beat_at_time(.{ .impl = self }, beat, at_time_us, quantum);
    }

    /// Rudely remap the beat/time relationship for all peers in a session.
    ///
    /// DANGER: this function should only be needed in certain special circumstances.
    /// Most applications should not use it. It is very similar to requestBeatAtTime
    /// except that it does not fall aback to the quantizing behavior when it is in a session
    /// with other peers. Calling thi function will unconditionally map the given beat
    /// to the given time and broadcast the result to the session.
    /// This is very anti-social behavior and should be avoided.
    ///
    /// One of the few legitimate uses of this function is to synchronize a Link session
    /// with an external clock source. By periodically forcing the beat/time mapping
    /// according to an external clock source, a peer can effectively bridge that clock
    /// into a Link session. Much care must be taken at the application when implementing
    /// such a feature so that users do not accidentally disrupt Link sessions that they may join.
    pub fn forceBeatAtTime(self: *SessionState, beat: f64, at_time_us: i64, quantum: f64) void {
        c.abl_link_force_beat_at_time(.{ .impl = self }, beat, @intCast(at_time_us), quantum);
    }

    /// Set if transport should be playing or stopped, taking effect at the given time.
    pub fn setIsPlaying(self: *SessionState, is_playing: bool, at_time_us: i64) void {
        c.abl_link_set_is_playing(.{ .impl = self }, is_playing, @intCast(at_time_us));
    }

    /// Is transport playing?
    pub fn isPlaying(self: *SessionState) bool {
        return c.abl_link_is_playing(.{ .impl = self });
    }

    /// Convenience function to attempt to map the given beat to the time
    /// when transport is starting to play in context of the given quantum
    /// this function evaluates to a no-op if isPlaying == false
    pub fn requestBeatAtStartPlayingTime(self: *SessionState, beat: f64, quantum: f64) void {
        c.abl_link_request_beat_at_start_playing_time(.{ .impl = self }, beat, quantum);
    }

    /// Convenience function to start or stop transport at a given time and attempt
    /// to map the given beat to this time in context of the given quantum.
    pub fn setIsPlayingAndRequestBeatAtTime(
        self: *SessionState,
        is_playing: bool,
        at_time_us: i64,
        beat: f64,
        quantum: f64,
    ) void {
        c.abl_link_set_is_playing_and_request_beat_at_time(
            .{ .impl = self },
            is_playing,
            @intCast(at_time_us),
            beat,
            quantum,
        );
    }
};

test "ref" {
    const std = @import("std");
    std.testing.refAllDeclsRecursive(@This());
}

test "create and destroy" {
    const link = Link.create(120) orelse return error.TestFailed;
    defer link.destroy();
    const state = SessionState.create() orelse return error.TestFailed;
    defer state.destroy();
    state.captureFromApplicationThread(link);
    _ = state.isPlaying();
    state.commitFromApplicationThread(link);
}

pub const c = @import("c.zig");
