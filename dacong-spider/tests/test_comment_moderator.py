"""
评论审核模块测试
"""

import unittest
import sys
import os

# 添加项目根目录到路径
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from core.comment_moderator import CommentModerator


class TestCommentModerator(unittest.TestCase):
    """评论审核器测试"""

    def setUp(self):
        """测试前准备"""
        self.moderator = CommentModerator()

    def test_empty_comment(self):
        """测试空评论"""
        result = self.moderator.moderate_comment("")
        self.assertFalse(result["approved"])
        self.assertIn("empty_content", result["issues"])

    def test_too_long_comment(self):
        """测试过长评论"""
        long_comment = "a" * 2001
        result = self.moderator.moderate_comment(long_comment)
        self.assertFalse(result["approved"])
        self.assertIn("too_long", result["issues"])

    def test_sensitive_words(self):
        """测试敏感词检测"""
        comments_with_sensitive_words = [
            "这是垃圾产品",
            "你个傻逼",
            "fuck this shit",
        ]

        for comment in comments_with_sensitive_words:
            result = self.moderator.moderate_comment(comment)
            self.assertFalse(result["approved"])
            self.assertIn("sensitive_words", result["issues"])

    def test_spam_detection(self):
        """测试垃圾评论检测"""
        spam_comments = [
            "访问 http://spam-site.com 领取奖品",
            "加我微信：1234567890",
            "广告推广，联系QQ：123456",
        ]

        for comment in spam_comments:
            result = self.moderator.moderate_comment(comment)
            self.assertFalse(result["approved"])
            self.assertIn("spam", result["issues"])

    def test_normal_comment(self):
        """测试正常评论"""
        normal_comments = [
            "这个工具真不错，推荐大家使用！",
            "非常有用的教程，感谢分享！",
            "Great tool, highly recommended!",
        ]

        for comment in normal_comments:
            result = self.moderator.moderate_comment(comment)
            # 正常评论应该通过基础检查
            self.assertNotIn("sensitive_words", result["issues"])
            self.assertNotIn("spam", result["issues"])

    def test_batch_moderate(self):
        """测试批量审核"""
        comments = [
            "正常评论",
            "垃圾评论",
            "http://spam.com",
        ]

        results = self.moderator.batch_moderate(comments)
        self.assertEqual(len(results), 3)
        self.assertIsInstance(results[0], dict)
        self.assertIn("approved", results[0])

    def test_confidence_score(self):
        """测试置信度分数"""
        result = self.moderator.moderate_comment("正常评论")
        self.assertIn("confidence", result)
        self.assertGreaterEqual(result["confidence"], 0.0)
        self.assertLessEqual(result["confidence"], 1.0)


class TestCommentModeratorEdgeCases(unittest.TestCase):
    """边界情况测试"""

    def setUp(self):
        self.moderator = CommentModerator()

    def test_whitespace_only(self):
        """测试仅包含空白字符"""
        result = self.moderator.moderate_comment("   \n\t  ")
        self.assertFalse(result["approved"])

    def test_exactly_2000_chars(self):
        """测试恰好2000字符"""
        comment = "a" * 2000
        result = self.moderator.moderate_comment(comment)
        # 应该通过长度检查
        self.assertNotIn("too_long", result["issues"])

    def test_mixed_language(self):
        """测试中英文混合"""
        comment = "This is a great tool 这个工具很棒"
        result = self.moderator.moderate_comment(comment)
        self.assertIsInstance(result, dict)
        self.assertIn("approved", result)

    def test_special_characters(self):
        """测试特殊字符"""
        comment = "Great! 👍 ❤️ 🎉"
        result = self.moderator.moderate_comment(comment)
        self.assertIsInstance(result, dict)


if __name__ == "__main__":
    # 运行测试
    unittest.main(verbosity=2)
