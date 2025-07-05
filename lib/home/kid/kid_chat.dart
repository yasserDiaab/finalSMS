import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ChatScreenn extends StatelessWidget {
  // قائمة الأشخاص
  final List<String> chatUsers = [
    "Supporter 1",
    "Supporter 2",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF30C988), Color(0xFF37A3B6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // مربع البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Search',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              // قائمة الأشخاص
              Expanded(
                child: ListView.builder(
                  itemCount: chatUsers.length,
                  itemBuilder: (context, index) {
                    final userName = chatUsers[index];
                    return buildChatItem(context, userName);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildChatItem(BuildContext context, String userName) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person, size: 28, color: Colors.white),
      ),
      title: Text(userName, style: const TextStyle(color: Colors.white)),
      subtitle: const Text(
        "Tap to chat",
        style: TextStyle(color: Color.fromRGBO(220, 245, 245, 1)),
      ),
      trailing: const Text(
        "Now",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(userName: userName)),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userName;

  ChatScreen({required this.userName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.white),
              radius: 20,
            ),
           const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const  Text("Active now",
                    style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF30C988), Color(0xFF37A3B6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 70),
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message['isMe'] as bool;

                        return Row(
                          mainAxisAlignment:
                              isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isMe)
                              Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                                ),
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 260),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.white : const Color.fromRGBO(2, 95, 104, 1),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: isMe ? const Radius.circular(0) : const Radius.circular(18),
                                  bottomRight: isMe ? const Radius.circular(18) : const Radius.circular(0),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                message['text'],
                                style: TextStyle(
                                  color: isMe ? Colors.black87 : Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Hello! How are you?",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        const  SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.mic, size: 20, color: Colors.black87),
              onPressed: () {
                print('Voice recording pressed');
              },
            ),
          ),
         const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(2, 95, 104, 1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  setState(() {
                    messages.add({
                      'text': _controller.text.trim(),
                      'isMe': false,
                    });
                    _controller.clear();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
