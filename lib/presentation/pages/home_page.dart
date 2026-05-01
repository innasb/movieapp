import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../injection_container.dart';
import '../cubits/home_cubit.dart';
import '../cubits/home_state.dart';
import '../widgets/movie_card.dart';
import '../widgets/error_display.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/search_history_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..loadHomeData(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchHistoryService _searchHistoryService = sl<SearchHistoryService>();
  bool _showSearch = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSearchHistory();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _loadSearchHistory() {
    setState(() {
      _searchHistory = _searchHistoryService.getHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<HomeCubit>().loadMoreMovies();
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _searchFocusNode.unfocus();
        context.read<HomeCubit>().clearSearch();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isNotEmpty) {
      _searchHistoryService.addQuery(query.trim());
      _loadSearchHistory();
      context.read<HomeCubit>().onSearchChanged(query);
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                decoration: InputDecoration(
                  hintText: 'search_movies'.tr(),
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
                      context.read<HomeCubit>().clearSearch();
                      setState(() {});
                    },
                  ),
                ),
                onChanged: (query) {
                  context.read<HomeCubit>().onSearchChanged(query);
                  setState(() {});
                },
              )
            : Text(
                'movies'.tr().toUpperCase(),
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
          if (!_showSearch)
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).iconTheme.color ??
                    Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onPressed: () {
                context.push('/notifications');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          } else if (state is HomeLoaded) {
            return RefreshIndicator(
              color: const Color(0xFFE50914),
              onRefresh: () async {
                context.read<HomeCubit>().loadHomeData();
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Category chips — hidden during search
                  if (!state.isSearchMode)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.categories.length,
                            itemBuilder: (context, index) {
                              final category = state.categories[index];
                              final isSelected =
                                  state.selectedCategoryId == category.id;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(category.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      context
                                          .read<HomeCubit>()
                                          .loadMoviesByCategory(category.id);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // Empty state for search
                  if (state.isSearchMode && state.movies.isEmpty && _searchController.text.isNotEmpty)
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
                              'no_movies_found'.tr(),
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
                  else if (_showSearch && _searchController.text.isEmpty && _searchHistory.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'recent_searches'.tr(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).textTheme.titleMedium?.color,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await _searchHistoryService.clearHistory();
                                    _loadSearchHistory();
                                  },
                                  child: Text('clear'.tr()),
                                ),
                              ],
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchHistory.length,
                            itemBuilder: (context, index) {
                              final query = _searchHistory[index];
                              return ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(query),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () async {
                                    await _searchHistoryService.removeQuery(query);
                                    _loadSearchHistory();
                                  },
                                ),
                                onTap: () {
                                  _searchController.text = query;
                                  _submitSearch(query);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  else if (state.isSearchMode ||
                      state.selectedCategoryId != 0) ...[
                    // Search Results or Category Results grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.55,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final movie = state.movies[index];
                          return MovieCard(
                            movie: movie,
                            onTap: () {
                              context.push('/detail/${movie.id}');
                            },
                          );
                        }, childCount: state.movies.length),
                      ),
                    ),
                  ] else ...[
                    // Home Default Layout (Hero, Trending, Top Rated)
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'trending_now'.tr()),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalList(
                        context,
                        state.trendingMovies,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'top_rated'.tr()),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalList(
                        context,
                        state.topRatedMovies,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildSectionTitle(context, 'recent_movies'.tr()),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHorizontalList(context, state.recentMovies),
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
          } else if (state is HomeError) {
            return ErrorDisplay(
              message: state.message,
              onRetry: () {
                context.read<HomeCubit>().loadHomeData();
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

  Widget _buildHorizontalList(BuildContext context, List movies) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 16),
            child: MovieCard(
              movie: movie,
              onTap: () {
                context.push('/detail/${movie.id}');
              },
            ),
          );
        },
      ),
    );
  }
}
