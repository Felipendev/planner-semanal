@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo.
echo ==========================================================
echo   Planner - primeira publicacao no GitHub
echo ==========================================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Git nao encontrado.
  echo Instale em https://git-scm.com/download/win e rode este arquivo de novo.
  pause & exit /b 1
)

if exist ".git" (
  echo Removendo repositorio anterior incompleto...
  rmdir /s /q ".git"
)

echo Inicializando repositorio...
git init -q
git config core.autocrlf false

echo.
echo O e-mail abaixo precisa ser o MESMO da sua conta do GitHub,
echo senao a Vercel recusa o deploy em repositorio privado.
echo Consulte em: github.com/settings/emails
echo.
set /p EMAIL="E-mail da conta GitHub: "
if "%EMAIL%"=="" (
  echo [ERRO] E-mail obrigatorio.
  pause & exit /b 1
)
set /p NOME="Nome para os commits (enter para 'Felipendev'): "
if "%NOME%"=="" set NOME=Felipendev
git config user.email "%EMAIL%"
git config user.name "%NOME%"

echo Preparando arquivos...
git add -A
git commit -q -m "Planner - Protocolo 180: app, PWA, schema Supabase e guia de deploy"
if errorlevel 1 (
  echo [ERRO] Falha ao criar o commit.
  pause & exit /b 1
)

git branch -M main
git remote remove origin >nul 2>nul
git remote add origin https://github.com/Felipendev/planner-semanal.git

echo.
echo Enviando para o GitHub...
echo (se pedir login, autorize na janela do navegador que vai abrir)
echo.
git push -u origin main
if errorlevel 1 (
  echo.
  echo [AVISO] O envio falhou. Causa mais comum: o repositorio no GitHub
  echo         ja tem um README. Nesse caso rode:
  echo.
  echo         git pull --rebase origin main
  echo         git push -u origin main
  echo.
  pause & exit /b 1
)

echo.
echo ==========================================================
echo   Pronto. Codigo no ar em:
echo   https://github.com/Felipendev/planner-semanal
echo.
echo   Proximo passo: vercel.com - Add New - Project
echo   Importe o repositorio e clique em Deploy.
echo   O vercel.json ja aponta para a pasta web.
echo ==========================================================
echo.
pause
