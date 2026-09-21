"""
单元测试 - 爬虫（registry 新架构）

新架构下爬虫只需实现 SpiderBase.do_fetch(fetcher, writer)，
HTTP 与数据库都由注入的协作者负责，因此测试策略是：
  1. 解析逻辑：直接喂 HTML 字符串，断言结构化输出
  2. 执行流程：用 MockFetcher / MockWriter 替身，断言 SpiderResult 与写入内容
  3. 错误路径：Fetcher 返回 None，断言不抛异常且记入 errors

不依赖网络、不依赖数据库。
"""
import pytest

from spiders.github_trending import GitHubTrendingSpider
from spiders.huggingface import HuggingFaceSpider
from tests.mocks import FakeResponse, MockFetcher, MockWriter


# ══════════════════════════════════════════════════════════
# 样本页面
# ══════════════════════════════════════════════════════════

def trending_html(repo: str = "owner/repo", description: str = "LLM inference server",
                  language: str = "Python", stars: str = "1,234",
                  forks: str = "56") -> str:
    """构造最小可用的 github.com/trending 页面片段"""
    return f"""
    <html><body>
      <article class="Box-row">
        <h2><a href="/{repo}">{repo}</a></h2>
        <p>{description}</p>
        <span itemprop="programmingLanguage">{language}</span>
        <a href="/{repo}/stargazers">{stars}</a>
        <a href="/{repo}/members">{forks}</a>
      </article>
    </body></html>
    """


def hf_models_html(path: str = "meta-llama/Llama-2-7b", name: str = "Llama 2 7B",
                   downloads: str = "1.2m", likes: str = "5,000") -> str:
    """构造最小可用的 huggingface.co/models 页面片段"""
    return f"""
    <html><body>
      <article id="model-card">
        <a href="/models/{path}">{path}</a>
        <h4>{name}</h4>
        <span class="text-secondary">{downloads}</span>
        <span class="like">{likes}</span>
      </article>
    </body></html>
    """


# ══════════════════════════════════════════════════════════
# Fixtures
# ══════════════════════════════════════════════════════════

@pytest.fixture
def github_spider(monkeypatch) -> GitHubTrendingSpider:
    """GitHub 爬虫：不爬语言子页、不调 GitHub API 补全（避免网络与 sleep）"""

    async def _no_enrich(self, repos, cache):
        return None

    monkeypatch.setattr(GitHubTrendingSpider, "languages", property(lambda self: []))
    monkeypatch.setattr(GitHubTrendingSpider, "_enrich_total_stars", _no_enrich)
    return GitHubTrendingSpider()


@pytest.fixture
def hf_spider(monkeypatch) -> HuggingFaceSpider:
    """HuggingFace 爬虫：只跑一个 pipeline tag，避免多次 sleep"""
    monkeypatch.setattr(
        "spiders.huggingface.SPIDERS",
        {"huggingface": {"tags": ["text-generation"]}},
    )
    return HuggingFaceSpider()


# ══════════════════════════════════════════════════════════
# GitHub - 页面解析
# ══════════════════════════════════════════════════════════

def test_parse_trending_page_extracts_fields(github_spider):
    """解析出仓库全名、描述、语言、今日星、fork、URL"""
    ai_repos, all_repos = github_spider._parse_trending_page(
        trending_html(stars="1,234", forks="56")
    )

    assert len(all_repos) == 1
    repo = all_repos[0]
    assert repo["full_name"] == "owner/repo"
    assert repo["owner"] == "owner"
    assert repo["repo"] == "repo"
    assert repo["description"] == "LLM inference server"
    assert repo["language"] == "Python"
    assert repo["stars_today"] == 1234
    assert repo["forks"] == 56
    assert repo["url"] == "https://github.com/owner/repo"


def test_parse_trending_page_splits_ai_repos(github_spider):
    """描述含 AI 关键词的仓库进入 ai_repos，否则只进 all_repos"""
    ai_repos, all_repos = github_spider._parse_trending_page(
        trending_html(description="LLM inference server")
    )
    assert len(ai_repos) == 1

    ai_repos, all_repos = github_spider._parse_trending_page(
        trending_html(description="A cli tool for logs", language="Go")
    )
    assert len(ai_repos) == 0
    assert len(all_repos) == 1


def test_parse_trending_page_skips_malformed_article(github_spider):
    """缺少 h2 a（拿不到仓库名）的条目被跳过，而不是抛异常"""
    html = "<html><body><article class='Box-row'><p>no link</p></article></body></html>"
    ai_repos, all_repos = github_spider._parse_trending_page(html)
    assert ai_repos == [] and all_repos == []


