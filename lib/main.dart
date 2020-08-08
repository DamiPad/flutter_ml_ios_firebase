
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';

import 'package:firebase_mlvision/src/paint_rectangle.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File pickedImage;
  var text = '';
  Size _imageSize;
  List<TextElement> _elements = [];


  bool imageLoaded = false;

  Future pickImage() async {
    var awaitImage = await ImagePicker.pickImage(source: ImageSource.gallery);
 
    setState(() {
      pickedImage = awaitImage;
      imageLoaded = true;
      if (pickedImage != null) {
      _getImageSize(pickedImage);
    }
    });
    FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    VisionText visionText = await textRecognizer.processImage(visionImage);

    for (TextBlock block in visionText.blocks) {

      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          setState(() {
            text = text + word.text + ' ';
            _elements.add(word);

          });
        }
        text = text + '\n';
      }
    }
    textRecognizer.close();
  }


   Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Flutter Firebase ML"),),
      child: Column(
        children: <Widget>[
          SizedBox(height: 100.0),
          imageLoaded ? Center(
                  child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    boxShadow: const [
                      BoxShadow(blurRadius: 20),
                    ],
                  ),
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                  height: 250,
                  child: CustomPaint(
                      foregroundPainter:
                          TextDetectorPainter(_imageSize, _elements),
                      child: AspectRatio(
                        aspectRatio: _imageSize.aspectRatio,
                        child: Image.file(
                          pickedImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  //child: Image.file(
                    //pickedImage,
                    //fit: BoxFit.cover,
                  //),
                )
          )
              : Container(),
          SizedBox(height: 10.0),
          Center(
            child: FlatButton.icon(
              icon: Icon(
                CupertinoIcons.photo_camera,
                size: 60,
              ),
              label: Text(''),
              textColor: CupertinoTheme.of(context).primaryColor,
              onPressed: () async {
                pickImage();
              },
            ),
          ),
          SizedBox(height: 10.0),
          SizedBox(height: 10.0),
          Row(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Texto identificado",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ),
          text == '' ? Text('Aqui se mostrara el texto encontrado'):  Expanded(
            child: SingleChildScrollView(
              child: Container(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                    child: Text(
                      text,
                    ),
                ),
              ),
            ),
          ),
                        
                              
        ],
      ),
    );
  }
}