import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../domain/entities/chat_message_entity.dart';
import '../../data/datasources/chat_remote_data_source.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _dataSource = ChatRemoteDataSource();
  bool _isUploading = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await FirebaseDatabase.instance
          .ref('chats/${widget.userId}')
          .update({'unreadCount': 0});
    } catch (e) {
      // Silently fail
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageCtrl.text.trim();
    if (message.isEmpty) return;

    try {
      await _dataSource.sendMessage(
        userId: widget.userId,
        userName: 'Admin',
        message: message,
        isAdmin: true,
      );

      _messageCtrl.clear();
      setState(() => _isTyping = false);
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      _showError('Failed to send message: $e');
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      await _uploadAndSendMedia(
        file: File(image.path),
        type: MessageType.image,
        message: '📷 Image',
      );
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;

      await _uploadAndSendMedia(
        file: file,
        type: MessageType.file,
        message: '📎 $fileName',
      );
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _uploadAndSendMedia({
    required File file,
    required MessageType type,
    required String message,
  }) async {
    setState(() => _isUploading = true);

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child('admin')
          .child(fileName);

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _dataSource.sendMessage(
        userId: widget.userId,
        userName: 'Admin',
        message: message,
        type: type,
        mediaUrl: downloadUrl,
        isAdmin: true,
      );

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      _showError('Failed to upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF9F7AEA)),
              title: const Text('Send Image'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Color(0xFF9F7AEA)),
              title: const Text('Send File'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF9F7AEA)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return;

      await _uploadAndSendMedia(
        file: File(photo.path),
        type: MessageType.image,
        message: '📷 Photo',
      );
    } catch (e) {
      _showError('Failed to take photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            Text(
              'User ID: ${widget.userId.substring(0, 8)}...',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9F7AEA),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder(
              stream: _dataSource.getMessagesStream(widget.userId),
              builder: (context, snapshot) {
                // Show loading only on initial connection
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showDateHeader = index == 0 ||
                        !_isSameDay(
                            messages[index - 1].timestamp, message.timestamp);

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message.timestamp),
                        _buildMessageBubble(message),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Uploading Indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading...'),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment Button
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Color(0xFF9F7AEA)),
                  onPressed: _isUploading ? null : _showMediaOptions,
                ),
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isUploading,
                    onChanged: (value) {
                      setState(() => _isTyping = value.isNotEmpty);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                CircleAvatar(
                  backgroundColor: const Color(0xFF9F7AEA),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isUploading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity message) {
    final isAdmin = message.isAdmin;

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFF9F7AEA) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isAdmin ? const Radius.circular(12) : Radius.zero,
            bottomRight: isAdmin ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isAdmin)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAdmin ? Colors.white70 : Colors.black54,
                ),
              ),
            if (!isAdmin) const SizedBox(height: 4),

            // Media Content
            if (message.type == MessageType.image && message.mediaUrl != null)
              GestureDetector(
                onTap: () => _showImageFullScreen(message.mediaUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.mediaUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      );
                    },
                  ),
                ),
              ),

            if (message.type == MessageType.file && message.mediaUrl != null)
              InkWell(
                onTap: () => _openFile(message.mediaUrl!),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.white24 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        color: isAdmin ? Colors.white : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isAdmin ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Text Message
            if (message.type == MessageType.text ||
                (message.type != MessageType.text && message.mediaUrl != null))
              Padding(
                padding: EdgeInsets.only(
                  top: message.type != MessageType.text &&
                          message.mediaUrl != null
                      ? 8
                      : 0,
                ),
                child: Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: isAdmin ? Colors.white : Colors.black87,
                  ),
                ),
              ),

            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isAdmin ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  void _openFile(String fileUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening file...'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            // TODO: Use url_launcher to open the file
          },
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String label;
    if (_isSameDay(date, now)) {
      label = 'Today';
    } else if (_isSameDay(date, yesterday)) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM dd, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
