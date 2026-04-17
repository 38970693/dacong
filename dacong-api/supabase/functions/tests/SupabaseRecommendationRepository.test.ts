/**
 * Supabase Recommendation Repository Unit Tests
 */

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { SupabaseRecommendationRepository } from "../_shared/repositories/SupabaseRecommendationRepository.ts";
import { Recommendation } from "../_shared/domain/Recommendation.ts";
import { Scenario } from "../_shared/domain/Content.ts";

// Mock Supabase Client
class MockSupabaseClient {
  private data: Record<string, unknown>[] = [
    {
      id: "rec-1",
      scenario: Scenario.CODING,
      rank: 1,
      content_id: "content-1",
      active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      id: "rec-2",
      scenario: Scenario.CODING,
      rank: 2,
      content_id: "content-2",
      active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
    {
      id: "rec-3",
      scenario: Scenario.VIDEO,
      rank: 1,
      content_id: "content-3",
      active: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ];

  from(_tableName: string) {
    return this;
  }

  select(_columns: string) {
    return this;
  }

  eq(column: string, value: unknown) {
    this.data = this.data.filter((row) => row[column] === value);
    return this;
  }

  order(_column: string, _options: { ascending: boolean }) {
    return this;
  }

  single() {
    return {
      data: this.data[0] || null,
      error: this.data.length === 0 ? new Error("Not found") : null,
    };
  }

  insert(_data: Record<string, unknown>) {
    return this;
  }

  update(_data: Record<string, unknown>) {
    return this;
  }

  delete() {
    return this;
  }

  then(callback: (result: { data: unknown; error: unknown }) => void) {
    callback({
      data: this.data,
      error: null,
    });
  }
}

Deno.test("SupabaseRecommendationRepository - findByScenario should return active recommendations", async () => {
  const mockClient = new MockSupabaseClient() as any;
  const repository = new SupabaseRecommendationRepository(mockClient);

  const recommendations = await repository.findByScenario(Scenario.CODING);

  assertExists(recommendations);
  assertEquals(recommendations.length, 2);
  assertEquals(recommendations[0].scenario, Scenario.CODING);
});

Deno.test("SupabaseRecommendationRepository - findByScenario should filter by active status", async () => {
  const mockClient = new MockSupabaseClient() as any;
  const repository = new SupabaseRecommendationRepository(mockClient);

  const recommendations = await repository.findByScenario(Scenario.VIDEO);

  // VIDEO场景有一个推荐，但是inactive，所以应该返回空数组
  assertEquals(recommendations.length, 0);
});

Deno.test("SupabaseRecommendationRepository - findAllActive should return all active recommendations", async () => {
  const mockClient = new MockSupabaseClient() as any;
  const repository = new SupabaseRecommendationRepository(mockClient);

  const recommendations = await repository.findAllActive();

  assertExists(recommendations);
  assertEquals(recommendations.length, 2);
  assertEquals(
    recommendations.every((r) => r.active),
    true
  );
});

Deno.test("Recommendation domain - isBest should return true for rank 1", () => {
  const rec = new Recommendation(
    "rec-1",
    Scenario.CODING,
    1,
    "content-1",
    true,
    new Date(),
    new Date()
  );

  assertEquals(rec.isBest(), true);
  assertEquals(rec.isAlternative(), false);
  assertEquals(rec.isFree(), false);
});

Deno.test("Recommendation domain - isAlternative should return true for rank 2", () => {
  const rec = new Recommendation(
    "rec-2",
    Scenario.CODING,
    2,
    "content-2",
    true,
    new Date(),
    new Date()
  );

  assertEquals(rec.isBest(), false);
  assertEquals(rec.isAlternative(), true);
  assertEquals(rec.isFree(), false);
});

Deno.test("Recommendation domain - isFree should return true for rank 3", () => {
  const rec = new Recommendation(
    "rec-3",
    Scenario.CODING,
    3,
    "content-3",
    true,
    new Date(),
    new Date()
  );

  assertEquals(rec.isBest(), false);
  assertEquals(rec.isAlternative(), false);
  assertEquals(rec.isFree(), true);
});

Deno.test("Recommendation domain - activate should set active to true", () => {
  const rec = new Recommendation(
    "rec-1",
    Scenario.CODING,
    1,
    "content-1",
    false,
    new Date(),
    new Date()
  );

  const activated = rec.activate();

  assertEquals(activated.active, true);
  assertEquals(activated.id, rec.id);
});

Deno.test("Recommendation domain - deactivate should set active to false", () => {
  const rec = new Recommendation(
    "rec-1",
    Scenario.CODING,
    1,
    "content-1",
    true,
    new Date(),
    new Date()
  );

  const deactivated = rec.deactivate();

  assertEquals(deactivated.active, false);
  assertEquals(deactivated.id, rec.id);
});

Deno.test("Recommendation domain - toJSON should return correct format", () => {
  const rec = new Recommendation(
    "rec-1",
    Scenario.CODING,
    1,
    "content-1",
    true,
    new Date("2024-01-01"),
    new Date("2024-01-02")
  );

  const json = rec.toJSON();

  assertEquals(json.id, "rec-1");
  assertEquals(json.scenario, Scenario.CODING);
  assertEquals(json.rank, 1);
  assertEquals(json.content_id, "content-1");
  assertEquals(json.active, true);
  assertExists(json.created_at);
  assertExists(json.updated_at);
});
