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
- Caminho único nas fases 1 e 2; duas entradas a partir da fase 3, escolhidas por grupo de monstros em cada onda. Na floresta, os caminhos só se unem perto da vila, e uma seta avisa por qual entrada vem a próxima onda.
- No cemitério, as entradas ficam em lados opostos do mapa. O campo de túmulos no meio impede que uma célula fora do alcance dos monstros cubra as duas entradas, o que um teste exige.
- Um conjunto base de tiles com variações de cor e detalhe por ambiente.

## Humanos

- Ficam parados depois de posicionados. Dispensar um humano devolve metade de todo o ouro gasto nele, incluindo melhorias.
- 3 níveis lineares. O nível 3 libera uma habilidade automática, com variação visual que destaca essa habilidade. Os níveis 2 e 3 têm sprites próprios.
- A explosão do mago dá dano cheio aos alvos mais próximos dentro do raio, até um limite: 5, 6 e 7 alvos nos níveis 1, 2 e 3. O fogo do nível 3 fica onde estava o alvo e queima por alguns segundos.
- Só o corpo a corpo segura monstros. Qualquer humano ao alcance de um monstro leva dano: quem não está bloqueado continua andando e bate de passagem no humano mais próximo. Ao perder toda a vida, o humano cai e volta depois de alguns segundos, sem morte permanente. Isso obriga a afastar arqueiros e magos do caminho.
- O lanceiro alcança 2 tiles, mas só segura quem chega perto. No nível 3, o golpe acerta todos na linha até o fim do alcance.
- O druida causa pouco dano e deixa lentos o alvo e quem está em volta. No nível 3, a cada 4 ataques as raízes prendem o alvo por alguns segundos; o intervalo é fixo, sem sorte, para as partidas poderem ser repetidas.
- O monge ataca rápido e segura menos monstros que o guerreiro. No nível 3, a cada 6 ataques atordoa o alvo, que não anda nem bate por alguns segundos. O intervalo é fixo, como o das raízes.
- O ladino tem alcance curto. A cada 3 ataques, o golpe crítico causa 2,5 vezes o dano e ignora a resistência do monstro, sem sorte. No nível 3, cada abate dele rende 1 de ouro extra, com uma moeda subindo do monstro.
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
- Lobo: quatro patas, rápido, escapa das defesas e pede bloqueio. Sem variantes por enquanto.
- Esqueleto: resiste a dano perfurante e um pouco à magia, e é fraco contra impacto. Ao morrer, desfaz-se numa pilha de ossos.
- Cavaleiro esqueleto: variante com elmo, escudo e espada, mais lenta e resistente. Resiste a perfurante e a impacto, e é fraca contra magia.
- Slime: três tamanhos em `data/monsters.json`. Cada um se divide em dois do tamanho seguinte ao morrer, e quem chega à vila não se divide.
- Rei Slime: chefe da Fase 5, num quadro de 96×72 px, com coroa, sobrancelhas bravas e um verde mais fundo que o dos slimes. A cada quarto da vida perdido solta 2 slimes grandes, e ao morrer solta 3. Não pode ser bloqueado: passa por cima dos humanos e bate em quem estiver no caminho. Não pode ser preso nem atordoado, mas pode ser lento. Resiste a perfurante e a impacto e é fraco contra magia. Se chegar à vila, leva metade das vidas: perde as 3 estrelas, mas a partida continua. Enquanto está em campo, uma barra larga no alto do mapa mostra a vida dele.

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
- Menu na barra superior, que pausa o jogo e reúne continuar, reiniciar, idioma e sair. No navegador, o botão de sair fica escondido.
- Marcador de vida acima da vila, com as vidas restantes em verde, as perdidas em vermelho e o número exato. A barra superior também mostra restantes/total.
- Com mais de 3 classes, a barra mostra só ícone e preço, e o nome e o tipo de dano aparecem ao passar o mouse. Com 7 classes, o ícone menor fica sobre o preço.
- Tipos de dano: o golpe pisca amarelo quando o monstro é fraco, cinza quando resiste e branco no caso normal. Ao lado do botão de chamar onda, aparece a que os monstros da próxima onda são fracos, e o humano selecionado mostra o tipo do seu dano.
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
- Nona avaliação, a primeira da Fase 3: impossível de ganhar. Em 6 tentativas ninguém passou da onda 9, que tinha 10 goblins blindados. A fase tinha sido calibrada com robôs que não chamam ondas antes da hora, e as ondas eram maiores que as da Fase 2, embora as duas entradas dividam a defesa. As ondas 4, 5 e 7 a 12 encolheram. Repetindo as partidas reais e gastando o ouro que sobra, a melhor vence com 12 vidas e outra com 7; a que abre com druida ainda perde na onda 11. Um robô com guerreiros e arqueiros de nível 3 vence sem perder vidas, então a fase pode não exigir lanceiro nem druida. Essas partidas ficam em `tests/fixtures/partidas`. Aguarda nova avaliação jogando.
- Décima avaliação: ainda impossível, mas a partida já chegou à onda 12 com 11 vidas. Tirar monstros também tinha tirado ouro: a renda caiu para 834, abaixo dos 939 da Fase 2. As ondas ficaram como estavam, e os bônus das ondas 4 a 11 subiram, levando a renda a 914. Quem dirige o projeto pediu que 3 estrelas continuem possíveis, e os testes e2e exigem isso. Na repetição, gastar o ouro que sobra dá 20 vidas; não gastar perde a partida. Um robô com guerreiros e arqueiros de nível 3 ainda vence sem perder vidas. Aguarda nova avaliação jogando.
- Décima primeira avaliação: ficou fácil depois das primeiras ondas. A partida venceu com 3 estrelas e 20 vidas em 6:41, com 5 humanos. O arqueiro de nível 3 em (7,6) alcança as duas entradas fora do alcance dos monstros, ninguém caiu da onda 5 em diante, e a onda 12 parou a 45% do caminho. Essa partida fica em `tests/fixtures/partidas`.
- Décima segunda avaliação, que aprova a Fase 3 com nota 8 de 10. Na sequência das 3 fases, todas venceram com 2 estrelas: Fase 1 com 16 vidas em 5:50 e 264 de ouro sobrando, Fase 2 com 14 vidas em 7:53 e 220 de ouro, Fase 3 com 14 vidas em 8:37 e 76 de ouro. Em todas, as vidas se perderam nas primeiras ondas ou na onda 9, nunca nas duas últimas. A Fase 4 deve cuidar desse fim tranquilo e da duração, abaixo dos 10 a 15 minutos previstos, porque quem joga chama quase todas as ondas. A vitória da Fase 3 e a de 3 estrelas precisam se repetir iguais.
- Primeira calibragem da Fase 4, ainda sem partida real: 13 ondas e renda de 1031. Com robôs que chamam a onda 6 segundos depois de limpar o campo, misturar classes vence com 11 a 18 vidas; arqueiros sozinhos ficam com 2 vidas e as outras classes sozinhas perdem, quase sempre na onda 13. A exceção é o mago sozinho, que vence com 17 vidas.
- Primeira avaliação da Fase 4: difícil demais para 3 estrelas. A vitória teve 16 vidas em 8:50, perdendo vidas só nas ondas 4 e 6; duas tentativas com ladino, lanceiro e guerreiro foram reiniciadas na onda 10 depois de perder vidas nas ondas 8 a 10. As ondas 4, 6, 8, 9 e 10 encolheram, as 11 a 13 ficaram iguais, e os bônus subiram para a renda ficar em 1015. Repetida, a vitória tem 19 vidas; as tentativas reiniciadas vencem com 20 gastando o ouro que sobra, e uma delas perde sem gastar. Essas partidas ficam em `tests/fixtures/partidas`.
- Segunda avaliação, que aprova a Fase 4 com nota 9 de 10: bem difícil. A vitória teve 16 vidas em 10:37, todas perdidas na onda 13, para slimes pequenos. A onda 13 encolheu de 56 para 44 monstros, e repetida a partida vence com 20 vidas. Seus 8 lobos viraram 8 esqueletos, porque sem eles só arqueiros também ganhavam 3 estrelas. Essa partida fica em `tests/fixtures/partidas` e precisa ganhar 3 estrelas.
- Primeira calibragem da Fase 5, ainda sem partida real: 14 ondas, com o Rei Slime e escolta na última. Os arredores do vilarejo têm uma entrada pela esquerda e outra pelo alto, que se juntam antes da vila; um campo de trigo no meio impede uma célula de cobrir as duas a salvo. Com o rei bloqueável, monges sozinhos venciam com 20 vidas segurando tudo onde os caminhos se juntam. Sem bloqueio, quem defende só esse trecho fica com 5 vidas, e monges, arqueiros ou guerreiros sozinhos ficam abaixo de 10 ou perdem. Um robô que defende o caminho inteiro vence com 20 vidas, mas o rei só cai depois de andar 81% do caminho. O mago sozinho vence com 12. Com 850 de vida em vez de 800, aquele robô fica com 15 vidas: o resultado é sensível à vida do rei.
- Primeira avaliação, que aprova a Fase 5 com nota 7 de 10. A vitória teve 3 estrelas e 20 vidas em 11:36, com o mago, o druida e o ladino no nível 3 abatendo o rei e os 91 slimes da última onda sem deixar nenhum passar. Repetida, a partida se repete igual; ela fica em `tests/fixtures/partidas`.

