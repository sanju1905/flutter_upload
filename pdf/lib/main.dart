import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  String url = '';
  int? number;
  uploadDatToFirebase() async {
    //generate random number
    number = Random().nextInt(10);
    //pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    File pick = File(result!.files.single.path.toString());
    var file = pick.readAsBytesSync();
    String name = DateTime.now().millisecondsSinceEpoch.toString();
    // uploading the file to firebase

    var pdfFile = FirebaseStorage.instance.ref().child(name).child('/ .pdf');
    UploadTask task = pdfFile.putData(file);
    TaskSnapshot snapshot = await task;
    url = await snapshot.ref.getDownloadURL();

    //upload url
    await FirebaseFirestore.instance.collection("file").doc().set({
      'fileUrl': url,
      'num': 'File' + number.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF',
      home: Directionality(
        textDirection: TextDirection.ltr, // or TextDirection.rtl
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'PDF',
              style: TextStyle(
                fontSize: 30.0,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
          ),
          body: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('file').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, i) {
                    QueryDocumentSnapshot x = snapshot.data!.docs[i];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => View(
                              url: x['fileUrl'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: Text(x["num"]),
                      ),
                    );
                  },
                );
              }
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: uploadDatToFirebase,
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class View extends StatelessWidget {
  final String url;

  View({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF View'),
      ),
      body: SfPdfViewer.network(
        url,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          print('Failed to load PDF: ${details.error}');
        },
      ),
    );
  }
}
