import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../injection_container.dart';
import '../cubits/tv_show_detail_cubit.dart';
import '../cubits/tv_show_detail_state.dart';
import '../widgets/error_display.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/episode.dart';

class TvShowDetailPage extends StatelessWidget {
  final int tvShowId;

  const TvShowDetailPage({super.key, required this.tvShowId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TvShowDetailCubit>()..loadTvShowDetail(tvShowId),
      child: Scaffold(
        body: BlocBuilder<TvShowDetailCubit, TvShowDetailState>(
          builder: (context, state) {
            if (state is TvShowDetailLoading || state is TvShowDetailInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              );
            } else if (state is TvShowDetailLoaded) {
              final tvShow = state.tvShow;
              final textColor =
                  Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: MediaQuery.of(context).size.height * 0.5,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildBackdrop(context, tvShow.backdropPath),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tvShow.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                tvShow.firstAirDate.isNotEmpty 
                                  ? tvShow.firstAirDate.substring(0, 4) 
                                  : '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tvShow.voteAverage.toStringAsFixed(1),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tvShow.genres
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
                          
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                context.push('/watch-together/tv/$tvShowId');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE50914),
                                side: const BorderSide(color: Color(0xFFE50914), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_alt_rounded, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'watch_together'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'overview'.tr(),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.titleLarge?.color,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tvShow.overview,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // SEASONS DROPDOWN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'episodes'.tr(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.color,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (tvShow.seasons.isNotEmpty)
                                DropdownButton<int>(
                                  value: state.selectedSeasonNumber,
                                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                                  underline: Container(),
                                  icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                                  items: tvShow.seasons.map((Season season) {
                                    return DropdownMenuItem<int>(
                                      value: season.seasonNumber,
                                      child: Text(
                                        season.name,
                                        style: TextStyle(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (int? newValue) {
                                    if (newValue != null && newValue != state.selectedSeasonNumber) {
                                      context.read<TvShowDetailCubit>().loadSeasonEpisodes(tvShowId, newValue);
                                    }
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
                  if (state.isEpisodesLoading)
                     const SliverToBoxAdapter(
                       child: Center(
                         child: Padding(
                           padding: EdgeInsets.all(32.0),
                           child: CircularProgressIndicator(color: Color(0xFFE50914)),
                         ),
                       ),
                     )
                  else if (state.currentSeasonEpisodes.isEmpty)
                     SliverToBoxAdapter(
                       child: Center(
                         child: Padding(
                           padding: const EdgeInsets.all(32.0),
                           child: Text(
                             'No episodes available.',
                             style: TextStyle(color: textColor.withOpacity(0.5)),
                           ),
                         ),
                       ),
                     )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final episode = state.currentSeasonEpisodes[index];
                          return _buildEpisodeItem(context, episode, tvShowId, state.selectedSeasonNumber);
                        },
                        childCount: state.currentSeasonEpisodes.length,
                      ),
                    ),
                    
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              );
            } else if (state is TvShowDetailError) {
              return ErrorDisplay(
                message: state.message,
                onRetry: () {
                  context.read<TvShowDetailCubit>().loadTvShowDetail(tvShowId);
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildEpisodeItem(BuildContext context, Episode episode, int tvId, int seasonNumber) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return InkWell(
      onTap: () {
        // Launch PlayerPage with TV Show config
        context.push('/player/tv/$tvId/$seasonNumber/${episode.episodeNumber}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Episode Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 120,
                height: 68,
                child: CachedNetworkImage(
                  imageUrl: episode.stillPath,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.tv, color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Episode Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${episode.episodeNumber}. ${episode.name}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    episode.overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
