class MessageModel {
  final String id;
  final String rideId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final String? senderFirstName;
  final String? senderLastName;
  final String? senderProfileImage;

  MessageModel({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.senderFirstName,
    this.senderLastName,
    this.senderProfileImage,
  });

  String get senderName =>
      '${senderFirstName ?? ''} ${senderLastName ?? ''}'.trim();

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:                  json['id'] ?? json['_id'] ?? '',
      rideId:              json['ride_id'] ?? '',
      senderId:            json['sender_id'] ?? '',
      receiverId:          json['receiver_id'] ?? '',
      content:             json['content'] ?? '',
      isRead:              json['is_read'] ?? false,
      createdAt:           json['created_at'] != null
                               ? DateTime.parse(json['created_at'])
                               : DateTime.now(),
      senderFirstName:     json['sender_first_name'],
      senderLastName:      json['sender_last_name'],
      senderProfileImage:  json['sender_profile_image'],
    );
  }
}
