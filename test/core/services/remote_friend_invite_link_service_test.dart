import 'package:chessiq/core/services/remote_friend_invite_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = RemoteFriendInviteLinkService.instance;

  group('inviteCodeFromScannedValue', () {
    test('accepts a raw six-character code', () {
      expect(service.inviteCodeFromScannedValue(' ab12x9 '), 'AB12X9');
    });

    test('extracts the code from the ChessIQ hosted invite URL', () {
      final link = service.buildInviteUri('AB12X9');

      expect(service.inviteCodeFromScannedValue(link.toString()), 'AB12X9');
    });

    test('extracts the code from the ChessIQ app URL', () {
      final link = service.buildAppInviteUri('AB12X9');

      expect(service.inviteCodeFromScannedValue(link.toString()), 'AB12X9');
    });

    test('rejects unrelated QR payloads', () {
      expect(
        service.inviteCodeFromScannedValue(
          'https://example.com/invite?code=AB12X9',
        ),
        isNull,
      );
      expect(service.inviteCodeFromScannedValue('not a code'), isNull);
    });
  });
}
