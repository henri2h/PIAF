//! One-line text previews of Matrix events (room list, notifications, reactions feed).

use matrix_sdk::Room;
use matrix_sdk::latest_events::LatestEventValue;
use matrix_sdk::ruma::events::{
    AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent, room::message::MessageType,
};
use matrix_sdk::ruma::exports::serde_json;
use matrix_sdk::ruma::serde::Raw;

/// Preview text for a message, or `None` for types we don't render.
pub fn message_body(msgtype: &MessageType) -> Option<String> {
    Some(match msgtype {
        MessageType::Text(t) => t.body.clone(),
        MessageType::Notice(n) => n.body.clone(),
        MessageType::Emote(e) => format!("* {}", e.body),
        MessageType::Image(_) => "📷 Image".to_string(),
        MessageType::File(_) => "📎 File".to_string(),
        MessageType::Audio(_) => "🎵 Audio".to_string(),
        MessageType::Video(_) => "🎬 Video".to_string(),
        MessageType::Location(_) => "📍 Location".to_string(),
        MessageType::VerificationRequest(_) => "🔐 Verification request".to_string(),
        _ => return None,
    })
}

/// `(body, sender_id)` of a timeline event, or `None` if it shouldn't be shown.
pub fn event_preview(raw: &Raw<AnySyncTimelineEvent>) -> Option<(String, String)> {
    use AnySyncMessageLikeEvent::{RoomEncrypted, RoomMessage};
    use SyncMessageLikeEvent::{Original, Redacted};

    const DELETED: &str = "🗑 Message deleted";
    match raw.deserialize() {
        Ok(AnySyncTimelineEvent::MessageLike(ev)) => match ev {
            RoomMessage(Original(msg)) => {
                Some((message_body(&msg.content.msgtype)?, msg.sender.to_string()))
            }
            RoomMessage(Redacted(r)) => Some((DELETED.into(), r.sender.to_string())),
            RoomEncrypted(Original(r)) => {
                Some(("🔐 Encrypted message".into(), r.sender.to_string()))
            }
            RoomEncrypted(Redacted(r)) => Some((DELETED.into(), r.sender.to_string())),
            _ => fallback_preview(raw),
        },
        _ => fallback_preview(raw),
    }
}

/// Labels event types ruma can't (or we don't) deserialize, from raw JSON.
fn fallback_preview(raw: &Raw<AnySyncTimelineEvent>) -> Option<(String, String)> {
    let val = raw.deserialize_as::<serde_json::Value>().ok()?;
    let sender = val.get("sender")?.as_str().filter(|s| !s.is_empty())?;
    let body = match val.get("type")?.as_str()? {
        "m.sticker" => "🎉 Sticker",
        "m.call.invite" | "m.call.answer" | "m.call.hangup" => "📞 Call",
        "m.room.member" => "Activity",
        "m.poll.start" | "org.matrix.msc3381.poll.start" => "📊 Poll",
        "m.location" | "org.matrix.msc3488.location" => "📍 Location",
        "m.room.tombstone" => "🚪 Room upgraded",
        "m.room.name"
        | "m.room.topic"
        | "m.room.avatar"
        | "m.room.canonical_alias"
        | "m.room.power_levels"
        | "m.room.join_rules"
        | "m.room.guest_access"
        | "m.room.history_visibility"
        | "m.room.server_acl"
        | "m.room.create" => "Room settings updated",
        _ => return None,
    };
    Some((body.to_string(), sender.to_string()))
}

#[derive(Debug, Clone, PartialEq)]
pub enum SenderPrefix {
    None,
    Me,
    Other(String),
}

/// Preview of a room's latest event and who to attribute it to.
pub fn last_message(room: &Room, my_user_id: Option<&str>) -> Option<(String, SenderPrefix)> {
    let latest = match room.latest_event() {
        LatestEventValue::RemoteInvite { inviter, .. } => {
            let body = match inviter {
                Some(id) => format!("You were invited by {}", id.localpart()),
                None => "You were invited".to_string(),
            };
            return Some((body, SenderPrefix::None));
        }
        LatestEventValue::Remote(latest) => latest,
        _ => return None,
    };
    let (body, sender) = event_preview(latest.raw())?;
    let prefix = if my_user_id == Some(sender.as_str()) {
        SenderPrefix::Me
    } else if room.is_dm() {
        SenderPrefix::None
    } else {
        SenderPrefix::Other(sender)
    };
    Some((body, prefix))
}

