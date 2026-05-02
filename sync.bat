@echo off
chcp 65001 >nul
echo ================================================
echo  WiFi Analyzer - 同步代码到 GitHub + Gitee
echo ================================================

:: 检查是否有未提交的变更
git diff --quiet && git diff --cached --quiet
if %errorlevel% neq 0 (
    echo.
    echo [!] 检测到未提交的变更，请先提交后再同步
    echo     git add -A
    echo     git commit -m "你的提交说明"
    echo.
    pause
    exit /b 1
)

echo.
echo [1/2] 推送到 GitHub...
git push origin main
if %errorlevel% neq 0 (
    echo [ERROR] GitHub 推送失败！
    pause
    exit /b 1
)
echo [OK] GitHub 推送成功

echo.
echo [2/2] 推送到 Gitee...
git push gitee main
if %errorlevel% neq 0 (
    echo [ERROR] Gitee 推送失败！
    pause
    exit /b 1
)
echo [OK] Gitee 推送成功

echo.
echo ================================================
echo  同步完成！代码已同步到 GitHub 和 Gitee
echo  - GitHub: https://github.com/xinxinl6/wifi-analyzer
echo  - Gitee:  https://gitee.com/xinxinl6/wifi-analyzer
echo ================================================
pause
