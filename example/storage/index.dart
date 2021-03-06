import 'dart:html';

import 'package:firebase_web/firebase.dart' as fb;
import 'package:firebase_web/src/assets/assets.dart';

main() async {
  //Use for firebase package development only
  await config();

  try {
    fb.initializeApp(
        apiKey: apiKey,
        authDomain: authDomain,
        databaseURL: databaseUrl,
        storageBucket: storageBucket);

    ImageUploadApp();
  } on fb.FirebaseJsNotLoadedException catch (e) {
    print(e);
  }
}

class ImageUploadApp {
  final fb.StorageReference ref;
  final InputElement _uploadImage;

  ImageUploadApp()
      : ref = fb.storage().ref("pkg_firebase/examples/storage"),
        _uploadImage = querySelector("#upload_image") {
    _uploadImage.disabled = false;

    _uploadImage.onChange.listen((e) async {
      e.preventDefault();
      var file = (e.target as FileUploadInputElement).files[0];

      var customMetadata = {"location": "Prague", "owner": "You"};
      var uploadTask = ref.child(file.name).put(
          file,
          fb.UploadMetadata(
              contentType: file.type, customMetadata: customMetadata));
      uploadTask.onStateChanged.listen((e) {
        querySelector("#message").text =
            "Transfered ${e.bytesTransferred}/${e.totalBytes}...";
      });

      try {
        var snapshot = await uploadTask.future;
        var filePath = await snapshot.ref.getDownloadURL();
        var image = ImageElement(src: filePath.toString());
        document.body.append(image);
        var metadata = snapshot.metadata.customMetadata;
        querySelector("#message").text = "Metadata: ${metadata.toString()}";
      } catch (e) {
        print(e);
      }
    });
  }
}
