package com.nps.icone_app

import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import com.android.apksig.ApkSigner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.Calendar
import java.util.Date
import javax.security.auth.x500.X500Principal

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nps.icone_app/signer"
    private val ALIAS = "nps_sign_key"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "signApk") {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")

                if (inputPath == null || outputPath == null) {
                    result.error("BAD_ARGS", "Chemins manquants", null)
                    return@setMethodCallHandler
                }

                Thread {
                    try {
                        signApkFile(inputPath, outputPath)
                        Handler(Looper.getMainLooper()).post {
                            result.success(outputPath)
                        }
                    } catch (e: Throwable) {
                        val details = StringBuilder()
                        var t: Throwable? = e
                        while (t != null) {
                            details.append(t.javaClass.name).append(": ").append(t.message).append(" | ")
                            t = t.cause
                        }
                        Handler(Looper.getMainLooper()).post {
                            result.error("SIGN_FAILED", details.toString(), null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getOrCreateKey(): Pair<PrivateKey, X509Certificate> {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)

        if (!keyStore.containsAlias(ALIAS)) {
            val notBefore = Date()
            val notAfterCal = Calendar.getInstance()
            notAfterCal.add(Calendar.YEAR, 30)

            val spec = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                .setKeySize(2048)
                .setCertificateSubject(X500Principal("CN=NPS.NELSON, OU=NPS, O=NPS Studio, C=CD"))
                .setCertificateSerialNumber(BigInteger.valueOf(1))
                .setCertificateNotBefore(notBefore)
                .setCertificateNotAfter(notAfterCal.time)
                .build()

            val kpg = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore"
            )
            kpg.initialize(spec)
            kpg.generateKeyPair()
        }

        val privateKey = keyStore.getKey(ALIAS, null) as PrivateKey
        val cert = keyStore.getCertificate(ALIAS) as X509Certificate
        return Pair(privateKey, cert)
    }

    private fun signApkFile(inputPath: String, outputPath: String) {
        val (privateKey, cert) = getOrCreateKey()

        val signerConfig = ApkSigner.SignerConfig.Builder(
            "nps_key",
            privateKey,
            listOf(cert)
        ).build()

        val apkSigner = ApkSigner.Builder(listOf(signerConfig))
            .setInputApk(File(inputPath))
            .setOutputApk(File(outputPath))
            .setV1SigningEnabled(false)
            .setV2SigningEnabled(true)
            .setV3SigningEnabled(true)
            .setMinSdkVersion(24)
            .build()

        apkSigner.sign()
    }
}