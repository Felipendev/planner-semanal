@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ==========================================================
echo   Corrigir o autor dos commits
echo ==========================================================
echo.
echo A Vercel recusou o deploy porque o e-mail do commit nao
echo bate com o da sua conta do GitHub.
echo.

if not exist ".git" (
  echo [ERRO] Repositorio nao encontrado. Rode publicar.bat antes.
  pause & exit /b 1
)

echo Autor atual dos commits:
git log -1 --pretty="   %%an ^<%%ae^>"
echo.
echo ----------------------------------------------------------
echo  Onde achar o e-mail certo:
echo.
echo  1. Abra github.com/settings/emails
echo  2. Use o e-mail marcado como *Primary*
echo  3. Se estiver ligado "Keep my email addresses private",
echo     use o que aparece ali no formato:
echo        12345678+Felipendev@users.noreply.github.com
echo ----------------------------------------------------------
echo.

set /p EMAIL="Cole o e-mail da sua conta GitHub: "
if "%EMAIL%"=="" (
  echo Nada informado. Saindo.
  pause & exit /b 1
)

set /p NOME="Nome para os commits (enter para 'Felipendev'): "
if "%NOME%"=="" set NOME=Felipendev

echo.
echo Reescrevendo o autor de todos os commits...
git config user.email "%EMAIL%"
git config user.name "%NOME%"

git -c "user.email=%EMAIL%" -c "user.name=%NOME%" commit --amend --reset-author --no-edit -q
if errorlevel 1 (
  echo [ERRO] Falha ao reescrever o commit.
  pause & exit /b 1
)

echo Novo autor:
git log -1 --pretty="   %%an ^<%%ae^>"
echo.
echo Enviando (force push, porque o commit foi reescrito)...
git push --force-with-lease origin main
if errorlevel 1 (
  echo.
  echo [ERRO] Falha ao enviar. Verifique o login do GitHub.
  pause & exit /b 1
)

echo.
echo ==========================================================
echo   Pronto. Va na Vercel e clique em Redeploy no projeto,
echo   ou aguarde - o push ja deve ter disparado um novo build.
echo ==========================================================
echo.
pause
