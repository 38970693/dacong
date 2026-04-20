# AI增强系统 - 详细设计文档

> 工期：8-10周 | 工时：160-200小时 | 优先级：P1（技术亮点）

---

## 📋 工程概览

### 目标
构建完整的AI增强系统，通过智能推荐、语义搜索、内容分析和AI审核，提升用户体验并降低运营成本。

### 核心价值
- 提升用户体验（个性化推荐）
- 降低运营成本（AI辅助审核）
- 形成技术壁垒
- 提高内容质量

---

## 🏗️ 系统架构

```
┌─────────────────────────────────────────────────────┐
│                   用户界面层                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │推荐列表  │  │智能搜索  │  │内容分析  │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
┌───────┼─────────────┼─────────────┼─────────────────┐
│       │             │             │   AI服务层       │
│  ┌────▼─────┐  ┌───▼──────┐  ┌──▼───────┐         │
│  │推荐引擎  │  │搜索引擎  │  │分析引擎  │         │
│  └────┬─────┘  └───┬──────┘  └──┬───────┘         │
└───────┼─────────────┼─────────────┼─────────────────┘
        │             │             │
┌───────┼─────────────┼─────────────┼─────────────────┐
│       │             │             │   数据层         │
│  ┌────▼─────┐  ┌───▼──────┐  ┌──▼───────┐         │
│  │用户画像  │  │向量索引  │  │内容特征  │         │
│  │行为数据  │  │Embeddings│  │标签库    │         │
│  └──────────┘  └──────────┘  └──────────┘         │
└─────────────────────────────────────────────────────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
   ┌────▼────┐              ┌──────▼──────┐
   │Supabase │              │  OpenAI API │
   │pgvector │              │  (GPT-4)    │
   └─────────┘              └─────────────┘
```

---

## 🧠 核心功能设计

## 1. 智能推荐引擎

### 1.1 推荐算法架构

```
用户请求
    │
    ▼
┌─────────────────┐
│  推荐调度器     │
└────┬────────────┘
     │
     ├──► 协同过滤推荐 (40%)
     │    └─ 基于用户行为相似度
     │
     ├──► 内容推荐 (40%)
     │    └─ 基于内容相似度
     │
     └──► 热门推荐 (20%)
          └─ 基于全局热度
     │
     ▼
┌─────────────────┐
│  结果融合器     │
│  (加权排序)     │
└────┬────────────┘
     │
     ▼
  推荐结果
```

### 1.2 协同过滤算法

**用户-物品矩阵**:
```
        Model1  Model2  Model3  Model4
User1     5       3       0       4
User2     4       0       5       3
User3     0       4       4       5
User4     3       5       0       0
```

**相似度计算** (余弦相似度):
```python
def cosine_similarity(user1_vector, user2_vector):
    dot_product = sum(a * b for a, b in zip(user1_vector, user2_vector))
    magnitude1 = sqrt(sum(a**2 for a in user1_vector))
    magnitude2 = sqrt(sum(b**2 for b in user2_vector))
    return dot_product / (magnitude1 * magnitude2)
```

**推荐生成**:
```python
def collaborative_filtering_recommend(user_id, top_k=10):
    # 1. 找到相似用户
    similar_users = find_similar_users(user_id, top_n=50)
    
    # 2. 聚合相似用户喜欢的内容
    candidate_items = aggregate_items(similar_users)
    
    # 3. 过滤用户已交互的内容
    candidate_items = filter_interacted(user_id, candidate_items)
    
    # 4. 按预测评分排序
    recommendations = rank_by_score(candidate_items)
    
    return recommendations[:top_k]
```

### 1.3 内容推荐算法

**内容特征提取**:
```python
def extract_content_features(content):
    return {
        'tags': content.tags,  # 标签
        'category': content.category,  # 分类
        'embedding': get_embedding(content.description),  # 语义向量
        'quality_score': content.quality_score,  # 质量分
    }
```

**内容相似度计算**:
```python
def content_similarity(content1, content2):
    # 标签相似度 (Jaccard)
    tag_sim = jaccard_similarity(content1.tags, content2.tags)
    
    # 语义相似度 (余弦)
    semantic_sim = cosine_similarity(
        content1.embedding, 
        content2.embedding
    )
    
    # 加权融合
    return 0.4 * tag_sim + 0.6 * semantic_sim
```

