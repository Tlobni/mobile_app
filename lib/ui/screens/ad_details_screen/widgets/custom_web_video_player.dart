import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class CustomWebVideoPlayer extends StatefulWidget {
  const CustomWebVideoPlayer(this.videoUrl, {super.key});

  final String videoUrl;

  @override
  State<CustomWebVideoPlayer> createState() => _CustomWebVideoPlayerState();
}

class _CustomWebVideoPlayerState extends State<CustomWebVideoPlayer> {
  late final VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
    ..addListener(() => setState(() {}));

  bool _init = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color.lerp(context.color.primary, Colors.white, 0.2) ?? Colors.transparent),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Builder(builder: (context) {
        if (controller.value.isBuffering) {
          return _loading();
        }
        if (controller.value.isPlaying) {
          if (!controller.value.isInitialized) return _loading();
          return _playing();
        }
        return _initial();
      }),
    );
  }

  Future<void> _initVideo() async {
    await controller.initialize();
    await controller.setLooping(true);
    _init = true;
  }

  void _playVideo() async {
    launchUrlString(widget.videoUrl);
    //todo continue
    // if (controller.value.isPlaying) return;
    // if (!_init) await _initVideo();
    // await controller.seekTo(Duration.zero);
    // await controller.play();
  }

  void _pauseVideo() async {
    await controller.pause();
  }

  Widget _initial() {
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(context.color.primary, Colors.white, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: GestureDetector(
          onTap: _playVideo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.color.secondary.withValues(alpha: 0.5),
                  border: Border.all(color: context.color.secondary),
                ),
                padding: EdgeInsets.all(10),
                child: Icon(Icons.play_arrow_outlined, color: Colors.white, size: 30),
              ),
              SizedBox(height: 10),
              SmallText('Watch Video', color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiUtils.progress(),
        ],
      );

  Widget _playing() => GestureDetector(onTap: _pauseVideo, child: VideoPlayer(controller));
}
