# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
cargo run          # Run the app (debug)
cargo build        # Build (debug)
cargo build --release
cargo check        # Fast type-check without linking (use this to verify edits)
cargo check --target aarch64-linux-android  # Verify Android build (always run after editing lib.rs or Android-specific code)
cargo test                  # Run all unit tests
cargo test <name>           # Run tests whose name contains <name>
```

The project optimizes dependency crates at `opt-level = 1` in dev builds (`Cargo.toml [profile.dev.package."*"]`), so incremental rebuilds are fast.

## Architecture

**PIAF** is a Matrix messaging client built with the [Freya](https://freyaui.dev) Rust GUI framework and `matrix-sdk` 0.17.

**Freya dependency is a local path** (`../freya/crates/freya`), not from crates.io. Changes to Freya itself are in the sibling repo.

### Routing & Layout (`src/main.rs`)

`Route` is a `Routable` enum covering all screens. The `Layout` component measures window width and decides how many panels to show:

- `< 800px`: single panel (standard `Outlet`)
- `≥ 800px`: two panels — `HomePage` (400px fixed) + `ActiveRoomPanel` (flex)
- `≥ 1200px`: three panels — room list + room + settings

Navigation uses `RouterContext::get().push(Route::...)`. In wide mode, the right panel is driven by `ACTIVE_ROOM_TX`/`ACTIVE_ROOM_RX` (watch channel) rather than router navigation.

**Always navigate rooms via the shared helper** `navigate_to_room(room_id)` defined in `src/ui/pages/home/mod.rs` — it handles both wide-mode (`ACTIVE_ROOM_TX`) and narrow-mode (router push) correctly. Submodules of `home` call it as `super::navigate_to_room(...)`.

### Global Singletons (`src/main.rs` and `src/lib.rs`)

```rust
REQUESTER: OnceLock<Requester>                               // Send tasks to the background worker
SYNC_TX/RX: OnceLock<watch::...>                             // Fires on every Matrix sync tick
ACTIVE_ROOM_TX/RX: OnceLock<watch::...>                      // Currently selected room (wide mode)
FOCUS_EVENT_TX/RX: OnceLock<watch::Option<(String, String)>> // (room_id, event_id) for scroll-to-event
WIDE_MODE: AtomicBool                                        // Current layout mode
```

`FOCUS_EVENT_TX/RX` passes a search-result target event to `RoomPage` across a navigation. It is **always cleared unconditionally** by the first `RoomPage` render after it is set (whether or not the room_id matches), which prevents stale events from persisting if navigation is aborted. `RoomPage` also installs a watcher in `use_hook` to handle re-focus when the same room is already mounted (wide mode).

All OnceLocks are initialized in `main()` before `launch()`, so `.get()` always returns `Some`. Call with `.expect("not initialized")` — never wrap in `if let Some(...)`.

### Background Worker (`src/utils/worker/`)

All Matrix SDK calls happen off the UI thread via two worker systems spawned at startup:

- **`MatrixClientWorker`** (`worker/client.rs`): handles login, avatar/name fetches, room preview fetches
- **`MatrixSyncWorker`** (`worker/sync.rs`): runs `matrix_sync()` in a loop, fires `SYNC_TX` each tick

Send tasks via `REQUESTER.get().expect(...).method(...)`.

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

Room sorting is shared: `sort_rooms_by_recency(&mut Vec<Room>)` in `src/ui/pages/home/mod.rs` is used by both the search and the normal room list. Submodules call it as `super::sort_rooms_by_recency(...)`.

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

Key Freya hooks: `use_state`, `use_hook` (runs once on mount), `use_query`, `use_side_effect_with_deps`, `use_tokio_track_watcher` (re-renders on watch channel change).

#### Hooks rules (Freya)

**Hooks must be called unconditionally at the top of `render`, every time, in the same order.** Never inside `if`/`else`, loops, or after an early `return`. This includes `use_state`, `use_hook`, `use_query`, and `use_tokio_track_watcher`.

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

## Tests

```bash
cargo test                     # Run all tests (unit + integration)
cargo test <name>              # Run tests whose name contains <name>
cargo test --lib               # Unit tests only (src/utils/mod.rs)
cargo test --test search       # Integration tests only (tests/search.rs)
```

**Unit tests** (`src/utils/mod.rs`) cover pure utility functions with no Matrix client or Freya context.

**Integration tests** (`tests/search.rs`) use `matrix_sdk::test_utils::logged_in_client_with_server()` to spin up a `wiremock::MockServer` and exercise the search functions at the HTTP layer — no real homeserver needed.

**Path versioning note:** The test client uses `MatrixVersion::V1_0`, so ruma routes requests to `/_matrix/client/r0/…` paths (not `/v3/`). When writing new integration tests, check the ruma `metadata! { history: { 1.0 => "...", 1.1 => "..." } }` block for the correct path per API.

True GUI end-to-end tests are not feasible (Freya has no headless renderer).
