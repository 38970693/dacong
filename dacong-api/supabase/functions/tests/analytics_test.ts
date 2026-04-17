import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL') || 'http://localhost:54321'
const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY') || ''

Deno.test('track-event: should accept and store events', async () => {
  const response = await fetch(`${supabaseUrl}/functions/v1/track-event`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${supabaseKey}`
    },
    body: JSON.stringify({
      events: [
        {
          event_type: 'page_view',
          user_id: 'test-user-1',
          session_id: 'test-session-1',
          content_id: null,
          properties: { page_name: 'home' },
          device_info: { platform: 'test' },
          created_at: new Date().toISOString()
        }
      ]
    })
  })

  assertEquals(response.status, 200)
  const data = await response.json()
  assertEquals(data.success, true)
  assertEquals(data.count, 1)
})

Deno.test('track-event: should reject invalid data', async () => {
  const response = await fetch(`${supabaseUrl}/functions/v1/track-event`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${supabaseKey}`
    },
    body: JSON.stringify({
      events: []
    })
  })

  assertEquals(response.status, 400)
  const data = await response.json()
  assertExists(data.error)
})

Deno.test('aggregate-analytics: should aggregate daily data', async () => {
  const response = await fetch(`${supabaseUrl}/functions/v1/aggregate-analytics`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${supabaseKey}`
    }
  })

  assertEquals(response.status, 200)
  const data = await response.json()
  assertEquals(data.success, true)
  assertExists(data.date)
  assertExists(data.metrics)
  assertExists(data.metrics.dau)
  assertExists(data.metrics.pv)
  assertExists(data.metrics.uv)
})

Deno.test('get-analytics: should return overview data', async () => {
  const response = await fetch(
    `${supabaseUrl}/functions/v1/get-analytics?type=overview&days=7`,
    {
      headers: {
        'Authorization': `Bearer ${supabaseKey}`
      }
    }
  )

  assertEquals(response.status, 200)
  const data = await response.json()
  assertEquals(data.success, true)
  assertEquals(data.type, 'overview')
  assertExists(data.data)
  assertExists(data.data.daily_data)
  assertExists(data.data.totals)
  assertExists(data.data.averages)
})

Deno.test('get-analytics: should return hot content', async () => {
  const response = await fetch(
    `${supabaseUrl}/functions/v1/get-analytics?type=hot_content&days=7&limit=10`,
    {
      headers: {
        'Authorization': `Bearer ${supabaseKey}`
      }
    }
  )

  assertEquals(response.status, 200)
  const data = await response.json()
  assertEquals(data.success, true)
  assertEquals(data.type, 'hot_content')
  assertExists(data.data.hot_content)
})

Deno.test('get-analytics: should return hot searches', async () => {
  const response = await fetch(
    `${supabaseUrl}/functions/v1/get-analytics?type=hot_searches&days=7&limit=10`,
    {
      headers: {
        'Authorization': `Bearer ${supabaseKey}`
      }
    }
  )

  assertEquals(response.status, 200)
  const data = await response.json()
  assertEquals(data.success, true)
  assertEquals(data.type, 'hot_searches')
  assertExists(data.data.hot_searches)
})

Deno.test('get-analytics: should return funnel data', async () => {
  const response = await fetch(
    `${supabaseUrl}/functions/v1/get-analytics?type=funnel&days=7`,
    {
      headers: {
        'Authorization': `Bearer ${supabaseKey}`
      }
    }
  )

  assertEquals(response.status, 200)
  const data = await response.json()
  assertEquals(data.success, true)
  assertEquals(data.type, 'funnel')
  assertExists(data.data.funnel)
})
