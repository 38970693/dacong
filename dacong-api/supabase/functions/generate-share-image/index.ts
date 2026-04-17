/**
 * Generate Share Image Edge Function
 * 生成分享图卡的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    validateMethod(req, ["GET"]);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 获取查询参数
    const params = getQueryParams(req);
    const contentId = params.get("contentId");

    if (!contentId) {
      return errorResponse("contentId is required", 400);
    }

    // 获取内容信息
    const { data: content, error: contentError } = await supabase
      .from("published_content")
      .select("*")
      .eq("id", contentId)
      .single();

    if (contentError || !content) {
      return errorResponse("Content not found", 404);
    }

    // 生成分享图卡 URL
    // 这里使用简单的方案：返回一个包含内容信息的 URL
    // 实际生产环境可以：
    // 1. 使用 Canvas API 生成图片
    // 2. 调用外部图片生成服务
    // 3. 使用 Puppeteer/Playwright 截图
    const shareImageUrl = generateShareImageUrl(content);

    return successResponse({
      imageUrl: shareImageUrl,
      content: {
        id: content.id,
        titleZh: content.title_zh,
        summaryZh: content.summary_zh,
        contentType: content.content_type,
      },
    });
  } catch (error) {
    console.error("Error in generate-share-image:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});

/**
 * 生成分享图卡 URL
 * 这是一个简化版本，实际生产环境需要更复杂的实现
 */
function generateShareImageUrl(content: {
  id: string;
  title_zh: string;
  summary_zh: string;
  content_type: string;
}): string {
  // 方案1：使用 Open Graph 图片服务（如 og-image.vercel.app）
  const title = encodeURIComponent(content.title_zh);
  const summary = encodeURIComponent(
    content.summary_zh?.substring(0, 100) || ""
  );

  // 返回一个动态生成的 OG 图片 URL
  // 实际项目中应该部署自己的图片生成服务
  return `https://og-image.vercel.app/${title}.png?theme=light&md=1&fontSize=75px&images=https%3A%2F%2Fassets.vercel.com%2Fimage%2Fupload%2Ffront%2Fassets%2Fdesign%2Fvercel-triangle-black.svg&widths=250&heights=250`;

  // 方案2：如果有自己的图片生成服务
  // return `${Deno.env.get("IMAGE_SERVICE_URL")}/generate?contentId=${content.id}`;

  // 方案3：使用预设的模板图片
  // return `${Deno.env.get("CDN_URL")}/share-templates/${content.content_type}.png`;
}
