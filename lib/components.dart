import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const ink = Color(0xff16191b),
    pageColor = Color(0xfff7f7f7),
    muted = Color(0xff7d858c),
    blue = Color(0xff0665eb),
    fieldColor = Color(0xffedeef2),
    focusedField = Color(0xffe0e3e6);

class PhoneCanvas extends StatelessWidget {
  const PhoneCanvas({
    super.key,
    required this.child,
    required this.simulated,
    this.dark = false,
  });
  final Widget child;
  final bool simulated, dark;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    child: Scaffold(
      backgroundColor: dark ? Colors.black : pageColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: child),
          if (simulated)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PreviewStatusBar(light: dark),
            ),
          if (simulated)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class PreviewStatusBar extends StatelessWidget {
  const PreviewStatusBar({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) {
    final c = light ? Colors.white : Colors.black;
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 15, 0),
        child: Row(
          children: [
            Text(
              '9:41',
              style: TextStyle(
                color: c,
                fontFamily: 'ReplicaSans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),
            Icon(Icons.signal_cellular_alt_rounded, color: c, size: 21),
            const SizedBox(width: 3),
            Icon(Icons.wifi, color: c, size: 20),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.battery_full, color: c, size: 25),
          ],
        ),
      ),
    );
  }
}

class ReferenceNav extends StatelessWidget {
  const ReferenceNav({super.key, required this.onBack, this.onHelp});
  final VoidCallback onBack;
  final VoidCallback? onHelp;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        tooltip: 'Back',
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded, size: 26, color: ink),
      ),
      if (onHelp != null)
        IconButton(
          tooltip: 'Help',
          onPressed: onHelp,
          icon: const Icon(
            CupertinoIcons.question_circle,
            size: 25,
            color: ink,
          ),
        ),
    ],
  );
}

class PillButton extends StatelessWidget {
  const PillButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.scale = 1,
    this.background = blue,
    this.foreground = Colors.white,
    this.icon,
    this.leading,
    this.glow = false,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final double scale;
  final Color background, foreground;
  final IconData? icon;
  final Widget? leading;
  final bool glow, busy;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      boxShadow: glow && onPressed != null
          ? [
              BoxShadow(
                color: background.withValues(alpha: .25),
                blurRadius: 16 * scale,
                offset: Offset(0, 4 * scale),
              ),
            ]
          : null,
    ),
    child: SizedBox(
      height: math.max(50 * scale, 44),
      width: double.infinity,
      child: TextButton(
        onPressed: busy ? null : onPressed,
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? const Color(0xffc2dafa)
                : background,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? const Color(0xffe2edfc)
                : foreground,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? blue.withValues(alpha: .22)
                : foreground.withValues(alpha: .1),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: blue, width: 2)
                : BorderSide.none,
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'ReplicaSans',
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 23 * scale),
                    SizedBox(width: 10 * scale),
                  ],
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: 10 * scale),
                  ],
                  Flexible(child: Text(label, textAlign: TextAlign.center)),
                ],
              ),
      ),
    ),
  );
}

class LinkAction extends StatelessWidget {
  const LinkAction(
    this.label, {
    super.key,
    required this.onPressed,
    this.scale = 1,
    this.align = Alignment.center,
  });
  final String label;
  final VoidCallback onPressed;
  final double scale;
  final Alignment align;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xff066bcb),
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      alignment: align,
      textStyle: TextStyle(
        fontFamily: 'ReplicaSans',
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
      ),
    ),
    child: Text(label),
  );
}

class StreakPainter extends CustomPainter {
  const StreakPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.black, BlendMode.srcOver);
    final random = math.Random(18),
        origin = Offset(size.width * .5, size.height * .52);
    for (var i = 0; i < 52; i++) {
      final end = Offset(
        random.nextDouble() * size.width * 3 - size.width,
        -size.height * .3,
      );
      canvas.drawLine(
        origin,
        end,
        Paint()
          ..color = [
            const Color(0xff1926bf),
            const Color(0xff8ec7ef),
            const Color(0xffc4f28c),
          ][i % 3].withValues(alpha: .4)
          ..strokeWidth = i % 7 == 0 ? 2 : .6,
      );
    }
  }

  @override
  bool shouldRepaint(StreakPainter oldDelegate) => false;
}

class Country {
  const Country(this.code, this.name, this.flag);
  final String code, name, flag;
}

