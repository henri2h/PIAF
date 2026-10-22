use freya::prelude::*;

use super::room_list::RoomListCtx;
use crate::ui::components::{HoverableExt, bottom_sheet, confirm_dialog};
use crate::utils::const_values::AppColors;
use crate::utils::room_actions::{RoomAction, run};
use crate::utils::room_list::RoomSummary;

/// Room actions sheet shown on Android; `confirm_leave` is its confirmation step.
#[derive(Clone, PartialEq)]
pub(super) struct RoomSheet {
    summary: RoomSummary,
    confirm_leave: bool,
}

enum Entry {
    Action(&'static str, RoomAction),
    Archive,
    /// Label, then the confirm button's label.
    Leave(&'static str, &'static str),
}

fn entries(s: &RoomSummary) -> Vec<Entry> {
    if s.is_invite {
        return vec![Entry::Leave("Decline invite", "Decline")];
    }
    vec![
        if s.is_unread() {
            Entry::Action("Mark as read", RoomAction::MarkRead)
        } else {
            Entry::Action("Mark as unread", RoomAction::MarkUnread)
        },
        if s.is_favourite {
            Entry::Action("Remove from favourites", RoomAction::Favourite(false))
        } else {
            Entry::Action("Add to favourites", RoomAction::Favourite(true))
        },
        if s.is_low_priority {
            Entry::Action("Remove from low priority", RoomAction::LowPriority(false))
        } else {
            Entry::Action("Move to low priority", RoomAction::LowPriority(true))
        },
        if s.is_muted {
            Entry::Action("Unmute", RoomAction::Mute(false))
        } else {
            Entry::Action("Mute", RoomAction::Mute(true))
        },
        Entry::Archive,
        Entry::Leave("Leave room", "Leave"),
    ]
}

/// The entry's icon, in the sheet and the menu.
fn icon(entry: &Entry) -> bytes::Bytes {
    use freya_icons::lucide;
    match entry {
        Entry::Action(_, RoomAction::MarkRead) => lucide::mail_open(),
        Entry::Action(_, RoomAction::MarkUnread) => lucide::mail(),
        Entry::Action(_, RoomAction::Favourite(true)) => lucide::star(),
        Entry::Action(_, RoomAction::Favourite(false)) => lucide::star_off(),
        Entry::Action(_, RoomAction::LowPriority(true)) => lucide::arrow_down_to_line(),
        Entry::Action(_, RoomAction::LowPriority(false)) => lucide::arrow_up_from_line(),
        Entry::Action(_, RoomAction::Mute(true)) => lucide::bell_off(),
        Entry::Action(_, RoomAction::Mute(false)) => lucide::bell(),
        Entry::Action(_, RoomAction::Leave) => lucide::log_out(),
        Entry::Archive => lucide::archive(),
        Entry::Leave("Decline invite", _) => lucide::circle_x(),
        Entry::Leave(..) => lucide::log_out(),
    }
}

/// Icon and label of a sheet row or menu item.
fn entry_row(entry: &Entry, text: &'static str, color: (u8, u8, u8), size: f32) -> Rect {
    rect()
        .horizontal()
        .spacing(16.)
        .cross_align(Alignment::Center)
        .child(
            SvgViewer::new(icon(entry))
                .width(Size::px(size))
                .height(Size::px(size))
                .color(color),
        )
        .child(label().text(text).font_size(15.).color(color))
}

fn archive(room_id: String) {
    tokio::spawn(async move {
        crate::utils::room_mailbox::archive_room(&room_id).await;
    });
}

/// Leaves the room, closing it if it's open.
fn leave(room_id: String) {
    run(room_id.clone(), RoomAction::Leave);
    let active = crate::ACTIVE_ROOM_RX
        .get()
        .expect("not initialized")
        .borrow()
        .clone();
    if active.as_deref() == Some(room_id.as_str()) {
        crate::app::navigation::close_room();
    }
}

/// Right-click (desktop) menu, or long-press (Android) bottom sheet, for a room row.
pub(super) fn open_room_menu(s: &RoomSummary, from_pointer_down: bool, ctx: Option<RoomListCtx>) {
    if cfg!(target_os = "android") {
        if let Some(mut ctx) = ctx {
            ctx.sheet.set(Some(RoomSheet {
                summary: s.clone(),
                confirm_leave: false,
            }));
        }
        return;
    }
    let menu = room_menu(s);
    if from_pointer_down {
        ContextMenu::open_from_down(menu);
    } else {
        ContextMenu::open(menu);
    }
}

fn room_menu(s: &RoomSummary) -> Menu {
    // Not a hook: the menu is built from an event handler.
    let color =
        crate::utils::const_values::AppColors::from_colors(&get_theme_or_default().read().colors)
            .on_surface_variant;
    entries(s).into_iter().fold(Menu::new(), |menu, entry| {
        let room_id = s.room_id.clone();
        match entry {
            Entry::Action(text, action) => menu.child(
                MenuButton::new()
                    .on_press(move |_| {
                        run(room_id.clone(), action);
                        ContextMenu::close();
                    })
                    .child(entry_row(&Entry::Action(text, action), text, color, 16.)),
            ),
            Entry::Archive => menu.child(
                MenuButton::new()
                    .on_press(move |_| {
                        archive(room_id.clone());
                        ContextMenu::close();
                    })
                    .child(entry_row(&Entry::Archive, "Archive", color, 16.)),
            ),
            Entry::Leave(text, confirm) => menu.child(
                SubMenu::new().label(text).child(
                    MenuButton::new()
                        .on_press(move |_| {
                            leave(room_id.clone());
                            ContextMenu::close();
                        })
                        .child(confirm),
                ),
            ),
        }
    })
}

/// The open room sheet, if any.
pub(super) fn room_sheet(mut sheet: State<Option<RoomSheet>>, c: AppColors) -> Option<Element> {
    let open = sheet.read().clone()?;
    let room_id = open.summary.room_id.clone();

    if open.confirm_leave {
        let confirm = match entries(&open.summary).pop() {
            Some(Entry::Leave(_, confirm)) => confirm,
            _ => "Leave",
        };
        return Some(
            confirm_dialog(
                open.summary.name.clone(),
                if open.summary.is_invite {
                    "Decline this invite?"
                } else {
                    "Leave this room?"
                },
                confirm,
                move || sheet.set(None),
                move || {
                    sheet.set(None);
                    leave(room_id.clone());
                },
            )
            .into_element(),
        );
    }

    let rows = entries(&open.summary).into_iter().map(|entry| {
        let room_id = room_id.clone();
        let summary = open.summary.clone();
        let (text, color) = match &entry {
            Entry::Action(text, _) => (*text, c.on_surface),
            Entry::Archive => ("Archive", c.on_surface),
            Entry::Leave(text, _) => (*text, c.error),
        };
        let row = entry_row(&entry, text, color, 22.);
        rect()
            .width(Size::fill())
            .padding(Gaps::new(14., 24., 14., 24.))
            .on_press(move |_| match &entry {
                Entry::Action(_, action) => {
                    sheet.set(None);
                    run(room_id.clone(), *action);
                }
                Entry::Archive => {
                    sheet.set(None);
                    archive(room_id.clone());
                }
                Entry::Leave(..) => sheet.set(Some(RoomSheet {
                    summary: summary.clone(),
                    confirm_leave: true,
                })),
            })
            .child(row)
            .hoverable(Size::fill(), Size::auto(), 0.)
            .into_element()
    });

    Some(
        bottom_sheet(c, move || sheet.set(None))
            .title(open.summary.name.clone())
            .children(rows)
            .into_element(),
    )
}
