import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

void main() {
  // Use the secp256k1 curve, which is the same as in the Python code
  final curve = ECCurve_secp256k1();

  // Generate a new key pair
  final keyGen = ECKeyGenerator();
  final random = math.Random.secure();
  final seedValue = List.generate(32, (e) => random.nextInt(256));
  final seed = Uint8List.fromList(seedValue);
  final seedParam = KeyParameter(seed);
  final keyGenParams = ParametersWithRandom(
    ECKeyGeneratorParameters(curve),
    FortunaRandom()..seed(seedParam),
  );
  keyGen.init(keyGenParams);
  final keyPair = keyGen.generateKeyPair();

  // Extract the private and public keys
  final privKey = keyPair.privateKey;
  final pubKey = keyPair.publicKey;

  // Print the private key in hex format
  stdout.writeln("save private key");
  stdout.writeln(privKey.d!.toRadixString(16));

  // Print the public key components (x and y) in hex format
  stdout.writeln("\nappender_open's parameter:");

  final pubKeyX = pubKey.Q!.x!.toBigInteger()!.toRadixString(16);
  final pubKeyY = pubKey.Q!.y!.toBigInteger()!.toRadixString(16);
  stdout.writeln("$pubKeyX$pubKeyY");
}
