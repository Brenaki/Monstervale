# Decisões do DT-SLIME

Registro das decisões tomadas em 2026-11-06. `DT-SLIME` é um nome provisório.

## Jogo

- Tower defense 2D em pixel art: o jogador comanda humanos de 7 classes e defende um vilarejo de ondas de monstros.
- Gratuito no itch.io, para navegador, Linux e Windows. Só mouse; mobile fora do escopo.
- Textos em PT-BR e EN, separados do código.
- Classificação de 14 anos: tom leve, com efeitos de sangue pequenos e passageiros, sem desmembramento nem corpos persistentes.
- Reação ao dano por família: slimes espirram gosma, esqueletos se desfazem em ossos, goblins e lobos soltam um pouco de sangue, humanos caem sem ferimentos.
- Sem áudio na primeira versão. Os eventos do jogo ficam prontos para ligar sons depois.

## Campanha

- 5 fases, cerca de 1 hora no total: 10 a 15 ondas e 10 a 15 minutos por fase.
- Uma dificuldade, com nota de 1 a 3 estrelas conforme as vidas restantes. 1 estrela libera a fase seguinte.
- Progresso salvo localmente, sem melhorias permanentes entre fases. Sem modo infinito.
- Cada fase mantém os monstros das anteriores.

| Fase | Monstro novo | Classes liberadas | Ambiente | O que ensina |
|---|---|---|---|---|
| 1 | Goblin | Arqueiro e guerreiro | Campos | Alcance e bloqueio |
| 2 | Slime | Mago | Pântano | Dano em área contra a divisão |
| 3 | Lobo | Lanceiro e druida | Floresta | Conter inimigos rápidos |
| 4 | Esqueleto | Monge e ladino | Cemitério | Tipos de dano |
| 5 | Rei Slime (chefe) | Todas | Arredores do vilarejo | Prova final |

## Mapa e posicionamento

- Caminho fixo, em qualquer direção, com humanos posicionados livremente nos tiles construíveis da grade.
- Caminho único nas fases 1 e 2; duas entradas ou bifurcação a partir da fase 3.
- Um conjunto base de tiles com variações de cor e detalhe por ambiente.

## Humanos

- Ficam parados depois de posicionados. Dispensar um humano devolve metade de todo o ouro gasto nele, incluindo melhorias.
- 3 níveis lineares. O nível 3 libera uma habilidade automática, com variação visual que destaca essa habilidade. Os níveis 2 e 3 têm sprites próprios.
- Só o corpo a corpo segura monstros. Qualquer humano ao alcance de um monstro leva dano: quem não está bloqueado continua andando e bate de passagem no humano mais próximo. Ao perder toda a vida, o humano cai e volta depois de alguns segundos, sem morte permanente. Isso obriga a afastar arqueiros e magos do caminho.
- As classes são inspiradas nos arquétipos de D&D, sem dados nem regras do sistema.

| Classe | Papel | Ataque | Dano | Habilidade no nível 3 | Destaque visual |
|---|---|---|---|---|---|
| Arqueiro | Alvo único e alcance longo | Distância | Perfurante | A flecha atravessa inimigos | Flecha com rastro |
| Guerreiro | Tanque, segura mais monstros | Corpo a corpo | Impacto | Segura um monstro a mais e leva menos dano | Escudo maior |
| Lanceiro | Alcance de 2 tiles, bom contra lobos | Corpo a corpo | Perfurante | Acerta todos em linha | Lança mais longa |
| Mago | Dano em área, lento e caro | Distância | Mágico | A explosão deixa fogo no chão | Chama no cajado |
| Druida | Controle, pouco dano e lentidão | Distância | Mágico | Raízes às vezes imobilizam | Vinhas no cajado |
| Ladino | Alcance curto e golpes críticos | Distância (adagas) | Perfurante | Abates dão ouro extra | Bolsa de ouro |
| Monge | Ataque rápido, bom contra esqueletos | Corpo a corpo | Impacto | Golpes às vezes atordoam | Aura nos punhos |

## Monstros

- 4 famílias, variantes por cor e arma sobre o mesmo corpo, e 1 chefe. Todos atacam só corpo a corpo, com alcance definido em `data/monsters.json`.
- Variantes da Fase 1: goblin veloz, com bandana e adagas; goblin blindado, com capacete, escudo e maça.
- Goblin: básico e em grupos.
- Slime: divide-se ao morrer, de grande em médios e depois em pequenos; os filhotes rendem pouco ou nenhum ouro.
- Lobo: quatro patas, rápido, escapa das defesas e pede bloqueio.
- Esqueleto: resiste a dano perfurante e é fraco contra impacto.
- Rei Slime: chefe da fase 5, ampliado e redesenhado, divide-se ao longo da luta.

## Economia

- Ouro por abate e bônus ao fim de cada onda.
- O vilarejo tem um total de vidas que cai a cada monstro que passa, com poucos estágios visuais de dano.
- A próxima onda pode ser chamada antes da hora em troca de ouro.

## Interface

Todos os comandos têm botão na tela:

- Alcance visível ao posicionar ou selecionar um humano.
- Barra de classes com preços sempre visíveis.
- Pausa e velocidade 1× ou 2×.
- Botão para chamar a próxima onda.
- Prévia dos monstros da próxima onda.
- Reiniciar a fase sem penalidade.
- Prioridade de alvo por humano: primeiro, último, mais forte ou mais perto.

## Arte

