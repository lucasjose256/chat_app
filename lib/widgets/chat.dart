import 'package:chat_app/widgets/messege_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat')
            .orderBy('createAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No messages found.'),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong...'),
            );
          }
          final loadedMesseges = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 40, left: 13, right: 13),
            reverse: true,
            itemBuilder: (context, index) {
              //   return Text(loadedMesseges[index].data()['text']);
              final chatMessege = loadedMesseges[index].data();
              final nextChatMessege = index + 1 < loadedMesseges.length
                  ? loadedMesseges[index + 1].data()
                  : null;
              final curretnMessegeUserId = chatMessege['userId'];
              final nextMessageUserId =
                  nextChatMessege != null ? nextChatMessege['userId'] : null;
              final nextUserIsSame = nextMessageUserId == curretnMessegeUserId;

              if (nextUserIsSame) {
                return MessageBubble.next(
                  message: chatMessege['text'],
                  isMe: authenticatedUser!.uid == curretnMessegeUserId,
                );
              } else
                return MessageBubble.first(
                  userImage: chatMessege['userImage'],
                  username: chatMessege['username'],
                  message: chatMessege['text'],
                  isMe: authenticatedUser!.uid == curretnMessegeUserId,
                );
            },
            itemCount: loadedMesseges.length,
          );
        });
  }
}
