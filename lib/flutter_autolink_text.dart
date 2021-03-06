library flutter_autolink_text;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

typedef VoidArgumentedCallback = void Function(String);

RegExp _phoneRegExp = RegExp(r"[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*");
RegExp _emailRegExp = RegExp(
    r"[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*");
RegExp _linksRegExp = RegExp(
    r"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})");

class AutolinkText extends StatelessWidget {
  final String text;
  final VoidArgumentedCallback onWebLinkTap, onPhoneTap, onEmailTap;
  final TextStyle textStyle, linkStyle;
  final TextAlign textAlign;
  final bool humanize;

  AutolinkText({
    Key key,
    @required this.text,
    this.textStyle,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onWebLinkTap,
    this.onEmailTap,
    this.onPhoneTap,
    this.humanize = false,
  }) : super(key: key);

  _onLinkTap(String link, _MatchType type) {
    switch (type) {
      case _MatchType.phone:
        onPhoneTap(link);
        break;
      case _MatchType.email:
        onEmailTap(link);
        break;
      case _MatchType.link:
        onWebLinkTap(link);
        break;
      case _MatchType.none:
        break;
    }
  }

  String _getTypes() {
    String types = '';
    if (onWebLinkTap != null) types += 'web';
    if (onEmailTap != null) types += 'email';
    if (onPhoneTap != null) types += 'phone';
    return types;
  }

  List<TextSpan> _buildTextSpans(BuildContext context) {
    return _findMatches(text, _getTypes(), humanize).map((match) {
      if (match.type == _MatchType.none)
        return TextSpan(text: match.text, style: effectiveTextStyle(context));
      final recognizer = TapGestureRecognizer();
      recognizer.onTap = () => _onLinkTap(match.text, match.type);
      return TextSpan(
          text: match.text,
          style: effectiveLinkStyle(context),
          recognizer: recognizer);
    }).toList();
  }

  TextStyle effectiveTextStyle(BuildContext context) {
    var effectiveTextStyle = textStyle ?? DefaultTextStyle.of(context).style;
    if (MediaQuery.of(context).boldText) {
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    return effectiveTextStyle;
  }

  TextStyle effectiveLinkStyle(BuildContext context) {
    var effectiveLinkStyle = linkStyle ?? DefaultTextStyle.of(context).style;
    if (MediaQuery.of(context).boldText) {
      effectiveLinkStyle = effectiveLinkStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    return effectiveLinkStyle;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: _buildTextSpans(context)),
      textAlign: textAlign,
    );
  }
}

enum _MatchType { phone, email, link, none }

class _MatchedString {
  final _MatchType type;
  final String text;

  _MatchedString({this.text, this.type});

  @override
  String toString() {
    return text;
  }
}

List<_MatchedString> _findMatches(String text, String types, bool humanize) {
  List<_MatchedString> matched = [
    _MatchedString(type: _MatchType.none, text: text)
  ];

  if (types.contains('phone')) {
    List<_MatchedString> newMatched = [];
    for (_MatchedString matchedBefore in matched) {
      if (matchedBefore.type == _MatchType.none) {
        newMatched
            .addAll(_findLinksByType(matchedBefore.text, _MatchType.phone));
      } else
        newMatched.add(matchedBefore);
    }
    matched = newMatched;
  }

  if (types.contains('email')) {
    List<_MatchedString> newMatched = [];
    for (_MatchedString matchedBefore in matched) {
      if (matchedBefore.type == _MatchType.none) {
        newMatched
            .addAll(_findLinksByType(matchedBefore.text, _MatchType.email));
      } else
        newMatched.add(matchedBefore);
    }
    matched = newMatched;
  }

  if (types.contains('web')) {
    List<_MatchedString> newMatched = [];
    for (_MatchedString matchedBefore in matched) {
      if (matchedBefore.type == _MatchType.none) {
        final webMatches =
            _findLinksByType(matchedBefore.text, _MatchType.link);
        for (_MatchedString webMatch in webMatches) {
          if (webMatch.type == _MatchType.link &&
              (webMatch.text.startsWith('http://') ||
                  webMatch.text.startsWith('https://')) &&
              humanize) {
            newMatched.add(_MatchedString(
                text: webMatch.text
                    .substring(webMatch.text.startsWith('http://') ? 7 : 8),
                type: _MatchType.link));
          } else {
            newMatched.add(webMatch);
          }
        }
      } else
        newMatched.add(matchedBefore);
    }
    matched = newMatched;
  }

  return matched;
}

RegExp _getRegExpByType(_MatchType type) {
  switch (type) {
    case _MatchType.phone:
      return _phoneRegExp;
    case _MatchType.email:
      return _emailRegExp;
    case _MatchType.link:
      return _linksRegExp;
    default:
      return null;
  }
}

List<_MatchedString> _findLinksByType(String text, _MatchType type) {
  List<_MatchedString> output = [];
  final matches = _getRegExpByType(type).allMatches(text);
  int endOfMatch = 0;
  for (Match match in matches) {
    final before = text.substring(endOfMatch, match.start);
    if (before.isNotEmpty)
      output.add(_MatchedString(text: before, type: _MatchType.none));
    final lastCharacterIndex =
        text[match.end - 1] == ' ' ? match.end - 1 : match.end;
    output.add(_MatchedString(
        type: type, text: text.substring(match.start, lastCharacterIndex)));
    endOfMatch = lastCharacterIndex;
  }
  final endOfText = text.substring(endOfMatch);
  if (endOfText.isNotEmpty)
    output.add(_MatchedString(text: endOfText, type: _MatchType.none));
  return output;
}
