/// Integration tests for PIAF's search functions.
///
/// These tests use `matrix_sdk::test_utils` to spin up a wiremock HTTP server
/// that intercepts Matrix REST calls. No real homeserver is needed.
///
/// Run with: `cargo test --test search`
use matrix_sdk::config::SyncSettings;
use matrix_sdk::test_utils::logged_in_client_with_server;
use piaf::ui::pages::home::search::{
    search_messages_remote, search_rooms_local, search_users_remote,
};
use serde_json::json;
use wiremock::{
    Mock, ResponseTemplate,
    matchers::{method, path},
};

// ---------------------------------------------------------------------------
// search_users_remote
// ---------------------------------------------------------------------------

#[tokio::test]
async fn search_users_remote_parses_results() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/user_directory/search"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "results": [
                {
                    "user_id": "@alice:example.org",
                    "display_name": "Alice Smith",
                    "avatar_url": null
                },
                {
                    "user_id": "@bob:example.org",
                    "display_name": "Bob Jones",
                    "avatar_url": "mxc://example.org/abc123"
                }
            ],
            "limited": false
        })))
        .mount(&server)
        .await;

    let results = search_users_remote(client, "ali".to_owned()).await;

    assert_eq!(results.len(), 2);
    assert_eq!(results[0].user_id, "@alice:example.org");
    assert_eq!(results[0].display_name, "Alice Smith");
    assert!(results[0].avatar_mxc.is_none());
    assert_eq!(results[1].user_id, "@bob:example.org");
    assert_eq!(results[1].avatar_mxc.as_deref(), Some("mxc://example.org/abc123"));
}

#[tokio::test]
async fn search_users_remote_falls_back_to_localpart_when_no_display_name() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/user_directory/search"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "results": [
                { "user_id": "@carol:example.org" }
            ],
            "limited": false
        })))
        .mount(&server)
        .await;

    let results = search_users_remote(client, "carol".to_owned()).await;

    assert_eq!(results.len(), 1);
    assert_eq!(results[0].display_name, "carol"); // localpart fallback
}

#[tokio::test]
async fn search_users_remote_returns_empty_on_server_error() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/user_directory/search"))
        .respond_with(ResponseTemplate::new(500))
        .mount(&server)
        .await;

    let results = search_users_remote(client, "query".to_owned()).await;
    assert!(results.is_empty());
}

// ---------------------------------------------------------------------------
// search_messages_remote
// ---------------------------------------------------------------------------

#[tokio::test]
async fn search_messages_remote_parses_text_result() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/search"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "search_categories": {
                "room_events": {
                    "count": 1,
                    "next_batch": null,
                    "results": [{
                        "rank": 1.0,
                        "result": {
                            "type": "m.room.message",
                            "content": { "msgtype": "m.text", "body": "hello world" },
                            "event_id": "$ev1:example.org",
                            "room_id": "!room1:example.org",
                            "sender": "@alice:example.org",
                            "origin_server_ts": 1609459200000_u64,
                            "unsigned": {}
                        },
                        "context": {
                            "profile_info": {
                                "@alice:example.org": {
                                    "displayname": "Alice Smith",
                                    "avatar_url": null
                                }
                            },
                            "events_before": [],
                            "events_after": []
                        }
                    }]
                }
            }
        })))
        .mount(&server)
        .await;

    let (results, next_batch) = search_messages_remote(client, "hello".to_owned(), None).await;

    assert!(next_batch.is_none());
    assert_eq!(results.len(), 1);
    let r = &results[0];
    assert_eq!(r.event_id, "$ev1:example.org");
    assert_eq!(r.room_id, "!room1:example.org");
    assert_eq!(r.body, "hello world");
    assert_eq!(r.sender_display_name, "Alice Smith");
    assert_eq!(r.event_ts_ms, 1609459200000);
}

#[tokio::test]
async fn search_messages_remote_returns_next_batch_token() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/search"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "search_categories": {
                "room_events": {
                    "count": 100,
                    "next_batch": "page2_token",
                    "results": [{
                        "rank": 1.0,
                        "result": {
                            "type": "m.room.message",
                            "content": { "msgtype": "m.text", "body": "first page result" },
                            "event_id": "$ev2:example.org",
                            "room_id": "!room1:example.org",
                            "sender": "@alice:example.org",
                            "origin_server_ts": 1609459200000_u64,
                            "unsigned": {}
                        },
                        "context": {
                            "profile_info": {},
                            "events_before": [],
                            "events_after": []
                        }
                    }]
                }
            }
        })))
        .mount(&server)
        .await;

    let (results, next_batch) = search_messages_remote(client, "result".to_owned(), None).await;

    assert_eq!(next_batch.as_deref(), Some("page2_token"));
    assert_eq!(results.len(), 1);
}

