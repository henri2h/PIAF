//! Media files: downloading, saving, and describing them (size, duration).

use matrix_sdk::ruma::events::room::MediaSource;
use tokio::fs;

use crate::utils::queries::{FetchMediaContent, media_source_key};

/// MIME type of an image file, from its name's extension.
pub fn image_mime(file_name: &str) -> mime::Mime {
    let ext = std::path::Path::new(file_name)
        .extension()
        .and_then(|e| e.to_str())
        .map(str::to_lowercase);
    match ext.as_deref() {
        Some("png") => mime::IMAGE_PNG,
        Some("gif") => mime::IMAGE_GIF,
        Some("webp") => "image/webp"
            .parse()
            .unwrap_or(mime::APPLICATION_OCTET_STREAM),
        Some("jpg" | "jpeg") => mime::IMAGE_JPEG,
        _ => mime::APPLICATION_OCTET_STREAM,
    }
}

/// A file picked to send.
pub struct PickedFile {
    pub file_name: String,
    pub mime: mime::Mime,
    pub bytes: Vec<u8>,
}

/// Where an attachment comes from (Android's picker sheet).
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum AttachSource {
    Gallery,
    Camera,
    File,
}

/// Asks for a file to send from `source`; `None` when cancelled. Run on tokio.
pub async fn pick_attachment(source: AttachSource) -> Option<PickedFile> {
    #[cfg(target_os = "android")]
    {
        crate::android::attachments::pick(source).await
    }
    #[cfg(not(target_os = "android"))]
    {
        let _ = source;
        pick_image("Send an image").await
    }
}

/// Asks for an image file; `None` when cancelled. Run on tokio.
#[cfg(not(target_os = "android"))]
pub async fn pick_image(title: &str) -> Option<PickedFile> {
    let file = rfd::AsyncFileDialog::new()
        .add_filter("Images", &["png", "jpg", "jpeg", "gif", "webp"])
        .set_title(title)
        .pick_file()
        .await?;
    let file_name = file.file_name();
    Some(PickedFile {
        mime: image_mime(&file_name),
        bytes: file.read().await,
        file_name,
    })
}

/// Sends `bytes` to the room as a file message. Run on tokio.
pub async fn send_attachment(room_id: &str, file_name: &str, mime: &mime::Mime, bytes: Vec<u8>) {
    use matrix_sdk::attachment::AttachmentConfig;
    if let Some(room) = crate::utils::matrix::get_room(room_id) {
        let _ = room
            .send_attachment(file_name, mime, bytes, AttachmentConfig::default())
            .await;
    }
}

/// Fetches `source` (from the media cache when possible) and saves it to the
/// downloads folder. Call from the UI.
pub fn download(source: &MediaSource) {
    use freya_query::prelude::QueryCapability;
    let key = media_source_key(source);
    freya::prelude::spawn(async move {
        if let Ok(bytes) = FetchMediaContent.run(&key).await {
            tokio::spawn(async move { save_to_downloads(&bytes).await });
        }
    });
}

fn media_extension(bytes: &[u8]) -> &'static str {
    if bytes.starts_with(b"\x89PNG") {
        "png"
    } else if bytes.starts_with(b"\xFF\xD8\xFF") {
        "jpg"
    } else if bytes.starts_with(b"GIF8") {
        "gif"
    } else if bytes.len() >= 12 && &bytes[..4] == b"RIFF" && &bytes[8..12] == b"WEBP" {
        "webp"
    } else {
        "bin"
    }
}

/// Saves `bytes` under the app's downloads folder, named by time and type.
pub async fn save_to_downloads(bytes: &[u8]) {
    let Some(data_dir) = crate::utils::matrix::DATA_DIR.get() else {
        return;
    };
    let downloads_dir = data_dir.join("downloads");
    let _ = fs::create_dir_all(&downloads_dir).await;
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let ext = media_extension(bytes);
    let path = downloads_dir.join(format!("media_{}.{}", ts, ext));
    let _ = fs::write(&path, bytes).await;
}

pub fn format_file_size(bytes: u64) -> String {
    if bytes < 1_024 {
        format!("{} B", bytes)
    } else if bytes < 1_024 * 1_024 {
        format!("{:.1} KB", bytes as f64 / 1_024.0)
    } else {
        format!("{:.1} MB", bytes as f64 / (1_024.0 * 1_024.0))
    }
}