/// Final preview line; `sender_name` is the resolved display name for `Other`.
pub fn preview_text(body: &str, prefix: &SenderPrefix, sender_name: Option<&str>) -> String {
    match prefix {
        SenderPrefix::None => body.to_string(),
        SenderPrefix::Me => format!("You: {body}"),
        SenderPrefix::Other(uid) => {
            format!("{}: {body}", sender_name.unwrap_or_else(|| localpart(uid)))
        }
    }
}

/// `@alice:example.org` -> `alice`.
pub fn localpart(user_id: &str) -> &str {
    let s = user_id.trim_start_matches('@');
    s.split(':').next().unwrap_or(s)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn raw(v: serde_json::Value) -> Raw<AnySyncTimelineEvent> {
        Raw::from_json_string(v.to_string()).unwrap()
    }

    fn event(ty: &str, content: serde_json::Value) -> Raw<AnySyncTimelineEvent> {
        raw(json!({
            "type": ty,
            "event_id": "$ev",
            "sender": "@bob:example.org",
            "origin_server_ts": 1,
            "content": content,
        }))
    }

    fn msg(content: serde_json::Value) -> Option<(String, String)> {
        event_preview(&event("m.room.message", content))
    }

    #[test]
    fn text_message() {
        let got = msg(json!({ "msgtype": "m.text", "body": "hi" }));
        assert_eq!(got, Some(("hi".into(), "@bob:example.org".into())));
    }

    #[test]
    fn emote_and_media_labels() {
        let emote = msg(json!({ "msgtype": "m.emote", "body": "waves" }));
        assert_eq!(emote.unwrap().0, "* waves");
        let image = msg(json!({ "msgtype": "m.image", "body": "a.png", "url": "mxc://x/y" }));
        assert_eq!(image.unwrap().0, "📷 Image");
    }

    #[test]
    fn unknown_msgtype_hidden() {
        assert_eq!(
            msg(json!({ "msgtype": "org.example.custom", "body": "x" })),
            None
        );
    }

    #[test]
    fn encrypted_message() {
        let got = event_preview(&event(
            "m.room.encrypted",
            json!({
                "algorithm": "m.megolm.v1.aes-sha2",
                "ciphertext": "c",
                "device_id": "D",
                "sender_key": "k",
                "session_id": "s",
            }),
        ));
        assert_eq!(got.unwrap().0, "🔐 Encrypted message");
    }

    #[test]
    fn fallback_types() {
        let sticker = event_preview(&event("m.sticker", json!({})));
        assert_eq!(sticker.unwrap().0, "🎉 Sticker");
        let rename = event_preview(&raw(json!({
            "type": "m.room.name",
            "state_key": "",
            "event_id": "$ev",
            "sender": "@bob:example.org",
            "origin_server_ts": 1,
            "content": { "name": "New" },
        })));
        assert_eq!(rename.unwrap().0, "Room settings updated");
    }

    #[test]
    fn reactions_and_unknown_hidden() {
        let reaction = event(
            "m.reaction",
            json!({ "m.relates_to": { "rel_type": "m.annotation", "event_id": "$x", "key": "👍" } }),
        );
        assert_eq!(event_preview(&reaction), None);
        assert_eq!(event_preview(&event("org.example.thing", json!({}))), None);
    }

    #[test]
    fn preview_text_prefixes() {
        assert_eq!(preview_text("hi", &SenderPrefix::None, None), "hi");
        assert_eq!(preview_text("hi", &SenderPrefix::Me, None), "You: hi");
        let other = SenderPrefix::Other("@bob:example.org".into());
        assert_eq!(preview_text("hi", &other, None), "bob: hi");
        assert_eq!(preview_text("hi", &other, Some("Bob")), "Bob: hi");
    }

    #[test]
    fn localpart_strips_sigil_and_server() {
        assert_eq!(localpart("@alice:example.org"), "alice");
        assert_eq!(localpart("alice"), "alice");
    }
}
