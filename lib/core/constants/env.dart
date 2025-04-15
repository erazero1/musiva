
import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied(path: '.env')
final class Env{
  @EnviedField(varName: "CLIENT_ID", obfuscate: true)
  static final String clientIdKey = _Env.clientIdKey;

  @EnviedField(varName: "CLIENT_SECRET", obfuscate: true)
  static final String clientSecretKey = _Env.clientSecretKey;

}