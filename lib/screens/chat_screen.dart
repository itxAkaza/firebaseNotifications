import 'package:flutter/material.dart';


class ChatScreen extends StatefulWidget {
  final String id;
  const ChatScreen({super.key,
  required this.id
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Message Screen${widget.id}"),
      ),
    );
  }
}
