import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';


class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;
  final String exerciseName;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.exerciseName,
  });

  Future<void> _launchVideo() async {
    final uri = Uri.parse(videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exerciseName), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 80.sp, color: Colors.blue),
            SizedBox(height: 3.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: Text(
                'Apasă butonul pentru a viziona video-ul',
                style: TextStyle(fontSize: 16.sp),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton.icon(
              onPressed: _launchVideo,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Vizionează Video'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
