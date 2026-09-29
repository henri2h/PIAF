# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
cargo run          # Run the app (debug)
cargo build        # Build (debug)
cargo build --release
cargo check        # Fast type-check without linking (use this to verify edits)
just -f AndroidApp/Justfile check  # Verify Android build via cargo-ndk (always run after editing src/app/, src/android/ or cfg(android) code)
cargo test                  # Run all unit tests
cargo test <name>           # Run tests whose name contains <name>
```

The project optimizes dependency crates at `opt-level = 1` in dev builds (`Cargo.toml [profile.dev.package."*"]`), so incremental rebuilds are fast.

## Architecture

**PIAF** is a Matrix messaging client built with the [Freya](https://freyaui.dev) Rust GUI framework and `matrix-sdk` 0.17.

**Freya dependency is a local path** (`../freya/crates/freya`), not from crates.io. Changes to Freya itself are in the sibling repo.

### Crate layout

`src/main.rs` only calls `piaf::run_desktop()`; everything lives in the lib (`src/lib.rs`). Android enters via `android_main` in `src/android/mod.rs` (JNI push exports in `src/android/jni_push.rs`).

- `src/app/routes.rs` — `Route`
- `src/app/layout/{desktop,android}.rs` — `Layout` per platform
- `src/app/active_room_panel.rs` — wide-mode right panel
- `src/app/navigation.rs` — navigation helpers
- `src/app/state.rs` — global singletons + `init()`
- `src/app/theme.rs` — `effective_theme`

### Routing & Layout (`src/app/`)

`Route` is a `Routable` enum covering all screens. The `Layout` component measures window width and decides how many panels to show:

- `< 800px`: single panel (standard `Outlet`)
- `≥ 800px`: two panels — `HomePage` (400px fixed) + `ActiveRoomPanel` (flex)
- `≥ 1200px`: three panels — room list + room + settings

Navigation uses `RouterContext::get().push(Route::...)`. In wide mode, the right panel is driven by `ACTIVE_ROOM_TX`/`ACTIVE_ROOM_RX` (watch channel) rather than router navigation.

**Always navigate rooms via the shared helper** `navigate_to_room(room_id)` (and `navigate_to_room_at_event`) in `src/app/navigation.rs` — it handles both wide-mode (`ACTIVE_ROOM_TX`) and narrow-mode (router push) correctly.

### Global Singletons (`src/app/state.rs`, re-exported at crate root)

```rust
REQUESTER: OnceLock<Requester>                               // Send tasks to the background worker
SYNC_TX/RX: OnceLock<watch::...>                             // Fires when a sync changed the room list
ACTIVE_ROOM_TX/RX: OnceLock<watch::...>                      // Currently selected room (wide mode)
FOCUS_EVENT_TX/RX: OnceLock<watch::Option<(String, String)>> // (room_id, event_id) for scroll-to-event
WIDE_MODE: AtomicBool                                        // Current layout mode
```

`FOCUS_EVENT_TX/RX` passes a search-result target event to `RoomPage` across a navigation. Handled in `room/focus.rs`: `take_focus_event` runs once when a `RoomPage` mounts and **always clears** the channel (whether or not the room_id matches), so an aborted navigation can't leak a stale focus. `watch_focus_events` (installed by `TimelineView`) handles re-focus when the same room is already mounted (wide mode) and clears the channel after handling.

### Room page (`src/ui/pages/room/`)

`RoomPage` is a wrapper: rooms in `RoomState::Invited` render `InviteView` (inviter, Accept / Decline via `room.join()` / `room.leave()`), joined rooms render `RoomView`. Never build a timeline or composer for an invited room. For invites use `room.is_direct().await`, not `room.is_dm()` (unreliable before joining).

- `timeline_task.rs` — tokio side: builds the matrix timeline, applies diffs, runs `MsgAction`s. UI talks to it through `TimelineHandle` (`paginate()`, `actions()`); dropping the handle stops the task.
- `use_room_timeline.rs` — hook returning `RoomTimeline { handle, state }`; `state` is a `Copy` bundle of `State`s (messages, loading, paginating, …). The smol receive loop must never hold the handle.
- `timeline_view.rs` — `TimelineView`: scroll view, rows, row height measuring, pagination triggers. Only it reads `messages`, so timeline updates don't re-render `RoomPage`.
- `ui_ctx.rs` — `RoomUiCtx` (popup/overlay states) provided as context; rows use `use_room_ui_ctx()` instead of props.
- The `ScrollController` and `pending_focus` live in `RoomPage` scope so they survive the media viewer unmounting `TimelineView`.

All OnceLocks are initialized by `app::state::init()` before `launch()` (desktop and Android), so `.get()` always returns `Some`. Call with `.expect("not initialized")` — never wrap in `if let Some(...)`.

### Background Worker (`src/utils/worker/`)

All Matrix SDK calls happen off the UI thread:

- **`MatrixClientWorker`** (`worker/client.rs`): handles login, avatar/name fetches, room preview fetches. Send tasks via `REQUESTER.get().expect(...).method(...)`.
- **Sync** (`utils/sync.rs`): matrix-sdk-ui `SyncService` (sliding sync: room list with account data/receipts/typing, plus encryption sync), built and started by `activate_client`. There is no classic `/sync` loop. A room-updates watcher calls `room_list::refresh`, which fires `SYNC_TX` when the room list changed; a state watcher maps `Offline`/`Error` to `DISCONNECTED` and restarts after errors (not after session expiry). The room list service for `subscribe_to_rooms` is `sync::room_list_service()`.
- Event handlers (`add_event_handler`) fire for sliding-sync responses too, but the room list uses `timeline_limit` 1: only the latest event per room per update reaches them.
- Requires a homeserver with Simplified Sliding Sync (MSC4186).

### Matrix Client (`src/utils/matrix.rs`)

- `CLIENT: OnceLock<matrix_sdk::Client>` — the global Matrix client
- Session is persisted to a JSON file (`~/.local/share/piaf/session.json`)
- SQLite store with random passphrase per install (`bundled-sqlite` feature)
- `restore_matrix_client()` is called at startup; if a session exists, it fires sync immediately
- Use `create_or_get_dm(user_id)` for DM creation — it checks for an existing DM room first

### Search Feature (`src/ui/pages/home/search.rs`, `search_tile.rs`)

Three search functions:
- `search_rooms_local(query)` — filters `joined_rooms()` + `invited_rooms()` client-side, returns top 8 by recency
- `search_users_remote(query)` — calls `client.search_users()` (network)
- `search_messages_remote(query, next_batch)` — calls Matrix search API with pagination

Room list data lives in `src/utils/room_list.rs`, built off the UI thread:
- `RoomSummary`: everything a row shows (name, latest_ts, unread/mention counts, `m.marked_unread`, dm, muted, `m.favourite`/`m.lowpriority`, invite, send failure, draft preview) plus the `Room` for the lazy preview text. Its `PartialEq` (ignores the `Room`) is the single definition of a visible change: it decides both whether a new list is published and whether a row re-renders. Add new visible fields there.
- `refresh(source)` only *requests* a rebuild: one background task coalesces requests (16ms) and rebuilds, so nothing builds on the UI thread (a build costs ~1.5µs/room, several ms on large accounts). The rebuild sorts (sections: invites, favourites, rooms, low priority; within each by server recency stamp, see `SortKey`) and publishes a `RoomListSnapshot { version, rooms }` only if the list changed (then also fires `SYNC_TX`). `version == 0` means not built yet.
- Room actions show instantly through `Pending` overrides applied in the build (`update_pending`), cleared when the server echo lands or on failure/timeout.
- Latest events (previews) are computed only for rooms registered with `sync::track_latest_event`, which each `RoomListItem` calls on mount — large accounts (thousands of rooms) only pay for rooms actually shown.
- `RoomList` reads it with `use_watch(room_list::receiver())`; `home/room_list_model.rs` only has the UI-side `RoomFilter` and `visible_rooms`.
- `sort_rooms_by_recency(&mut Vec<Room>)` for code working on raw `Room`s (search).

Context menu (right-click / long-press): `home/room_menu.rs`, actions in `utils/room_actions.rs`. `ContextMenuViewer` is mounted in both layouts.

Drafts: `utils/drafts.rs` (in-memory, mirrored to `drafts.json`). Read with `drafts::get`/`preview`, write with `drafts::set`/`clear`; `set` refreshes the list when the preview changes.

Row gestures are in `home/row_interaction/{desktop,android}.rs`, same API on both: `use_row_interaction()`, `is_highlighted()`, `feedback()`, `attach()`. Put platform differences there, not `#[cfg]` in `RoomListItem`.

