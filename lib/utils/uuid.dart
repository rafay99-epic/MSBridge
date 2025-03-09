import 'package:uuid/uuid.dart';

String generateUuid() {
  const uuid = Uuid();
  return uuid.v4();
}
