import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final Color customGreen = const Color(0xFF86BF3E);

  void _sendMessage() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add(Message(content: input, isUser: true));
      _isLoading = true;
      _controller.clear();
    });

    try {
      String response = await ChatService.getChatResponse(input);
      setState(() {
        _messages.add(Message(content: response, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(content: "⚠️ Error: $e", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: customGreen,
        title: const Text(
          "Helly AI Assistant",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/chatbot.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'How can I help you today?',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return ChatBubble(message: msg.content, isUser: msg.isUser);
                      },
                    ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(customGreen),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about your health...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: customGreen,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}