## Técnica

- Godot 4.7.2 com GDScript e GUT 9.7.1, versões fixadas.
- Regras do jogo em GDScript sem depender de cenas, escritas em TDD e testadas sem janela.
- As partidas reais ficam em `tests/fixtures/partidas` e viram testes e2e em `tests/e2e`: um jogador gravado clica nos botões reais, com o ritmo relativo às ondas e esperando ter ouro. As partidas aprovadas das Fases 1, 2 e 3 precisam se repetir iguais, onda por onda; toda partida nova nessa pasta entra sozinha na repetição geral.
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
8. Feito: Fase 3, aprovada em 2026-11-06 com nota 8 de 10, com lobo, lanceiro, druida, floresta com duas entradas, menu e marcador de vida da vila.
9. Feito: Fase 4, aprovada em 2026-11-07 com nota 9 de 10, com esqueletos, monge, ladino, cemitério, barra de 7 classes e indicações de tipo de dano.
10. Feito: Fase 5, aprovada em 2026-11-07 com nota 7 de 10, com Rei Slime, arredores do vilarejo e mensagem de fim de campanha.
11. Menu principal e sons.

## Decisões adiadas

- Antes de publicar: título e licença do código e da arte.
- Depois da primeira versão: linguagem de programação de áudio, com os sons avaliados de ouvido por quem dirige o projeto.
- Só se o núcleo pedir: casas com renda, caminhos ramificados de melhoria, novos modos de dificuldade, monstros à distância, slimes elementais, curandeiros, invocadores e voadores.

## Ainda sem verificação real

- Abrir o `.exe` no Windows e publicar no itch.io.
- Fases 3 a 5 e menu nos builds de navegador, Linux e Windows: os builds atuais ainda têm só até a Fase 2.
- Pintar o caminho no editor de mapas do Godot: o TileSet já tem o terreno `caminho` configurado, mas isso não foi usado à mão.
- Revisão do código do GUT.
