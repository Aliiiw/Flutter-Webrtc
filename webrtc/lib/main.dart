import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebRTC',
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

  final sdpController = TextEditingController();

  bool offer = false;
  late RTCPeerConnection peerConnection;

  late MediaStream localStream;

  @override
  dispose() {
    localRenderer.dispose();
    remoteRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initRenderers();
    createMyPeerConnection().then((pc) {
      peerConnection = pc;
    });
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
    return stream;
  }

  createMyPeerConnection() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };
    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiverAudio": true,
        "OfferToReceiverVideo": true,
      },
      "optional": [],
    };

    localStream = await getUserMedia();
    RTCPeerConnection peerConnection =
        await createPeerConnection(configuration, offerSdpConstraints);

    peerConnection.addStream(localStream);

    peerConnection.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMLineIndex.toString()
        }));
      }
    };

    peerConnection.onIceConnectionState = (e) {
      print(e);
    };

    peerConnection.onAddStream = (stream) {
      print('addStream${stream.id}');
      remoteRenderer.srcObject = stream;
    };

    return peerConnection;
  }

  void createOffer() async {
    RTCSessionDescription description =
        await peerConnection.createOffer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(json.encode(session));
    offer = true;
    peerConnection.setLocalDescription(description);
  }

  void setRemoteDescription() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    String sdp = write(session, null);
    RTCSessionDescription description =
        RTCSessionDescription(sdp, offer ? 'answer' : 'offer');
    print(description.toMap());
    await peerConnection.setRemoteDescription(description);
  }

  void createAnswer() async {
    RTCSessionDescription description =
        await peerConnection.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp.toString());
    print(json.encode(session));

    peerConnection.setLocalDescription(description);
  }

  void setCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);
    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMLineIndex']);
    await peerConnection.addCandidate(candidate);
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
              child: RTCVideoView(
                localRenderer,
                mirror: true,
              ),
            )),
            Flexible(
                child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(
                remoteRenderer,
                mirror: true,
              ),
            ))
          ],
        ),
      );

  Row offerButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: createOffer,
            style: ElevatedButton.styleFrom(
              primary: Colors.amber,
              onPrimary: Colors.black,
            ),
            child: const Text('Offer'),
          ),
          ElevatedButton(
            onPressed: createAnswer,
            style: ElevatedButton.styleFrom(
              primary: Colors.amber,
              onPrimary: Colors.black,
            ),
            child: const Text('Answer'),
          )
        ],
      );

  Padding sdpCandidate() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: sdpController,
          keyboardType: TextInputType.multiline,
          maxLines: 4,
          maxLength: TextField.noMaxLength,
        ),
      );

  Row sdpCandidateButton() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: setRemoteDescription, //setRemoteDescription,
            style: ElevatedButton.styleFrom(
              primary: Colors.amber,
              onPrimary: Colors.black,
            ),
            child: const Text('Set Remote Description'),
          ),
          ElevatedButton(
            onPressed: setCandidate, // setCandidate,
            style: ElevatedButton.styleFrom(
              primary: Colors.amber,
              onPrimary: Colors.black,
            ),
            child: const Text('Set Candidate'),
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
            sdpCandidate(),
            sdpCandidateButton(),
          ],
        ));
  }
}
