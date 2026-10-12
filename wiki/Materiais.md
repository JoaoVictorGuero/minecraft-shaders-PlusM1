# Blocos, itens e materiais

[Início](Home.md) · [Efeitos](Efeitos.md) · [Arquitetura](Arquitetura.md)

Os arquivos `.properties` associam nomes de registro do Minecraft a IDs internos. Os exemplos abaixo são resumidos; a lista completa e as condições de estado estão em [block.properties](../VanillaPlus_M1/shaders/block.properties) e [item.properties](../VanillaPlus_M1/shaders/item.properties).

## IDs de blocos

| ID | Grupo | Exemplos |
| --- | --- | --- |
| `10000` | Vegetação baixa e cultivos | Grama, samambaias, trigo, cenouras, batatas |
| `10001` | Folhas | Carvalho, pinheiro, cerejeira, mangue, azaleia e carvalho pálido |
| `10002` | Vinhas | Vinhas comuns, choronas e retorcidas |
| `10003` | Flores | Dente-de-leão, papoula, tulipas e outras flores listadas |
| `10004` | Água | `minecraft:water` |
| `10010` | Emissores de fogo comum | Tochas, lanternas, fogo; fornalhas, velas e fogueiras nos estados listados |
| `10011` | Emissores de alma | Tochas, lanternas, fogo e fogueiras de alma |
| `10012` | Redstone emissiva | Tochas e minérios nos estados `lit=true` |
| `10013` | Grupo de emissores claros | Lanterna do mar, haste do End, sinalizador, conduto, froglight perolado |
| `10014` | Grupo de emissores quentes | Pedra luminosa, shroomlight, abóbora iluminada, froglight ocre, lâmpada acesa e vinhas com bagas |
| `10015` | Lava | Lava e bloco de magma |
| `10016` | Grupo de emissores roxos | Obsidiana chorona, formações de ametista listadas, froglight verdejante e âncora de renascimento |
| `10017` | Portal do Nether | `minecraft:nether_portal` |
| `10018` | Portal e gateway do End | `minecraft:end_portal`, `minecraft:end_gateway` |

Os IDs `10000` a `10003` recebem vento e tratamento de folhagem. Os IDs `10010` a `10016` passam pelo mesmo realce de emissão no programa de terreno, usando a cor da textura e `EMISSIVE_BOOST`. A divisão em grupos no arquivo não implementa, por si só, luz colorida propagada para blocos vizinhos, apesar do comentário presente em `block.properties`.

Estados como `lit=true` e `berries=true` fazem parte do mapeamento: não remova esses filtros se quiser preservar a distinção entre blocos acesos e apagados.

## Luz dos itens nas mãos

| ID | Cor usada | Exemplos |
| --- | --- | --- |
| `20000` | Âmbar | Tocha e fogueira |
| `20001` | Azul/ciano | Tocha, lanterna e fogueira de alma |
| `20002` | Vermelha | Tocha de redstone |
| `20003` | Branco frio | Lanterna do mar, haste do End, sinalizador e conduto |
| `20004` | Amarelo quente | Pedra luminosa, lanterna, bagas luminosas e outros itens listados |
| `20005` | Laranja | Balde de lava, magma, vara de blaze e carga de fogo |
| `20006` | Roxa | Obsidiana chorona, agregado de ametista e froglight verdejante |

O ID escolhe a cor. A intensidade também depende dos níveis de luz fornecidos pelo carregador para cada mão. O código força um nível mínimo de 15 no grupo `20005` e 10 no grupo `20006`; nos demais grupos, o mapeamento sozinho não garante emissão se o nível recebido for zero. IDs não tratados pela seleção de cor usam `TORCH_COLOR` quando há luz disponível.

Fonte: funções `heldLightColor`, `heldLightLevel` e `getHandLight` em [common.glsl](../VanillaPlus_M1/shaders/lib/common.glsl).

## Portais, entidades e partículas

Os portais mantêm cores emissivas independentes da luz ambiente da dimensão. O portal do Nether usa sua textura com realce; o portal/gateway do End recebe uma superfície procedural escura com estrelas verdes em movimento.

O programa de entidades procura regiões roxas pela cor para produzir um brilho inspirado nos olhos de Endermen e do dragão. Como a detecção não consulta a identidade da entidade, outras texturas com cores semelhantes também podem ser afetadas. Partículas roxas, brancas, alaranjadas e cianas usam detecção semelhante.

Fonte: [portals.glsl](../VanillaPlus_M1/shaders/lib/portals.glsl), [entidades](../VanillaPlus_M1/shaders/program/gbuffers_entities_fragment.glsl) e [partículas](../VanillaPlus_M1/shaders/program/gbuffers_particles_fragment.glsl).
