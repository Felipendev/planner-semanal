/* ═══════════════════════════════════════════════════════════
   Configuração da nuvem — preencha uma vez e todo aparelho
   que abrir o site já vem conectado, bastando fazer login.

   Estes dois valores são PÚBLICOS por natureza: eles vão dentro
   do site e qualquer visitante consegue lê-los. Quem protege os
   dados é a política de acesso do banco, que só libera a linha
   do usuário logado.

   Onde achar: Supabase → Connect (topo), ou ⚙ Project Settings
   → API Keys. Use a "Publishable key" ou a "anon / public".
   NUNCA a "secret" nem a "service_role".
   ═══════════════════════════════════════════════════════════ */
window.PLANNER_CFG = {
  url: "https://smhpomzcsucyriacmncz.supabase.co",
  key: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtaHBvbXpjc3VjeXJpYWNtbmN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY5MTk0NDMsImV4cCI6MjEwMjQ5NTQ0M30.sZt6qo5gt_1T-HLXWg67XEwSTszhJFMNrL17MVd0fEc"
};
