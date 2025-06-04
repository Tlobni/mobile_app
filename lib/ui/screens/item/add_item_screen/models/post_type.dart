// Shared enum definition for post types
enum PostType {
  service,
  experience;

  @override
  String toString() => switch (this) {
        PostType.service => "Service",
        PostType.experience => "Experience",
      };
}
