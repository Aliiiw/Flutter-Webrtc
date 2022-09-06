import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Video App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  @override
  dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initRenderers();
    getUserMedia();
    super.initState();
  }

  initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {'facingMode': 'user'},
    };

    MediaStream stream = await navigator.getUserMedia(mediaConstraints);

    localRenderer.srcObject = stream;
  }

  SizedBox videoRenderers() => SizedBox(
        height: 210,
        child: Row(
          children: [
            Flexible(
                child: Container(
              key: const Key('local'),
              margin: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(localRenderer),
            )),
            Flexible(
                child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(remoteRenderer),
            ))
          ],
        ),
      );

  Row offerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RaisedButton(
            onPressed: null,
            child: Text('Offer'),
            color: Colors.amber,
          ),
          RaisedButton(
            onPressed: null,
            child: Text('Answer'),
            color: Colors.amber,
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            videoRenderers(),
            offerButtons(),
            //     sdpCandidate();
            // sdpCandidateButton();
          ],
        ));
  }
}