### Shared helpers

- `utils/matrix.rs`: `get_room(&str)`, `my_user_id()`, `latest_event_ts(&Room)` — use instead of `RoomId::parse` + `CLIENT.get_room`.
- `utils/room_preview.rs`: `message_body(&MessageType)` (one label per msgtype, used by room list, notifications, reactions, search), `event_preview`, `last_message`, `preview_text`.
- `utils/room_mailbox.rs`: `is_room_archived(&Room, &mailbox)`.

Search state in `HomePage` uses an `Arc<AtomicU64>` version counter to invalidate stale in-flight requests. Version is incremented on each new query; async tasks compare against the version before writing results.

### UI Components (`src/ui/`)

Components are structs that implement `Component + PartialEq`. They use Freya's builder API:

```rust
#[derive(PartialEq)]
pub struct MyComponent { pub some_prop: String }

impl Component for MyComponent {
    fn render(&self) -> impl IntoElement {
        let state = use_state(|| 0u32);
        rect().vertical().child(label().text(self.some_prop.clone()))
    }
}
```

Key Freya hooks: `use_state`, `use_hook` (runs once on mount), `use_query`, `use_side_effect_with_deps`, and ours in `utils/mod.rs`: `use_watch(rx) -> State<T>` (mirrors a tokio watch channel), `use_watch_tick(rx) -> State<u64>` (change counter, for memo keys), `bridge_watch(rx, on_change)` (callback form). Never await `watch::Receiver::changed()` from a Freya `spawn` (tokio coop budget makes it spin at 100% CPU); these helpers await it on tokio and stop when the component unmounts.

