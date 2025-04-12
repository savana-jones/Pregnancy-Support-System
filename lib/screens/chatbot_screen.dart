import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];

  bool isLoading = false;

  Future<void> sendMessage(String userMessage) async {
    setState(() {
      messages.add({'role': 'user', 'message': userMessage});
      isLoading = true;
    });

    // Replace with your Flask backend URL (use your local IP if testing on device)
    const apiUrl = 'http://192.168.160.1:5000/chat';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"messages": userMessage}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        String botResponse = responseData['response'];

        setState(() {
          messages.add({'role': 'bot', 'message': botResponse});
          isLoading = false;
        });
      } else {
        setState(() {
          messages.add({'role': 'bot', 'message': 'Error: Server error'});
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        messages.add({'role': 'bot', 'message': 'Error: Failed to connect'});
        isLoading = false;
      });
    }

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Widget _buildMessage(String message, bool isUser) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.deepPurpleAccent
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy Support Chatbot'),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.deepPurple[900] : Colors.deepPurple[300],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['role'] == 'user';
                return _buildMessage(message['message']!, isUser);
              },
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          const Divider(height: 1), // Add a divider for clear separation
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildUserInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  sendMessage(value.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Ask me about pregnancy...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  sendMessage(text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
