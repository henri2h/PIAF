use freya::prelude::*;

use crate::utils::avatars::AvatarSource;

use crate::ui::components::HoverableExt;
use freya_query::prelude::*;

use crate::ui::pages::home::room_list_item::{RoomListItem, RoomSummary};
use crate::utils::matrix::CLIENT;
use crate::utils::queries::FetchMutualRooms;

use super::{Avatar, bottom_sheet};
use crate::utils::use_app_colors;

/// Rooms in common scroll past this height.
const COMMON_ROOMS_MAX_H: f32 = 280.;

#[derive(Clone, PartialEq)]
pub struct UserPopupInfo {
    pub user_id: String,
    pub display_name: String,
    pub avatar: Option<AvatarSource>,
}

#[derive(PartialEq)]
pub struct UserPopupOverlay {
    pub open: State<Option<UserPopupInfo>>,
}

impl Component for UserPopupOverlay {
    fn render(&self) -> impl IntoElement {
        let c = use_app_colors();
        let mut open = self.open;
        let info_opt = self.open.read().clone();

        // Hooks must always be called; use empty key when no user is selected.
        let user_id_key = info_opt
            .as_ref()
            .map(|i| i.user_id.clone())
            .unwrap_or_default();
        let mutual_query = use_query(Query::new(user_id_key, FetchMutualRooms));
        let mutual_state = mutual_query.read();
        let is_loading = mutual_state.state().is_pending() || mutual_state.state().is_loading();
        let common_room_ids = mutual_state.state().ok().cloned().unwrap_or_default();
        drop(mutual_state);

        let Some(info) = info_opt else {
            return rect().into_element();
        };
        let common_rooms: Vec<_> = common_room_ids
            .iter()
            .filter_map(|id| crate::utils::matrix::get_room(id))
            .collect();
        let has_dm = CLIENT
            .get()
            .and_then(|client| {
                matrix_sdk::ruma::UserId::parse(&info.user_id)
                    .ok()
                    .and_then(|uid| client.get_dm_room(&uid))
            })
            .is_some();
        let common_count = common_rooms.len();
        let user = crate::utils::users::UserInfo {
            user_id: info.user_id.clone(),
            display_name: info.display_name.clone(),
            avatar: info.avatar.clone(),
        };

        let header = rect()
            .horizontal()
            .width(Size::fill())
            .content(Content::Flex)
            .spacing(16.)
            .cross_align(Alignment::Center)
            .child(Avatar {
                size: 56.,
                source: info.avatar.clone(),
                name: info.display_name.clone(),
                color: crate::utils::id_color(&info.user_id),
            })
            .child(
                rect()
                    .vertical()
                    .width(Size::flex(1.))
                    .spacing(2.)
                    .child(
                        label()
                            .width(Size::fill())
                            .text(info.display_name.clone())
                            .max_lines(1)
                            .text_overflow(TextOverflow::Ellipsis)
                            .font_size(18.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.on_surface),
                    )
                    .child(
                        label()
                            .width(Size::fill())
                            .text(info.user_id.clone())
                            .max_lines(1)
                            .text_overflow(TextOverflow::Ellipsis)
                            .font_size(13.)
                            .color(c.on_surface_variant),
                    ),
            );
        let dm_button = rect()
            .width(Size::fill())
            .padding(Gaps::new(14., 0., 14., 0.))
            .corner_radius(24.)
            .background(c.primary)
            .overflow(Overflow::Clip)
            .center()
            .on_press(move |_| {
                open.set(None);
                crate::app::navigation::open_dm(user.clone());
            })
            .child(
                label()
                    .text(if has_dm { "Open DM" } else { "Send message" })
                    .font_size(16.)
                    .font_weight(FontWeight::MEDIUM)
                    .color(c.on_primary),
            )
            .hoverable(Size::fill(), Size::auto(), 24.);
        let common = (!is_loading && common_count > 0).then(|| {
            rect()
                .vertical()
                .width(Size::fill())
                .spacing(2.)
                .child(
                    rect().padding(Gaps::new(0., 16., 0., 16.)).child(
                        label()
                            .text(format!(
                                "{common_count} room{} in common",
                                if common_count == 1 { "" } else { "s" }
                            ))
                            .font_size(12.)
                            .font_weight(FontWeight::MEDIUM)
                            .color(c.primary),
                    ),
                )
                .child(
                    ScrollView::new()
                        .width(Size::fill())
                        .height(Size::auto())
                        .max_height(Size::px(COMMON_ROOMS_MAX_H))
                        .children(common_rooms.into_iter().map(|room| {
                            RoomListItem {
                                summary: RoomSummary::new(room),
                            }
                            .into_element()
                        })),
                )
        });
        let body = rect()
            .vertical()
            .width(Size::fill())
            .spacing(16.)
            .child(
                rect()
                    .vertical()
                    .width(Size::fill())
                    .padding(Gaps::new(0., 16., 0., 16.))
                    .spacing(16.)
                    .child(header)
                    .child(dm_button),
            )
            .maybe_child(common);

        // Android: a bottom sheet, the mobile way; a popup elsewhere.
        if cfg!(target_os = "android") {
            bottom_sheet(c, move || open.set(None))
                .child(rect().padding(Gaps::new(0., 8., 8., 8.)).child(body))
                .into_element()
        } else {
            Popup::new()
                .on_close_request(move |_| open.set(None))
                .child(body)
                .into_element()
        }
    }
}
