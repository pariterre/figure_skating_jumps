import 'package:camera/camera.dart';
import 'package:figure_skating_jumps/constants/colors.dart';
import 'package:figure_skating_jumps/enums/ice_button_importance.dart';
import 'package:figure_skating_jumps/enums/ice_button_size.dart';
import 'package:figure_skating_jumps/enums/recording/recorder_state.dart';
import 'package:figure_skating_jumps/services/camera_service.dart';
import 'package:figure_skating_jumps/services/external_storage_service.dart';
import 'package:figure_skating_jumps/services/x_sens/x_sens_dot_connection_service.dart';
import 'package:figure_skating_jumps/services/x_sens/x_sens_dot_recording_service.dart';
import 'package:figure_skating_jumps/widgets/buttons/ice_button.dart';
import 'package:figure_skating_jumps/widgets/dialogs/capture/device_not_ready_dialog.dart';
import 'package:figure_skating_jumps/widgets/dialogs/capture/start_recording_dialog.dart';
import 'package:figure_skating_jumps/widgets/prompts/instruction_prompt.dart';
import 'package:flutter/material.dart';
import '../../constants/lang_fr.dart';
import '../../enums/season.dart';
import '../dialogs/capture/no_camera_recording_dialog.dart';
import '../layout/scaffold/ice_drawer_menu.dart';
import '../layout/scaffold/topbar.dart';
import 'dart:developer' as developer;

import '../titles/page_title.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({
    Key? key,
  }) : super(key: key);

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  final XSensDotRecordingService _xSensDotRecordingService =
      XSensDotRecordingService();
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFullscreen = false;
  bool _isCameraActivated = true;
  Season _selectedSeason = XSensDotRecordingService.season;

  @override
  void initState() {
    _controller = CameraController(
      enableAudio: false,
      CameraService().rearCamera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isFullscreen
        ? Builder(builder: (context) {
            return Stack(
              children: [
                FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: _buildCameraPreview),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: IceButton(
                        onPressed: () async {
                          await _onCaptureStopPressed();
                        },
                        text: stopCapture,
                        textColor: primaryColor,
                        color: primaryColor,
                        iceButtonImportance:
                            IceButtonImportance.secondaryAction,
                        iceButtonSize: IceButtonSize.medium,
                      ),
                    ),
                  ],
                )
              ],
            );
          })
        : Scaffold(
            appBar: const Topbar(isUserDebuggingFeature: false),
            drawerEnableOpenDragGesture: false,
            drawerScrimColor: Colors.transparent,
            drawer: const IceDrawerMenu(isUserDebuggingFeature: false),
            body: Builder(builder: (context) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 16.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageTitle(text: captureViewTitle),
                      const Padding(
                        padding: EdgeInsets.only(top: 24.0),
                        child: InstructionPrompt(
                            captureViewInstructions, secondaryColor),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 24.0),
                        child: InstructionPrompt(
                            captureViewCameraInstruction, secondaryColor),
                      ),
                      if (_isCameraActivated)
                        FutureBuilder<void>(
                            future: _initializeControllerFuture,
                            builder: _buildCameraPreview),
                      Expanded(
                          child: Center(
                              child: _isCameraActivated
                                  ? const SizedBox()
                                  : const Icon(Icons.no_photography_outlined,
                                      size: 56))),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(captureViewCameraSwitchPrompt),
                            Switch(
                                value: _isCameraActivated,
                                onChanged: (val) {
                                  setState(() {
                                    _isCameraActivated = val;
                                  });
                                })
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Text(selectSeasonPrompt),
                            ),
                            DropdownButton<Season>(
                                selectedItemBuilder: (context) {
                                  return Season.values
                                      .map<Widget>((Season item) {
                                    // This is the widget that will be shown when you select an item.
                                    // Here custom text style, alignment and layout size can be applied
                                    // to selected item string.
                                    return Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 80),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.displayedString,
                                            style: const TextStyle(
                                                color: darkText,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                                value: _selectedSeason,
                                menuMaxHeight: 300,
                                items: List.generate(Season.values.length,
                                    (index) {
                                  return DropdownMenuItem<Season>(
                                    value: Season.values[index],
                                    child: Text(
                                        Season.values[index].displayedString),
                                  );
                                }),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSeason = val!;
                                    XSensDotRecordingService.season =
                                        _selectedSeason;
                                  });
                                }),
                          ]),
                      Center(
                        child: IceButton(
                          onPressed: () async {
                            await _onCaptureStartPressed();
                          },
                          text: captureViewStart,
                          textColor: primaryColor,
                          color: primaryColor,
                          iceButtonImportance:
                              IceButtonImportance.secondaryAction,
                          iceButtonSize: IceButtonSize.medium,
                        ),
                      ),
                    ]),
              );
            }),
          );
  }

  Future<void> _onCaptureStopPressed() async {
    try {
      _displayWaitingDialog(exportingData);
      await _initializeControllerFuture;
      await _xSensDotRecordingService.stopRecording(_isCameraActivated);
      if(_isCameraActivated) {
        XFile f = await _controller.stopVideoRecording();
        String path = await ExternalStorageService().saveVideo(f);
        // TODO: Save to localDataBase. and eventually Firebase?
        // To ignore the warning of unused variable -> will be used for localDB storage
        path = path;
      }
    } catch (e) {
      developer.log(e.toString());
    }
    setState(() {
      _isFullscreen = false;
    });
  }

  Future<void> _onCaptureStartPressed() async {
    if (!XSensDotConnectionService().isInitialized) {
      await _displayStepDialog(const DeviceNotReadyDialog());
      return;
    }

    try {
      await _initializeControllerFuture;
      await _xSensDotRecordingService.startRecording();
      _displayStepDialog(const StartRecordingDialog()).then((_) async {
        if (_xSensDotRecordingService.recorderState == RecorderState.idle) {
          return;
        }

        if(!_isCameraActivated) {
          _displayStepDialog(const NoCameraRecordingDialog()).then((value) async {
            await _onCaptureStopPressed();
          });
          return;
        }

        setState(() {
          _isFullscreen = true;
        });
        await _controller.startVideoRecording();
      });
    } catch (e) {
      developer.log(e.toString());
    }
  }

  Widget _buildCameraPreview(
      BuildContext context, AsyncSnapshot<void> snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      Size screenSize = MediaQuery.of(context).size;
      double cameraHeight = screenSize.height;
      double cameraWidth = screenSize.height / _controller.value.aspectRatio;

      if (cameraWidth > screenSize.width) {
        cameraWidth = screenSize.width;
        cameraHeight = screenSize.width * _controller.value.aspectRatio;
      }
      if (!_isFullscreen) {
        //Reduce size to let place for other UI elements
        //TODO put back to 2 before merge
        cameraWidth /= 3;
        cameraHeight /= 3;
      }

      return Center(
        child: SizedBox(
          width: _isFullscreen ? screenSize.width : cameraWidth,
          height: _isFullscreen ? screenSize.height : cameraHeight,
          child: _controller.buildPreview(),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _displayStepDialog(Widget dialog) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return dialog;
        });
  }

  void _displayWaitingDialog(String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return SimpleDialog(
            title: Text(
              message,
              textAlign: TextAlign.center,
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                        width: 50,
                        child: LinearProgressIndicator(
                          color: primaryColor,
                          backgroundColor: discreetText,
                        )),
                  ),
                  Text(pleaseWait)
                ],
              )
            ],
          );
        });
  }
}