#### Hooks rules (Freya)

**Hooks must be called unconditionally at the top of `render`, every time, in the same order.** Never inside `if`/`else`, loops, or after an early `return`. This includes `use_state`, `use_hook`, `use_query`, `use_watch` and `use_watch_tick`.

**`Size::flex()` requires `.content(Content::Flex)` on the parent** — any rect whose children use `Size::flex(n)` must have `.content(Content::Flex)`, or the flex sizing is silently ignored.

**RefCell double-borrow hazard:** `State<T>.read()` returns a `Ref<T>`. Rust extends the `Ref`'s lifetime to the end of an `if let` block, so calling `.write()` on the same `State` inside the block panics at runtime. Always extract to a named `let` first to drop the borrow:

```rust
// Wrong — Ref lives until the closing } and write() panics
if let Some(x) = my_state.read().clone() { *my_state.write() = None; }

// Correct — Ref is dropped at the semicolon
let val = my_state.read().clone();
if let Some(x) = val { *my_state.write() = None; }
```

#### File layout rules

- **1 file = 1 component or 1 page.** Page-specific sub-components go under `src/ui/pages/<page_name>/`.
- Shared, reusable components live under `src/ui/components/`.

#### VirtualScrollView is required for long lists

**Key every item the builder returns** by a stable id (`rect().key(&room_id).child(Row {..})`); components can't take keys themselves. Unkeyed items are matched by position, so each scroll step gives every visible row new props and re-renders all of them (measured: 11× more renders).

**Never replace `VirtualScrollView` with `ScrollView`** for the room list or message list — these lists are too large. `VirtualScrollView` memoizes on `length` + `item_size`; force a re-render when content changes without a count change by keying on a stamp derived from the top item's recency (e.g. `first_room.recency_stamp() + rooms_len`).

