"""
单元测试 - 飙升榜评分纯函数

覆盖 spiders/github_trending.py 的 compute_velocity / compute_rank_score，
这两个函数是 Edge Function `compute-rising-stars` 的参考实现，
改动任一侧都应让本测试同时通过。
"""
import pytest

from spiders.github_trending import compute_rank_score, compute_velocity


# ══════════════════════════════════════════════════════════
# compute_velocity：最小二乘斜率（stars/day）
# ══════════════════════════════════════════════════════════

class TestComputeVelocity:

    def test_perfect_linear_growth(self):
        """每天稳定涨 10 星 → 斜率 10"""
        points = [(float(day), 100 + 10 * day) for day in range(7)]
        assert compute_velocity(points) == pytest.approx(10.0)

    def test_flat_series_has_zero_velocity(self):
        """星数不变 → 斜率 0"""
        points = [(float(day), 500) for day in range(5)]
        assert compute_velocity(points) == pytest.approx(0.0)

    def test_declining_series_is_negative(self):
        """星数下降 → 斜率为负"""
        points = [(0.0, 300), (1.0, 290), (2.0, 280)]
        assert compute_velocity(points) == pytest.approx(-10.0)

    def test_noisy_series_fits_average_slope(self):
        """带噪声时拟合平均增速，而非首尾直连"""
        points = [(0.0, 0), (1.0, 30), (2.0, 10), (3.0, 30)]
        # 最小二乘解：7.0（首尾直连会得到 10.0）
        assert compute_velocity(points) == pytest.approx(7.0)

    def test_uneven_intervals(self):
        """采样间隔不均匀时仍按 x 轴真实间距拟合"""
        points = [(0.0, 100), (1.0, 110), (5.0, 150)]
        assert compute_velocity(points) == pytest.approx(10.0)

    @pytest.mark.parametrize("points", [[], [(0.0, 100)]])
    def test_insufficient_points_return_zero(self, points):
        """不足 2 个点无法拟合 → 0.0"""
        assert compute_velocity(points) == 0.0

    def test_identical_x_returns_zero(self):
        """x 无变化会导致除零 → 兜底返回 0.0"""
        points = [(3.0, 100), (3.0, 200)]
        assert compute_velocity(points) == 0.0


# ══════════════════════════════════════════════════════════
# compute_rank_score：0.5*stars_7d + 0.3*velocity + 0.2*stars_1d
# ══════════════════════════════════════════════════════════

class TestComputeRankScore:

    def test_weighted_sum(self):
        # 0.5*700 + 0.3*100 + 0.2*50 = 350 + 30 + 10 = 390
        assert compute_rank_score(stars_1d=50, stars_7d=700, velocity=100.0) == pytest.approx(390.0)

    def test_all_zero(self):
        assert compute_rank_score(0, 0, 0.0) == 0.0

    def test_weekly_growth_dominates_daily(self):
        """相同总增量下，7 日权重高于 1 日"""
        weekly_heavy = compute_rank_score(stars_1d=0, stars_7d=100, velocity=0.0)
        daily_heavy = compute_rank_score(stars_1d=100, stars_7d=0, velocity=0.0)
        assert weekly_heavy > daily_heavy

    def test_negative_velocity_lowers_score(self):
        """增速转负会拉低综合分"""
        rising = compute_rank_score(stars_1d=10, stars_7d=70, velocity=10.0)
        cooling = compute_rank_score(stars_1d=10, stars_7d=70, velocity=-10.0)
        assert cooling < rising
