use freya::prelude::*;
use freya_router::prelude::Routable;

use super::layout::Layout;
use crate::ui::pages::{
    archived::ArchivedPage,
    bookmarks::BookmarksPage,
    home::HomePage,
    login::LoginPage,
    new_chat::{NewChat, NewGroup, NewGroupConfig, PendingDm, PendingGroup},
    reactions::ReactionsPage,
    recontact::RecontactPage,
    room::RoomPage,
    room_media::RoomMediaPage,
    room_members::RoomMembers,
    room_search::RoomSearch,
    room_settings::RoomSettings,
    settings::{
        Settings, SettingsAppearance, SettingsNotifications, SettingsProfile, SettingsSecurity,
    },
    welcome::WelcomePage,
};

#[derive(Routable, Clone, PartialEq)]
#[rustfmt::skip]
pub enum Route {
    #[layout(Layout)]
        #[route("/")]
        HomePage,
        #[route("/welcome")]
        WelcomePage,
        #[route("/login")]
        LoginPage,
        #[route("/settings")]
        Settings,
        #[route("/settings/profile")]
        SettingsProfile,
        #[route("/settings/security")]
        SettingsSecurity,
        #[route("/settings/notifications")]
        SettingsNotifications,
        #[route("/settings/appearance")]
        SettingsAppearance,
        #[route("/new-chat")]
        NewChat,
        #[route("/new-group")]
        NewGroup,
        #[route("/new-group/config")]
        NewGroupConfig,
        #[route("/pending-dm/:user_id")]
        PendingDm { user_id: String },
        #[route("/pending-group")]
        PendingGroup,
        #[route("/room/:room_id")]
        RoomPage { room_id: String },
        #[route("/room/:room_id/search")]
        RoomSearch { room_id: String },
        #[route("/room/:room_id/settings")]
        RoomSettings { room_id: String },
        #[route("/room/:room_id/media")]
        RoomMediaPage { room_id: String },
        #[route("/room/:room_id/members")]
        RoomMembers { room_id: String },
        #[route("/reactions")]
        ReactionsPage,
        #[route("/bookmarks")]
        BookmarksPage,
        #[route("/recontact")]
        RecontactPage,
        #[route("/archived")]
        ArchivedPage,
}