- Desenhada do zero pelo MCP do Aseprite, a partir de `docs/referencias`, sem decalcar nem copiar. Ajustes podem ser feitos por qualquer um dos dois.
- Resolução interna de 640×360, tiles de 32×32 e personagens de 24 a 32 px. Armas e lobos usam telas maiores, sem mudar a grade.
- Visão top-down em 3/4, com sprites só de lado, espelhados em movimento horizontal. Em trechos verticais, o sprite mantém o último lado.
- Goblins, esqueletos e humanos cabeçudos, com contorno escuro, armas grandes e mãos soltas (`dM6yj6`, `of5ORW`).
- Slimes como em `Free-Slime`. Terreno como a grama e as trilhas de `of5ORW` e `Free-Slime`. Lobos de silhueta baixa e alongada (`f51e`, `L9LaBi`).
- Humanos indicam a classe por roupa, cor e arma (`DvqwHY` como base de corpo e itens).
- Vegetação em moitas redondas de borda serrilhada, com variantes de frutinhas e pedras (`Free-Top-Down-Bushes`, `OIP`).
- O destino dos monstros é uma vila, não uma casa: casas em enxaimel com empena frontal, telhado inclinado, base de pedra e janelas acesas, mais poço, cerca, barris e feno (`qV+rhb`). Cada casa tem de 44 a 56 px de largura e a vila ocupa 160×160 px.
- Paleta, contorno e luz únicos em todo o jogo.
- Não usar o personagem de `b0d95e` nem o visual das goblins de `3080290`.

| Sprite | Animações (teto de quadros) |
|---|---|
| Humanos | Parado (2), ataque (3) e queda (2) |
| Monstros | Andar (4) e ataque (3), mais morte (2) quando a família pedir |
| Slimes | Andar com achatar e esticar (4), mais morte (2) |
| Rei Slime | Andar (6) e divisão (4) |

O dano aparece como um breve clarão feito por código, sem quadros extras. O teto só sobe onde o sprite de referência pedir.

## Avaliação das partidas

- Cada partida gera um relatório em `user://partidas`, em Markdown e JSON, ao vencer, perder, reiniciar ou fechar o jogo. No Linux, a pasta é `~/.local/share/godot/app_userdata/DT-SLIME/partidas`.
- O relatório traz, por onda, defesa, monstros, abates, vidas, ouro, dano por classe, humanos caídos, ações e uma linha para notas. É sempre em português.
- Primeira avaliação da Fase 1: divertida, fácil no início e bem equilibrada para ensinar.
- Segunda avaliação: fácil demais. A partida do relatório terminou em 3 minutos, sem perder vidas e com 746 de ouro sobrando. Daí veio a regra de todo humano poder cair.
- Terceira avaliação: ainda fácil, com ouro demais. Sem monstro nenhum passar, a partida recebeu 1447 de ouro. A renda da fase, sem contar chamadas de onda, caiu de 1257 para 746, e chamar uma onda rende até cerca de 10 de ouro em vez de 21. Essa partida fica em `tests/fixtures/partida_facil_demais.json`, e um teste exige que ela não seja mais perfeita.
- Quarta avaliação: venceu com 3 estrelas só comprando arqueiros de nível 1 e perdeu rápido só com guerreiros. O guerreiro passou a custar 50 de ouro e o arqueiro, 65.

## Técnica

- Godot 4.7.2 com GDScript e GUT 9.7.1, versões fixadas.
- Regras do jogo em GDScript sem depender de cenas, escritas em TDD e testadas sem janela.
- Balanceamento em JSON, editável sem mexer no código e validado por testes. A palavra final sobre a dificuldade é de quem dirige o projeto, jogando.
- Arquivos `.aseprite` no repositório, com um conversor próprio e testado de JSON do Aseprite para `.tres`, sem plugin.
- Textos em arquivos de tradução do Godot.
- Repositório local até a publicação.

### Armadilhas verificadas

- Os cliques de `simulate_input` usam coordenadas da janela: com a janela maior que o viewport, some a margem de `get_final_transform()` e confirme o efeito pelo estado do jogo, nunca pelo `ok` (issue #76 do `godot-mcp-runtime`).
- `get_global_mouse_position()` lê o cursor real e ignora cliques simulados. Leia a posição pelo evento, com `make_input_local(event)`.
- Um projeto novo precisa de `godot --headless --import` antes de rodar, ou os recursos não carregam.
- Export e testes não são feitos pelo MCP, e sim pela linha de comando do Godot.
- O MCP do Playwright grava logs em `.playwright-mcp/` na raiz do projeto.
- `run_script` executa GDScript com as permissões do usuário: use o MCP só em projetos nossos e não o aprove automaticamente.

## Ordem de trabalho

1. Feito: tela de teste de estilo, aprovada para os personagens em 2026-11-06, com pedido de melhorar arbustos e vila.
2. Feito: Fase 1 completa em TDD, com goblins, arqueiro, guerreiro, mapa, ouro, vidas, ondas, 3 níveis, interface e relatórios de partida.
3. Feito: vila e arbustos novos, aprovados em 2026-11-06.
4. Feito para a Fase 1: animações reais de goblin, arqueiro e guerreiro, no limite de quadros definido. O slime é animado quando entrar na Fase 2.
5. Feito: troca de arma das variantes e visual dos níveis 2 e 3.
6. Avaliar a dificuldade com a nova regra, usando os relatórios.
7. Demais fases.

## Decisões adiadas

- Antes de publicar: título e licença do código e da arte.
- Depois da primeira versão: linguagem de programação de áudio, com os sons avaliados de ouvido por quem dirige o projeto.
- Só se o núcleo pedir: casas com renda, caminhos ramificados de melhoria, novos modos de dificuldade, monstros à distância, slimes elementais, curandeiros, invocadores e voadores.

## Ainda sem verificação real

- Abrir o `.exe` no Windows e publicar no itch.io.
- Pintar o caminho no editor de mapas do Godot: o TileSet já tem o terreno `caminho` configurado, mas isso não foi usado à mão.
- Revisão do código do GUT.
