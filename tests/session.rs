/// Session expiry detection against a mocked homeserver.
///
/// Run with: `cargo test --test session`
use matrix_sdk::config::SyncSettings;
use matrix_sdk::test_utils::logged_in_client_with_server;
use piaf::utils::matrix::is_unknown_token;
use serde_json::json;
use wiremock::{
    Mock, ResponseTemplate,
    matchers::{method, path},
};

async fn sync_error(status: u16, body: serde_json::Value) -> matrix_sdk::Error {
    let (client, server) = logged_in_client_with_server().await;
    Mock::given(method("GET"))
        .and(path("/_matrix/client/r0/sync"))
        .respond_with(ResponseTemplate::new(status).set_body_json(body))
        .mount(&server)
        .await;
    client
        .sync_once(SyncSettings::default())
        .await
        .expect_err("sync should fail")
}

#[tokio::test]
async fn revoked_token_is_detected() {
    let err = sync_error(
        401,
        json!({ "errcode": "M_UNKNOWN_TOKEN", "error": "Invalid access token passed.", "soft_logout": false }),
    )
    .await;
    assert!(is_unknown_token(&err), "{err:?}");
}

#[tokio::test]
async fn other_errors_are_not_expiry() {
    let err = sync_error(403, json!({ "errcode": "M_FORBIDDEN", "error": "nope" })).await;
    assert!(!is_unknown_token(&err), "{err:?}");
}