### 1.4 冷启动策略

**新用户冷启动**:
1. 显示热门内容（全局Top 20）
2. 引导用户选择兴趣标签
3. 基于标签推荐相关内容
4. 收集初始行为数据后切换到个性化推荐

**新内容冷启动**:
1. 基于内容特征推荐给相关兴趣用户
2. 收集初始反馈（点击、点赞、收藏）
3. 根据反馈调整推荐权重
4. 逐步扩大推荐范围

### 1.5 数据库设计

```sql
-- 用户画像表
CREATE TABLE user_profiles_ai (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  interest_tags TEXT[], -- 兴趣标签
  preference_vector VECTOR(1536), -- 偏好向量
  activity_level VARCHAR(20), -- 活跃度: low/medium/high
  last_active_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 推荐结果缓存表
CREATE TABLE recommendation_cache (
  user_id UUID NOT NULL REFERENCES auth.users(id),
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  score FLOAT NOT NULL,
  algorithm VARCHAR(50) NOT NULL, -- 'collaborative', 'content', 'hot'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, content_id, content_type)
);

CREATE INDEX idx_recommendation_cache_user ON recommendation_cache(user_id, score DESC);
CREATE INDEX idx_recommendation_cache_created ON recommendation_cache(created_at);

-- 定期清理过期缓存（24小时）
CREATE OR REPLACE FUNCTION cleanup_old_recommendations()
RETURNS void AS $$
BEGIN
  DELETE FROM recommendation_cache 
  WHERE created_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;
```

---

## 2. 智能搜索引擎

### 2.1 语义搜索架构

```
用户查询
    │
    ▼
┌─────────────────┐
│  查询理解       │
│  - 意图识别     │
│  - 实体提取     │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  Embedding生成  │
│  (OpenAI API)   │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  向量检索       │
│  (pgvector)     │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│  结果排序       │
│  - 相关性       │
│  - 质量分       │
│  - 时效性       │
└────┬────────────┘
     │
     ▼
  搜索结果
```

### 2.2 向量数据库设计

```sql
-- 启用pgvector扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 内容向量表
CREATE TABLE content_embeddings (
  content_id UUID PRIMARY KEY,
  content_type VARCHAR(50) NOT NULL,
  title_embedding VECTOR(1536), -- 标题向量
  description_embedding VECTOR(1536), -- 描述向量
  combined_embedding VECTOR(1536), -- 组合向量
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 向量索引（HNSW算法，更快的近似搜索）
CREATE INDEX idx_content_embeddings_combined 
ON content_embeddings 
USING hnsw (combined_embedding vector_cosine_ops);

CREATE INDEX idx_content_embeddings_title 
ON content_embeddings 
USING hnsw (title_embedding vector_cosine_ops);
```

### 2.3 语义搜索实现

```typescript
// supabase/functions/semantic-search/index.ts
import { OpenAI } from 'openai';

const openai = new OpenAI({
  apiKey: Deno.env.get('OPENAI_API_KEY'),
});

export async function semanticSearch(query: string, limit: number = 20) {
  // 1. 生成查询向量
  const embedding = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: query,
  });
  
  const queryVector = embedding.data[0].embedding;
  
  // 2. 向量检索
  const { data, error } = await supabase.rpc('search_content_by_vector', {
    query_embedding: queryVector,
    match_threshold: 0.7, // 相似度阈值
    match_count: limit,
  });
  
  if (error) throw error;
  
  // 3. 结果排序（相关性 + 质量分 + 时效性）
  const rankedResults = data.map(item => ({
    ...item,
    final_score: calculateFinalScore(item),
  })).sort((a, b) => b.final_score - a.final_score);
  
  return rankedResults;
}

function calculateFinalScore(item: any): number {
  const relevanceScore = item.similarity; // 0-1
  const qualityScore = item.quality_score / 100; // 0-1
  const recencyScore = calculateRecencyScore(item.created_at); // 0-1
  
  return (
    0.5 * relevanceScore +
    0.3 * qualityScore +
    0.2 * recencyScore
  );
}

function calculateRecencyScore(createdAt: string): number {
  const daysSinceCreation = (Date.now() - new Date(createdAt).getTime()) / (1000 * 60 * 60 * 24);
  return Math.max(0, 1 - daysSinceCreation / 365); // 1年内线性衰减
}
```

