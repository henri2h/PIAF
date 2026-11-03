package dev.piaf.app

import android.net.http.X509TrustManagerExtensions
import android.util.Log
import java.io.ByteArrayInputStream
import java.security.KeyStore
import java.security.cert.CertificateExpiredException
import java.security.cert.CertificateFactory
import java.security.cert.CertificateNotYetValidException
import java.security.cert.X509Certificate
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

/**
 * Server certificate checks for the Rust HTTP client (`android/tls.rs`):
 * Android's default trust manager (the network security config's CAs, the
 * system blocklist), without online revocation checks. See SECURITY.md.
 * The host name is checked on the Rust side.
 */
object TlsVerifier {
    private const val TAG = "piaf.tls"

    const val TRUSTED = 0
    const val EXPIRED = 1
    const val NOT_YET_VALID = 2
    const val UNTRUSTED = 3

    private val certificates = CertificateFactory.getInstance("X.509")

    private val trustManager by lazy {
        val factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        factory.init(null as KeyStore?)
        X509TrustManagerExtensions(factory.trustManagers.filterIsInstance<X509TrustManager>().first())
    }

    /** `chain`: DER certificates, the server's first. Called from Rust. */
    @JvmStatic
    fun verify(chain: Array<ByteArray>, host: String): Int = try {
        val certs = chain.map {
            certificates.generateCertificate(ByteArrayInputStream(it)) as X509Certificate
        }
        trustManager.checkServerTrusted(certs.toTypedArray(), "RSA", host)
        TRUSTED
    } catch (e: Exception) {
        Log.w(TAG, "certificate rejected for $host: $e")
        when (generateSequence<Throwable>(e) { it.cause }.firstOrNull {
            it is CertificateExpiredException || it is CertificateNotYetValidException
        }) {
            is CertificateExpiredException -> EXPIRED
            is CertificateNotYetValidException -> NOT_YET_VALID
            else -> UNTRUSTED
        }
    }
}
