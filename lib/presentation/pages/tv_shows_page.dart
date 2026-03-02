import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../injection_container.dart';
import '../cubits/tv_shows_cubit.dart';
import '../cubits/tv_shows_state.dart';
import '../widgets/tv_show_card.dart';
import '../widgets/error_display.dart';
import 'package:go_router/go_router.dart';

class TvShowsPage extends StatelessWidget {
  const TvShowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TvShowsCubit>()..loadTvShowsData(),
      child: const _TvShowsView(),
    );
  }
}

class _TvShowsView extends StatefulWidget {
  const _TvShowsView();

  @override
  State<_TvShowsView> createState() => _TvShowsViewState();
}

class _TvShowsViewState extends State<_TvShowsView> {
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
      context.read<TvShowsCubit>().loadMoreTvShows();
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        context.read<TvShowsCubit>().clearSearch();
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
                  hintText: 'search_tv_shows'.tr(),
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(
                        context,
                      ).iconTheme.color?.withOpacity(0.7),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      context.read<TvShowsCubit>().clearSearch();
                    },
                  ),
                ),
                onChanged: (query) {
                  context.read<TvShowsCubit>().onSearchChanged(query);
                },
              )
            : Text(
                'tv_shows'.tr().toUpperCase(),
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
              color:
                  Theme.of(context).iconTheme.color ??
                  Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: _toggleSearch,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TvShowsCubit, TvShowsState>(
        builder: (context, state) {
          if (state is TvShowsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          } else if (state is TvShowsLoaded) {
            return RefreshIndicator(
              color: const Color(0xFFE50914),
              onRefresh: () async {
                context.read<TvShowsCubit>().loadTvShowsData();
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Empty state for search
                  if (state.isSearchMode && state.shows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              color: Theme.of(
                                context,
                              ).iconTheme.color?.withOpacity(0.38),
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_tv_shows_found'.tr(),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.55,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final show = state.shows[index];
                          return TvShowCard(
                            tvShow: show,
                            onTap: () {
                              context.push('/tv_detail/${show.id}');
                            },
                          );
                        }, childCount: state.shows.length),
                      ),
                    ),
                  ] else ...[
                    // Default Layout (Trending, Top Rated)
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'trending_now'.tr()),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalList(
                        context,
                        state.trendingTvShows,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'top_rated'.tr()),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalList(
                        context,
                        state.topRatedTvShows,
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
          } else if (state is TvShowsError) {
            return ErrorDisplay(
              message: state.message,
              onRetry: () {
                context.read<TvShowsCubit>().loadTvShowsData();
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

  Widget _buildHorizontalList(BuildContext context, List shows) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: TvShowCard(
              tvShow: show,
              onTap: () {
                context.push('/tv_detail/${show.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