### 2.4 PostgreSQL向量搜索函数

```sql
-- 向量搜索函数
CREATE OR REPLACE FUNCTION search_content_by_vector(
  query_embedding VECTOR(1536),
  match_threshold FLOAT,
  match_count INT
)
RETURNS TABLE (
  content_id UUID,
  content_type VARCHAR(50),
  title TEXT,
  description TEXT,
  similarity FLOAT,
  quality_score FLOAT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.content_id,
    ce.content_type,
    c.title,
    c.description,
    1 - (ce.combined_embedding <=> query_embedding) AS similarity,
    c.quality_score,
    c.created_at
  FROM content_embeddings ce
  JOIN contents c ON ce.content_id = c.id
  WHERE 1 - (ce.combined_embedding <=> query_embedding) > match_threshold
  ORDER BY ce.combined_embedding <=> query_embedding
  LIMIT match_count;
END;
$$ LANGUAGE plpgsql;
```

### 2.5 搜索建议（自动补全）

```typescript
export async function searchSuggestions(prefix: string, limit: number = 5) {
  // 1. 基于前缀的模糊匹配
  const { data: fuzzyMatches } = await supabase
    .from('search_queries')
    .select('query, frequency')
    .ilike('query', `${prefix}%`)
    .order('frequency', { ascending: false })
    .limit(limit);
  
  // 2. 基于语义的相关搜索
  const embedding = await getEmbedding(prefix);
  const { data: semanticMatches } = await supabase.rpc('search_queries_by_vector', {
    query_embedding: embedding,
    match_count: limit,
  });
  
  // 3. 合并去重
  const suggestions = mergeSuggestions(fuzzyMatches, semanticMatches);
  
  return suggestions.slice(0, limit);
}
```

---

## 3. AI内容分析

### 3.1 自动标签提取

```typescript
export async function extractTags(content: string): Promise<string[]> {
  const response = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: '你是一个专业的内容分析助手。从给定的文本中提取5-10个最相关的标签。标签应该简洁、准确，涵盖主题、技术、应用场景等维度。',
      },
      {
        role: 'user',
        content: `请从以下内容中提取标签：\n\n${content}`,
      },
    ],
    temperature: 0.3,
  });
  
  const tagsText = response.choices[0].message.content;
  const tags = tagsText.split(/[,，、\n]/).map(t => t.trim()).filter(t => t);
  
  return tags;
}
```

### 3.2 内容质量评分

```typescript
export async function scoreContentQuality(content: {
  title: string;
  description: string;
  tags: string[];
}): Promise<number> {
  const response = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: '你是一个内容质量评估专家。根据标题、描述和标签，评估内容的质量。评分标准：信息完整性(30%)、准确性(30%)、可读性(20%)、实用性(20%)。返回0-100的分数。',
      },
      {
        role: 'user',
        content: JSON.stringify(content),
      },
    ],
    temperature: 0.1,
  });
  
  const scoreText = response.choices[0].message.content;
  const score = parseInt(scoreText.match(/\d+/)?.[0] || '50');
  
  return Math.min(100, Math.max(0, score));
}
```

### 3.3 趋势预测

```sql
-- 趋势分析表
CREATE TABLE content_trends (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tag VARCHAR(100) NOT NULL,
  period DATE NOT NULL, -- 统计周期（天）
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  trend_score FLOAT, -- 趋势分数
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(tag, period)
);

CREATE INDEX idx_content_trends_period ON content_trends(period DESC);
CREATE INDEX idx_content_trends_score ON content_trends(trend_score DESC);

-- 计算趋势分数
CREATE OR REPLACE FUNCTION calculate_trend_score(
  current_count INTEGER,
  previous_count INTEGER,
  weight FLOAT DEFAULT 1.0
)
RETURNS FLOAT AS $$
BEGIN
  IF previous_count = 0 THEN
    RETURN current_count * weight;
  END IF;
  
  RETURN ((current_count - previous_count)::FLOAT / previous_count) * weight;
END;
$$ LANGUAGE plpgsql;
```

