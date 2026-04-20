/**
 * Validation Tests
 * 验证系统单元测试
 */

import { assertEquals, assertThrows } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  isValidEmail,
  isValidUrl,
  isValidHttpsUrl,
  isValidUuid,
  isValidSlug,
  isValidUsername,
  containsXss,
  containsSqlInjection,
  isWhitelistedDomain,
  validatePasswordStrength,
  isValidPhoneNumber,
  isValidDate,
  isValidDateRange,
  isValidJson,
  isValidHexColor,
  isInRange,
} from "../_shared/utils/validation.ts";

Deno.test("Email Validation", () => {
  // Valid emails
  assertEquals(isValidEmail("user@example.com"), true);
  assertEquals(isValidEmail("test.user@example.co.uk"), true);
  assertEquals(isValidEmail("user+tag@example.com"), true);

  // Invalid emails
  assertEquals(isValidEmail("invalid"), false);
  assertEquals(isValidEmail("user@"), false);
  assertEquals(isValidEmail("@example.com"), false);
  assertEquals(isValidEmail("user @example.com"), false);
});

Deno.test("URL Validation", () => {
  // Valid URLs
  assertEquals(isValidUrl("http://example.com"), true);
  assertEquals(isValidUrl("https://example.com"), true);
  assertEquals(isValidUrl("https://example.com/path?query=value"), true);

  // Invalid URLs
  assertEquals(isValidUrl("not-a-url"), false);
  assertEquals(isValidUrl("javascript:alert(1)"), false);
  assertEquals(isValidUrl("ftp://example.com"), false);
});

Deno.test("HTTPS URL Validation", () => {
  // Valid HTTPS URLs
  assertEquals(isValidHttpsUrl("https://example.com"), true);

  // Invalid (HTTP or other)
  assertEquals(isValidHttpsUrl("http://example.com"), false);
  assertEquals(isValidHttpsUrl("ftp://example.com"), false);
});

Deno.test("UUID Validation", () => {
  // Valid UUIDs
  assertEquals(isValidUuid("123e4567-e89b-12d3-a456-426614174000"), true);
  assertEquals(isValidUuid("550e8400-e29b-41d4-a716-446655440000"), true);

  // Invalid UUIDs
  assertEquals(isValidUuid("not-a-uuid"), false);
  assertEquals(isValidUuid("123e4567-e89b-12d3-a456"), false);
  assertEquals(isValidUuid("123e4567e89b12d3a456426614174000"), false);
});

Deno.test("Slug Validation", () => {
  // Valid slugs
  assertEquals(isValidSlug("hello-world"), true);
  assertEquals(isValidSlug("my-post-123"), true);

  // Invalid slugs
  assertEquals(isValidSlug("Hello World"), false);
  assertEquals(isValidSlug("hello_world"), false);
  assertEquals(isValidSlug("hello--world"), false);
});

Deno.test("Username Validation", () => {
  // Valid usernames
  assertEquals(isValidUsername("john_doe"), true);
  assertEquals(isValidUsername("user123"), true);
  assertEquals(isValidUsername("test-user"), true);

  // Invalid usernames
  assertEquals(isValidUsername("ab"), false); // Too short
  assertEquals(isValidUsername("a".repeat(31)), false); // Too long
  assertEquals(isValidUsername("user name"), false); // Contains space
  assertEquals(isValidUsername("user@name"), false); // Invalid character
});

Deno.test("XSS Detection", () => {
  // Contains XSS
  assertEquals(containsXss("<script>alert(1)</script>"), true);
  assertEquals(containsXss("javascript:alert(1)"), true);
  assertEquals(containsXss("<img onerror='alert(1)'>"), true);
  assertEquals(containsXss("<iframe src='evil.com'>"), true);

  // Safe content
  assertEquals(containsXss("Hello World"), false);
  assertEquals(containsXss("This is safe text"), false);
});

Deno.test("SQL Injection Detection", () => {
  // Contains SQL injection patterns
  assertEquals(containsSqlInjection("SELECT * FROM users"), true);
  assertEquals(containsSqlInjection("1' OR '1'='1"), true);
  assertEquals(containsSqlInjection("DROP TABLE users"), true);
  assertEquals(containsSqlInjection("UNION SELECT password"), true);

  // Safe content
  assertEquals(containsSqlInjection("Hello World"), false);
  assertEquals(containsSqlInjection("user@example.com"), false);
});

