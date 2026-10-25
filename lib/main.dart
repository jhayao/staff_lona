import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components.dart';

void main() => runApp(const MyApp());

enum ReferenceScreen {
  launch('Launch screen'),
  ready('Ready to change'),
  pay('Pay at home and away'),
  invest('Invest your way'),
  loading('Loading'),
  welcome('Welcome back'),
  countries('Country picker'),
  noCountries('Country search: usa'),
  filteredCountries('Country search: us'),
  phone('Phone recovery'),
  email('Email recovery'),
  filledEmail('Email entered');

  const ReferenceScreen(this.label);
  final String label;
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialScreen,
    this.autoAdvance = true,
    this.showReviewPanel = true,
    this.captureKey,
    this.simulateDevice,
  });
  final ReferenceScreen? initialScreen;
  final bool autoAdvance, showReviewPanel;
  final GlobalKey? captureKey;
  final bool? simulateDevice;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Revolut · reference flow',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'ReplicaSans',
      scaffoldBackgroundColor: pageColor,
      colorScheme: const ColorScheme.light(
        primary: blue,
        surface: pageColor,
        onSurface: ink,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: blue,
        selectionColor: Color(0xffb6d4fc),
      ),
    ),
    home: ReferenceFlow(
      initialScreen: initialScreen,
      autoAdvance: autoAdvance,
      showReviewPanel: showReviewPanel,
      captureKey: captureKey,
      simulateDevice: simulateDevice,
    ),
  );
}

class ReferenceFlow extends StatefulWidget {
  const ReferenceFlow({
    super.key,
    this.initialScreen,
    required this.autoAdvance,
    required this.showReviewPanel,
    this.captureKey,
    this.simulateDevice,
  });
  final ReferenceScreen? initialScreen;
  final bool autoAdvance, showReviewPanel;
  final GlobalKey? captureKey;
  final bool? simulateDevice;
  @override
  State<ReferenceFlow> createState() => _ReferenceFlowState();
}

