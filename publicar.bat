@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

echo.
echo ==========================================================
echo   Planner - publicar no GitHub
echo ==========================================================
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Git nao encontrado.
  echo Instale em https://git-scm.com/download/win e rode este arquivo de novo.
  pause & exit /b 1
)

rem mantem a copia local e a versao publicada sempre iguais
copy /y "planner-semanal.html" "web\index.html" >nul

if not exist ".git" (
  echo Inicializando repositorio...
  git init -q
  git config core.autocrlf false
  git branch -M main
)

rem ---------- identidade ----------
for /f "delims=" %%E in ('git config user.email 2^>nul') do set EMAIL=%%E
if "%EMAIL%"=="" (
  echo.
  echo O e-mail precisa ser o MESMO da sua conta do GitHub,
  echo senao a Vercel recusa o deploy. Veja em github.com/settings/emails
  echo.
  set /p EMAIL="E-mail da conta GitHub: "
)
if "%EMAIL%"=="" (
  echo [ERRO] E-mail obrigatorio.
  pause & exit /b 1
)
for /f "delims=" %%N in ('git config user.name 2^>nul') do set NOME=%%N
if "%NOME%"=="" set NOME=Felipendev
git config user.email "%EMAIL%"
git config user.name "%NOME%"
echo Autor dos commits: %NOME% ^<%EMAIL%^>

rem ---------- remoto ----------
git remote remove origin >nul 2>nul
git remote add origin https://github.com/Felipendev/planner-semanal.git

rem ---------- commit local ----------
git add -A
git diff --cached --quiet
if errorlevel 1 (
  git commit -q -m "Planner - Protocolo 180: atualizacao"
)

git rev-parse --verify HEAD >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Nenhum commit para enviar.
  pause & exit /b 1
)

rem ---------- reancorar no historico do GitHub ----------
echo.
echo Verificando o que ja existe no GitHub...
git fetch -q origin main 2>nul
git rev-parse --verify origin/main >nul 2>nul
if not errorlevel 1 (
  git merge-base --is-ancestor origin/main HEAD
  if errorlevel 1 (
    echo O historico local estava separado do remoto. Reancorando...
    git reset --soft origin/main
    git add -A
    git diff --cached --quiet
    if errorlevel 1 (
      git commit -q -m "Planner - Protocolo 180: atualizacao"
    ) else (
      echo Os arquivos locais ja sao identicos aos do GitHub. Nada a enviar.
      pause & exit /b 0
    )
  )
)

echo Enviando...
git push -u origin main
if errorlevel 1 (
  echo.
  echo [ERRO] Falha ao enviar. Se pediu login, autorize na janela do navegador.
  echo Se o erro voltar a falar em "fetch first", rode este arquivo de novo.
  pause & exit /b 1
)

echo.
echo ==========================================================
echo   Enviado. A Vercel publica sozinha em cerca de 30s.
echo   https://github.com/Felipendev/planner-semanal
echo.
echo   Da proxima vez use atualizar.bat - e mais rapido.
echo ==========================================================
echo.
pause