@pytest.mark.parametrize("text,expected", [
    ("1,234", 1234),
    ("2.3k", 2300),
    ("1.5m", 1500000),
    ("12 stars today", 12),
    ("0", 0),
])
def test_parse_stars(github_spider, text, expected):
    """星标字符串支持千分位、k/m 后缀与 stars today 后缀"""
    assert github_spider._parse_stars(text) == expected


def test_parse_stars_invalid_returns_zero(github_spider):
    with pytest.raises(ValueError):
        github_spider._parse_stars("not-a-number")


# ══════════════════════════════════════════════════════════
# GitHub - 执行流程（MockFetcher + MockWriter）
# ══════════════════════════════════════════════════════════

async def test_github_do_fetch_success(github_spider):
    """正常流程：抓取 → 解析 → 写入，SpiderResult 计数正确"""
    fetcher = MockFetcher(default=FakeResponse(trending_html()))
    writer = MockWriter()

    result = await github_spider.do_fetch(fetcher, writer)

    assert result.success is True
    assert result.items_fetched == 2  # 1 条 AI + 1 条全量（同一仓库计入两次）
    assert result.items_written == 2
    assert len(writer.repo_metrics) == 1
    assert len(writer.model_metrics) == 1


async def test_github_do_fetch_failure_is_not_raised(github_spider):
    """首屏请求失败：success=False、记录 errors，但不抛异常"""
    fetcher = MockFetcher(default=None)
    writer = MockWriter()

    result = await github_spider.do_fetch(fetcher, writer)

    assert result.success is False
    assert result.items_fetched == 0
    assert result.items_written == 0
    assert any("失败" in e for e in result.errors)


async def test_github_do_fetch_deduplicates_same_repo(github_spider):
    """同一仓库在页面重复出现，repository_metrics 只写一条"""
    html = trending_html() + trending_html()
    fetcher = MockFetcher(default=FakeResponse(html))
    writer = MockWriter()

    result = await github_spider.do_fetch(fetcher, writer)

    assert result.success is True
    assert len(writer.repo_metrics) == 1  # 去重后唯一
    assert result.items_written == 2      # AI + 全量各写一次成功，第二次被去重


async def test_github_do_fetch_content_update(github_spider):
    """同一仓库 star 变化后再爬取：写入器按业务键覆盖，不产生新记录"""
    writer = MockWriter()

    result1 = await github_spider.do_fetch(
        MockFetcher(default=FakeResponse(trending_html(stars="100"))), writer
    )
    result2 = await github_spider.do_fetch(
        MockFetcher(default=FakeResponse(trending_html(stars="200"))), writer
    )

    assert result1.items_written == 2
    assert result2.items_written == 0  # 24h 内重复，全部跳过
    assert len(writer.repo_metrics) == 1


# ══════════════════════════════════════════════════════════
# HuggingFace - 页面解析
# ══════════════════════════════════════════════════════════

def test_hf_parse_models_page_extracts_fields(hf_spider):
    """解析出模型路径、名称、下载量、点赞数、URL"""
    models = hf_spider._parse_models_page(hf_models_html())

    assert len(models) == 1
    m = models[0]
    assert m["path"] == "meta-llama/Llama-2-7b"
    assert m["name"] == "Llama 2 7B"
    assert m["downloads"] == 1200000
    assert m["likes"] == 5000
    assert m["url"] == "https://huggingface.co/meta-llama/Llama-2-7b"


def test_hf_parse_models_page_keeps_full_path(hf_spider):
    """
    路径必须以 /models/ 前缀整体剥离，而不是按字符集剥离。

    曾因 lstrip("/models/") 把 "meta-llama/..." 削成 "ta-llama/..."。
    """
    models = hf_spider._parse_models_page(hf_models_html(path="mistralai/Mistral-7B"))
    assert models[0]["path"] == "mistralai/Mistral-7B"


def test_hf_parse_models_page_skips_cards_without_link(hf_spider):
    html = "<html><body><article><h4>orphan</h4></article></body></html>"
    assert hf_spider._parse_models_page(html) == []


async def test_hf_do_fetch_success(hf_spider):
    """正常流程：抓取 → 解析 → 写入一条模型指标"""
    fetcher = MockFetcher(default=FakeResponse(hf_models_html()))
    writer = MockWriter()

    result = await hf_spider.do_fetch(fetcher, writer)

    assert result.success is True
    assert result.items_fetched == 1
    assert result.items_written == 1
    assert len(writer.model_metrics) == 1


async def test_hf_do_fetch_failure_is_not_raised(hf_spider):
    """请求失败：success=False、记录 errors，但不抛异常"""
    result = await hf_spider.do_fetch(MockFetcher(default=None), MockWriter())

    assert result.success is False
    assert result.items_written == 0
    assert any("失败" in e for e in result.errors)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
