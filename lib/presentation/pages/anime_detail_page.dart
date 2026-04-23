import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../injection_container.dart';
import '../cubits/anime_detail_cubit.dart';
import '../cubits/anime_detail_state.dart';
import '../widgets/error_display.dart';

class AnimeDetailPage extends StatelessWidget {
  final int malId;

  const AnimeDetailPage({super.key, required this.malId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnimeDetailCubit>()..loadAnimeDetail(malId),
      child: Scaffold(
        body: BlocBuilder<AnimeDetailCubit, AnimeDetailState>(
          builder: (context, state) {
            if (state is AnimeDetailLoading || state is AnimeDetailInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              );
            } else if (state is AnimeDetailLoaded) {
              final anime = state.anime;
              final textColor =
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.5,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildBackdrop(context, anime.imageUrl),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (anime.titleJapanese.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              anime.titleJapanese,
                              style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE50914),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  anime.type,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: textColor.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  anime.status,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                anime.score.toStringAsFixed(1),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (anime.episodes > 0) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '${anime.episodes} ep',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Genres
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: anime.genres
                                .map(
                                  (genre) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: textColor.withOpacity(0.1),
                                      border: Border.all(
                                        color: textColor.withOpacity(0.2),
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      genre,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'overview'.tr(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            anime.synopsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Sub / Dub Toggle
                          Text(
                            'episodes'.tr(),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSubDubChip(
                                context,
                                label: 'SUB',
                                isSelected: state.subOrDub == 'sub',
                                onTap: () {
                                  context
                                      .read<AnimeDetailCubit>()
                                      .toggleSubDub('sub');
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildSubDubChip(
                                context,
                                label: 'DUB',
                                isSelected: state.subOrDub == 'dub',
                                onTap: () {
                                  context
                                      .read<AnimeDetailCubit>()
                                      .toggleSubDub('dub');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // EPISODES LIST
                  if (anime.episodes > 0)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final episodeNumber = index + 1;
                          return _buildEpisodeItem(
                            context,
                            episodeNumber,
                            malId,
                            state.subOrDub,
                          );
                        },
                        childCount: anime.episodes,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Episodes info not available. Tap below to try playing.',
                            style: TextStyle(
                              color: textColor.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              );
            } else if (state is AnimeDetailError) {
              return ErrorDisplay(
                message: state.message,
                onRetry: () {
                  context.read<AnimeDetailCubit>().loadAnimeDetail(malId);
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildSubDubChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE50914)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE50914)
                : (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white)
                    .withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeItem(
    BuildContext context,
    int episodeNumber,
    int animeId,
    String subOrDub,
  ) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return InkWell(
      onTap: () {
        context.push('/player/anime/$animeId/$episodeNumber/$subOrDub');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Episode number circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE50914).withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '$episodeNumber',
                  style: const TextStyle(
                    color: Color(0xFFE50914),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'episodes'.tr()} $episodeNumber',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subOrDub.toUpperCase(),
                    style: TextStyle(
                      color: textColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline,
              color: const Color(0xFFE50914),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackdrop(BuildContext context, String url) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[900]),
            errorWidget: (context, url, error) =>
                Container(color: Colors.grey[900]),
          )
        else
          Container(color: Colors.grey[900]),

        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  bgColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [bgColor, bgColor.withOpacity(0.0)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