const countries = [
  Country('+44', 'United Kingdom', 'gb'),
  Country('+33', 'France', 'fr'),
  Country('+1', 'United States', 'us'),
  Country('+86', 'China mainland', 'cn'),
  Country('+91', 'India', 'in'),
  Country('+93', 'Afghanistan', 'af'),
  Country('+61', 'Australia', 'au'),
  Country('+43', 'Austria', 'at'),
  Country('+375', 'Belarus', 'by'),
  Country('+357', 'Cyprus', 'cy'),
  Country('+63', 'Philippines', 'ph'),
];

class CountryButton extends StatelessWidget {
  const CountryButton({
    super.key,
    required this.country,
    required this.scale,
    required this.onPressed,
  });
  final Country country;
  final double scale;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 59 * scale,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: fieldColor,
        foregroundColor: ink,
        padding: EdgeInsets.all(8 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18 * scale),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flag(country.flag, size: 24 * scale),
          SizedBox(width: 8 * scale),
          Text(
            country.code,
            style: TextStyle(fontSize: 16 * scale, color: ink),
          ),
        ],
      ),
    ),
  );
}

class CountrySheet extends StatefulWidget {
  const CountrySheet({
    super.key,
    required this.selected,
    required this.simulated,
    required this.onSelect,
    required this.onCancel,
    this.initialQuery = '',
    this.embedded = false,
  });
  final Country selected;
  final bool simulated, embedded;
  final String initialQuery;
  final ValueChanged<Country> onSelect;
  final VoidCallback onCancel;
  @override
  State<CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<CountrySheet> {
  late final TextEditingController query = TextEditingController(
    text: widget.initialQuery,
  );
  final focus = FocusNode();
  @override
  void initState() {
    super.initState();
    if (!widget.simulated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    query.dispose();
    focus.dispose();
    super.dispose();
  }

  List<Country> get results {
    final q = query.text.trim().toLowerCase();
    return countries
        .where((c) => c.name.toLowerCase().contains(q) || c.code.contains(q) || (c.flag == 'us' && q == 'us'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(
          MediaQuery.sizeOf(context).width,
          widget.embedded ? double.infinity : 480.0,
        ),
        s = width / 375;
    return DefaultTextStyle(
      style: const TextStyle(fontFamily: 'ReplicaSans', color: ink),
      child: SizedBox(
        height: widget.embedded
            ? double.infinity
            : MediaQuery.sizeOf(context).height - 54 * s,
        width: width,
        child: Material(
          color: pageColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(11 * s)),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: query,
            builder: (context, _) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36 * s,
                          decoration: BoxDecoration(
                            color: focusedField,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextField(
                            controller: query,
                            focusNode: focus,
                            textInputAction: TextInputAction.search,
                            style: TextStyle(fontSize: 16 * s, color: ink),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search country',
                              hintStyle: TextStyle(
                                color: muted,
                                fontSize: 14 * s,
                              ),
                              prefixIcon: Icon(
                                CupertinoIcons.search,
                                size: 23 * s,
                                color: muted,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 7 * s,
                              ),
                              suffixIcon: query.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      padding: EdgeInsets.zero,
                                      onPressed: query.clear,
                                      icon: Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        size: 20 * s,
                                        color: const Color(0xffa2a8af),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      TextButton(
                        onPressed: widget.onCancel,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          foregroundColor: const Color(0xff066bcb),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16 * s),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28 * s),
                Expanded(
                  child: results.isEmpty
                      ? const SizedBox.expand()
                      : Container(
                          margin: EdgeInsets.symmetric(horizontal: 16 * s),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20 * s),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView(
                            padding: EdgeInsets.all(4 * s),
                            children: results
                                .map(
                                  (c) => SizedBox(
                                    height: 72 * s,
                                    child: TextButton(
                                      onPressed: () => widget.onSelect(c),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12 * s,
                                        ),
                                        backgroundColor:
                                            c == widget.selected &&
                                                query.text.isEmpty
                                            ? const Color(0xfff3f8fe)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15 * s,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Flag(c.flag, size: 40 * s),
                                              if (c == widget.selected &&
                                                  query.text.isEmpty)
                                                Positioned(
                                                  right: -3,
                                                  bottom: -3,
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: blue,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    child: const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(width: 16 * s),
                                          SizedBox(
                                            width: 56 * s,
                                            child: Text(
                                              c.code,
                                              style: TextStyle(
                                                fontSize: 16 * s,
                                                color: muted,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              c.name,
                                              style: TextStyle(
                                                fontSize: 16 * s,
                                                color: ink,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
                if (widget.simulated)
                  PreviewKeyboard(
                    controller: query,
                    scale: s,
                    search: true,
                    onDone: () => focus.unfocus(),
                  ),
                if (!widget.simulated)
                  SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Code-drawn flag stand-ins, avoiding external flag image dependencies.
class Flag extends StatelessWidget {
  const Flag(this.code, {super.key, required this.size});
  final String code;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$code flag',
    child: ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: FlagPainter(code)),
      ),
    ),
  );
}

class FlagPainter extends CustomPainter {
  const FlagPainter(this.code);
  final String code;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void rect(double x, double y, double rw, double rh, Color c) =>
        canvas.drawRect(
          Rect.fromLTWH(x * w, y * h, rw * w, rh * h),
          Paint()..color = c,
        );
    const red = Color(0xffe82138), navy = Color(0xff032975);
    canvas.drawColor(Colors.white, BlendMode.srcOver);
    if (code == 'gb' || code == 'au') {
      rect(0, 0, 1, 1, navy);
      final p = Paint()
        ..color = Colors.white
        ..strokeWidth = w * .19;
      canvas.drawLine(Offset.zero, Offset(w, h), p);
      canvas.drawLine(Offset(w, 0), Offset(0, h), p);
      p
        ..color = red
        ..strokeWidth = w * .075;
      canvas.drawLine(Offset.zero, Offset(w, h), p);
      canvas.drawLine(Offset(w, 0), Offset(0, h), p);
      rect(.36, 0, .28, 1, Colors.white);
      rect(0, .36, 1, .28, Colors.white);
      rect(.42, 0, .16, 1, red);
      rect(0, .42, 1, .16, red);
    } else if (code == 'us') {
      for (var i = 0; i < 13; i++) {
        rect(0, i / 13, 1, 1 / 13, i.isEven ? red : Colors.white);
      }
      rect(0, 0, .5, .54, navy);
      for (var i = 0; i < 5; i++) {
        for (var j = 0; j < 5; j++) {
          canvas.drawCircle(
            Offset(w * (.04 + j * .1), h * (.05 + i * .105)),
            w * .018,
            Paint()..color = Colors.white,
          );
        }
      }
    } else if (code == 'fr') {
      rect(0, 0, 1 / 3, 1, navy);
      rect(2 / 3, 0, 1 / 3, 1, red);
    } else if (code == 'cn') {
      rect(0, 0, 1, 1, const Color(0xffe51f00));
      final t = TextPainter(
        text: TextSpan(
          text: '★',
          style: TextStyle(color: Colors.yellow, fontSize: w * .38),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, Offset(w * .1, h * .12));
    } else if (code == 'in') {
      rect(0, 0, 1, 1 / 3, const Color(0xffff9933));
      rect(0, 2 / 3, 1, 1 / 3, const Color(0xff088800));
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * .12,
        Paint()
          ..color = navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    } else if (code == 'at') {
      rect(0, 0, 1, 1 / 3, red);
      rect(0, 2 / 3, 1, 1 / 3, red);
    } else if (code == 'by') {
      rect(0, 0, 1, .67, const Color(0xffc63040));
      rect(0, .67, 1, .33, const Color(0xff009c57));
      rect(.05, 0, .14, 1, Colors.white);
    } else if (code == 'cy') {
      final t = TextPainter(
        text: TextSpan(
          text: '◆',
          style: TextStyle(color: Colors.orange, fontSize: w * .6),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, Offset(w * .2, h * .15));
    } else {
      rect(0, 0, 1, .5, navy);
      rect(0, .5, 1, .5, red);
    }
  }

  @override
  bool shouldRepaint(FlagPainter oldDelegate) => oldDelegate.code != code;
}

/// Desktop/web-only interactive keyboard. Native builds use the OS keyboard.
class PreviewKeyboard extends StatelessWidget {
  const PreviewKeyboard({
    super.key,
    required this.controller,
    required this.scale,
    required this.onDone,
    this.numeric = false,
    this.email = false,
    this.search = false,
    this.suggestion,
  });
  final TextEditingController controller;
  final double scale;
  final bool numeric, email, search;
  final String? suggestion;
  final VoidCallback onDone;
  void type(String value) {
    if (value == '⌫') {
      if (controller.text.isNotEmpty) {
        controller.text = controller.text.substring(
          0,
          controller.text.length - 1,
        );
      }
    } else if (value != '⇧' && value != '123') {
      controller.text += value == 'space' ? ' ' : value;
    }
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  Widget keyboardKey(
    String label, {
    int flex = 1,
    Color? color,
    String? small,
  }) => Expanded(
    flex: flex,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 3 * scale),
      child: SizedBox(
        height: (numeric ? 47 : 43) * scale,
        child: TextButton(
          onPressed: label == 'search' || label == 'return'
              ? onDone
              : () => type(label),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: color ?? Colors.white,
            foregroundColor: color == const Color(0xff087bfa)
                ? Colors.white
                : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5 * scale),
            ),
            shadowColor: const Color(0xff777b80),
            elevation: 1,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (label == '⌫' || label == '⇧') Icon(label == '⌫' ? Icons.backspace_outlined : Icons.arrow_upward_rounded, size: 24*scale)
              else Text(
                label,
                style: TextStyle(
                  fontFamily: 'ReplicaSans',
                  fontSize: (label.length > 2 ? 17 : 24) * scale,
                  height: 1,
                ),
              ),
              if (small != null)
                Text(
                  small,
                  style: TextStyle(
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    height: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xffd1d4dc),
    child: SizedBox(
      height: (numeric || suggestion != null ? 336 : 291) * scale,
      child: Column(
        children: [
          if (suggestion != null)
            SizedBox(
              height: 51 * scale,
              child: Center(
                child: Text(
                  suggestion!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: (numeric ? 16 : 18) * scale,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          SizedBox(height: 8 * scale),
          if (numeric) ...[
            for (var row = 0; row < 3; row++) ...[
              Row(
                children: List.generate(3, (col) {
                  final n = row * 3 + col + 1;
                  return keyboardKey(
                    '$n',
                    small: n == 1
                        ? ' '
                        : [
                            '',
                            '',
                            'ABC',
                            'DEF',
                            'GHI',
                            'JKL',
                            'MNO',
                            'PQRS',
                            'TUV',
                            'WXYZ',
                          ][n],
                  );
                }),
              ),
              SizedBox(height: 7 * scale),
            ],
            Row(
              children: [
                keyboardKey('+ * #', color: const Color(0xffd1d4dc)),
                keyboardKey('0'),
                keyboardKey('⌫', color: const Color(0xffd1d4dc)),
              ],
            ),
          ] else ...[
            Row(
              children: 'qwertyuiop'
                  .split('')
                  .map((c) => keyboardKey(c))
                  .toList(),
            ),
            SizedBox(height: 12 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18 * scale),
              child: Row(
                children: 'asdfghjkl'
                    .split('')
                    .map((c) => keyboardKey(c))
                    .toList(),
              ),
            ),
            SizedBox(height: 12 * scale),
            Row(
              children: [
                keyboardKey('⇧', color: const Color(0xffa9aeb8)),
                SizedBox(width: 8 * scale),
                ...'zxcvbnm'.split('').map((c) => keyboardKey(c)),
                SizedBox(width: 8 * scale),
                keyboardKey('⌫', color: const Color(0xffa9aeb8)),
              ],
            ),
            SizedBox(height: 12 * scale),
            Row(
              children: [
                keyboardKey('123', flex: 3, color: const Color(0xffa9aeb8)),
                keyboardKey('space', flex: email ? 3 : 6),
                if (email) ...[keyboardKey('@'), keyboardKey('.')],
                keyboardKey(
                  search ? 'search' : 'return',
                  flex: 3,
                  color: search
                      ? const Color(0xff087bfa)
                      : const Color(0xffa9aeb8),
                ),
              ],
            ),
            SizedBox(height: 20 * scale),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    CupertinoIcons.smiley,
                    size: 28 * scale,
                    color: const Color(0xff565e65),
                  ),
                  if (!email)
                    Icon(
                      CupertinoIcons.mic,
                      size: 28 * scale,
                      color: const Color(0xff565e65),
                    ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Container(
            width: 134 * scale,
            height: 5 * scale,
            margin: EdgeInsets.only(bottom: 8 * scale),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ),
  );
}
