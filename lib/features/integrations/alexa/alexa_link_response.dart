class AlexaLinkResponse {
  final String ssoToken;
  final int expiresInSeconds;
  final String authorizeUrl;

  const AlexaLinkResponse({
    required this.ssoToken,
    required this.expiresInSeconds,
    required this.authorizeUrl,
  });

  factory AlexaLinkResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map = json;
    if (json['data'] is Map<String, dynamic>) {
      map = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json['result'] is Map<String, dynamic>) {
      map = Map<String, dynamic>.from(json['result'] as Map);
    }

    final dynamic expiresVal = map['expiresInSeconds'] ?? map['expires_in_seconds'] ?? map['expiresIn'];

    final String ssoToken = map['ssoToken']?.toString() ??
        map['sso_token']?.toString() ??
        map['token']?.toString() ??
        map['linkToken']?.toString() ??
        '';

    String authUrl = map['authorizeUrl']?.toString() ??
        map['authorizationUrl']?.toString() ??
        map['authorization_url']?.toString() ??
        map['authUrl']?.toString() ??
        map['auth_url']?.toString() ??
        map['url']?.toString() ??
        '';

    if (authUrl.isEmpty && ssoToken.isNotEmpty) {
      authUrl = 'https://alexa.amazon.com/oauth/authorize?client_id=smart_homez&token=$ssoToken';
    } else if (authUrl.isEmpty) {
      authUrl = 'https://alexa.amazon.com/oauth/authorize?client_id=smart_homez';
    }

    return AlexaLinkResponse(
      ssoToken: ssoToken,
      expiresInSeconds: expiresVal is num
          ? expiresVal.toInt()
          : (int.tryParse(expiresVal?.toString() ?? '') ?? 0),
      authorizeUrl: authUrl,
    );
  }
}
