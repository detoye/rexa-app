import 'package:flutter/material.dart';
import '../../../config/supabase_client.dart';
import '../../../config/theme.dart';
import '../../../core/models/models.dart';
import '../../../data/repositories/post_repository.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final _postRepo = PostRepository();
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _estateId;
  String? _selectedCategory;

  static const _categories = ['All', 'Update', 'Discussion', 'Event', 'Lost & Found', 'Recommendation'];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      _estateId = await _postRepo.getCurrentEstateId();
      if (_estateId != null) {
        final posts = await _postRepo.getPosts(_estateId!, category: _selectedCategory);
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RezaColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: RezaColors.backgroundDark,
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showCreatePostSheet(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = (_selectedCategory == null && cat == 'All') || _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = cat == 'All' ? null : cat;
                            });
                            _loadPosts();
                          },
                          selectedColor: RezaColors.accentGold,
                          backgroundColor: RezaColors.cardDark,
                          labelStyle: TextStyle(
                            color: isSelected ? RezaColors.primaryNavy : RezaColors.textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _posts.isEmpty
                        ? _buildEmptyState(Icons.forum, 'No posts yet')

                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) => _buildPostCard(_posts[index]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: RezaColors.textGray, size: 40),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: RezaColors.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final userId = SupabaseConfig.auth.currentUser?.id;
    final isLiked = userId != null && post.likes.contains(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RezaColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: RezaColors.accentGold.withValues(alpha: 0.2),
                child: Text(
                  (post.authorId ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: RezaColors.accentGold, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorId?.substring(0, 8) ?? 'User',
                      style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600),
                    ),
                    Text(_formatTime(post.createdAt), style: const TextStyle(color: RezaColors.textGray, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RezaColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(post.category, style: const TextStyle(color: RezaColors.accentGold, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (post.title != null) ...[
            const SizedBox(height: 12),
            Text(post.title!, style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
          const SizedBox(height: 8),
          Text(post.content, style: Theme.of(context).bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (_estateId != null && userId != null) {
                    await _postRepo.toggleLike(post.id, userId);
                    _loadPosts();
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_outline,
                      color: isLiked ? RezaColors.errorRed : RezaColors.textGray,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likes.length}', style: TextStyle(color: isLiked ? RezaColors.errorRed : RezaColors.textGray, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showCommentsSheet(context, post),
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined, color: RezaColors.textGray, size: 20),
                    const SizedBox(width: 4),
                    Text('${post.numComments}', style: const TextStyle(color: RezaColors.textGray, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    final contentController = TextEditingController();
    final titleController = TextEditingController();
    String selectedCategory = 'Update';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Post', style: TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(hintText: 'Category'),
                      items: _categories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setModalState(() => selectedCategory = v ?? 'Update'),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title (optional)')),
                    const SizedBox(height: 12),
                    TextField(controller: contentController, maxLines: 4, decoration: const InputDecoration(hintText: "What's on your mind?")),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_estateId != null && contentController.text.isNotEmpty) {
                            final user = SupabaseConfig.auth.currentUser;
                            if (user == null) return;
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await _postRepo.createPost(
                                estateId: _estateId!,
                                authorId: user.id,
                                content: contentController.text,
                                category: selectedCategory,
                                title: titleController.text.isNotEmpty ? titleController.text : null,
                              );
                              navigator.pop();
                              _loadPosts();
                              messenger.showSnackBar(const SnackBar(content: Text('Post published')));
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          }
                        },
                        child: const Text('Post'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCommentsSheet(BuildContext context, Post post) {
    final commentController = TextEditingController();
    List<Comment> comments = [];
    bool isLoadingComments = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RezaColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (isLoadingComments) {
              _postRepo.getComments(post.id).then((c) {
                setModalState(() {
                  comments = c;
                  isLoadingComments = false;
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Comments (${comments.length})', style: const TextStyle(color: RezaColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: isLoadingComments
                        ? const Center(child: CircularProgressIndicator(color: RezaColors.accentGold))
                        : comments.isEmpty
                            ? const Center(child: Text('No comments yet', style: TextStyle(color: RezaColors.textGray)))
                            : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: RezaColors.accentGold.withValues(alpha: 0.2),
                                          child: Text(
                                            (comment.authorId ?? 'U')[0].toUpperCase(),
                                            style: const TextStyle(color: RezaColors.accentGold, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(comment.authorId?.substring(0, 8) ?? 'User',
                                                  style: const TextStyle(color: RezaColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                                              Text(comment.content, style: Theme.of(context).bodyMedium),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(hintText: 'Write a comment...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: RezaColors.accentGold),
                        onPressed: () async {
                          if (commentController.text.isNotEmpty) {
                            final user = SupabaseConfig.auth.currentUser;
                            if (user == null) return;
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await _postRepo.addComment(
                                postId: post.id,
                                authorId: user.id,
                                content: commentController.text,
                              );
                              commentController.clear();
                              setModalState(() => isLoadingComments = true);
                              _loadPosts();
                            } catch (e) {
                              messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
