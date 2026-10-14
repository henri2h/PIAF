//! System clipboard (desktop).

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

/// The image on the system clipboard, as PNG.
/// Returns PNG bytes on success, `None` if clipboard has no image.
/// Safe to call from the UI/main thread.
pub fn read_image() -> Option<Vec<u8>> {
    let mut cb = arboard::Clipboard::new().ok()?;
    let img = cb.get_image().ok()?;
    encode_rgba_to_png(img.width as u32, img.height as u32, &img.bytes)
}
