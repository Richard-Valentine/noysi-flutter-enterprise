import 'dart:io';

import 'package:code/data/api/remote/endpoints.dart';
import 'package:code/data/api/remote/remote_constants.dart';

class CommonUtils {
  static String getDefLang() {
    try {
      return Platform.localeName.split("_").first;
    } catch (_) {
      return RemoteConstants.defLang;
    }
  }

  static String getUsernameFromLink(String link, String currentTeamName) {
    return link.startsWith(
            "#${Endpoint.teams}/$currentTeamName${Endpoint.channels}/")
        ? link
            .split('/')[link.split('/').length - 2]
            .replaceFirst('@', '')
            .toLowerCase()
            .trim()
        : "";
  }
}
