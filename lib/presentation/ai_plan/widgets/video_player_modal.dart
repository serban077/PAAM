import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerModal extends StatefulWidget {
  final String videoUrl;
  final String exerciseName;

  const VideoPlayerModal({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
  });

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late YoutubePlayerController _controller;
  bool _hasError = false;
  String _errorMessage = '';


  @override
  void initState() {
    super.initState();
    
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          isLive: false,
          forceHD: false,
          hideControls: false,
        ),
      );
    } else {
      // Fallback for invalid URL
      _controller = YoutubePlayerController(
        initialVideoId: 'dQw4w9WgXcQ', // Placeholder video
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openInYouTube() async {
    final Uri url = Uri.parse(widget.videoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nu se poate deschide YouTube')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(2.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exerciseName,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Video player
          YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Theme.of(context).primaryColor,
              progressColors: ProgressBarColors(
                playedColor: Theme.of(context).primaryColor,
                handleColor: Theme.of(context).primaryColor,
              ),
              onReady: () {
                print('YouTube player is ready');
                if (mounted) {
                  setState(() {
                    _hasError = false;
                  });
                }
              },
              onEnded: (metaData) {
                print('Video ended');
              },
            ),
            builder: (context, player) {
              return Column(
                children: [
                  player,
                  // Error message if video can't be played
                  if (_controller.value.hasError || _hasError)
                    Container(
                      margin: EdgeInsets.all(2.h),
                      padding: EdgeInsets.all(2.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  'Acest videoclip nu poate fi redat în aplicație',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Proprietarul videoclipului a restricționat redarea în aplicații externe.',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 1.5.h),
                          ElevatedButton.icon(
                            onPressed: _openInYouTube,
                            icon: const Icon(Icons.open_in_new),
                            label: Text(
                              'Deschide în YouTube',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 1.5.h,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          
          // Instructions section (optional)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Perform',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Watch the video above for proper form and technique. '
                    'Make sure to warm up before starting and maintain proper form throughout the exercise.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