#[tokio::test]
async fn search_messages_remote_skips_non_text_events() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/search"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "search_categories": {
                "room_events": {
                    "count": 2,
                    "next_batch": null,
                    "results": [
                        {
                            "rank": 2.0,
                            "result": {
                                "type": "m.room.message",
                                "content": { "msgtype": "m.text", "body": "text message" },
                                "event_id": "$text:example.org",
                                "room_id": "!room1:example.org",
                                "sender": "@alice:example.org",
                                "origin_server_ts": 1609459200000_u64,
                                "unsigned": {}
                            },
                            "context": { "profile_info": {}, "events_before": [], "events_after": [] }
                        },
                        {
                            "rank": 1.0,
                            "result": {
                                "type": "m.room.message",
                                "content": {
                                    "msgtype": "m.image",
                                    "body": "photo.jpg",
                                    "url": "mxc://example.org/img1"
                                },
                                "event_id": "$img:example.org",
                                "room_id": "!room1:example.org",
                                "sender": "@bob:example.org",
                                "origin_server_ts": 1609459201000_u64,
                                "unsigned": {}
                            },
                            "context": { "profile_info": {}, "events_before": [], "events_after": [] }
                        }
                    ]
                }
            }
        })))
        .mount(&server)
        .await;

    let (results, _) = search_messages_remote(client, "photo".to_owned(), None).await;

    // Only the text message should be returned; the image is skipped.
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].event_id, "$text:example.org");
}

#[tokio::test]
async fn search_messages_remote_returns_empty_on_server_error() {
    let (client, server) = logged_in_client_with_server().await;

    Mock::given(method("POST"))
        .and(path("/_matrix/client/r0/search"))
        .respond_with(ResponseTemplate::new(500))
        .mount(&server)
        .await;

    let (results, next_batch) = search_messages_remote(client, "query".to_owned(), None).await;
    assert!(results.is_empty());
    assert!(next_batch.is_none());
}

// ---------------------------------------------------------------------------
// search_rooms_local
// ---------------------------------------------------------------------------

fn minimal_sync_response(rooms: &[(&str, &str)]) -> serde_json::Value {
    let mut join = serde_json::Map::new();
    for (room_id, name) in rooms {
        join.insert(
            room_id.to_string(),
            json!({
                "state": {
                    "events": [
                        {
                            "type": "m.room.create",
                            "content": { "creator": "@user:example.org", "room_version": "10" },
                            "event_id": format!("$create_{room_id}"),
                            "sender": "@user:example.org",
                            "origin_server_ts": 1000_u64,
                            "state_key": ""
                        },
                        {
                            "type": "m.room.name",
                            "content": { "name": name },
                            "event_id": format!("$name_{room_id}"),
                            "sender": "@user:example.org",
                            "origin_server_ts": 1001_u64,
                            "state_key": ""
                        },
                        {
                            "type": "m.room.member",
                            "content": { "membership": "join", "displayname": "Test User" },
                            "event_id": format!("$member_{room_id}"),
                            "sender": "@user:example.org",
                            "origin_server_ts": 1002_u64,
                            "state_key": "@user:example.org"
                        }
                    ]
                },
                "timeline": { "events": [], "limited": false, "prev_batch": null },
                "ephemeral": { "events": [] },
                "account_data": { "events": [] },
                "unread_notifications": {}
            }),
        );
    }
    json!({
        "next_batch": "s1",
        "rooms": { "join": join },
        "account_data": { "events": [] },
        "presence": { "events": [] },
        "to_device": { "events": [] }
    })
}

#[tokio::test]
async fn search_rooms_local_filters_by_name() {
    let (client, server) = logged_in_client_with_server().await;

    let sync_body = minimal_sync_response(&[
        ("!alice:example.org", "Alice Room"),
        ("!bob:example.org", "Bob Room"),
        ("!alice2:example.org", "Alice's Second Place"),
    ]);

    Mock::given(method("GET"))
        .and(path("/_matrix/client/r0/sync"))
        .respond_with(ResponseTemplate::new(200).set_body_json(sync_body))
        .mount(&server)
        .await;

    client.sync_once(SyncSettings::default()).await.expect("sync failed");

    let results = search_rooms_local(&client, "alice");

    assert_eq!(results.len(), 2);
    let names: Vec<&str> = results.iter().map(|r| r.display_name.as_str()).collect();
    assert!(names.contains(&"Alice Room"), "expected Alice Room in {names:?}");
    assert!(names.contains(&"Alice's Second Place"), "expected Alice's Second Place in {names:?}");
    assert!(!names.contains(&"Bob Room"), "Bob Room should not appear for 'alice' query");
}

#[tokio::test]
async fn search_rooms_local_returns_empty_for_no_match() {
    let (client, server) = logged_in_client_with_server().await;

    let sync_body = minimal_sync_response(&[("!alice:example.org", "Alice Room")]);

    Mock::given(method("GET"))
        .and(path("/_matrix/client/r0/sync"))
        .respond_with(ResponseTemplate::new(200).set_body_json(sync_body))
        .mount(&server)
        .await;

    client.sync_once(SyncSettings::default()).await.expect("sync failed");

    let results = search_rooms_local(&client, "xyz_no_match");
    assert!(results.is_empty());
}
