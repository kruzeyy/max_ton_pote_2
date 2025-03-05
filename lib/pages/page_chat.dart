import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String currentUserEmail; // Email de l'utilisateur connecté
  final String targetUserEmail;  // Email du destinataire

  ChatPage({required this.currentUserEmail, required this.targetUserEmail});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = []; // Stocke les messages localement
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToMessages();
  }

  /// 🔹 Charge les messages depuis Supabase
  Future<void> _loadMessages() async {
    final response = await supabase
        .from('messages')
        .select()
        .or('sender.eq.${widget.currentUserEmail},receiver.eq.${widget.currentUserEmail}')
        .order('created_at', ascending: true);

    if (response != null) {
      setState(() {
        messages = List<Map<String, dynamic>>.from(response);
      });
      _scrollToBottom();
    }
  }

  /// 🔹 Écoute les nouveaux messages en temps réel
  void _listenToMessages() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
      });
      _scrollToBottom();
      _markMessagesAsRead();
    });
  }

  /// 🔹 Envoie un message à Supabase
  Future<void> _sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final messageData = {
      'sender': widget.currentUserEmail,
      'receiver': widget.targetUserEmail,
      'message': messageText,
      'created_at': DateTime.now().toIso8601String(),
      'seen': false, // Ajout du statut "vu"
    };

    await supabase.from('messages').insert(messageData);
    _messageController.clear();
  }

  /// 🔹 Marque les messages comme "vus" si l'utilisateur est le destinataire
  Future<void> _markMessagesAsRead() async {
    await supabase.from('messages').update({'seen': true}).match({
      'receiver': widget.currentUserEmail,
      'sender': widget.targetUserEmail,
      'seen': false,
    });
  }

  /// 🔹 Scroll automatiquement vers le dernier message
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat avec ${widget.targetUserEmail}"),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          /// 🔹 Liste des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isMe = message['sender'] == widget.currentUserEmail;
                bool isSeen = message['seen'] ?? false;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.red[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message['message'],
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                        if (isMe)
                          Text(
                            isSeen ? "Vu ✅" : "Envoyé ⏳",
                            style: TextStyle(fontSize: 10, color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🔹 Champ de saisie de message
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Écrire un message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.red),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}