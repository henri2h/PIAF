// Android starts through `android_main` in the lib; this binary is desktop only.
fn main() {
    #[cfg(not(target_os = "android"))]
    piaf::run_desktop();
}
