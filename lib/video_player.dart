import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {

  late Size size;
  late YoutubePlayerController _controller;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  late PlayerState _playerState;
  late YoutubeMetaData _videoMetaData;
  double _volume = 100;
  bool _muted = false;
  bool _isPlayerReady = false;
  late String videoId;


  final List<String> _ids = [
    'HrmWAdF_s6Y',
    'oPmhE_EmLjk',
    'NSh8hgXfaEU',
    's25hNv8UPKo',

  ];

  @override
  void initState() {
    super.initState();
    videoId = YoutubePlayer.convertUrlToId("https://www.youtube.com/watch?v=Dw1BhP7WJbo")!;
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(listener);
    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    print(videoId);
    return YoutubePlayerBuilder(
      onEnterFullScreen: (){
        print("Full Screen Entered");
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      },
      onExitFullScreen: () {
        print("Full Screen Exited");
        // The player forces portraitUp after exiting fullscreen. This overrides the behaviour.
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        progressColors: ProgressBarColors(
          playedColor: Color(0xFFFE0002),
          handleColor: Colors.white,
          backgroundColor: Colors.black38,
        ),
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

        ],
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          _controller
              .load(_ids[(_ids.indexOf(data.videoId) + 1) % _ids.length]);
          _showSnackBar('Next Video Started!');
        },
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/playerLogo.png',
                height: 40.0,
                width: 40.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  'Youtube Player Flutter',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold ),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFFE0002),

        ),
        body: Container(
          height: size.height,
          width: size.width,
          decoration: BoxDecoration(
            color: Colors.black,
          ),
          child: Center(
            child: ListView(
              shrinkWrap: true,
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.skip_previous),
                            onPressed: _isPlayerReady
                                ? () => _controller.load(_ids[
                            (_ids.indexOf(_controller.metadata.videoId) -
                                1) %
                                _ids.length])
                                : null,
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            onPressed: _isPlayerReady
                                ? () {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                              setState(() {});
                            }
                                : null,
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.skip_next),
                            onPressed: _isPlayerReady
                                ? () => _controller.load(_ids[
                            (_ids.indexOf(_controller.metadata.videoId) +
                                1) %
                                _ids.length])
                                : null,
                          ),

                          FullScreenButton(
                            controller: _controller,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      _space,
                      Row(
                        children: <Widget>[
                          IconButton(
                            color: Colors.white,
                            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                            onPressed: _isPlayerReady
                                ? () {
                              _muted
                                  ? _controller.unMute()
                                  : _controller.mute();
                              setState(() {
                                _muted = !_muted;
                              });
                            }
                                : null,
                          ),
                          Expanded(
                            child: CupertinoSlider(
                              activeColor: Color(0xFFFE0002),
                              thumbColor: Colors.white,
                              value: _volume,
                              min: 0.0,
                              max: 100.0,


                              onChanged: _isPlayerReady
                                  ? (value) {
                                setState(() {
                                  _volume = value;
                                });
                                _controller.setVolume(_volume.round());
                              }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      _space,
                      AnimatedContainer(
                        margin: const EdgeInsets.only(top: 50.0),
                        duration: const Duration(milliseconds: 800),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: _getStateColor(_playerState),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _playerState.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStateColor(PlayerState state) {
    switch (state) {

      case PlayerState.ended:
        return Color(0xff36633F);
      case PlayerState.playing:
        return Color(0xFFFE0002);
      case PlayerState.paused:
        return Color(0xffF7D715);
      case PlayerState.buffering:
        return Color(0xff165EAA);

      default:
        return Colors.blue;
    }
  }
  Widget get _space => const SizedBox(height: 10);
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(0x00000000),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 80.0),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }

  Widget get height => const SizedBox(height: 100)
}
