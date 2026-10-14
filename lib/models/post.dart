class Post {
  const Post({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;

  factory Post.fromMap(Map<dynamic, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    final body = map['body'];
    if (id is! int || title is! String || body is! String) {
      throw const FormatException('The post data is incomplete.');
    }
    return Post(id: id, title: title, body: body);
  }

  // Maps work both as named-route arguments and as Hive values.
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'body': body};
}