class _ReferenceFlowState extends State<ReferenceFlow> {
  late ReferenceScreen screen;
  Timer? timer;
  final phone = TextEditingController(), email = TextEditingController();
  final phoneFocus = FocusNode(), emailFocus = FocusNode();
  Country country = countries.first;
  bool busy = false;
  bool get simulated =>
      widget.simulateDevice ?? (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android));
  @override
  void initState() {
    super.initState();
    final q = int.tryParse(Uri.base.queryParameters['screen'] ?? '');
    screen =
        widget.initialScreen ??
        (q != null && q > 0 && q <= 12
            ? ReferenceScreen.values[q - 1]
            : ReferenceScreen.launch);
    seed();
    if (screen == ReferenceScreen.launch && widget.autoAdvance) {
      timer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) go(ReferenceScreen.ready);
      });
    }
  }

  void seed() {
    if (screen == ReferenceScreen.filledEmail) email.text = 'alex@example.com';
    if (screen == ReferenceScreen.email) email.clear();
  }

  void go(ReferenceScreen value) {
    timer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      screen = value;
      seed();
    });
    if (!simulated && value.index >= 9) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          (value == ReferenceScreen.phone ? phoneFocus : emailFocus)
              .requestFocus();
        }
      });
    }
  }

  void back() {
    if (screen == ReferenceScreen.launch) return;
    if (screen.index <= 4) {
      go(ReferenceScreen.values[screen.index - 1]);
      return;
    }
    go(
      screen.index >= 10
          ? ReferenceScreen.phone
          : screen == ReferenceScreen.welcome
          ? ReferenceScreen.ready
          : ReferenceScreen.welcome,
    );
  }

  Future<void> notice(String title, String body) => showCupertinoDialog<void>(
    context: context,
    builder: (c) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(c),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  Future<void> submit() async {
    if (busy) return;
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => busy = false);
    await notice(
      'Preview complete',
      'This is a local screen recreation. No verification message was sent.',
    );
  }

  Future<void> picker() async {
    final value = await showCupertinoModalPopup<Country>(
      context: context,
      builder: (c) => CountrySheet(
        selected: country,
        simulated: simulated,
        onCancel: () => Navigator.pop(c),
        onSelect: (v) => Navigator.pop(c, v),
      ),
    );
    if (mounted && value != null) setState(() => country = value);
  }

  @override
  void dispose() {
    timer?.cancel();
    phone.dispose();
    email.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth >= 850 && widget.showReviewPanel;
      final app = RepaintBoundary(
        key: widget.captureKey,
        child: SizedBox(
          width: wide ? 390 : bounds.maxWidth,
          height: wide
              ? math.min(844, bounds.maxHeight - 48)
              : bounds.maxHeight,
          child: PopScope(
            canPop: screen == ReferenceScreen.launch,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) back();
            },
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): back,
                const SingleActivator(
                  LogicalKeyboardKey.arrowRight,
                  alt: true,
                ): () =>
                    go(ReferenceScreen.values[(screen.index + 1) % 12]),
                const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
                    back,
              },
              child: Focus(autofocus: true, child: buildScreen()),
            ),
          ),
        ),
      );
      if (!wide) return app;
      return Scaffold(
        backgroundColor: const Color(0xffe8e9eb),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 270,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revolut',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'REFERENCE FLOW / 12 STATES',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final v in ReferenceScreen.values)
                      TextButton(
                        onPressed: () => go(v),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: v == screen ? blue : ink,
                          minimumSize: const Size(double.infinity, 44),
                          backgroundColor: v == screen
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        child: Text(
                          '${(v.index + 1).toString().padLeft(2, '0')}   ${v.label}',
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Local prototype · no live authentication\nAlt + ← / → to inspect states',
                      style: TextStyle(color: muted, fontSize: 12, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(borderRadius: BorderRadius.circular(32), child: app),
            const SizedBox(width: 48),
          ],
        ),
      );
    },
  );

  Widget buildScreen() {
    if (screen.index >= 6 && screen.index <= 8) {
      return ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            if (simulated)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: PreviewStatusBar(light: true),
              ),
            Positioned.fill(
              top: 54,
              child: CountrySheet(
                key: ValueKey(screen),
                selected: country,
                simulated: simulated,
                embedded: true,
                initialQuery: screen == ReferenceScreen.noCountries
                    ? 'usa'
                    : screen == ReferenceScreen.filteredCountries
                    ? 'us'
                    : '',
                onCancel: () => go(ReferenceScreen.welcome),
                onSelect: (v) {
                  setState(() => country = v);
                  go(ReferenceScreen.welcome);
                },
              ),
            ),
          ],
        ),
      );
    }
    if (screen.index <= 4) return intro();
    final recovery = screen == ReferenceScreen.phone,
        isEmail = screen.index >= 10;
    final controller = isEmail ? email : phone;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final valid = isEmail
            ? RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text)
            : phone.text.replaceAll(RegExp(r'\D'), '').length >= 7;
        return PhoneCanvas(
          simulated: simulated,
          child: LayoutBuilder(
            builder: (context, box) {
              final s = box.maxWidth / 375, h = box.maxHeight / s;
              final keyboard = simulated && (recovery || isEmail);
              Widget pos(double y, Widget child) => Positioned(
                top: y * s,
                left: 16 * s,
                right: 16 * s,
                child: child,
              );
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  height: math.max(h, keyboard ? 710 : 640) * s,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 44 * s,
                        left: 8 * s,
                        right: 8 * s,
                        child: ReferenceNav(
                          onBack: back,
                          onHelp: !recovery && !isEmail
                              ? () => notice(
                                  'Need help?',
                                  'Use your phone number or verified email to explore recovery. This preview does not connect to Revolut.',
                                )
                              : null,
                        ),
                      ),
                      pos(
                        91,
                        Text(
                          isEmail
                              ? 'Enter your email'
                              : recovery
                              ? 'Enter phone\nnumber'
                              : 'Welcome back',
                          style: TextStyle(
                            fontSize: 34 * s,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                            letterSpacing: -.5 * s,
                            color: ink,
                          ),
                        ),
                      ),
                      pos(
                        recovery ? 178 : 140,
                        Text(
                          isEmail
                              ? 'Enter the email used with your Revolut account. You can recover access only if your email is verified'
                              : recovery
                              ? 'Make sure it’s the number you use with the Revolut account you lost access to'
                              : 'Enter the phone number associated with your Revolut account',
                          style: TextStyle(
                            fontSize: 14 * s,
                            height: 1.45,
                            color: muted,
                          ),
                        ),
                      ),
                      pos(
                        isEmail
                            ? 215
                            : recovery
                            ? 248
                            : 203,
                        isEmail
                            ? ReplicaField(
                                controller: email,
                                focusNode: emailFocus,
                                hint: 'example@mail.com',
                                scale: s,
                                focused: true,
                                keyboardType: TextInputType.emailAddress,
                                obscureFixture:
                                    screen == ReferenceScreen.filledEmail,
                                onSubmitted: valid ? (_) => submit() : null,
                              )
                            : Row(
                                children: [
                                  SizedBox(
                                    width: 94 * s,
                                    child: CountryButton(
                                      country: country,
                                      scale: s,
                                      onPressed: picker,
                                    ),
                                  ),
                                  SizedBox(width: 8 * s),
                                  Expanded(
                                    child: ReplicaField(
                                      controller: phone,
                                      focusNode: phoneFocus,
                                      hint: recovery
                                          ? 'Mobile number'
                                          : 'Enter your phone',
                                      scale: s,
                                      focused: recovery,
                                      keyboardType: TextInputType.phone,
                                      onSubmitted: valid
                                          ? (_) => submit()
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      if (!isEmail && !recovery) ...[
                        pos(
                          278,
                          LinkAction(
                            'Lost access to my phone number',
                            onPressed: () => go(ReferenceScreen.phone),
                            scale: s,
                            align: Alignment.centerLeft,
                          ),
                        ),
                        pos(
                          332,
                          PillButton(
                            'Continue',
                            scale: s,
                            onPressed: valid ? submit : null,
                            busy: busy,
                          ),
                        ),
                        pos(
                          399,
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xffdfe2e5)),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16 * s,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    fontSize: 17 * s,
                                    color: muted,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xffdfe2e5)),
                              ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < 3; i++)
                          pos(
                            438 + i * 68,
                            PillButton(
                              [
                                'Continue with email',
                                'Continue with Google',
                                'Continue with Apple',
                              ][i],
                              scale: s,
                              background: Colors.white,
                              foreground: ink,
                              icon: i == 0
                                  ? Icons.email_rounded
                                  : i == 2
                                  ? Icons.apple
                                  : null,
                              leading: i == 1
                                  ? const Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xff4285f4),
                                      ),
                                    )
                                  : null,
                              onPressed: i == 0
                                  ? () => go(ReferenceScreen.email)
                                  : () => notice(
                                      'Local preview',
                                      'Provider authentication is not connected. Continue with email to inspect recovery.',
                                    ),
                            ),
                          ),
                      ],
                      if (recovery) ...[
                        pos(
                          332,
                          PillButton(
                            'Continue',
                            scale: s,
                            onPressed: valid ? submit : null,
                            busy: busy,
                          ),
                        ),
                        pos(
                          405,
                          LinkAction(
                            'Forgot your phone number?',
                            onPressed: () => go(ReferenceScreen.email),
                            scale: s,
                          ),
                        ),
                      ],
                      if (isEmail)
                        Positioned(
                          top: keyboard
                              ? (screen == ReferenceScreen.filledEmail
                                        ? h - 367
                                        : h - 412) *
                                    s
                              : null,
                          bottom: keyboard ? null : 24 * s,
                          left: 16 * s,
                          right: 16 * s,
                          child: PillButton(
                            'Continue',
                            scale: s,
                            onPressed: valid ? submit : null,
                            busy: busy,
                            glow: valid,
                          ),
                        ),
                      if (keyboard)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: PreviewKeyboard(
                            controller: controller,
                            scale: s,
                            numeric: recovery,
                            email: isEmail,
                            suggestion: recovery
                                ? 'mobile\n+1 (415) 209-6798'
                                : screen == ReferenceScreen.email
                                ? 'Hide My Email'
                                : null,
                            onDone: valid ? submit : () {},
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget intro() {
    final launch = screen == ReferenceScreen.launch,
        pay = screen == ReferenceScreen.pay,
        loading = screen == ReferenceScreen.loading;
    final dark = !launch && !pay, color = dark ? Colors.white : ink;
    void next() => go(ReferenceScreen.values[math.min(screen.index + 1, 5)]);
    return PhoneCanvas(
      simulated: simulated,
      dark: dark,
      child: LayoutBuilder(
        builder: (context, box) {
          final s = box.maxWidth / 375, h = box.maxHeight / s;
          if (launch) {
            return Semantics(
              label: 'Revolut launch screen. Activate to continue.',
              button: true,
              child: InkWell(
                onTap: next,
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: Image.asset(
                      'assets/art/wordmark.webp',
                      width: 218 * s,
                      semanticLabel: 'Revolut',
                    ),
                  ),
                ),
              ),
            );
          }
          return GestureDetector(
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -50) next();
              if ((d.primaryVelocity ?? 0) > 50) back();
            },
            child: Stack(
              children: [
                if (screen == ReferenceScreen.ready) ...[
                  const Positioned.fill(
                    child: CustomPaint(painter: StreakPainter()),
                  ),
                  Positioned(
                    top: 216.67 * s,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/art/ready.webp',
                      fit: BoxFit.fitWidth,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
                if (pay)
                  Positioned(
                    left: 21.67 * s,
                    right: 21.67 * s,
                    top: 283.33 * s,
                    child: Image.asset(
                      'assets/art/cards.webp',
                      excludeFromSemantics: true,
                    ),
                  ),
                if (screen == ReferenceScreen.invest)
                  Positioned(
                    top: 226.67 * s,
                    left: 83.33 * s,
                    width: 200 * s,
                    child: Image.asset(
                      'assets/art/invest.webp',
                      excludeFromSemantics: true,
                    ),
                  ),
                Positioned(
                  top: 52 * s,
                  left: 8 * s,
                  right: 8 * s,
                  child: Row(
                    children: List.generate(
                      6,
                      (i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 5 ? 0 : 2 * s),
                          child: Container(
                            height: 2 * s,
                            color: loading
                                ? ink
                                : i <=
                                      (pay
                                          ? 1
                                          : screen == ReferenceScreen.invest
                                          ? 3
                                          : 0)
                                ? color
                                : color.withValues(alpha: .24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 63 * s,
                  left: 12 * s,
                  child: Row(
                    children: [
                      Text(
                      'R',
                        style: TextStyle(
                          color: loading ? ink : color,
                          fontSize: 25 * s,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 12 * s),
                      Text(
                        'Welcome to Revolut',
                        style: TextStyle(
                          color: loading ? ink : color,
                          fontSize: 16 * s,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 103 * s,
                  left: 24 * s,
                  right: 16 * s,
                  child: Text(
                    pay
                        ? 'EASY TO PAY AT\nHOME AND AWAY'
                        : screen == ReferenceScreen.invest
                        ? 'INVEST YOUR WAY,\nFROM \$1'
                        : loading
                        ? 'YOUR MONEY,\nPROTECTED —\nPERIOD.'
                        : 'READY TO CHANGE\nTHE WAY YOU\nMONEY?',
                    style: TextStyle(
                      color: loading ? const Color(0xff101317) : color,
                      fontSize: 31 * s,
                      fontWeight: FontWeight.w900,
                      height: 1.17,
                      letterSpacing: -.25 * s,
                    ),
                  ),
                ),
                if (pay || screen == ReferenceScreen.invest)
                  Positioned(
                    top: 191 * s,
                    left: 24 * s,
                    right: 16 * s,
                    child: Text(
                      pay
                          ? 'Some cards available on paid plans only'
                          : 'Capital at risk',
                      style: TextStyle(
                        fontSize: 16 * s,
                        color: pay
                            ? const Color(0xff505253)
                            : const Color(0xffbdbdbd),
                      ),
                    ),
                  ),
                if (loading)
                  Positioned(
                    top: h / 2 * s - 14,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: .78,
                          color: blue,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 215 * s,
                  bottom: (h - 695) * s,
                  child: Semantics(
                    label: 'Next walkthrough screen',
                    button: true,
                    child: InkWell(
                      onTap: next,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),
                Positioned(
                  left: 16 * s,
                  right: 16 * s,
                  bottom: 58 * s,
                  child: Row(
                    children: [
                      Expanded(
                        child: PillButton(
                          'Log in',
                          scale: s,
                          onPressed: () => go(ReferenceScreen.welcome),
                          background: const Color(0xff111419),
                          foreground: Colors.white,
                          glow: pay,
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      Expanded(
                        child: PillButton(
                          'Sign up',
                          scale: s,
                          onPressed: () => notice(
                            'Sign up',
                            'The supplied screens cover sign-in and recovery. Account creation is outside this local preview.',
                          ),
                          background: Colors.white,
                          foreground: ink,
                          glow: pay,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReplicaField extends StatelessWidget {
  const ReplicaField({
    super.key,
    required this.controller,
    required this.hint,
    required this.scale,
    this.focusNode,
    this.focused = false,
    this.obscureFixture = false,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final double scale;
  final bool focused, obscureFixture;
  final TextInputType keyboardType;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) {
    final input = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: blue,
      cursorWidth: 2,
      style: TextStyle(fontSize: 16 * scale, color: ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: muted),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 18 * scale,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear',
                onPressed: controller.clear,
                icon: Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: const Color(0xffb2b7bd),
                  size: 20 * scale,
                ),
              )
            : null,
      ),
    );
    return Container(
      height: 60 * scale,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: focused ? focusedField : fieldColor,
        borderRadius: BorderRadius.circular(18 * scale),
      ),
      child: obscureFixture
          ? Stack(
              children: [
                Opacity(opacity: 0, child: input),
                Positioned(
                  left: 16 * scale,
                  top: 22 * scale,
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Text(
                        controller.text,
                        style: TextStyle(fontSize: 16 * scale, color: muted),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    tooltip: 'Clear email',
                    onPressed: controller.clear,
                    icon: const Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: Color(0xffb2b7bd),
                    ),
                  ),
                ),
              ],
            )
          : input,
    );
  }
}
