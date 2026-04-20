@echo off
REM 部署 DaCong Admin 所需的 Edge Functions

echo 开始部署 Edge Functions...
echo.

cd /d "%~dp0\dacong-api\supabase\functions"

echo 1. 部署实时统计函数...
call supabase functions deploy get-realtime-stats

echo 2. 部署趋势数据函数...
call supabase functions deploy get-trend-data

echo 3. 部署管理员统计函数...
call supabase functions deploy admin-stats

echo 4. 部署待处理任务函数...
call supabase functions deploy admin-content-management

echo 5. 部署用户管理函数...
call supabase functions deploy admin-users-list

echo 6. 部署评论审核函数...
call supabase functions deploy admin-comment-moderation

echo 7. 部署审计日志函数...
call supabase functions deploy admin-audit-logs

echo.
echo ✅ 所有函数部署完成！
echo.
echo 验证部署：
echo supabase functions list
echo.
pause
