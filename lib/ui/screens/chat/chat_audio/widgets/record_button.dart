import 'dart:async';
import 'dart:io';

import 'package:tlobni/ui/screens/chat/chat_audio/audio_state.dart';
import 'package:tlobni/ui/screens/chat/chat_audio/globals.dart';
import 'package:tlobni/ui/screens/chat/chat_audio/widgets/flow_shader.dart';
import 'package:tlobni/ui/screens/chat/chat_audio/widgets/lottie_animation.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';

class RecordButton extends StatefulWidget {
  const RecordButton(
      {super.key,
      required this.controller,
      required this.callback,
      required this.isSending});

  final AnimationController controller;
  final Function(dynamic path)? callback;
  final bool isSending;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  static const double size = 43;

  final double lockerHeight = 200;
  double timerWidth = 0;

  late Animation<double> buttonScaleAnimation;
  late Animation<double> timerAnimation;
  late Animation<double> lockerAnimation;

  DateTime? startTime;
  Timer? timer;
  String recordDuration = "00:00";
  final record = AudioRecorder();

  bool isLocked = false;
  bool showLottie = false;

  @override
  void initState() {
    super.initState();
    buttonScaleAnimation = Tween<double>(begin: 1, end: 2).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticInOut),
      ),
    );
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    timerWidth =
        MediaQuery.of(context).size.width - 2 * ChatGlobals.defaultPadding - 4;
    timerAnimation =
        Tween<double>(begin: timerWidth + ChatGlobals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
    lockerAnimation =
        Tween<double>(begin: lockerHeight + ChatGlobals.defaultPadding, end: 0)
            .animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: const Interval(0.2, 1, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    record.dispose();
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        (timer?.isActive ?? false) ? lockSlider() : const SizedBox.shrink(),
        (timer?.isActive ?? false) ? cancelSlider() : const SizedBox.shrink(),
        audioButton(),
        if (isLocked) timerLocked(),
      ],
    );
  }

  Widget lockSlider() {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      bottom: -lockerAnimation.value,
      child: Container(
        height: lockerHeight,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
          color: context.color.secondaryColor,
          //color: Colors.black,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            //const FaIcon(FontAwesomeIcons.lock, size: 20),
            const Icon(Icons.lock, size: 20),
            const SizedBox(height: 8),
            FlowShader(
              direction: Axis.vertical,
              child: const Column(
                children: [
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                  Icon(Icons.keyboard_arrow_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cancelSlider() {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      end: -timerAnimation.value,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
          color: context.color.primaryColor,
          //color: Colors.black,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              showLottie ? const LottieAnimation() : CustomText(recordDuration),
              FlowShader(
                duration: const Duration(seconds: 3),
                flowColors: [
                  context.color.territoryColor,
                  const Color(0xFF9E9E9E)
                ],
                child: Row(
                  children: [
                    const Icon(Icons.keyboard_arrow_left),
                    CustomText("slidetocancel".translate(context)),
                    const SizedBox(
                      width: 10,
                    ),
                  ],
                ),
                //flowColors: const [Colors.white, Colors.grey],
              ),
              const SizedBox(width: size),
            ],
          ),
        ),
      ),
    );
  }

  Widget timerLocked() {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      end: 0,
      child: Container(
        height: size,
        width: timerWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChatGlobals.borderRadius),
          color: context.color.secondaryColor,
          //color: Colors.black,
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: 15, end: 25),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              saveFile();
              setState(() {
                isLocked = false;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomText(recordDuration),
                const SizedBox(
                  width: 5,
                ),
                FlowShader(
                  duration: const Duration(seconds: 3),
                  flowColors: [context.color.territoryColor, Colors.grey],
                  child: CustomText("taploacktostop".translate(context)),
                  //flowColors: const [Colors.white, Colors.grey],
                ),
                const Center(
                  child: Icon(
                    Icons.lock,
                    size: 18,
                    color: Colors.green,
                  ),
                  /*  child: FaIcon(
                    FontAwesomeIcons.lock,
                    size: 18,
                    color: Colors.green,
                  ), */
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget audioButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.isSending) return;
        // Check if the app has permission to record audio
        bool hasPermission = await record.hasPermission();

        // Request permission to record audi
        if (hasPermission) {
          // Permission denied, handle accordingly (show a message, etc.)
          return;
        }

        // Start recording audio
        //await startRecording();
      },
      child: Transform.scale(
        scale: buttonScaleAnimation.value,
        child: Container(
          height: size,
          width: size,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.color.territoryColor,
          ),
          child: widget.isSending
              ? CircularProgressIndicator()
              : Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
        ),
      ),
      onLongPressDown: (_) {
        if (widget.isSending) return;

        widget.controller.forward();
      },
      onLongPressEnd: (details) async {
        if (widget.isSending) return;

        if (isCancelled(details.localPosition, context)) {
          // if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.heavy);
          if (await Vibration.hasVibrator() != null) {
            Vibration.vibrate();
          }
          timer?.cancel();
          timer = null;
          //startTime = null;
          recordDuration = "00:00";

          setState(() {
            showLottie = true;
          });

          Timer(const Duration(milliseconds: 1440), () async {
            widget.controller.reverse();

            var filePath = await record.stop();
            debugPrint(filePath);
            File(filePath!).delete();
            showLottie = false;
          });
        } else if (checkIsLocked(details.localPosition)) {
          widget.controller.reverse();

          //if (await Vibrate.canVibrate) Vibrate.feedback(FeedbackType.heavy);
          if (await Vibration.hasVibrator() != null) {
            Vibration.vibrate();
          }
          debugPrint(details.localPosition.dy.toString());
          setState(() {
            isLocked = true;
          });
        } else {
          widget.controller.reverse();
          saveFile();
        }
      },
      onLongPressCancel: () {
        if (widget.isSending) return;
        debugPrint("onLongPressCancel");
        widget.controller.reverse();
      },
      onLongPress: () async {
        if (widget.isSending) return;
        if (await Vibration.hasVibrator() != null) {
          Vibration.vibrate();
        }
        await startRecording();
      },
    );
  }

  Future<void> startRecording() async {
    if (await record.hasPermission()) {
      // Start recording to file

      String documentPath =
          "${(await getApplicationDocumentsDirectory()).path}/";
      await record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path:
            "${documentPath}audio_${DateTime.now().millisecondsSinceEpoch}.mp3",
      );
      startTime = DateTime.now();

      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final minDur = DateTime.now().difference(startTime!).inMinutes;
        final secDur = DateTime.now().difference(startTime!).inSeconds % 60;
        String min = minDur < 10 ? "0$minDur" : minDur.toString();
        String sec = secDur < 10 ? "0$secDur" : secDur.toString();

        setState(() {
          recordDuration = "$min:$sec";
        });
      });
    }
  }

  Future<void> saveFile() async {
    if (await Vibration.hasVibrator() != null) {
      Vibration.vibrate();
    }
    timer?.cancel();
    timer = null;
    startTime = null;
    recordDuration = "00:00";

    var filePath = await record.stop();
    AudioState.files.add(filePath!);
    if (ChatGlobals.audioListKey.currentState != null) {
      ChatGlobals.audioListKey.currentState!
          .insertItem(AudioState.files.length - 1);
    }
    debugPrint(filePath);

    // if (widget.callback != Null) {
    final fileAudio = File(filePath);
    widget.callback!(fileAudio.path);
    //}
  }

  bool checkIsLocked(Offset offset) {
    return (offset.dy < -35);
  }

  bool isCancelled(Offset offset, BuildContext context) {
    return (offset.dx < -(MediaQuery.of(context).size.width * 0.2));
  }
}
