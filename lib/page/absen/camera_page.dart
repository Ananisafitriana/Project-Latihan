import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:jujur_ajalah/page/absen/absen_page.dart';
import 'package:jujur_ajalah/utils/facedetection/google_ml_kit.dart';

class CameraAbsenPage extends StatefulWidget {
  const CameraAbsenPage({super.key});

  @override
  State<CameraAbsenPage> createState() => _State();
}

class _State extends State<CameraAbsenPage> with TickerProviderStateMixin {
  FaceDetector faceDetector =
      GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
    enableTracking: true,
    enableLandmarks: true,
  ));

  List<CameraDescription>? cameras;
  CameraController? controller;
  XFile? image;
  bool isBusy = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      loadCamera();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.camera_alt,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Camera permission is required to take photos.",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> loadCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        throw CameraException(
            'NoCamerasAvailable', 'No cameras found on device.');
      }
      controller = CameraController(cameras![0], ResolutionPreset.max);
      await controller!.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Error initializing camera: $e",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: const StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 0, 183, 255),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Foto Selfie",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: size.height,
            width: size.width,
            child: controller == null
                ? const Center(
                    child: Text("Ups, kamera bermasalah!",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)))
                : !controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : CameraPreview(controller!),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Lottie.asset(
                "assets/raw/face_id_ring.json",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: size.width,
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    "Pastikan Anda berada di tempat terang, agar wajah terlihat jelas.",
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 20),
                    child: ClipOval(
                      child: Material(
                        color: Color.fromARGB(255, 0, 183, 255), // Button color
                        child: InkWell(
                          splashColor:
                              Color.fromARGB(255, 55, 0, 255), // Splash color
                          onTap: () async {
                            final hasPermission =
                                await handleLocationPermission();
                            try {
                              if (controller != null &&
                                  controller!.value.isInitialized) {
                                controller!.setFlashMode(FlashMode.off);
                                image = await controller!.takePicture();
                                setState(() {
                                  if (hasPermission) {
                                    showLoaderDialog(context);
                                    final inputImage =
                                        InputImage.fromFilePath(image!.path);
                                    Platform.isAndroid
                                        ? processImage(inputImage)
                                        : Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    AbsenPage(image: image)));
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Nyalakan perizinan lokasi terlebih dahulu!",
                                            style:
                                                TextStyle(color: Colors.white),
                                          )
                                        ],
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      shape: StadiumBorder(),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Ups, $e",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    )
                                  ],
                                ),
                                backgroundColor: Colors.redAccent,
                                shape: const StadiumBorder(),
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          },
                          child: const SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              Icons.camera_enhance_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

  //permission location
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.location_off,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Location services are disabled. Please enable the services.",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.location_off,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                "Location permission denied.",
                style: TextStyle(color: Colors.white),
              )
            ],
          ),
          backgroundColor: Colors.redAccent,
          shape: StadiumBorder(),
          behavior: SnackBarBehavior.floating,
        ));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.location_off,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Location permission denied forever, we cannot access.",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
        backgroundColor: Colors.redAccent,
        shape: StadiumBorder(),
        behavior: SnackBarBehavior.floating,
      ));
      return false;
    }
    return true;
  }

  //face detection
  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage);
    isBusy = false;

    if (mounted) {
      setState(() {
        Navigator.of(context).pop(true);
        if (faces.isNotEmpty) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => AbsenPage(image: image)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.face_retouching_natural_outlined,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Ups, pastikan wajah Anda terlihat jelas dengan cahaya yang cukup!",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
            backgroundColor: Colors.redAccent,
            shape: StadiumBorder(),
            behavior: SnackBarBehavior.floating,
          ));
        }
      });
    }
  }

  //show loader dialog
  void showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 0, 183, 255))),
          Container(
              margin: const EdgeInsets.only(left: 20),
              child: const Text("Sedang memeriksa data...")),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
