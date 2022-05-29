import 'package:code/data/api/remote/endpoints.dart';
import 'package:code/domain/meet/meeting_model.dart';
import 'package:code/ui/_base/bloc_global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';

class TXHtmlWidget extends StatelessWidget {
  final String body;
  final Map<String, Style> style;
  final bool shrinkWrap;
  final ValueChanged<String>? onLinkTap;

  const TXHtmlWidget({
    Key? key,
    required this.body,
    required this.style,
    this.shrinkWrap = false,
    this.onLinkTap,
  }) : super(key: key);

  final String meetProdHttp = "http://meet.noysi.com";
  final String meetDevHttp = "http://dev-meet.noysi.com";
  final String meetPreHttp = "http://pre-meet.noysi.com";

  @override
  Widget build(BuildContext context) => Html(
        data: body,
        style: style,
        shrinkWrap: shrinkWrap,
        onAnchorTap: (anchor, context, map, element) {
          if (onLinkTap != null &&  anchor?.isNotEmpty == true)
            onLinkTap!(anchor!);
        },
        onLinkTap: (link, context, map, element) async {
          if(link != null) {
            if (link.trim().startsWith(Endpoint.meetBaseUrlProd) ||
                link.trim().startsWith(meetProdHttp) ||
                link.trim().startsWith(Endpoint.meetBaseUrlPre) ||
                link.trim().startsWith(meetPreHttp) ||
                link.trim().startsWith(Endpoint.meetBaseUrlDev) ||
                link.trim().startsWith(meetDevHttp)) {
              final room = link.trim().split("/")[3];
              final url = link.trim().startsWith(Endpoint.meetBaseUrlProd) ||
                  link.trim().startsWith(meetProdHttp)
                  ? Endpoint.meetBaseUrlProd
                  : link.trim().startsWith(Endpoint.meetBaseUrlPre) ||
                  link.trim().startsWith(meetPreHttp)
                  ? Endpoint.meetBaseUrlPre
                  : Endpoint.meetBaseUrlDev;
              final res = await joinMeeting(room: room, url: url);
              if (res?.isSuccess == true) {
                currentMeeting = MeetingModel(
                  room: room,
                  url: url,
                );
              }
            } else if (onLinkTap != null && link.isNotEmpty)
              onLinkTap!(link);
          }
        },
      );
}
