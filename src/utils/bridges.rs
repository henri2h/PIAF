//! Bridged rooms (WhatsApp, Telegram, Signal…): the network, the bridge bot
//! and the remote chat, from the `m.bridge` state event (MSC2346, also sent as
//! `uk.half-shot.bridge`), else from a known bridge bot among the members.

use matrix_sdk::Room;
use matrix_sdk::ruma::events::StateEventType;
use matrix_sdk::ruma::exports::serde_json::Value;

#[derive(Clone, Debug, PartialEq)]
pub struct BridgeInfo {
    /// The remote network, e.g. "WhatsApp".
    pub network: String,
    /// The bridge bot's user ID.
    pub bot: Option<String>,
    /// The remote chat's name, when the bridge says.
    pub channel: Option<String>,
}

const STATE_TYPES: [&str; 2] = ["m.bridge", "uk.half-shot.bridge"];

/// Bridge bots by localpart (mautrix and others): the network they bridge.
const BOTS: [(&str, &str); 14] = [
    ("whatsappbot", "WhatsApp"),
    ("telegrambot", "Telegram"),
    ("signalbot", "Signal"),
    ("discordbot", "Discord"),
    ("slackbot", "Slack"),
    ("metabot", "Messenger"),
    ("facebookbot", "Messenger"),
    ("instagrambot", "Instagram"),
    ("twitterbot", "X"),
    ("gmessagesbot", "Google Messages"),
    ("googlechatbot", "Google Chat"),
    ("linkedinbot", "LinkedIn"),
    ("bluesky", "Bluesky"),
    ("imessagebot", "iMessage"),
];

/// The bridge of `room`, if it is bridged.
pub async fn bridge_info(room: &Room) -> Option<BridgeInfo> {
    for event_type in STATE_TYPES {
        let Ok(events) = room
            .get_state_events(StateEventType::from(event_type))
            .await
        else {
            continue;
        };
        for raw in events {
            use matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState as Raw;
            let parsed = match &raw {
                Raw::Sync(e) => e.deserialize_as::<Value>(),
                Raw::Stripped(e) => e.deserialize_as::<Value>(),
            };
            let Ok(json) = parsed else {
                continue;
            };
            if let Some(info) = parse_state(&json) {
                return Some(info);
            }
        }
    }
    let members = room
        .members_no_sync(matrix_sdk::RoomMemberships::JOIN)
        .await
        .ok()?;
    members
        .iter()
        .find_map(|m| bot_network(m.user_id().as_str()).map(|n| (m.user_id().to_string(), n)))
        .map(|(bot, network)| BridgeInfo {
            network: network.to_string(),
            bot: Some(bot),
            channel: None,
        })
}

/// A bridge state event (its whole JSON).
pub fn parse_state(event: &Value) -> Option<BridgeInfo> {
    let content = event.get("content")?;
    let protocol = content.get("protocol")?;
    let network = protocol
        .get("displayname")
        .or_else(|| protocol.get("id"))
        .and_then(Value::as_str)?
        .to_string();
    Some(BridgeInfo {
        network,
        bot: content
            .get("bridgebot")
            .and_then(Value::as_str)
            .map(str::to_string),
        channel: content
            .get("channel")
            .and_then(|c| c.get("displayname"))
            .and_then(Value::as_str)
            .map(str::to_string),
    })
}

/// The network a known bridge bot (`@whatsappbot:server`) bridges.
pub fn bot_network(user_id: &str) -> Option<&'static str> {
    let localpart = user_id.strip_prefix('@')?.split(':').next()?;
    BOTS.iter()
        .find(|(bot, _)| localpart.eq_ignore_ascii_case(bot))
        .map(|(_, network)| *network)
}

/// Whether `user_id` is the bridge's bot.
pub fn is_bot(info: &BridgeInfo, user_id: &str) -> bool {
    info.bot.as_deref() == Some(user_id) || bot_network(user_id).is_some()
}

#[cfg(test)]
mod tests {
    use matrix_sdk::ruma::exports::serde_json::json;

    use super::*;

    #[test]
    fn parses_the_bridge_state_event() {
        let event = json!({
            "type": "m.bridge",
            "content": {
                "bridgebot": "@whatsappbot:example.org",
                "protocol": { "id": "whatsapp", "displayname": "WhatsApp" },
                "channel": { "id": "123", "displayname": "Family" }
            }
        });
        assert_eq!(
            parse_state(&event),
            Some(BridgeInfo {
                network: "WhatsApp".into(),
                bot: Some("@whatsappbot:example.org".into()),
                channel: Some("Family".into()),
            })
        );
    }

    #[test]
    fn protocol_id_when_no_display_name() {
        let event = json!({ "content": { "protocol": { "id": "telegram" } } });
        assert_eq!(parse_state(&event).unwrap().network, "telegram");
        assert_eq!(parse_state(&json!({ "content": {} })), None);
    }

    #[test]
    fn known_bridge_bots() {
        assert_eq!(bot_network("@whatsappbot:beeper.local"), Some("WhatsApp"));
        assert_eq!(bot_network("@SignalBot:x"), Some("Signal"));
        assert_eq!(
            bot_network("@whatsapp_3361234:x"),
            None,
            "a puppet, not the bot"
        );
        assert_eq!(bot_network("@alice:x"), None);
    }
}
