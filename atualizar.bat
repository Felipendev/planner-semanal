@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo.
echo ==========================================================
echo   Planner - publicar alteracoes
echo ==========================================================
echo.

if not exist ".git" (
  echo [ERRO] Repositorio nao inicializado.
  echo Rode primeiro o arquivo publicar.bat
  pause & exit /b 1
)

rem mantem a copia local e a versao publicada sempre iguais
copy /y "planner-semanal.html" "web\index.html" >nul
if errorlevel 1 (
  echo [AVISO] Nao consegui copiar planner-semanal.html para web\index.html
)

git add -A
git diff --cached --quiet
if not errorlevel 1 (
  echo Nada mudou desde a ultima publicacao.
  pause & exit /b 0
)

set /p MSG="Descreva a mudanca (enter para 'ajustes'): "
if "%MSG%"=="" set MSG=ajustes

git commit -q -m "%MSG%"

rem ---------- reancorar se o historico local estiver separado ----------
git fetch -q origin main 2>nul
git rev-parse --verify origin/main >nul 2>nul
if not errorlevel 1 (
  git merge-base --is-ancestor origin/main HEAD
  if errorlevel 1 (
    echo Historico local separado do remoto. Reancorando...
    git reset --soft origin/main
    git add -A
    git diff --cached --quiet
    if errorlevel 1 (
      git commit -q -m "%MSG%"
    ) else (
      echo Os arquivos ja sao identicos aos do GitHub. Nada a enviar.
      pause & exit /b 0
    )
  )
)

git push -u origin main
if errorlevel 1 (
  echo.
  echo [ERRO] Falha ao enviar. Verifique a conexao e o login do GitHub.
  pause & exit /b 1
)

echo.
echo Enviado. A Vercel publica sozinha em cerca de 30 segundos.
echo.
pause
