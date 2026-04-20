/**
 * Schema Validation Tests
 * Schema 验证测试
 */

import { assertEquals, assertThrows } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import {
  registerSchema,
  loginSchema,
  changePasswordSchema,
} from "../_shared/schemas/auth_schemas.ts";
import {
  submitCommentSchema,
  likeCommentSchema,
  reportCommentSchema,
} from "../_shared/schemas/comment_schemas.ts";
import {
  submitFeedbackSchema,
  searchContentSchema,
} from "../_shared/schemas/content_schemas.ts";
import {
  paginationSchema,
  sortSchema,
  searchSchema,
} from "../_shared/schemas/query_schemas.ts";

Deno.test("Register Schema - Valid Input", () => {
  const validInput = {
    email: "user@example.com",
    password: "SecurePass123",
    username: "john_doe",
  };

  const result = registerSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Register Schema - Invalid Email", () => {
  const invalidInput = {
    email: "not-an-email",
    password: "SecurePass123",
    username: "john_doe",
  };

  const result = registerSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Register Schema - Weak Password", () => {
  const invalidInput = {
    email: "user@example.com",
    password: "weak",
    username: "john_doe",
  };

  const result = registerSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Register Schema - Invalid Username", () => {
  const invalidInput = {
    email: "user@example.com",
    password: "SecurePass123",
    username: "ab", // Too short
  };

  const result = registerSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Login Schema - Valid Input", () => {
  const validInput = {
    email: "user@example.com",
    password: "password123",
  };

  const result = loginSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Change Password Schema - Valid Input", () => {
  const validInput = {
    old_password: "OldPass123",
    new_password: "NewPass123",
  };

  const result = changePasswordSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Submit Comment Schema - Valid Input", () => {
  const validInput = {
    content_id: "123e4567-e89b-12d3-a456-426614174000",
    parent_id: null,
    content: "This is a comment",
  };

  const result = submitCommentSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Submit Comment Schema - Content Too Long", () => {
  const invalidInput = {
    content_id: "123e4567-e89b-12d3-a456-426614174000",
    content: "a".repeat(1001), // Too long
  };

  const result = submitCommentSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Like Comment Schema - Valid Input", () => {
  const validInput = {
    comment_id: "123e4567-e89b-12d3-a456-426614174000",
    action: "like",
  };

  const result = likeCommentSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Report Comment Schema - Valid Input", () => {
  const validInput = {
    comment_id: "123e4567-e89b-12d3-a456-426614174000",
    reason: "spam",
    description: "This is spam content",
  };

  const result = reportCommentSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Submit Feedback Schema - Valid Input", () => {
  const validInput = {
    content_id: "123e4567-e89b-12d3-a456-426614174000",
    feedback_type: "helpful",
    rating: 5,
    comment: "Very helpful!",
  };

  const result = submitFeedbackSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Search Content Schema - Valid Input", () => {
  const validInput = {
    query: "test query",
    page: 1,
    limit: 20,
  };

  const result = searchContentSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Search Content Schema - Query Too Long", () => {
  const invalidInput = {
    query: "a".repeat(101), // Too long
  };

  const result = searchContentSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Pagination Schema - Valid Input", () => {
  const validInput = {
    page: 1,
    limit: 20,
  };

  const result = paginationSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Pagination Schema - Invalid Page", () => {
  const invalidInput = {
    page: 0, // Must be at least 1
    limit: 20,
  };

  const result = paginationSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Pagination Schema - Limit Too Large", () => {
  const invalidInput = {
    page: 1,
    limit: 101, // Max is 100
  };

  const result = paginationSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Sort Schema - Valid Input", () => {
  const validInput = {
    sort_by: "created_at",
    sort_order: "desc",
  };

  const result = sortSchema.safeParse(validInput);
  assertEquals(result.success, true);
});

Deno.test("Sort Schema - Invalid Order", () => {
  const invalidInput = {
    sort_by: "created_at",
    sort_order: "invalid", // Must be asc or desc
  };

  const result = sortSchema.safeParse(invalidInput);
  assertEquals(result.success, false);
});

Deno.test("Search Schema - Trim Whitespace", () => {
  const input = {
    query: "  test query  ",
  };

  const result = searchSchema.parse(input);
  assertEquals(result.query, "test query");
});
