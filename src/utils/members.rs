//! Room members as shown in member lists.

use matrix_sdk::Room;
use matrix_sdk::RoomMemberships;
use matrix_sdk::ruma::events::room::power_levels::UserPowerLevel;

use crate::utils::avatars::AvatarSource;

/// Power level from which a member is shown (and acts) as an admin.
pub const ADMIN_LEVEL: i64 = 50;

#[derive(Clone, Debug, PartialEq)]
pub struct MemberItem {
    pub user_id: String,
    pub display_name: String,
    pub power_level: i64,
}

impl MemberItem {
    pub fn is_admin(&self) -> bool {
        self.power_level >= ADMIN_LEVEL
    }

    pub fn avatar(&self, room_id: &str) -> AvatarSource {
        AvatarSource::member(room_id, &self.user_id)
    }

    /// Matches a search query (name or user ID, case-insensitive).
    pub fn matches(&self, query: &str) -> bool {
        let query = query.to_lowercase();
        self.display_name.to_lowercase().contains(&query)
            || self.user_id.to_lowercase().contains(&query)
    }
}

/// Joined members, admins first, then by name. Loads the member list from the
/// server if needed: run on tokio.
pub async fn joined(room: &Room) -> Vec<MemberItem> {
    let mut members: Vec<MemberItem> = room
        .members(RoomMemberships::JOIN)
        .await
        .unwrap_or_default()
        .into_iter()
        .map(|m| MemberItem {
            user_id: m.user_id().to_string(),
            display_name: m
                .display_name()
                .map(|s| s.to_string())
                .unwrap_or_else(|| m.user_id().to_string()),
            power_level: match m.power_level() {
                UserPowerLevel::Int(level) => i64::from(level),
                _ => i64::MAX,
            },
        })
        .collect();
    members.sort_by(|a, b| {
        b.power_level
            .cmp(&a.power_level)
            .then(a.display_name.cmp(&b.display_name))
    });
    members
}
