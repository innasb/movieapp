import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../injection_container.dart';
import '../cubits/anime_cubit.dart';
import '../cubits/anime_state.dart';
import '../widgets/anime_card.dart';
import '../widgets/error_display.dart';

class AnimePage extends StatelessWidget {
  const AnimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnimeCubit>()..loadAnimeData(),
      child: const _AnimeView(),
    );
  }
}

class _AnimeView extends StatefulWidget {
  const _AnimeView();

  @override
  State<_AnimeView> createState() => _AnimeViewState();
}

class _AnimeViewState extends State<_AnimeView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<AnimeCubit>().loadMoreAnime();
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        context.read<AnimeCubit>().clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'search_anime'.tr(),
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context)
                          .iconTheme
                          .color
                          ?.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      context.read<AnimeCubit>().clearSearch();
                    },
                  ),
                ),
                onChanged: (query) {
                  context.read<AnimeCubit>().onSearchChanged(query);
                },
              )
            : Text(
                'anime'.tr().toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFE50914),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Theme.of(context).iconTheme.color ??
                  Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: _toggleSearch,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<AnimeCubit, AnimeState>(
        builder: (context, state) {
          if (state is AnimeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          } else if (state is AnimeLoaded) {
            return RefreshIndicator(
              color: const Color(0xFFE50914),
              onRefresh: () async {
                context.read<AnimeCubit>().loadAnimeData();
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Empty state for search
                  if (state.isSearchMode && state.animeList.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              color: Theme.of(context)
                                  .iconTheme
                                  .color
                                  ?.withOpacity(0.38),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_anime_found'.tr(),
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state.isSearchMode) ...[
                    // Search Results grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate:
                            SliverChildBuilderDelegate((context, index) {
                          final anime = state.animeList[index];
                          return AnimeCard(
                            anime: anime,
                            onTap: () {
                              context.push('/anime_detail/${anime.malId}');
                            },
                          );
                        }, childCount: state.animeList.length),
                      ),
                    ),
                  ] else ...[
                    // Default Layout — Top Anime
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'top_rated'.tr()),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalList(context, state.topAnime),
                    ),
                    // All anime grid below
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'anime'.tr()),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate:
                            SliverChildBuilderDelegate((context, index) {
                          final anime = state.animeList[index];
                          return AnimeCard(
                            anime: anime,
                            onTap: () {
                              context.push('/anime_detail/${anime.malId}');
                            },
                          );
                        }, childCount: state.animeList.length),
                      ),
                    ),
                  ],

                  // Loading more indicator
                  if (state.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          } else if (state is AnimeError) {
            return ErrorDisplay(
              message: state.message,
              onRetry: () {
                context.read<AnimeCubit>().loadAnimeData();
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List animeList) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: animeList.length,
        itemBuilder: (context, index) {
          final anime = animeList[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: AnimeCard(
              anime: anime,
              onTap: () {
                context.push('/anime_detail/${anime.malId}');
              },
            ),
          );
        },
      ),
    );
  }
}
