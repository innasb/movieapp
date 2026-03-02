import '../entities/tv_show_detail.dart';
import '../repositories/tv_repository.dart';

class GetTvShowDetail {
  final TvRepository repository;

  GetTvShowDetail(this.repository);

  Future<TvShowDetail> call(int id) {
    return repository.getTvShowDetail(id);
  }
}
