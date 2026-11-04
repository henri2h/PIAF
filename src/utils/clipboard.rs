//! System clipboard images (desktop). Text goes through Freya's `Clipboard`
//! (on Android, `freya-android` installs the system one).

#[cfg(not(target_os = "android"))]
/// Encode raw RGBA pixels to a PNG byte vector.
fn encode_rgba_to_png(width: u32, height: u32, rgba: &[u8]) -> Option<Vec<u8>> {
    let mut buf = Vec::new();
    let mut enc = png::Encoder::new(&mut buf, width, height);
    enc.set_color(png::ColorType::Rgba);
    enc.set_depth(png::BitDepth::Eight);
    let mut writer = enc.write_header().ok()?;
    writer.write_image_data(rgba).ok()?;
    drop(writer);
    Some(buf)
}

#[cfg(not(target_os = "android"))]
/// The image on the system clipboard: copied pixels (as PNG), else an image
/// file copied in a file manager (its bytes). `None` without either.
/// Safe to call from the UI/main thread.
pub fn read_image() -> Option<Vec<u8>> {
    let mut cb = arboard::Clipboard::new().ok()?;
    if let Ok(img) = cb.get_image() {
        return encode_rgba_to_png(img.width as u32, img.height as u32, &img.bytes);
    }
    let path = image_file(&cb.get_text().ok()?)?;
    let bytes = std::fs::read(&path).ok()?;
    // Only what the room can show as an image.
    (crate::utils::media::sniff_image_mime(&bytes).0.type_() == mime::IMAGE).then_some(bytes)
}

/// Largest copied image file sent by a paste.
#[cfg(not(target_os = "android"))]
const MAX_FILE: u64 = 100 * 1024 * 1024;

/// The image file a copied file's text names: a single `file://` URI (file
/// managers) or absolute path, with an image extension.
#[cfg(not(target_os = "android"))]
fn image_file(text: &str) -> Option<std::path::PathBuf> {
    let mut lines = text.lines().map(str::trim).filter(|l| !l.is_empty());
    let line = lines.next()?;
    if lines.next().is_some() {
        return None;
    }
    let path = match line.strip_prefix("file://") {
        Some(uri) => percent_decode(uri)?,
        None => line.to_string(),
    };
    let path = std::path::PathBuf::from(path);
    let ext = path.extension()?.to_str()?.to_ascii_lowercase();
    let is_image = ["png", "jpg", "jpeg", "gif", "webp"].contains(&ext.as_str());
    let size = std::fs::metadata(&path).ok()?.len();
    (path.is_absolute() && is_image && size <= MAX_FILE).then_some(path)
}

/// `%XX` escapes of a URI path (spaces, accents).
#[cfg(not(target_os = "android"))]
fn percent_decode(s: &str) -> Option<String> {
    let mut out = Vec::with_capacity(s.len());
    let bytes = s.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' {
            let hex = s.get(i + 1..i + 3)?;
            out.push(u8::from_str_radix(hex, 16).ok()?);
            i += 3;
        } else {
            out.push(bytes[i]);
            i += 1;
        }
    }
    String::from_utf8(out).ok()
}

#[cfg(all(test, not(target_os = "android")))]
mod tests {
    use super::*;

    #[test]
    fn copied_image_files() {
        let dir = std::env::temp_dir().join(format!("piaf-clip-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let file = dir.join("a photo.PNG");
        std::fs::write(&file, b"x").unwrap();
        let uri = format!("file://{}", file.display()).replace(' ', "%20");
        assert_eq!(image_file(&uri), Some(file.clone()));
        assert_eq!(image_file(&file.display().to_string()), Some(file.clone()));
        // Several files, other types, text: not an image paste.
        assert_eq!(image_file(&format!("{uri}\n{uri}")), None);
        let text = dir.join("notes.txt");
        std::fs::write(&text, b"x").unwrap();
        assert_eq!(image_file(&text.display().to_string()), None);
        assert_eq!(image_file("hello"), None);
        std::fs::remove_dir_all(&dir).unwrap();
    }
}
