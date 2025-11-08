import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../repositories/Akram/media_comment_repository.dart';

class TopMediaPieChart extends StatefulWidget {
  const TopMediaPieChart({super.key});

  @override
  State<TopMediaPieChart> createState() => _TopMediaPieChartState();
}

class _TopMediaPieChartState extends State<TopMediaPieChart> {
  List<MediaRating> topMediaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopMedia();
  }

  Future<void> _loadTopMedia() async {
    try {
      final allComments = await CommentRepository.loadComments();

      // Group comments by media title and calculate average rating
      final mediaRatings = <String, List<double>>{};

      for (var comment in allComments) {
        if (!mediaRatings.containsKey(comment.mediaTitle)) {
          mediaRatings[comment.mediaTitle] = [];
        }
        mediaRatings[comment.mediaTitle]!.add(comment.rating);
      }

      // Calculate average ratings and create list
      final ratings = mediaRatings.entries
          .map((entry) {
        final ratings = entry.value;
        final avgRating = ratings.fold(0.0, (a, b) => a + b) / ratings.length;
        return MediaRating(
          title: entry.key,
          averageRating: avgRating,
          commentCount: ratings.length,
        );
      })
          .toList();

      // Sort by average rating (descending) and take top 5
      ratings.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      final top5 = ratings.take(5).toList();

      setState(() {
        topMediaList = top5;
        isLoading = false;
      });

      print('✅ Loaded ${top5.length} top media');
      for (var media in top5) {
        print('📊 ${media.title}: ${media.averageRating.toStringAsFixed(2)}/5 (${media.commentCount} comments)');
      }
    } catch (e) {
      print('❌ Error loading top media: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Media'),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : topMediaList.isEmpty
          ? const Center(
        child: Text('No comments data available'),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie Chart
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Top 5 Media by Average Rating',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                // Handle pie chart touch
                              },
                            ),
                            sections: _getPieChartSections(),
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Legend and Details
              Text(
                'Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...topMediaList.asMap().entries.map((entry) {
                final index = entry.key;
                final media = entry.value;
                final color = _getColorForIndex(index);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                media.title.isEmpty ? 'Unknown' : media.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${media.commentCount} ${media.commentCount == 1 ? 'comment' : 'comments'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${media.averageRating.toStringAsFixed(2)}/5',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.amber,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                5,
                                    (i) => Icon(
                                  i < media.averageRating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    return topMediaList.asMap().entries.map((entry) {
      final index = entry.key;
      final media = entry.value;
      final color = _getColorForIndex(index);

      return PieChartSectionData(
        color: color,
        value: media.averageRating,
        title: '${media.averageRating.toStringAsFixed(1)}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}

class MediaRating {
  final String title;
  final double averageRating;
  final int commentCount;

  MediaRating({
    required this.title,
    required this.averageRating,
    required this.commentCount,
  });
}