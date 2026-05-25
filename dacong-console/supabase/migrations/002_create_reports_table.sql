-- Create reports table for comment/post/review reporting
-- Run this migration in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type TEXT NOT NULL CHECK (target_type IN ('comment', 'post', 'review')),
  target_id UUID NOT NULL,
  reporter_id UUID, -- nullable for anonymous reports
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'hate_speech', 'violence', 'misinformation', 'other')),
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID -- admin who resolved the report
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_reports_target ON reports(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);

-- Add foreign key constraints (optional, depends on your database structure)
-- ALTER TABLE reports
--   ADD CONSTRAINT fk_reports_target_comment
--   FOREIGN KEY (target_id) REFERENCES comments(id) ON DELETE CASCADE;

-- ALTER TABLE reports
--   ADD CONSTRAINT fk_reports_reporter
--   FOREIGN KEY (reporter_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- Enable Row Level Security
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can create reports
CREATE POLICY "Anyone can create reports"
  ON reports FOR INSERT
  WITH CHECK (true);

-- Policy: Only admins can view all reports
CREATE POLICY "Admins can view all reports"
  ON reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policy: Admins can update report status
CREATE POLICY "Admins can update reports"
  ON reports FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policy: Admins can delete reports
CREATE POLICY "Admins can delete reports"
  ON reports FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Comments for reference:
--
-- To add profiles.role column if not exists:
-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';
--
-- To resolve a report:
-- UPDATE reports SET status = 'resolved', resolved_at = NOW(), resolved_by = auth.uid() WHERE id = 'report-id';
--
-- To get report statistics:
-- SELECT reason, COUNT(*) as count FROM reports WHERE status = 'pending' GROUP BY reason ORDER BY count DESC;