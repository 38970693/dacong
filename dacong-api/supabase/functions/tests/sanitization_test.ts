/**
 * Sanitization Tests
 * 清理工具单元测试
 */

import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  escapeHtml,
  sanitizeUserInput,
  sanitizeUrl,
  sanitizeEmail,
  sanitizeFilename,
  sanitizeMarkdown,
  sanitizeSearchQuery,
  sanitizeTag,
  sanitizeSlug,
  containsSensitiveWords,
  filterSensitiveWords,
} from "../_shared/utils/sanitize.ts";

Deno.test("HTML Escaping", () => {
  assertEquals(escapeHtml("<script>alert(1)</script>"), "&lt;script&gt;alert(1)&lt;&#x2F;script&gt;");
  assertEquals(escapeHtml('Hello "World"'), "Hello &quot;World&quot;");
  assertEquals(escapeHtml("A & B"), "A &amp; B");
});

Deno.test("User Input Sanitization", () => {
  // Remove HTML tags
  assertEquals(sanitizeUserInput("<b>Hello</b>"), "Hello");

  // Remove JavaScript
  assertEquals(sanitizeUserInput("javascript:alert(1)"), "alert(1)");

  // Remove event handlers
  assertEquals(sanitizeUserInput("onclick=alert(1)"), "");

  // Normalize whitespace
  assertEquals(sanitizeUserInput("Hello    World"), "Hello World");
});

Deno.test("URL Sanitization", () => {
  // Valid URLs
  assertEquals(sanitizeUrl("https://example.com"), "https://example.com");
  assertEquals(sanitizeUrl("http://example.com"), "http://example.com");

  // Invalid protocols
  assertEquals(sanitizeUrl("javascript:alert(1)"), "");
  assertEquals(sanitizeUrl("data:text/html,<script>"), "");

  // Invalid URLs
  assertEquals(sanitizeUrl("not-a-url"), "");
});

Deno.test("Email Sanitization", () => {
  // Valid emails
  assertEquals(sanitizeEmail("User@Example.COM"), "user@example.com");
  assertEquals(sanitizeEmail("  test@example.com  "), "test@example.com");

  // Invalid emails
  assertEquals(sanitizeEmail("not-an-email"), null);
  assertEquals(sanitizeEmail("user@"), null);
});

Deno.test("Filename Sanitization", () => {
  // Remove path separators
  assertEquals(sanitizeFilename("../../etc/passwd"), "..........etcpasswd");

  // Remove special characters
  assertEquals(sanitizeFilename("file name!@#.txt"), "file_name___.txt");

  // Limit length
  const longName = "a".repeat(300) + ".txt";
  assertEquals(sanitizeFilename(longName).length, 255);
});

Deno.test("Markdown Sanitization", () => {
  // Remove dangerous HTML
  const markdown = "# Hello\n<script>alert(1)</script>\n**Bold**";
  const sanitized = sanitizeMarkdown(markdown);
  assertEquals(sanitized.includes("<script>"), false);
  assertEquals(sanitized.includes("# Hello"), true);
  assertEquals(sanitized.includes("**Bold**"), true);
});

Deno.test("Search Query Sanitization", () => {
  // Remove special characters
  assertEquals(sanitizeSearchQuery("hello!@#$%world"), "hello world");

  // Normalize whitespace
  assertEquals(sanitizeSearchQuery("hello    world"), "hello world");

  // Preserve Chinese characters
  assertEquals(sanitizeSearchQuery("你好世界"), "你好世界");
});

Deno.test("Tag Sanitization", () => {
  // Convert to lowercase
  assertEquals(sanitizeTag("JavaScript"), "javascript");

  // Remove special characters
  assertEquals(sanitizeTag("hello world!"), "helloworld");

  // Normalize hyphens
  assertEquals(sanitizeTag("hello---world"), "hello-world");

  // Remove leading/trailing hyphens
  assertEquals(sanitizeTag("-hello-world-"), "hello-world");
});

Deno.test("Slug Sanitization", () => {
  // Convert spaces to hyphens
  assertEquals(sanitizeSlug("Hello World"), "hello-world");

  // Remove special characters
  assertEquals(sanitizeSlug("Hello, World!"), "hello-world");

  // Normalize hyphens
  assertEquals(sanitizeSlug("hello---world"), "hello-world");
});

Deno.test("Sensitive Words Detection", () => {
  // Contains sensitive words
  assertEquals(containsSensitiveWords("这是垃圾内容"), true);
  assertEquals(containsSensitiveWords("This is shit"), true);

  // Clean content
  assertEquals(containsSensitiveWords("Hello World"), false);
  assertEquals(containsSensitiveWords("正常内容"), false);
});

Deno.test("Sensitive Words Filtering", () => {
  // Filter sensitive words
  assertEquals(filterSensitiveWords("这是垃圾内容"), "这是**内容");
  assertEquals(filterSensitiveWords("This is shit"), "This is ****");

  // Clean content unchanged
  assertEquals(filterSensitiveWords("Hello World"), "Hello World");
});