Deno.test("Domain Whitelist", () => {
  // Whitelisted domains
  assertEquals(isWhitelistedDomain("https://dacong.com"), true);
  assertEquals(isWhitelistedDomain("https://cdn.dacong.com"), true);
  assertEquals(isWhitelistedDomain("https://images.dacong.com"), true);

  // Non-whitelisted domains
  assertEquals(isWhitelistedDomain("https://evil.com"), false);
  assertEquals(isWhitelistedDomain("https://example.com"), false);
});

Deno.test("Password Strength Validation", () => {
  // Strong passwords
  const strong1 = validatePasswordStrength("SecurePass123!");
  assertEquals(strong1.valid, true);
  assertEquals(strong1.score >= 3, true);

  const strong2 = validatePasswordStrength("MyP@ssw0rd");
  assertEquals(strong2.valid, true);

  // Weak passwords
  const weak1 = validatePasswordStrength("short");
  assertEquals(weak1.valid, false);
  assertEquals(weak1.feedback.length > 0, true);

  const weak2 = validatePasswordStrength("alllowercase");
  assertEquals(weak2.valid, false);

  const weak3 = validatePasswordStrength("ALLUPPERCASE");
  assertEquals(weak3.valid, false);

  const weak4 = validatePasswordStrength("NoNumbers!");
  assertEquals(weak4.valid, false);

  // Common passwords
  const common = validatePasswordStrength("password123");
  assertEquals(common.score < 3, true);
});

Deno.test("Phone Number Validation", () => {
  // Valid Chinese phone numbers
  assertEquals(isValidPhoneNumber("13800138000"), true);
  assertEquals(isValidPhoneNumber("15912345678"), true);

  // Invalid phone numbers
  assertEquals(isValidPhoneNumber("12345678901"), false); // Wrong prefix
  assertEquals(isValidPhoneNumber("1380013800"), false); // Too short
  assertEquals(isValidPhoneNumber("138001380000"), false); // Too long
});

Deno.test("Date Validation", () => {
  // Valid dates
  assertEquals(isValidDate("2026-04-19"), true);
  assertEquals(isValidDate("2026-04-19T12:00:00Z"), true);

  // Invalid dates
  assertEquals(isValidDate("not-a-date"), false);
  assertEquals(isValidDate("2026-13-01"), false); // Invalid month
});

Deno.test("Date Range Validation", () => {
  // Valid ranges
  assertEquals(isValidDateRange("2026-04-01", "2026-04-30"), true);
  assertEquals(isValidDateRange("2026-04-19", "2026-04-19"), true); // Same day

  // Invalid ranges
  assertEquals(isValidDateRange("2026-04-30", "2026-04-01"), false); // End before start
  assertEquals(isValidDateRange("invalid", "2026-04-30"), false);
});

Deno.test("JSON Validation", () => {
  // Valid JSON
  assertEquals(isValidJson('{"key": "value"}'), true);
  assertEquals(isValidJson('["item1", "item2"]'), true);
  assertEquals(isValidJson('null'), true);

  // Invalid JSON
  assertEquals(isValidJson("{key: value}"), false); // Missing quotes
  assertEquals(isValidJson("not json"), false);
});

Deno.test("Hex Color Validation", () => {
  // Valid hex colors
  assertEquals(isValidHexColor("#FF0000"), true);
  assertEquals(isValidHexColor("#f00"), true);
  assertEquals(isValidHexColor("#123ABC"), true);

  // Invalid hex colors
  assertEquals(isValidHexColor("FF0000"), false); // Missing #
  assertEquals(isValidHexColor("#GG0000"), false); // Invalid characters
  assertEquals(isValidHexColor("#FF00"), false); // Wrong length
});

Deno.test("Range Validation", () => {
  // In range
  assertEquals(isInRange(5, 1, 10), true);
  assertEquals(isInRange(1, 1, 10), true);
  assertEquals(isInRange(10, 1, 10), true);

  // Out of range
  assertEquals(isInRange(0, 1, 10), false);
  assertEquals(isInRange(11, 1, 10), false);

  // Non-integer
  assertEquals(isInRange(5.5, 1, 10), false);
});
