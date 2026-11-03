//! matrix-sdk's HTTP client, with server certificates checked by Android's
//! default trust manager (`TlsVerifier.kt`) instead of rustls-platform-verifier.
//!
//! That verifier adds online revocation checks: CRL downloads over HTTP, 1-2s
//! before the first response at each start (soft-fail, so they protect little;
//! see SECURITY.md). The check runs through JNI inside the TLS handshake, so it
//! runs in `block_in_place`: tokio hands the worker's other tasks to another
//! thread (before, blocked handshakes held every worker and even store reads
//! waited for the network).

use std::sync::{Arc, OnceLock};
use std::time::Duration;

use jni::objects::{GlobalRef, JClass, JObject, JValue};
use rustls::client::danger::{HandshakeSignatureValid, ServerCertVerified, ServerCertVerifier};
use rustls::crypto::{CryptoProvider, verify_tls12_signature, verify_tls13_signature};
use rustls::pki_types::{CertificateDer, ServerName, UnixTime};
use rustls::server::ParsedCertificate;
use rustls::{CertificateError, DigitallySignedStruct, SignatureScheme};

const CLASS: &str = "dev.piaf.app.TlsVerifier";

// `TlsVerifier.kt` results.
const TRUSTED: i32 = 0;
const EXPIRED: i32 = 1;
const NOT_YET_VALID: i32 = 2;

static JAVA: OnceLock<(jni::JavaVM, GlobalRef)> = OnceLock::new();

/// Finds `TlsVerifier` through `context`'s class loader (callers' threads may
/// be native ones, where `FindClass` doesn't see app classes). Once.
pub(crate) fn init(vm: *mut std::ffi::c_void, context: *mut std::ffi::c_void) {
    if JAVA.get().is_some() {
        return;
    }
    let result = (|| -> jni::errors::Result<(jni::JavaVM, GlobalRef)> {
        // SAFETY: the VM and context pointers come from the running app.
        let vm = unsafe { jni::JavaVM::from_raw(vm.cast()) }?;
        let class = {
            let mut env = vm.attach_current_thread()?;
            let context = unsafe { JObject::from_raw(context.cast()) };
            let loader = env
                .call_method(context, "getClassLoader", "()Ljava/lang/ClassLoader;", &[])?
                .l()?;
            let name = env.new_string(CLASS)?;
            let class = env
                .call_method(
                    loader,
                    "loadClass",
                    "(Ljava/lang/String;)Ljava/lang/Class;",
                    &[(&name).into()],
                )?
                .l()?;
            env.new_global_ref(class)?
        };
        Ok((vm, class))
    })();
    match result {
        Ok(java) => {
            let _ = JAVA.set(java);
        }
        Err(e) => tracing::error!("TLS verifier init failed: {e}"),
    }
}

/// The client matrix-sdk would build (its `HttpSettings::make_client`
/// defaults), with [`AndroidVerifier`].
pub fn http_client() -> anyhow::Result<reqwest::Client> {
    anyhow::ensure!(JAVA.get().is_some(), "TLS verifier not initialized");
    let provider = CryptoProvider::get_default()
        .cloned()
        .unwrap_or_else(|| Arc::new(rustls::crypto::aws_lc_rs::default_provider()));
    let verifier = AndroidVerifier(provider.clone());
    let mut tls = rustls::ClientConfig::builder_with_provider(provider)
        .with_safe_default_protocol_versions()?
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(verifier))
        .with_no_client_auth();
    tls.alpn_protocols = vec![b"h2".to_vec(), b"http/1.1".to_vec()];
    Ok(reqwest::Client::builder()
        .user_agent("matrix-rust-sdk")
        .timeout(Duration::from_secs(30))
        .tls_backend_preconfigured(tls)
        .build()?)
}

/// Runs `f` with tokio told it blocks, where it can (not on a current-thread
/// runtime).
fn blocking<T>(f: impl FnOnce() -> T) -> T {
    use tokio::runtime::{Handle, RuntimeFlavor};
    match Handle::try_current() {
        Ok(handle) if handle.runtime_flavor() == RuntimeFlavor::MultiThread => {
            tokio::task::block_in_place(f)
        }
        _ => f(),
    }
}

/// `TlsVerifier.verify(chain, host)`; `None` if the call itself failed.
fn verify_chain(chain: &[&CertificateDer<'_>], host: &str) -> Option<i32> {
    let (vm, class) = JAVA.get()?;
    // Permanently: tokio workers handshake often, attaching each time costs.
    let mut env = vm.attach_current_thread_permanently().ok()?;
    let result = env.with_local_frame(8, |env| -> jni::errors::Result<i32> {
        let certs = env.new_object_array(chain.len() as i32, "[B", JObject::null())?;
        for (i, cert) in chain.iter().enumerate() {
            let bytes = env.byte_array_from_slice(cert.as_ref())?;
            env.set_object_array_element(&certs, i as i32, bytes)?;
        }
        let host = env.new_string(host)?;
        let class: &JClass = class.as_obj().into();
        env.call_static_method(
            class,
            "verify",
            "([[BLjava/lang/String;)I",
            &[JValue::Object(&certs), JValue::Object(&host)],
        )?
        .i()
    });
    match result {
        Ok(status) => Some(status),
        Err(e) => {
            let _ = env.exception_clear();
            tracing::error!("TLS verifier call failed: {e}");
            None
        }
    }
}

#[derive(Debug)]
struct AndroidVerifier(Arc<CryptoProvider>);

impl ServerCertVerifier for AndroidVerifier {
    fn verify_server_cert(
        &self,
        end_entity: &CertificateDer<'_>,
        intermediates: &[CertificateDer<'_>],
        server_name: &ServerName<'_>,
        _ocsp_response: &[u8],
        _now: UnixTime,
    ) -> Result<ServerCertVerified, rustls::Error> {
        // Android's trust manager doesn't check the name.
        rustls::client::verify_server_name(&ParsedCertificate::try_from(end_entity)?, server_name)?;
        let chain: Vec<_> = std::iter::once(end_entity).chain(intermediates).collect();
        let host = server_name.to_str();
        let host = host.strip_suffix('.').unwrap_or(&host);
        let error = match blocking(|| verify_chain(&chain, host)) {
            Some(TRUSTED) => return Ok(ServerCertVerified::assertion()),
            Some(EXPIRED) => CertificateError::Expired,
            Some(NOT_YET_VALID) => CertificateError::NotValidYet,
            Some(_) => CertificateError::UnknownIssuer,
            None => return Err(rustls::Error::General("certificate check failed".into())),
        };
        Err(rustls::Error::InvalidCertificate(error))
    }

    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        verify_tls12_signature(message, cert, dss, &self.0.signature_verification_algorithms)
    }

    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &CertificateDer<'_>,
        dss: &DigitallySignedStruct,
    ) -> Result<HandshakeSignatureValid, rustls::Error> {
        verify_tls13_signature(message, cert, dss, &self.0.signature_verification_algorithms)
    }

    fn supported_verify_schemes(&self) -> Vec<SignatureScheme> {
        self.0.signature_verification_algorithms.supported_schemes()
    }
}
