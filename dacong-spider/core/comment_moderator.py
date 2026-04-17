"""
评论审核模块
使用 Claude API 进行智能审核，检测垃圾评论、敏感内容等
"""

import os
import re
from typing import Dict, List, Tuple
from anthropic import Anthropic


class CommentModerator:
    """评论审核器"""

    def __init__(self):
        self.client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
        self.model = "claude-3-5-sonnet-20241022"

        # 敏感词库（可扩展）
        self.sensitive_words = [
            "垃圾", "傻逼", "fuck", "shit", "damn", "idiot",
            "政治", "暴力", "色情", "赌博", "毒品",
        ]

        # 垃圾评论特征
        self.spam_patterns = [
            r"(http|https)://[^\s]+",  # URL链接
            r"\d{10,}",  # 长数字（可能是电话号码）
            r"(微信|QQ|联系方式|加我)",  # 联系方式
            r"(广告|推广|代理|招商)",  # 广告词
        ]

    def moderate_comment(self, content: str) -> Dict:
        """
        审核评论

        Args:
            content: 评论内容

        Returns:
            {
                "approved": bool,  # 是否通过审核
                "reason": str,  # 拒绝原因
                "confidence": float,  # 置信度 (0-1)
                "issues": List[str],  # 发现的问题列表
            }
        """
        issues = []

        # 1. 基础检查
        if not content or len(content.strip()) == 0:
            return {
                "approved": False,
                "reason": "Empty comment",
                "confidence": 1.0,
                "issues": ["empty_content"],
            }

        if len(content) > 2000:
            return {
                "approved": False,
                "reason": "Comment too long",
                "confidence": 1.0,
                "issues": ["too_long"],
            }

        # 2. 敏感词检测
        has_sensitive_words = self._check_sensitive_words(content)
        if has_sensitive_words:
            issues.append("sensitive_words")

        # 3. 垃圾评论检测
        is_spam = self._check_spam(content)
        if is_spam:
            issues.append("spam")

        # 4. 如果有明显问题，直接拒绝
        if has_sensitive_words or is_spam:
            return {
                "approved": False,
                "reason": "Contains sensitive words or spam",
                "confidence": 0.9,
                "issues": issues,
            }

        # 5. 使用 Claude API 进行深度审核
        ai_result = self._ai_moderate(content)

        return {
            "approved": ai_result["approved"],
            "reason": ai_result["reason"],
            "confidence": ai_result["confidence"],
            "issues": issues + ai_result["issues"],
        }

    def _check_sensitive_words(self, content: str) -> bool:
        """检查敏感词"""
        content_lower = content.lower()
        for word in self.sensitive_words:
            if word.lower() in content_lower:
                return True
        return False

    def _check_spam(self, content: str) -> bool:
        """检查垃圾评论特征"""
        for pattern in self.spam_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                return True
        return False

    def _ai_moderate(self, content: str) -> Dict:
        """
        使用 Claude API 进行智能审核

        Returns:
            {
                "approved": bool,
                "reason": str,
                "confidence": float,
                "issues": List[str],
            }
        """
        try:
            prompt = f"""你是一个评论审核助手。请审核以下评论内容，判断是否应该通过审核。

评论内容：
{content}

审核标准：
1. 不包含人身攻击、侮辱、歧视性言论
2. 不包含政治敏感内容
3. 不包含色情、暴力、赌博等违法内容
4. 不是垃圾广告或营销信息
5. 不是无意义的灌水内容

请以JSON格式返回审核结果：
{{
    "approved": true/false,
    "reason": "拒绝原因（如果approved为false）",
    "confidence": 0.0-1.0,
    "issues": ["issue1", "issue2"]
}}

只返回JSON，不要其他内容。"""

            response = self.client.messages.create(
                model=self.model,
                max_tokens=500,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )

            # 解析响应
            result_text = response.content[0].text.strip()

            # 提取JSON（去除可能的markdown代码块标记）
            if result_text.startswith("```"):
                result_text = result_text.split("```")[1]
                if result_text.startswith("json"):
                    result_text = result_text[4:]

            import json
            result = json.loads(result_text)

            return {
                "approved": result.get("approved", True),
                "reason": result.get("reason", ""),
                "confidence": result.get("confidence", 0.5),
                "issues": result.get("issues", []),
            }

        except Exception as e:
            print(f"AI moderation error: {e}")
            # 如果AI审核失败，默认通过（避免误杀）
            return {
                "approved": True,
                "reason": "",
                "confidence": 0.5,
                "issues": ["ai_moderation_failed"],
            }

    def batch_moderate(self, comments: List[str]) -> List[Dict]:
        """批量审核评论"""
        results = []
        for content in comments:
            result = self.moderate_comment(content)
            results.append(result)
        return results


# 使用示例
if __name__ == "__main__":
    moderator = CommentModerator()

    # 测试用例
    test_comments = [
        "这个工具真不错，推荐大家使用！",
        "垃圾产品，浪费时间",
        "加我微信：123456789，有好东西分享",
        "http://spam-site.com 点击领取奖品",
        "",
        "非常有用的教程，感谢分享！",
    ]

    print("评论审核测试：\n")
    for i, comment in enumerate(test_comments, 1):
        result = moderator.moderate_comment(comment)
        print(f"评论 {i}: {comment[:30]}...")
        print(f"  通过: {result['approved']}")
        print(f"  原因: {result['reason']}")
        print(f"  置信度: {result['confidence']}")
        print(f"  问题: {result['issues']}")
        print()
