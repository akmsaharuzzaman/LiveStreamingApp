import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_player/video_player.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final ImagePicker _picker = ImagePicker();
  VideoEditorController? videoEditorController;
  VideoPlayerController? videoPlayerController;
  bool canShowEditor = false;
  List<String?> trimVideos = [];
  bool isSeeking = false;

  Future<void> _pickVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      videoEditorController = VideoEditorController.file(
        File(file.path),
        maxDuration: const Duration(seconds: 59),
        minDuration: const Duration(seconds: 1),
      );
      videoPlayerController = VideoPlayerController.file(File(file.path));

      try {
        await Future.wait([
          videoEditorController!.initialize(),
          videoPlayerController!.initialize(),
        ]);

        videoPlayerController!.addListener(() {
          if (videoPlayerController!.value.position >=
              videoEditorController!.endTrim) {
            videoPlayerController!.pause();
          }
        });

        setState(() {
          canShowEditor = true;
        });
      } catch (e) {
        log("Initialize Error: $e");
      }
    }
  }

  Future<void> _trimVideo() async {
    if (videoEditorController == null) return;
    final start = videoEditorController!.startTrim.inMilliseconds / 1000;
    final end = videoEditorController!.endTrim.inMilliseconds / 1000;
    final Directory tempDir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().microsecondsSinceEpoch.toString();
    final String filename = 'trimed_video_$timestamp.mp4';
    log("Filename: $filename");
    final String outputPath = path.join(tempDir.path, filename);

    final String command =
        '-i ${videoEditorController!.file.path} -ss $start -to $end -c copy $outputPath';
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          trimVideos.add(outputPath);
        });
        log("Filename: $filename");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Video exported to : $outputPath")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to export video ")));
      }
    });
  }

  Future<void> _mergeVideos() async {
    if (trimVideos.isEmpty) return;
    final Directory tempDir = await getTemporaryDirectory();
    final String mergedVideoPath = '${tempDir.path}/merged_video.mp4';
    final String fileListPath = '${tempDir.path}/file_list_txt';
    File fileList = File(fileListPath);

    String fileListContent =
        trimVideos.map((path) => "file '$path'").join("\n");
    await fileList.writeAsString(fileListContent);
    print('fileListContent : $fileListContent');

    final String command =
        '-f concat -safe 0 -i $fileListPath -c copy $mergedVideoPath';

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        log("Merge video saved to: $mergedVideoPath");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Final video exported to : $mergedVideoPath")));
      } else {
        log("Merge video saved to: ${session.getOutput()}");
        log("Merge video saved to: ${session.getOutput()}");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to merge video ")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Video editor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (canShowEditor &&
              videoPlayerController!.value.isInitialized &&
              videoEditorController!.initialized) ...[
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(videoPlayerController!),
                        ),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                if (videoPlayerController!.value.isPlaying) {
                                  videoPlayerController!.pause();
                                } else {
                                  if (!isSeeking) {
                                    int startTrimDuration =
                                        videoEditorController!
                                            .startTrim.inSeconds;
                                    videoPlayerController!.seekTo(
                                        Duration(seconds: startTrimDuration));
                                  }
                                  videoPlayerController!.play();
                                }
                              });
                            },
                            icon: Icon(
                              videoPlayerController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 45.sp,
                            ))
                      ],
                    ),
                  ),
                  Slider(
                    value: videoPlayerController!.value.position.inMilliseconds
                        .toDouble(),
                    max: videoPlayerController!.value.duration.inMilliseconds
                        .toDouble(),
                    onChangeStart: (value) {
                      isSeeking = true;
                    },
                    onChanged: (value) {
                      videoPlayerController!
                          .seekTo(Duration(milliseconds: value.toInt()));
                      setState(() {});
                    },
                    onChangeEnd: (value) {
                      isSeeking = false;
                      videoPlayerController!.play();
                    },
                  )
                ],
              ),
            ),

            Expanded(
                flex: 2,
                child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trimVideos.length,
                    onReorder: (int oldIndex, int newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final String? movedClip = trimVideos.removeAt(oldIndex);
                      trimVideos.insert(newIndex, movedClip);
                    },
                    itemBuilder: (context, index) {
                      return ReorderableDragStartListener(
                        index: index,
                        key: ValueKey(trimVideos[index]),
                        child: Container(
                          width: 100,
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          child: Stack(
                            children: [
                              Image.asset(
                                  "assets/images/new_images/ic_logo_white.png"),
                              Positioned(
                                  child: IconButton(
                                      onPressed: () => setState(() {
                                            trimVideos.removeAt(index);
                                          }),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      )))
                            ],
                          ),
                        ),
                      );
                    })),

            //Trim Slider
            Padding(
              padding: const EdgeInsets.only(right: 22.0),
              child: TrimSlider(
                controller: videoEditorController!,
                height: 60.sp,
                horizontalMargin: 15.sp,
                child: TrimTimeline(controller: videoEditorController!),
              ),
            ),

            //Editing Toolbar
            Padding(
              padding: EdgeInsets.only(
                  top: 10.sp, right: 20.sp, left: 20.sp, bottom: 8.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _trimVideo,
                    child: Icon(
                      Icons.content_cut,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    Icons.crop,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.speed,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.music_note,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            //Bottom action Button

            Padding(
              padding: EdgeInsets.all(16.sp),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return Colors.red;
                    }
                    return Colors.red;
                  }),
                ),
                onPressed: _mergeVideos,
                child: Text(
                  "Merge & Export final video",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          ] else ...[
            Expanded(
                child: Center(
                    child: Text(
              "Select a video to start Editing",
              style: TextStyle(color: Colors.white),
            ))),
            Padding(
              padding:
                  EdgeInsets.only(left: 15.sp, right: 15.sp, bottom: 50.sp),
              child: SizedBox(
                height: 40.h,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.red;
                      }
                      return const Color(0xff2c3968);
                    }),
                  ),
                  onPressed: _pickVideo,
                  child: Text(
                    "Import Video",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
