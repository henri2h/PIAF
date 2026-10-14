//! Users: search results, DM contacts.

use matrix_sdk::Client;
use matrix_sdk::ruma::UserId;

use crate::utils::avatars::AvatarSource;

#[derive(Clone, Debug, PartialEq)]
pub struct UserInfo {
    pub user_id: String,
    pub display_name: String,
    pub avatar: Option<AvatarSource>,
}

/// User directory search (server-side); empty on error.
pub async fn search(client: &Client, query: &str, limit: u64) -> Vec<UserInfo> {
    let Ok(response) = client.search_users(query, limit).await else {
        return vec![];
    };
    response
        .results
        .into_iter()
        .map(|u| UserInfo {
            display_name: u
                .display_name
                .unwrap_or_else(|| u.user_id.localpart().to_string()),
            avatar: u.avatar_url.map(|a| AvatarSource::Mxc(a.to_string())),
            user_id: u.user_id.to_string(),
        })
        .collect()
}

/// People the user has DMs with (up to 8), from `m.direct` and the local
/// member store: suggestions before anything is typed.
pub async fn dm_contacts() -> Vec<UserInfo> {
    use matrix_sdk::ruma::events::direct::DirectEventContent;
    let Some(client) = crate::utils::matrix::CLIENT.get().cloned() else {
        return vec![];
    };
    let Ok(Some(raw)) = client.account().account_data::<DirectEventContent>().await else {
        return vec![];
    };
    let Ok(direct) = raw.deserialize() else {
        return vec![];
    };

    // Collect DM contacts: get cached member info from local store
    let mut suggestions = Vec::new();
    let my_id = client.user_id().map(|id| id.to_string());
    'outer: for (user, rooms) in direct.0 {
        let user_id_str = user.to_string();
        if my_id.as_deref() == Some(&user_id_str) {
            continue;
        }
        let Ok(uid) = UserId::parse(&user_id_str) else {
            continue;
        };
        for room_id in &rooms {
            let Some(room) = client.get_room(room_id) else {
                continue;
            };
            let Ok(Some(member)) = room.get_member_no_sync(&uid).await else {
                continue;
            };
            let display_name = member
                .display_name()
                .unwrap_or_else(|| uid.localpart())
                .to_string();
            let avatar = member
                .avatar_url()
                .map(|u| AvatarSource::Mxc(u.to_string()));
            suggestions.push(UserInfo {
                user_id: uid.to_string(),
                display_name,
                avatar,
            });
            if suggestions.len() >= 8 {
                break 'outer;
            }
            break;
        }
    }
    suggestions
}