### 3.4 相似内容检测

```typescript
export async function findSimilarContent(
  contentId: string,
  threshold: number = 0.85
): Promise<Array<{ id: string; similarity: number }>> {
  // 1. 获取内容向量
  const { data: content } = await supabase
    .from('content_embeddings')
    .select('combined_embedding')
    .eq('content_id', contentId)
    .single();
  
  if (!content) return [];
  
  // 2. 查找相似内容
  const { data: similar } = await supabase.rpc('find_similar_content', {
    query_embedding: content.combined_embedding,
    similarity_threshold: threshold,
    exclude_id: contentId,
  });
  
  return similar || [];
}
```

---

## 4. AI辅助审核

### 4.1 内容安全检测

```typescript
export async function moderateContent(content: string): Promise<{
  safe: boolean;
  categories: string[];
  scores: Record<string, number>;
}> {
  const response = await openai.moderations.create({
    input: content,
  });
  
  const result = response.results[0];
  
  return {
    safe: !result.flagged,
    categories: Object.keys(result.categories).filter(
      key => result.categories[key]
    ),
    scores: result.category_scores,
  };
}
```

### 4.2 垃圾评论过滤

```typescript
export async function detectSpam(comment: string): Promise<{
  isSpam: boolean;
  confidence: number;
  reason?: string;
}> {
  // 规则检测
  const ruleResult = ruleBasedSpamDetection(comment);
  if (ruleResult.isSpam) return ruleResult;
  
  // AI检测
  const response = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [
      {
        role: 'system',
        content: '你是一个垃圾评论检测专家。判断评论是否为垃圾评论（广告、恶意链接、无意义内容等）。返回JSON格式：{"isSpam": boolean, "confidence": 0-1, "reason": string}',
      },
      {
        role: 'user',
        content: comment,
      },
    ],
    temperature: 0.1,
  });
  
  return JSON.parse(response.choices[0].message.content);
}

function ruleBasedSpamDetection(comment: string): {
  isSpam: boolean;
  confidence: number;
  reason?: string;
} {
  // 规则1: 包含多个URL
  const urlCount = (comment.match(/https?:\/\//g) || []).length;
  if (urlCount > 2) {
    return { isSpam: true, confidence: 0.9, reason: '包含过多链接' };
  }
  
  // 规则2: 重复字符过多
  if (/(.)\1{10,}/.test(comment)) {
    return { isSpam: true, confidence: 0.95, reason: '包含大量重复字符' };
  }
  
  // 规则3: 包含敏感关键词
  const spamKeywords = ['加微信', '代理', '刷单', '兼职'];
  if (spamKeywords.some(kw => comment.includes(kw))) {
    return { isSpam: true, confidence: 0.85, reason: '包含敏感关键词' };
  }
  
  return { isSpam: false, confidence: 0 };
}
```

### 4.3 敏感信息识别

```typescript
export async function detectSensitiveInfo(text: string): Promise<{
  hasSensitiveInfo: boolean;
  types: string[];
  maskedText: string;
}> {
  const patterns = {
    phone: /1[3-9]\d{9}/g,
    email: /[\w.-]+@[\w.-]+\.\w+/g,
    idCard: /\d{17}[\dXx]/g,
    bankCard: /\d{16,19}/g,
  };
  
  const detected: string[] = [];
  let maskedText = text;
  
  for (const [type, pattern] of Object.entries(patterns)) {
    if (pattern.test(text)) {
      detected.push(type);
      maskedText = maskedText.replace(pattern, '***');
    }
  }
  
  return {
    hasSensitiveInfo: detected.length > 0,
    types: detected,
    maskedText,
  };
}
```

---

## 📊 性能和成本评估

### 性能指标

| 功能 | 目标延迟 | 目标QPS |
|------|---------|---------|
| 推荐接口 | <200ms | 100 |
| 语义搜索 | <500ms | 50 |
| 标签提取 | <2s | 10 |
| 内容审核 | <1s | 20 |