### Async bridging: always use `futures::channel::oneshot`, never `tokio::sync::oneshot`

Freya's `spawn` runs on the smol executor. Awaiting a `tokio::sync::oneshot::Receiver` inside a smol task blocks the entire smol thread, freezing the UI.

**Rule:** whenever you need to bridge a `tokio::spawn` result back to a Freya `spawn` task, use `futures::channel::oneshot` — it is executor-agnostic and safe to `.await` from either runtime.

```rust
// Correct
let (tx, rx) = futures::channel::oneshot::channel::<Result<T, ()>>();
tokio::spawn(async move { let _ = tx.send(do_work().await); });
let result = rx.await; // safe in smol

// Wrong — freezes UI
let (tx, rx) = tokio::sync::oneshot::channel::<T>();
```

### Data Fetching (`src/utils/queries.rs`)

Avatar and display-name lookups use `freya-query` for caching. Implement `QueryCapability` with `stale_time`, then call `use_query(Query::new(key, MyCapability).stale_time(...))` in a component.

### Design System (`src/utils/const_values.rs`)

All colors are Material Design 3 tokens as `(u8, u8, u8)` RGB tuples: `PRIMARY`, `ON_SURFACE`, `ON_SURFACE_VARIANT`, `ERROR`, `OUTLINE_VARIANT`, etc. The `Ripple` component from `freya-material-design` is the standard interactive feedback for tappable items. Use `Overflow::Clip` on the outer container.

## Keyboard navigation (desktop, vim-style)

`src/app/keys.rs`. The desktop `Layout` is the only raw key handler: it ignores keys while a text field is focused (`text_input_focused`, by accessibility role), parses them (`parse`, incl. `gg`), and publishes a `KeyCommand` on the `KeyNav` context bus. Components react with `use_key_commands(|nav, command| ...)`, which skips commands sent before they mounted; check `nav.area` (`List` / `Room`) so only the focused pane acts. `KeyNav.selected` is the list cursor. In wide mode the area follows the active room (opening a room focuses it; `h`/`Esc` returns to the list); in narrow mode it follows the route. Text inputs must handle `Esc` themselves (unfocus) so navigation resumes. Bindings and the `?` help text live in `keys.rs` (`HELP`).

## Logging

Use `tracing` (`tracing::info!` etc.), never `println!`. Setup in `src/logging.rs`: desktop filters with `RUST_LOG` (default `warn,piaf=info`); Android forwards to logcat through the `log` bridge.

Perf diagnostics use the `piaf::perf` target (`crate::logging::PERF`): hold a `RenderTimer::new("Name")` for a component's whole `render` (trace = every render, debug = slow renders). Sync batches and timeline updates also log there.

```bash
RUST_LOG=warn,piaf=info,piaf::perf=debug cargo run   # timings
RUST_LOG=warn,piaf=info,piaf::perf=trace cargo run   # + every render
```

## Tests

```bash
cargo test                     # Run all tests (unit + integration)
cargo test <name>              # Run tests whose name contains <name>
cargo test --lib               # Unit tests only (src/utils/mod.rs)
cargo test --test search       # Integration tests only (tests/search.rs)
```

**Unit tests** (`#[cfg(test)]` modules, e.g. `src/utils/mod.rs`, `utils/room_preview.rs`) cover pure functions with no Freya context; `utils/room_list.rs` tests build real `Room`s from a mocked sync via `room_list::test_support` (`MatrixMockServer`). Build events for tests with `Raw::from_json_string(json!({...}).to_string())`.

**Integration tests** (`tests/search.rs`) use `matrix_sdk::test_utils::logged_in_client_with_server()` to spin up a `wiremock::MockServer` and exercise the search functions at the HTTP layer — no real homeserver needed.

**Path versioning note:** The test client uses `MatrixVersion::V1_0`, so ruma routes requests to `/_matrix/client/r0/…` paths (not `/v3/`). When writing new integration tests, check the ruma `metadata! { history: { 1.0 => "...", 1.1 => "..." } }` block for the correct path per API.

True GUI end-to-end tests are not feasible (Freya has no headless renderer).
