import '../../core/models/models.dart';
import '../../config/supabase_client.dart';

class PostRepository {
  final _client = SupabaseConfig.client;

  Future<String?> getCurrentEstateId() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('members')
        .select('estate_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();
    return data?['estate_id'] as String?;
  }

  Future<List<Post>> getPosts(String estateId, {String? category}) async {
    var query = _client
        .from('posts')
        .select()
        .eq('estate_id', estateId);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map((p) => Post.fromJson(p)).toList();
  }

  Future<Post> createPost({
    required String estateId,
    required String authorId,
    required String content,
    String category = 'Update',
    String? title,
    List<String> photos = const [],
    String? videoUrl,
  }) async {
    final data = await _client
        .from('posts')
        .insert({
          'estate_id': estateId,
          'author_id': authorId,
          'content': content,
          'category': category,
          'title': title,
          'photos': photos,
          'video_url': videoUrl,
        })
        .select()
        .single();

    return Post.fromJson(data);
  }

  Future<void> toggleLike(String postId, String userId) async {
    final post = await _client.from('posts').select('likes').eq('id', postId).single();
    final likes = List<String>.from(post['likes'] ?? []);

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    await _client.from('posts').update({'likes': likes}).eq('id', postId);
  }

  Future<int> getCommentCount(String postId) async {
    final data = await _client
        .from('comments')
        .select('id')
        .eq('post_id', postId);

    return data.length;
  }

  Future<List<Comment>> getComments(String postId) async {
    final data = await _client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return data.map((c) => Comment.fromJson(c)).toList();
  }

  Future<Comment> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    final data = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'author_id': authorId,
          'content': content,
        })
        .select()
        .single();

    await _client.rpc('increment_comment_count', params: {'post_id': postId});

    return Comment.fromJson(data);
  }

  Stream<List<Post>> watchPosts(String estateId) {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('estate_id', estateId)
        .order('created_at', ascending: false)
        .map((data) => data.map((p) => Post.fromJson(p)).toList());
  }
}