### 成本估算（月度）

| 服务 | 用量 | 单价 | 月成本 |
|------|------|------|--------|
| OpenAI API (Embedding) | 100万次 | $0.0001/次 | $100 |
| OpenAI API (GPT-4) | 10万次 | $0.03/1K tokens | $300 |
| Supabase (存储) | 10GB | $0.125/GB | $1.25 |
| Supabase (计算) | 100小时 | $0.01344/小时 | $1.34 |
| **总计** | - | - | **~$402** |

### 成本优化策略

1. **缓存策略**
   - Embedding结果缓存（24小时）
   - 推荐结果缓存（1小时）
   - 搜索结果缓存（30分钟）

2. **批处理**
   - 标签提取批量处理（每小时）
   - 趋势分析离线计算（每天）

3. **降级策略**
   - 高峰期使用缓存结果
   - 新用户使用热门推荐
   - 搜索降级到关键词匹配

---

## 📋 实施计划

### Phase 1: 推荐引擎（Week 1-3，48小时）

**Week 1: 数据准备**
- [ ] 创建用户画像表
- [ ] 实现行为数据收集
- [ ] 构建用户-物品矩阵

**Week 2: 算法实现**
- [ ] 实现协同过滤算法
- [ ] 实现内容推荐算法
- [ ] 实现结果融合逻辑
- [ ] 实现冷启动策略

**Week 3: 集成测试**
- [ ] 推荐API开发
- [ ] 前端集成
- [ ] 性能优化
- [ ] A/B测试准备

---

### Phase 2: 智能搜索（Week 4-5，40小时）

**Week 4: 向量数据库**
- [ ] 配置pgvector扩展
- [ ] 生成内容Embeddings
- [ ] 创建向量索引
- [ ] 实现向量搜索函数

**Week 5: 搜索功能**
- [ ] 实现语义搜索API
- [ ] 实现搜索建议
- [ ] 前端集成
- [ ] 性能优化

---

### Phase 3: 内容分析（Week 6-7，40小时）

**Week 6: 分析功能**
- [ ] 实现标签提取
- [ ] 实现质量评分
- [ ] 实现相似内容检测
- [ ] 批处理任务调度

**Week 7: 趋势分析**
- [ ] 创建趋势分析表
- [ ] 实现趋势计算逻辑
- [ ] 实现趋势预测
- [ ] 前端展示

---

### Phase 4: AI审核（Week 8-9，32小时）

**Week 8: 审核功能**
- [ ] 集成OpenAI Moderation API
- [ ] 实现垃圾评论过滤
- [ ] 实现敏感信息识别
- [ ] 审核队列管理

**Week 9: 人工复审**
- [ ] 实现审核工作台
- [ ] 实现审核记录
- [ ] 实现反馈循环
- [ ] 审核规则优化

---

### Phase 5: 优化和监控（Week 10，16小时）

- [ ] 性能优化
- [ ] 成本优化
- [ ] 监控告警配置
- [ ] 文档编写

---

## 🧪 测试计划

### 1. 推荐质量测试
- 准确率（Precision@K）
- 召回率（Recall@K）
- 多样性（Diversity）
- 覆盖率（Coverage）

### 2. 搜索质量测试
- 相关性评分（NDCG）
- 响应时间
- 召回率

### 3. 审核准确率测试
- 误报率（False Positive）
- 漏报率（False Negative）
- F1分数

---

## ✅ 验收标准

### 功能验收
- [ ] 推荐系统上线，推荐准确率>60%
- [ ] 语义搜索上线，相关性>70%
- [ ] 自动标签提取准确率>80%
- [ ] 内容审核准确率>90%

### 性能验收
- [ ] 推荐接口延迟<200ms
- [ ] 搜索接口延迟<500ms
- [ ] 月度成本<$500

### 业务指标
- [ ] 用户点击率提升20%+
- [ ] 搜索使用率提升30%+
- [ ] 审核效率提升50%+

---

**设计者**: Claude Code  
**审核状态**: 待审核  
**开始日期**: 待定  
**预计完成日期**: 开始后8-10周
