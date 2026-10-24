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

`Cargo.lock` is edited by hand in one place: `bindgen` (Freya's skia build) uses `prettyplease 0.3` while `bon-macros` (matrix-sdk's search, via tantivy) keeps `0.2`. Both are allowed, but cargo would unify them onto 0.2, which doesn't compile with the `syn 3` bindgen then gets. After a `cargo update` that touches them, re-point bindgen's `prettyplease` to `0.3.x`.

The project optimizes dependency crates at `opt-level = 1` in dev builds (`Cargo.toml [profile.dev.package."*"]`, line-table debug info only), so incremental rebuilds are fast. Android debug APKs (`just build`) use the `android-dev` profile: dependencies optimised, the piaf crate at `opt-level = 0` (an edit rebuilds in ~5s), arm64 only. `just build` also caps `target/` at 30 GB with `cargo sweep` (`cargo install cargo-sweep`); `just -f AndroidApp/Justfile sweep` also drops artifacts of uninstalled toolchains. Cargo never deletes build files of configurations it stops using (~1 GB per piaf configuration).

## Architecture

**PIAF** is a Matrix messaging client built with the [Freya](https://freyaui.dev) Rust GUI framework and `matrix-sdk` 0.19 (needs Rust ≥ 1.96; TLS via its `rustls-aws-lc-rs` feature, required with `default-features = false`). On Android, certificates are checked by `rustls-platform-verifier` against the system trust store: `android_main` initializes it (`init_tls_verifier`, jni 0.22 as `jni22`), and so does `nativeInitForPush` (a process started for a push never runs `android_main`), and Gradle pulls its Kotlin component (`org.rustls:rustls-platform-verifier`, from the GitHub Maven repo in `settings.gradle.kts`) at the version of `rustls-platform-verifier-android` in `Cargo.lock` (read by `app/build.gradle.kts`). Without the init every HTTPS request panics (`Expect rustls-platform-verifier to be initialized`); with a component older than 0.2.0, Let's Encrypt certificates (no OCSP URL) fail as `Revoked` (its manifest allows the CA revocation lists over HTTP).

**Freya dependency is a local path** (`../freya/crates/freya`), not from crates.io. Changes to Freya itself are in the sibling repo.

### Crate layout

`src/main.rs` only calls `piaf::run_desktop()`; everything lives in the lib (`src/lib.rs`). Android enters via `android_main` in `src/android/mod.rs` (JNI push exports in `src/android/jni_push.rs`).

- `src/app/routes.rs` — `Route`
- `src/app/layout/{desktop,android}.rs` — `Layout` per platform
- `src/app/active_room_panel.rs` — wide-mode right panel
- `src/app/navigation.rs` — navigation helpers
- `src/app/state.rs` — global singletons + `init()`
- `src/app/theme.rs` — `effective_theme`
- `src/app/page_transition.rs` — Android: incoming page slides/fades in around the `Outlet` (direction from path depth)

### Routing & Layout (`src/app/`)

`Route` is a `Routable` enum covering all screens. The `Layout` component measures window width and decides how many panels to show:

- `< 800px`: single panel (standard `Outlet`)
- `≥ 800px`: two panels — `HomePage` (400px fixed) + `ActiveRoomPanel` (flex)
- `≥ 1200px`: three panels — room list + room + settings

Navigation uses `RouterContext::get().push(Route::...)`. In wide mode, the right panel is driven by `ACTIVE_ROOM_TX`/`ACTIVE_ROOM_RX` (watch channel) rather than router navigation.

**Always navigate rooms via the shared helper** `navigate_to_room(room_id)` (and `navigate_to_room_at_event`) in `src/app/navigation.rs` — it handles both wide-mode (`ACTIVE_ROOM_TX`) and narrow-mode (router push) correctly. Open a DM with `open_dm(UserInfo)` (existing room, else the pending-DM page; never create rooms on a tap). Back buttons use `go_back_or_home`, never a push of the parent route (that grows the history). Other taps that navigate use `navigation::push(route)`: all of these play the navigation haptic. Raw `RouterContext::get().push` only for programmatic redirects (session restore, after login / leaving a room).

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

- `timeline_task.rs` — tokio side: builds the matrix timeline, applies diffs, runs `MsgAction`s (send / edit / reply take an `outgoing::Draft`: markdown → `formatted_body`, mentions → pills + `m.mentions`; `MarkRead`, `Typing`). Failed actions come back as `errors`, shown by a `Snackbar`. It fetches reply details the SDK marks `Unavailable`, and sends typing names as display names. UI talks to it through `TimelineHandle` (`paginate()`, `actions()`, `mark_read()`); dropping the handle stops the task.
- `use_room_timeline.rs` — hook returning `RoomTimeline { handle, state }`; `state` is a `Copy` bundle of `State`s (messages, loading, paginating, …). The smol receive loop must never hold the handle.
- `timeline_view.rs` — `TimelineView`: scroll view, rows, row height measuring, pagination triggers, read receipts (live timeline, at its end, app focused), `JumpToLatest` (`jump_to_latest.rs`). Only it reads `messages`, so timeline updates don't re-render `RoomPage`. Scrolling to an event (`focus::focus_event`: a tapped reply, a search result) loads older pages until the event is found, then highlights its row.
- `message_row/` — `MessageRow` (bubble, avatar, platform extras) built from `content.rs` (per msgtype), `body.rs` (text: a formatted message's body is its markdown source, a plain one is escaped; rendered line by line since Freya's markdown joins lines; mentions from `utils/mentions.rs` become `MentionPill`s with the member's display name, through `MarkdownViewer::inline_element`), `reply_quote.rs`, `reactions.rs`, `receipts.rs`, `meta.rs` (time, "edited", send state), `notices.rs` (day dividers, read marker, membership, deleted / undecryptable placeholders). Forwarded messages (bridges): found by the `<p data-mx-forwarded-notice>` of the HTML body (`timeline_media::forward_split`), never by its text; the row shows a small "Forwarded" line and the notice is dropped from the body, captions and file names.
- `message_actions.rs` — a message's menu (long press, right click, "more"): reaction row (the message's reactions, ours highlighted, then quick ones), Reply / Copy text / Edit / Bookmark / Details / Delete (confirmed). A bottom sheet on Android, a popup on desktop. The avatar's `UserPopupOverlay` follows the same rule.
- Composer on Android: the soft keyboard types into an invisible `ImeInputView` (`AndroidApp/.../ImeInput.kt`, an `InputConnection`: suggestions, accents, swipe typing); commits / compositions / deletes reach the composer (`composer/ime.rs`, `use_composer_ime`) through `android/ime.rs` → `utils/ime.rs` (no-op on desktop), applied by `utils/ime_edit.rs` (shared with the search field). `ime::show(text, cursor, ImeKind)`: `Composer` (multiline) or `Search` (one line, the action key arrives as `ImeEvent::Action`). `ImeInputView` is focusable only between show and hide, or it steals the keyboard from every other text field. The composer shows/hides it on focus and re-syncs it (`ime::sync`) when its text changes elsewhere. Touch editing (long press selects the word under the finger, dragging extends the selection; Cut / Copy / Paste / Select all bar) comes from Freya's `touch_edit` (`use_touch_edit`, `place_cursor`, `EditMenu`), shared with `SearchField` and built into Freya's `Input`. The Android text clipboard is installed by `freya-android`; `utils/clipboard.rs` only reads desktop clipboard images.
- Composer (`composer/`): one filled pill (`@` suggestions and the reply / edit card on top, attach icon + text below, placeholder kept while focused and empty), and a round send button that fades in only with something to send. `@` autocomplete (`mentions.rs`) inserts `@Name` and remembers the member for the `Draft`; Tab / Enter take the first suggestion. Typing notices while there is text. Reply / edit state is `RoomUiCtx::{reply_to, editing}` (`ReplyTo`, `Editing`); `RoomUiCtx::reply` starts a reply. Attach: desktop opens the file dialog; Android a sheet (Photos & videos / Camera / File) → `media::pick_attachment(AttachSource)` → `android/attachments.rs` ↔ `AttachmentPicker.kt` (photo picker, `ACTION_IMAGE_CAPTURE` into the FileProvider cache, `ACTION_OPEN_DOCUMENT`; ≤ 100 MB) → `media::send_attachment`.
- `ui_ctx.rs` — `RoomUiCtx` (popup/overlay states) provided as context; rows use `use_room_ui_ctx()` instead of props. The media viewer covers the room (overlay) instead of replacing it, so the composer and its text stay mounted.
- The `ScrollController` and `pending_focus` live in `RoomPage` scope so they survive the media viewer unmounting `TimelineView`.

All OnceLocks are initialized by `app::state::init()` before `launch()` (desktop and Android), so `.get()` always returns `Some`. Call with `.expect("not initialized")` — never wrap in `if let Some(...)`.

### Background Worker (`src/utils/worker/`)

All Matrix SDK calls happen off the UI thread:

- **`MatrixClientWorker`** (`worker/client.rs`): handles login and room preview fetches. Send tasks via `REQUESTER.get().expect(...).method(...)`.
- **Sync** (`utils/sync.rs`): matrix-sdk-ui `SyncService` (sliding sync: room list with account data/receipts/typing, plus encryption sync), built and started by `activate_client`. There is no classic `/sync` loop. A room-updates watcher calls `room_list::refresh`, which fires `SYNC_TX` when the room list changed; a state watcher maps `Offline`/`Error` to `DISCONNECTED` and restarts after errors (not after session expiry). Room subscriptions go through `sync::subscribe_room` (guard held by `RoomView`: the open room gets 20 events per update; without it the room list's limit of 1 makes responses `limited` and the event cache unloads all but the newest messages) and `sync::subscribe_previews`; never call `set_room_subscriptions` directly (it replaces the whole set).
- Event handlers (`add_event_handler`) fire for sliding-sync responses too, but the room list uses `timeline_limit` 1: only the latest event per room per update reaches them.
- Requires a homeserver with Simplified Sliding Sync (MSC4186).

### Matrix Client (`src/utils/matrix.rs`)

- `CLIENT: OnceLock<matrix_sdk::Client>` — the global Matrix client
- Session is persisted to a JSON file (`~/.local/share/piaf/session.json`)
- SQLite store with random passphrase per install (`bundled-sqlite` feature)
- `restore_matrix_client()` is called at startup; if a session exists, it fires sync immediately
- Use `create_or_get_dm(user_id)` for DM creation — it checks for an existing DM room first

### Notifications

- Desktop (`utils/notifications.rs`): event handler on new messages, gated by window focus and session start, then the account's push rules (`room.event_push_actions`); icon = the room's avatar (`AvatarSource::Room`, DM → other user).
- Android: UnifiedPush → Kotlin `PushReceiver` → `RoomNotifications.show` (on its own thread: the main thread must stay free to start the app on a tap) (`AndroidApp/.../RoomNotifications.kt`): one MessagingStyle notification per room. Content comes from Rust over JNI (`android/jni_push.rs` → `push::fetch_notification_payload`: `Show` / `Skip` (edits, non-messages) / `Unavailable`), else `HttpFallback`. Large icon: other user in a DM, the room's own avatar in a group (never a member's), letter avatar (`id_color`) without picture. `SeenEvents` dedupes event IDs; swiping a notification away (`NotificationDismissedReceiver`) or reading the room clears its history. Tapping one calls `nativeOpenRoom` → `navigation::request_open_room`, opened by the Android layout once past welcome/login. Each room notification has Reply / Mark as read actions (`NotificationActionReceiver` → `nativeSendReply` / `nativeMarkRead` → `push::send_text` / `push::mark_read`) and a long-lived conversation shortcut (id = room id); no group summary. `fetch_notification_payload` skips events the user's read receipt already covers.

### Search Feature (`src/ui/pages/home/search.rs`, `search_tile.rs`)

Desktop searches inline in the home bar (`HomeAppBar`). Android opens search mode as its own page, `Route::SearchPage` (`ui/pages/search/`), reusing `SearchResults`; its query survives a result's round trip and is cleared when `HomePage` mounts. The page's field is `SearchField` (the app bar's own text, typed through the IME bridge with `ImeKind::Search`: search key, × clear), filter chips (`SearchFilter`: All / Rooms / People / Messages; one section alone shows more results), and `EmptySearch` before typing (recent chats, recent searches from `utils/recent_searches.rs`, cleared on sign-out). Scrolling the results hides the keyboard.

Three search functions:
- `search_rooms_local(client, query, limit)` — filters `joined_rooms()` + `invited_rooms()` client-side, top `limit` by recency (8, or 50 with the Rooms chip)
- `search_users_remote(query)` — calls `client.search_users()` (network)
- `search_messages_remote(query, next_batch)` — calls Matrix search API with pagination

Room list data lives in `src/utils/room_list.rs`, built off the UI thread:
- `RoomSummary`: everything a row shows (name, latest_ts, unread/mention counts, `m.marked_unread`, dm, muted, `m.favourite`/`m.lowpriority`, invite, send failure, draft preview) plus the `Room` for the lazy preview text. Its `PartialEq` (ignores the `Room`) is the single definition of a visible change: it decides both whether a new list is published and whether a row re-renders. Add new visible fields there.
- `refresh(source)` only *requests* a rebuild: one background task coalesces requests (16ms) and rebuilds, so nothing builds on the UI thread (a build costs ~1.5µs/room, several ms on large accounts). The rebuild sorts (sections: invites, favourites, rooms, low priority; within each by server recency stamp, see `SortKey`) and publishes a `RoomListSnapshot { version, rooms }` only if the list changed (then also fires `SYNC_TX`). `version == 0` means not built yet.
- Room actions show instantly through `Pending` overrides applied in the build (`update_pending`), cleared when the server echo lands or on failure/timeout.
- Latest events (previews) are computed only for rooms registered with `sync::track_latest_event`, which each `RoomListItem` calls on mount — large accounts (thousands of rooms) only pay for rooms actually shown.
- `RoomList` reads it with `use_watch(room_list::receiver())`; `home/room_list_model.rs` only has the UI-side `RoomFilter` and `visible_rooms`.
- `sort_rooms_by_recency(&mut Vec<Room>)` for code working on raw `Room`s (search).

Spaces (`utils/spaces.rs`): matrix-sdk-ui's `SpaceService` (started by `sync::start`, stopped on logout) publishes the joined top-level spaces on `spaces::receiver()`: `Space { rooms, subspaces }`, `rooms` covering sub-spaces too (`build`, unit-tested). Joined spaces are not listed as chats (`room_list::listed_rooms`); invites to them are. `RoomList { scope }` and `visible_rooms` / `unread_conversations(.., scope)` narrow to a space. Desktop: `home/space_rail.rs` (left of the list, inside the 400px side panel) selects through the global `spaces::selection()`; a space's sub-spaces become a chip row in `RoomFilterBar` (`filter_bar_height`). Android: a Spaces tab (`ui/pages/spaces/`: `SpacesPage`, `SpacePage` with sub-space chips over a scoped `RoomList`).

Android bottom tabs: Chats, Spaces, More (Settings opens from the avatar in the home app bar). The More tab (`ui/pages/more/`) holds Reactions, Bookmarks and the Recontact / Archived mailboxes (`ui/pages/mailbox/`, `RoomList` with `filter_bar: None`); desktop keeps them in the home app bar and the filter bar's mailbox selector.

Room actions: `home/room_menu.rs` (one entry list; desktop right-click opens a `ContextMenu`, Android long-press a `BottomSheet` held in `RoomListCtx`), actions in `utils/room_actions.rs`. `ContextMenuViewer` is mounted in both layouts.

Drafts: `utils/drafts.rs` (in-memory, mirrored to `drafts.json`). Read with `drafts::get`/`preview`, write with `drafts::set`/`clear`; `set` refreshes the list when the preview changes.

Row gestures are in `home/row_interaction/{desktop,android}.rs`, same API on both: `use_row_interaction()`, `is_highlighted()`, `feedback()`, `attach()`. Put platform differences there, not `#[cfg]` in `RoomListItem`.

### Shared helpers

- `utils/matrix.rs`: `get_room(&str)`, `my_user_id()`, `latest_event_ts(&Room)` — use instead of `RoomId::parse` + `CLIENT.get_room`.
- `utils/room_preview.rs`: `message_body(&MessageType)` (one label per msgtype, used by room list, notifications, reactions, search), `reply_preview`, `sender_name(&EventTimelineItem)`, `event_preview`, `last_message`, `preview_text`.
- `utils/timeline_media.rs`: images / files / links in timeline items (`entries`, `MediaEntry`, `MediaKind`, `caption`).
- `utils/media.rs`: `download(&MediaSource)`, `save_to_downloads`, `send_attachment`, `pick_image` (desktop), `image_mime`, `format_file_size`, `format_media_duration`.
- `utils/users.rs`: `UserInfo`, `search` (user directory), `dm_contacts`. `utils/members.rs`: `MemberItem`, `joined(&Room)`, `ADMIN_LEVEL`.
- `utils::id_color(id)`: the one color for a user/room ID (avatars, sender names).
- `utils/room_mailbox.rs`: `is_archived_hidden(latest_ts, archived_until_ts)`.
- `utils/haptics.rs`: `play(Haptic::Click | HeavyClick)` (Android vibrator, no-op elsewhere). `navigate_to_room` and `go_back_or_home` already tick.
- `utils/insets.rs`: system insets in logical px, reported by `MainActivity` (edge to edge). `status_bar_inset()` for app bars drawn under the status bar; `use_insets()` (reactive: keyboard) — the Android `Layout` pads the app above the keyboard / navigation bar and hides the tab bar while typing. Never hard-code bottom paddings for the gesture bar.

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

#### Shared building blocks (`src/ui/components/`) — reuse, don't re-implement

- `Hoverable` / `.hoverable(w, h, radius)`: hover tint for anything pressable (fades in/out). No hand-rolled `hovered` states for highlights.
- `IconButton`: round icon button (hover, ripple, optional `.tooltip()`, press doesn't reach the parent).
- `Chip`: pill toggle for filters, tabs and option pickers (selection colours animate).
- `ListItem`: any list row (leading, headline + optional badge, supporting line, trailing, press). Text fills the space left and ellipsizes, so it never runs under `trailing`: build rows on it instead of hand-made `rect`s. `ListItem::with_headline(el)` for a styled headline.
- `TopAppBar::new(title)`: a page's bar with a back button (`go_back_or_home`); `.action(icon, on_press)` adds trailing buttons. `search_app_bar(SearchField {..}, c)`: a search page's bar.
- `picked_users(users, on_remove, c)`: removable chips for people being picked (invites, new group). `sender_in_room(sender, room, c)` / `row_time(ts_ms, c)`: headline and time of a `ListItem` pointing at a message elsewhere (bookmarks, reactions).
- `use_member_name(room_id, user_id) -> Option<String>` (`utils/queries.rs`): a member's display name, cached. `matrix::own_display_name(&client)`.
- `use_auth_size()` → `AuthSize` (`is_wide`, `is_short`, `page(body, c)`): the welcome / login layout.
- `PersonRow`: a person (a `ListItem`: avatar, name, badge, subtitle or user ID, trailing, press). `badge("Admin", c)`.
- `bottom_sheet(c, on_close)`: Freya's `BottomSheet` (shared with rusty_map, in the Freya fork) in piaf colours, above the navigation bar, grab bar on Android. `Dialog` (centered modal, any children, `dialog_button` for actions) / `confirm_dialog(title, message, confirm, on_cancel, on_confirm)`: dialogs and destructive confirmations.
- `empty_state(icon, title, hint, c)` / `loading_state(caption, c)`: placeholders filling a list's area.
- `SearchBox { value, placeholder, auto_focus }`: a search box filtering a page's list (Android: types through the IME bridge, like `SearchField`; desktop: `search_input`). `SearchField`: the query field of a search page's app bar. Plain `search_input(state, placeholder, c)` only for desktop-only UI: an `Input` gets Android's raw keyboard (no suggestions, accents or swipe typing).
- `use_fade(visible, ms) -> f32` and `use_fading(Option<T>, ms) -> Option<(T, opacity)>` (keeps the last value while fading out): for things that appear and disappear. Both start at their end value, so nothing animates on mount (virtual lists remount rows while scrolling).
- `use_color_transition(target, ms)`: a colour easing to each new target (bars tinting on scroll). A page whose content scrolls under its `TopAppBar` provides `AppBarTint(State<bool>)` to tint it.
- `MediaViewer` (`components/media_viewer/`): full-bleed image on black, controls over it on gradients (a tap hides them). Touch gestures live in the pure, unit-tested `gesture.rs` model (page between images, swipe down/up to close, double tap / pinch to zoom, pan); `settle` eases the offsets after a release. Desktop keeps arrow keys and round overlay arrows. Share uses `media::share_image` → `android/share.rs` ↔ `ShareSheet.kt`.
- `Avatar` + `AvatarSource` (see Avatars).
- `use_swipe()` / `SwipeBounds` (Android): horizontal swipe on a touch row (follows the finger, haptic tick at the commit point, spring back). Used by room rows and swipe-to-reply (`room/message_gesture.rs`). It picks its direction with the scroll view's rule (8px, horizontal when `|dx| > |dy|`), so a drag is always either the list's or the row's. Panels revealed behind a swiped row stay at the normal layer, with the row lifted above them (`ROW_LAYER`): a negative layer goes below the page's background. Feed `moved` from `on_global_pointer_move` (a row's `touchmove` stops once the finger drifts onto the next row, leaving it stuck half-swiped) and pass `start`/`moved` the scroll's `touch_generation()`. Rows inside a scroll view must also finish on `on_global_pointer_up`, and long-press timers must snapshot `ScrollController::touch_generation()` at touch start and give up if it changed: once the list claims a touch (or cancels its lift, e.g. a tap that stops a fling), rows get no more `touchmove`/`touchend`/global pointer up. Taps on parts of a swipeable row (message image, reactions, avatar…) check a guard (`allows_press()` / `PressGuard`) in their `on_press`: it can run before the row's `on_touch_end` cancels it.

#### Hooks rules (Freya)

**Hooks must be called unconditionally at the top of `render`, every time, in the same order.** Never inside `if`/`else`, loops, or after an early `return`. This includes `use_state`, `use_hook`, `use_query`, `use_watch` and `use_watch_tick`.

**Layers add up with nesting depth**: an overlay (`.layer(n)`) is drawn under anything nested deeper than it plus `n`, e.g. images inside timeline rows. Floating things over the timeline use a large layer (`1000`, like the composer's edit menu). An absolutely positioned overlay sized with `expanded()` gets the space its siblings leave (often none): size it with `Size::percent(100.)`.

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

**Never replace `VirtualScrollView` with `ScrollView`** for the room list — it is too large. The message list is the exception: its rows have no fixed height (text, images, reactions), which `VirtualScrollView` needs, so `TimelineView` uses a `ScrollView` with measured row heights. `VirtualScrollView` memoizes on `length` + `item_size`; force a re-render when content changes without a count change by keying on a stamp derived from the top item's recency (e.g. `first_room.recency_stamp() + rooms_len`).

### Async bridging: `utils::on_tokio`, never `tokio::sync::oneshot`

Run tokio work from the UI with `let result = on_tokio(async move { ... }).await;` (returns `Option<T>`, `None` if the task panicked). It spawns right away and bridges through a `futures` oneshot. To wait inside a Freya task use Freya's `timer(duration)`, not `tokio::time::sleep`. The rule below is what `on_tokio` implements:

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

### Avatars (`src/utils/avatars.rs`, `ui/components/avatar.rs`)

`Avatar { size, source: Option<AvatarSource>, name, color }` shows `source`'s image, else the initial of `name` (don't compute initials yourself; color: `id_color`). **Always pick the source by what is shown, never build string keys:** `Room(room_id)` (DM → other user, own avatar, hero), `Member { room_id, user_id }` (room avatar → global profile; use `AvatarSource::member(..)` for anyone seen in a room: senders, receipts, member lists), `User(user_id)`, `Mxc(uri)` (raw `mxc://` URI already in hand, e.g. search results), `Me`, `Bytes(..)`. Each source has one cache entry app-wide and one fetch path (`avatars::fetch`, server thumbnails). Failures log under `piaf::avatar` (debug).

### Data Fetching (`src/utils/queries.rs`)

Display-name and media lookups use `freya-query` for caching. Implement `QueryCapability` with `stale_time`, then call `use_query(Query::new(key, MyCapability).stale_time(...))` in a component.

### Design System (`src/utils/const_values.rs`)

All colors are Material Design 3 tokens as `(u8, u8, u8)` RGB tuples: `PRIMARY`, `ON_SURFACE`, `ON_SURFACE_VARIANT`, `ERROR`, `OUTLINE_VARIANT`, etc. The `Ripple` component from `freya-material-design` is the standard interactive feedback for tappable items. Use `Overflow::Clip` on the outer container.

## Keyboard navigation (desktop, vim-style)

`src/app/keys.rs`. The desktop `Layout` is the only raw key handler: it ignores keys while a text field is focused (`text_input_focused`, by accessibility role), parses them (`parse`, incl. `gg`), and publishes a `KeyCommand` on the `KeyNav` context bus. Components react with `use_key_commands(|nav, command| ...)`, which skips commands sent before they mounted; check `nav.area` (`List` / `Room`) so only the focused pane acts. `KeyNav.selected` is the list cursor. In wide mode the area follows the active room (opening a room focuses it; `h`/`Esc` returns to the list); in narrow mode it follows the route. Text inputs must handle `Esc` themselves (unfocus) so navigation resumes. Bindings and the `?` help text live in `keys.rs` (`HELP`).

## Logging

Use `tracing` (`tracing::info!` etc.), never `println!`. Setup in `src/logging.rs`: desktop filters with `RUST_LOG` (default `DEFAULT_FILTER`: `warn,matrix_sdk_crypto=error,piaf=info`); Android forwards to logcat through the `log` bridge. Never log secrets or private data: push endpoints, tokens, keys, message content, user IDs or names at info and above.

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

**Component tests** use `freya-testing` (headless runner): `launch_test(app)`, then `sync_and_update()`, `click_cursor`, `write_text`, `find(..)` / `layout()`, `render_to_file(path)` for a PNG. Call `use_init_theme(light_theme)` in the test app (`use_app_colors` needs a theme). Toggle a component's states in a test to catch hook-order panics (e.g. `bookmarks::tests`). Components reading the global singletons (`CLIENT`, `REQUESTER`…) need `app::state::init` first, or test their pure parts.
