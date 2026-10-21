use freya::prelude::*;
use freya_router::prelude::Routable;

use super::layout::Layout;
use crate::ui::pages::{
    bookmarks::BookmarksPage,
    home::HomePage,
    login::LoginPage,
    mailbox::{ArchivedPage, RecontactPage},
    more::MorePage,
    new_chat::{NewChat, NewGroup, NewGroupConfig, PendingDm, PendingGroup},
    reactions::ReactionsPage,
    room::RoomPage,
    room_media::RoomMediaPage,
    room_members::RoomMembers,
    room_search::RoomSearch,
    room_settings::RoomSettings,
    search::SearchPage,
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
        /// Android "More" tab and its mailbox pages.
        #[route("/more")]
        MorePage,
        #[route("/recontact")]
        RecontactPage,
        #[route("/archived")]
        ArchivedPage,
        /// Android search mode (desktop searches inline in the home bar).
        #[route("/search")]
        SearchPage,
}
