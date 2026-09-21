// 飙升榜 Provider - Riverpod 状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/rising_star_model.dart';
import '../../data/repositories/rising_stars_repository.dart';

// Repository Provider
final risingStarsRepositoryProvider = Provider<RisingStarsRepository>((ref) {
  return RisingStarsRepository.instance;
});

class RisingStarsState {
  final List<RisingStar> repos;
  final bool isLoading;
  final String? error;
  final String period;

  const RisingStarsState({
    this.repos = const [],
    this.isLoading = false,
    this.error,
    this.period = '7d',
  });

  RisingStarsState copyWith({
    List<RisingStar>? repos,
    bool? isLoading,
    String? error,
    String? period,
  }) {
    return RisingStarsState(
      repos: repos ?? this.repos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      period: period ?? this.period,
    );
  }
}

class RisingStarsNotifier extends StateNotifier<RisingStarsState> {
  final RisingStarsRepository _repo;

  RisingStarsNotifier(this._repo) : super(const RisingStarsState());

  Future<void> load({String? period}) async {
    if (state.isLoading) return;
    final target = period ?? state.period;
    state = state.copyWith(isLoading: true, error: null, period: target);

    try {
      final repos = await _repo.getRisingStars(period: target);
      state = RisingStarsState(repos: repos, isLoading: false, period: target);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => load();
}

final risingStarsProvider =
    StateNotifierProvider<RisingStarsNotifier, RisingStarsState>((ref) {
  return RisingStarsNotifier(ref.watch(risingStarsRepositoryProvider));
});
