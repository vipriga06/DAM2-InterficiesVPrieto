import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

Uint8List _randomBytes(int len) {
  final rnd = SecureRandom('Fortuna')..seed(KeyParameter(Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256)))));
  return rnd.nextBytes(len);
}

Future<Uint8List> encryptFileWithPublicKey(String pemPublic, File inputFile) async {
  final pub = CryptoUtils.rsaPublicKeyFromPem(pemPublic); // RSAPublicKey
  final plain = await inputFile.readAsBytes();

  final aesKey = _randomBytes(32); // AES-256
  final iv = _randomBytes(12); // GCM nonce

  // 1) AES-GCM encrypt (usa GCMBlockCipher + AEADParameters)
  final ciphertext = _aesGcmEncrypt(aesKey, iv, plain);

  // 2) RSA encrypt aesKey with pub (PKCS#1 v1.5) - sufficient for short keys
  final rsaEncryptedKey = _rsaPkcs1Encrypt(pub, aesKey);

  // 3) package: 4 bytes length + rsaEncryptedKey + iv + ciphertext
  final out = BytesBuilder();
  final lenBytes = ByteData(4)..setUint32(0, rsaEncryptedKey.length, Endian.big);
  out.add(lenBytes.buffer.asUint8List());
  out.add(rsaEncryptedKey);
  out.add(iv);
  out.add(ciphertext);
  return out.toBytes();
}

Future<void> decryptToFileWithPrivateKey(String pemPrivate, Uint8List package, File outFile) async {
  final priv = CryptoUtils.rsaPrivateKeyFromPem(pemPrivate); // RSAPrivateKey

  final reader = ByteData.sublistView(package);
  final len = reader.getUint32(0, Endian.big);
  int offset = 4;
  final rsaEncryptedKey = package.sublist(offset, offset + len); offset += len;
  final iv = package.sublist(offset, offset + 12); offset += 12;
  final ciphertext = package.sublist(offset);

  final aesKey = _rsaPkcs1Decrypt(priv, rsaEncryptedKey);
  final plain = _aesGcmDecrypt(aesKey, iv, ciphertext);

  await outFile.writeAsBytes(plain);
}

// Implement helpers: _aesGcmEncrypt, _aesGcmDecrypt, _rsaOaepEncrypt, _rsaOaepDecrypt
// Usa pointycastle: GCMBlockCipher/AEADParameters for AES-GCM and OAEPEncoding(RSAEngine()) for RSA.
Uint8List _aesGcmEncrypt(Uint8List key, Uint8List iv, Uint8List plaintext) {
  final aead = GCMBlockCipher(AESEngine());
  final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
  aead.init(true, params);
  return aead.process(plaintext);
}

Uint8List _aesGcmDecrypt(Uint8List key, Uint8List iv, Uint8List ciphertext) {
  final aead = GCMBlockCipher(AESEngine());
  final params = AEADParameters(KeyParameter(key), 128, iv, Uint8List(0));
  aead.init(false, params);
  return aead.process(ciphertext);
}

Uint8List _rsaPkcs1Encrypt(RSAPublicKey publicKey, Uint8List data) {
  final pkcs1 = PKCS1Encoding(RSAEngine());
  pkcs1.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
  return _processInBlocks(pkcs1, data);
}

Uint8List _rsaPkcs1Decrypt(RSAPrivateKey privateKey, Uint8List cipher) {
  final pkcs1 = PKCS1Encoding(RSAEngine());
  pkcs1.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  return _processInBlocks(pkcs1, cipher);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final out = BytesBuilder();
  final inputLen = input.length;
  final blockSize = engine.inputBlockSize;
  int offset = 0;
  while (offset < inputLen) {
    final end = (offset + blockSize < inputLen) ? offset + blockSize : inputLen;
    final chunk = input.sublist(offset, end);
    final processed = engine.process(chunk);
    out.add(processed);
    offset = end;
  }
  return out.toBytes();
}

// Simple interface and implementation to follow SOLID (single responsibility
// and dependency inversion for easier testing). Junior-friendly API.
abstract class ICryptoService {
  Future<Uint8List> encryptFileWithPublicKeyPem(String pemPublic, File inputFile);
  Future<void> decryptPackageWithPrivateKeyPem(String pemPrivate, Uint8List package, File outFile);
}

class CryptoService implements ICryptoService {
  const CryptoService();

  @override
  Future<Uint8List> encryptFileWithPublicKeyPem(String pemPublic, File inputFile) => encryptFileWithPublicKey(pemPublic, inputFile);

  @override
  Future<void> decryptPackageWithPrivateKeyPem(String pemPrivate, Uint8List package, File outFile) => decryptToFileWithPrivateKey(pemPrivate, package, outFile);
}