/// `m:ss`, or `h:mm:ss` from an hour.
pub fn format_media_duration(d: std::time::Duration) -> String {
    let s = d.as_secs();
    if s >= 3_600 {
        format!("{}:{:02}:{:02}", s / 3_600, (s % 3_600) / 60, s % 60)
    } else {
        format!("{}:{:02}", s / 60, s % 60)
    }
}

#[cfg(test)]
mod tests {
    use super::{format_file_size, format_media_duration, image_mime, media_extension};

    #[test]
    fn image_mime_by_extension() {
        assert_eq!(image_mime("a.PNG"), mime::IMAGE_PNG);
        assert_eq!(image_mime("photo.jpeg"), mime::IMAGE_JPEG);
        assert_eq!(image_mime("anim.gif"), mime::IMAGE_GIF);
        assert_eq!(image_mime("x.webp").essence_str(), "image/webp");
        assert_eq!(image_mime("notes"), mime::APPLICATION_OCTET_STREAM);
    }
    use std::time::Duration;

    #[test]
    fn detects_png() {
        // PNG magic: \x89 P N G
        assert_eq!(media_extension(b"\x89PNG\r\n\x1a\nextra"), "png");
    }

    #[test]
    fn detects_jpeg() {
        // JPEG SOI marker: FF D8 FF
        assert_eq!(media_extension(b"\xFF\xD8\xFF\xE0extra"), "jpg");
    }

    #[test]
    fn detects_gif() {
        // GIF87a and GIF89a both start with GIF8
        assert_eq!(media_extension(b"GIF89a..."), "gif");
        assert_eq!(media_extension(b"GIF87a..."), "gif");
    }

    #[test]
    fn detects_webp() {
        // WebP: RIFF????WEBP
        let mut bytes = Vec::new();
        bytes.extend_from_slice(b"RIFF");
        bytes.extend_from_slice(&[0u8; 4]); // file size (ignored)
        bytes.extend_from_slice(b"WEBP");
        bytes.extend_from_slice(b"VP8 extra");
        assert_eq!(media_extension(&bytes), "webp");
    }

    #[test]
    fn unknown_format_returns_bin() {
        assert_eq!(media_extension(b"PK\x03\x04"), "bin"); // zip
        assert_eq!(media_extension(b"unknown data"), "bin");
    }

    #[test]
    fn empty_slice_returns_bin() {
        assert_eq!(media_extension(b""), "bin");
    }

    #[test]
    fn webp_requires_full_12_byte_header() {
        // RIFF present but only 11 bytes — must not panic
        let bytes = b"RIFF\x00\x00\x00\x00WEB";
        assert_eq!(media_extension(bytes), "bin");
    }

    // ── format_file_size ──────────────────────────────────────────────────────

    #[test]
    fn file_size_bytes_boundary() {
        assert_eq!(format_file_size(0), "0 B");
        assert_eq!(format_file_size(512), "512 B");
        assert_eq!(format_file_size(1023), "1023 B"); // last byte before KB
    }

    #[test]
    fn file_size_kilobytes() {
        assert_eq!(format_file_size(1024), "1.0 KB");
        assert_eq!(format_file_size(1536), "1.5 KB"); // 1.5 * 1024
        assert_eq!(format_file_size(2048), "2.0 KB");
    }

    #[test]
    fn file_size_megabytes() {
        assert_eq!(format_file_size(1024 * 1024), "1.0 MB");
        assert_eq!(format_file_size(1024 * 1024 * 5), "5.0 MB");
    }

    // ── format_media_duration ─────────────────────────────────────────────────

    #[test]
    fn duration_seconds_only() {
        assert_eq!(format_media_duration(Duration::ZERO), "0:00");
        assert_eq!(format_media_duration(Duration::from_secs(9)), "0:09");
        assert_eq!(format_media_duration(Duration::from_secs(59)), "0:59");
    }

    #[test]
    fn duration_minutes_and_seconds() {
        assert_eq!(format_media_duration(Duration::from_secs(60)), "1:00");
        assert_eq!(format_media_duration(Duration::from_secs(90)), "1:30");
        assert_eq!(format_media_duration(Duration::from_secs(3599)), "59:59");
    }

    #[test]
    fn duration_hours() {
        assert_eq!(format_media_duration(Duration::from_secs(3600)), "1:00:00");
        assert_eq!(format_media_duration(Duration::from_secs(3661)), "1:01:01");
        assert_eq!(format_media_duration(Duration::from_secs(7322)), "2:02:02");
    }
}
