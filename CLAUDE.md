# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
cargo run          # Run the app (debug)
cargo build        # Build (debug)
cargo build --release
cargo check        # Fast type-check without linking (use this to verify edits)
cargo check --target aarch64-linux-android  # Verify Android build (always run after editing lib.rs or Android-specific code)
```

The project uses the `mold` linker (configured in `.cargo/config.toml`) and optimizes dependency crates at `opt-level = 1` in dev builds, so incremental rebuilds are fast.

There is no test suite yet.

## Architecture

**PIAF** is a Matrix messaging client built with the [Freya](https://freyaui.dev) Rust GUI framework and `matrix-sdk` 0.16.

**Freya dependency is a local path** (`../freya/crates/freya`), not from crates.io. Changes to Freya itself are in the sibling repo.

### Routing & Layout (`src/main.rs`)

`Route` is a `Routable` enum covering all screens. The `Layout` component measures window width and decides how many panels to show:

- `< 800px`: single panel (standard `Outlet`)
- `≥ 800px`: two panels — `HomePage` (400px fixed) + `ActiveRoomPanel` (flex)
- `≥ 1200px`: three panels — room list + room + settings

Navigation uses `RouterContext::get().push(Route::...)`. In wide mode, the right panel is driven by `ACTIVE_ROOM_TX`/`ACTIVE_ROOM_RX` (watch channel) rather than router navigation.

### Global Singletons (`src/main.rs`)

```rust
REQUESTER: OnceLock<Requester>          // Send tasks to the background worker
SYNC_TX/RX: OnceLock<watch::...>        // Fires on every Matrix sync tick
ACTIVE_ROOM_TX/RX: OnceLock<watch::...> // Currently selected room (wide mode)
WIDE_MODE: AtomicBool                   // Current layout mode
```

### Background Worker (`src/utils/worker.rs`)

All Matrix SDK calls happen off the UI thread via two worker loops spawned at startup:

- **ClientWorker**: handles login, avatar/name fetches, media downloads
- **SyncWorker**: runs `matrix_sync()` in a loop, fires `SYNC_TX` each tick

### Matrix Client (`src/utils/matrix.rs`)

- `CLIENT: OnceLock<matrix_sdk::Client>` — the global Matrix client
- Session is persisted to a JSON file (`~/.local/share/piaf/session.json`)
- SQLite store with random passphrase per install
- `restore_matrix_client()` is called at startup; if a session exists, it fires sync immediately

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

Key Freya hooks: `use_state`, `use_hook` (runs once on mount), `use_query`, `use_track_watcher` (re-renders on watch channel change).

**`Size::flex()` requires `.content(Content::Flex)` on the parent** — any rect whose children use `Size::flex(n)` must have `.content(Content::Flex)`, or the flex sizing is silently ignored. This applies to both horizontal and vertical rects, including divider rows with flex spacers.

#### File layout rules

- **1 file = 1 component or 1 page.** Each file contains exactly one `Component` impl or one page-level component, nothing more. Helper functions that are pure UI (no hooks) live in their own file too.
- Pages live under `src/ui/pages/<page_name>/`. Page-specific sub-components and helpers go in that same directory (e.g. `src/ui/pages/room/message_row.rs`).
- Shared, reusable components live under `src/ui/components/`.
- A page `mod.rs` may contain the page struct + shared types used by its sub-files. All other logic must be split out.

#### VirtualScrollView is required for long lists

**Never replace `VirtualScrollView` with `ScrollView`** for the room list or message list — these lists are too large. `VirtualScrollView` memoizes on `length` + `item_size`; force a re-render when content changes without a count change by keying on a stamp derived from the top item's recency (e.g. `first_room.recency_stamp() + rooms_len`).

### Async bridging: always use `futures::channel::oneshot`, never `tokio::sync::oneshot`

Freya's `spawn` runs on the smol executor. Awaiting a `tokio::sync::oneshot::Receiver` inside a smol task blocks the entire smol thread, freezing the UI (confirmed by GDB: `tokio::sync::oneshot::Receiver::poll` hanging in a smol context).

**Rule:** whenever you need to bridge a `tokio::spawn` result back to a Freya `spawn` task, use `futures::channel::oneshot` — it is executor-agnostic and safe to `.await` from either runtime.

```rust
// Correct
let (tx, rx) = futures::channel::oneshot::channel::<Result<T, ()>>();
tokio::spawn(async move { let _ = tx.send(do_work().await); });
let result = rx.await; // safe in smol

// Wrong — freezes UI
let (tx, rx) = tokio::sync::oneshot::channel::<T>();
tokio::spawn(async move { let _ = tx.send(do_work().await); });
let result = rx.await; // blocks smol thread
```

### Data Fetching (`src/utils/queries.rs`)

Avatar and display-name lookups use `freya-query` for caching. Implement `QueryCapability` with `stale_time`, then call `use_query(Query::new(key, MyCapability).stale_time(...))` in a component.

### Design System (`src/utils/const_values.rs`)

All colors are Material Design 3 tokens as `(u8, u8, u8)` RGB tuples: `PRIMARY`, `ON_SURFACE`, `ON_SURFACE_VARIANT`, `ERROR`, `OUTLINE_VARIANT`, etc. Import what you need from `crate::utils::const_values`.

The `Ripple` component from `freya-material-design` is the standard interactive feedback for tappable items. Use `Overflow::Clip` on the outer container.
