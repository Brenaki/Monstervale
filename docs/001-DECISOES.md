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
- O jogo abre na fase mais avançada já liberada. O botão de fase na barra superior abre o painel para voltar a qualquer fase liberada.
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
- A explosão do mago dá dano cheio aos alvos mais próximos dentro do raio, até um limite: 5, 6 e 7 alvos nos níveis 1, 2 e 3. O fogo do nível 3 fica onde estava o alvo e queima por alguns segundos.
- Só o corpo a corpo segura monstros. Qualquer humano ao alcance de um monstro leva dano: quem não está bloqueado continua andando e bate de passagem no humano mais próximo. Ao perder toda a vida, o humano cai e volta depois de alguns segundos, sem morte permanente. Isso obriga a afastar arqueiros e magos do caminho.
- Guerreiros de nível 2 e 3 recuperam um pouco de vida depois de alguns segundos sem levar dano, com valores em `data/units.json`.
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
- Slime: três tamanhos em `data/monsters.json`. Cada um se divide em dois do tamanho seguinte ao morrer, e quem chega à vila não se divide.
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
- Terceira avaliação: ainda fácil, com ouro demais. Sem monstro nenhum passar, a partida recebeu 1447 de ouro. A renda da fase, sem contar chamadas de onda, caiu de 1257 para 746, e chamar uma onda rende até cerca de 10 de ouro em vez de 21. Essa partida fica em `tests/fixtures/partidas/partida_2026-11-06_12-38-53_level_01.json`, e um teste exige que ela não seja mais perfeita.
- Quarta avaliação: venceu com 3 estrelas só comprando arqueiros de nível 1 e perdeu rápido só com guerreiros. O guerreiro passou a custar 50 de ouro e o arqueiro, 65.
- Nivelamento depois da quarta avaliação: guerreiro mais forte, com melhorias mais baratas e retorno em 6 s; arqueiro de nível 1 atirando a cada 1,0 s; chamar uma onda rende até cerca de 4 de ouro, porque com o campo limpo não havia risco. Testes em `test_balance.gd` exigem esta ordem: misturar classes vence uma classe só, melhorar vence só comprar mais, arqueiros de nível 1 sozinhos perdem e guerreiros de nível 1 sozinhos chegam à última onda. A partida só de arqueiros fica em `tests/fixtures/partidas/partida_2026-11-06_12-56-30_level_01.json`.
- Quinta avaliação, que aprova a Fase 1: difícil no começo e tranquila depois, com 3 estrelas em 5 minutos. As ondas 1 a 6 renderam 182 de ouro e as ondas 7 a 12, 444; 5 humanos seguraram a última onda e sobraram 127 de ouro. O arqueiro de nível 3 é o grande salto de dano. As fases seguintes devem cuidar dessa curva.
- Sexta avaliação, a primeira da Fase 2: quem joga deu nota 7 de 10 à Fase 1 e 5 de 10 à Fase 2, que deveria ser mais difícil. A partida séria venceu com 3 estrelas em 6:36, sem perder vidas, com 7 humanos, e nenhum monstro passou de 30% do caminho. Como a explosão não tinha limite de alvos, aumentar as ondas não pesava para quem tinha mago. A explosão ganhou limite, as ondas 7 a 12 cresceram até o dobro na última e o bônus das ondas 7 a 11 caiu para 10. Repetindo a mesma partida, sobram 6 vidas; reinvestindo o ouro, 16. Aguarda nova avaliação jogando.
- Sétima avaliação: a Fase 2 ficou impossível. A partida chegou à onda 11 com 19 vidas, perdeu 13 só nela e a onda 12 entrou antes de ela acabar, mesmo com a defesa evoluída. As ondas 11 e 12 encolheram: a 11 tem 8 goblins blindados e 12 slimes; a 12 tem 15 slimes e 48 goblins. Essa partida fica em `tests/fixtures/partidas` e um teste exige que ela vença sem 3 estrelas. Repetida, vence com 15 vidas; pequenas mudanças na última onda levam esse número a algo entre 6 e 18. Aguarda nova avaliação jogando.
- Oitava avaliação, que aprova a Fase 2 com nota 8 de 10: difícil, mas possível. Em duas tentativas com o mago comprado tarde, uma foi reiniciada com 6 vidas e a outra perdeu; a terceira abriu com o mago e venceu com 3 estrelas e 19 vidas em 6:13. Nessa vitória, as ondas 11 e 12 não derrubaram nenhum humano nem tiraram vidas, e o mago causou 2340 dos 2884 de dano da última onda. As fases seguintes devem cuidar desse fim tranquilo. Essa partida fica em `tests/fixtures/partidas` e precisa se repetir igual.

## Técnica

- Godot 4.7.2 com GDScript e GUT 9.7.1, versões fixadas.
- Regras do jogo em GDScript sem depender de cenas, escritas em TDD e testadas sem janela.
- As partidas reais ficam em `tests/fixtures/partidas` e viram testes e2e em `tests/e2e`: um jogador gravado clica nos botões reais, com o ritmo relativo às ondas e esperando ter ouro. As partidas aprovadas das Fases 1 e 2 precisam se repetir iguais, onda por onda; toda partida nova nessa pasta entra sozinha na repetição geral.
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
6. Feito: dificuldade da Fase 1 avaliada com os relatórios e aprovada em 2026-11-06.
7. Feito: Fase 2, aprovada em 2026-11-06, com slimes que se dividem, mago com explosão e fogo no nível 3, mapa do pântano, painel de fases e botão de próxima fase.
8. Demais fases.

## Decisões adiadas

- Antes de publicar: título e licença do código e da arte.
- Depois da primeira versão: linguagem de programação de áudio, com os sons avaliados de ouvido por quem dirige o projeto.
- Só se o núcleo pedir: casas com renda, caminhos ramificados de melhoria, novos modos de dificuldade, monstros à distância, slimes elementais, curandeiros, invocadores e voadores.

## Ainda sem verificação real

- Abrir o `.exe` no Windows e publicar no itch.io.
- Pintar o caminho no editor de mapas do Godot: o TileSet já tem o terreno `caminho` configurado, mas isso não foi usado à mão.
- Revisão do código do GUT.
