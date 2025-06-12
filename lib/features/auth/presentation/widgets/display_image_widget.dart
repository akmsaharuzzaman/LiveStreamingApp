import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DisplayImage extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;

  // Constructor
  const DisplayImage({
    Key? key,
    required this.imagePath,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color.fromRGBO(64, 105, 225, 1);

    return Center(
      child: Stack(
        children: [
          buildImage(color),
          Positioned(
            child: buildEditIcon(color),
            right: 4,
            top: 10,
          ),
        ],
      ),
    );
  }

  // Builds Profile Image
  Widget buildImage(Color color) {
    // If the image path is a URL, use CachedNetworkImage for caching
    final image = imagePath.contains('https://')
        ? CachedNetworkImage(
            imageUrl: imagePath,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          )
        : Image.asset(imagePath);

    return CircleAvatar(
      radius: 38,
      backgroundColor: color,
      child: CircleAvatar(
        backgroundImage: image is CachedNetworkImage
            ? NetworkImage(imagePath)
            : AssetImage(imagePath) as ImageProvider,
        radius: 36,
      ),
    );
  }

  // Builds Edit Icon on Profile Picture
  Widget buildEditIcon(Color color) => buildCircle(
        all: 4,
        child: Icon(
          Icons.edit,
          color: color,
          size: 10,
        ),
      );

  // Builds/Makes Circle for Edit Icon on Profile Picture
  Widget buildCircle({
    required Widget child,
    required double all,
  }) =>
      ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: Colors.white,
          child: child,
        ),
      );
}
