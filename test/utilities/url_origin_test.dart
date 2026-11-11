import 'package:flutter_test/flutter_test.dart';
import 'package:form_fields/src/utilities/url_origin.dart';

void main() {
  const upload = 'https://api.example.com/upload';

  test('a link on the upload server is the same origin', () {
    expect(
      isSameOrigin('https://api.example.com/files/1.png', upload),
      isTrue,
    );
  });

  test('a link on another host is not, so the token is not sent there', () {
    expect(
      isSameOrigin('https://cdn.elsewhere.net/1.png', upload),
      isFalse,
    );
  });

  test('a different scheme or port is not the same origin', () {
    expect(isSameOrigin('http://api.example.com/1.png', upload), isFalse);
    expect(
      isSameOrigin('https://api.example.com:8443/1.png', upload),
      isFalse,
    );
  });

  test('a relative link, a missing origin or junk is never the same origin', () {
    expect(isSameOrigin('/files/1.png', upload), isFalse);
    expect(isSameOrigin('https://api.example.com/1.png', null), isFalse);
    expect(isSameOrigin('https://api.example.com/1.png', ''), isFalse);
    expect(isSameOrigin('not a url', upload), isFalse);
  });
}
