# Estrutura técnica

[Início](Home.md) · [Configurações](Configuracoes.md) · [Materiais](Materiais.md)

## Organização

```text
VanillaPlus_M1/shaders/
├── *.vsh / *.fsh       Entradas dos programas do Overworld
├── nether/            Entradas com VP_DIMENSION = -1
├── end/               Entradas com VP_DIMENSION = 1
├── program/           Implementações compartilhadas de vértices e fragmentos
├── lib/               Bibliotecas de efeitos e configurações
├── lang/              Rótulos em português e inglês
├── shaders.properties Menus, perfis e opções do carregador
├── dimension.properties Roteamento por ID de dimensão
├── block.properties   IDs de materiais dos blocos
└── item.properties    IDs de cores para luz de itens nas mãos
```

As entradas usam `#version 330 compatibility`, definem `VP_DIMENSION` e incluem a implementação compartilhada. A raiz define `0`; Nether e End usam `-1` e `1`. Isso permite manter os efeitos em um lugar e selecionar comportamento por dimensão.

## Etapas de renderização

| Programa | Responsabilidade |
| --- | --- |
| `shadow` | Geometria do mapa de sombras, incluindo deformação da vegetação e descarte por alfa |
| `gbuffers_terrain` | Texturas, cor de bioma/AO recebido, iluminação, sombras, emissão, portais e cáusticas |
| `gbuffers_block` | Reutiliza os programas de terreno |
| `gbuffers_entities` | Iluminação, sombras, cor de dano e realce emissivo por detecção de cor |
| `gbuffers_particles` | Partículas comuns e detecção de cores emissivas |
| `gbuffers_water` | Água e demais materiais translúcidos; tratamento específico por ID |
| `gbuffers_weather` | Precipitação; entradas próprias presentes na raiz |
| `gbuffers_skybasic` | Escreve fundo transparente para a composição do céu próprio |
| `gbuffers_clouds` | Descarta a malha de nuvens do jogo |
| `composite` | Pré-cálculo de nuvens e raios solares em resolução reduzida |
| `composite1` | Céu, neblina, composição de nuvens, efeitos subaquáticos e extração de brilho |
| `composite2` | Bloom, exposição, mapeamento de tons, cor e vinheta |
| `final` | FXAA e saída final |

Fluxo simplificado: **geometria e sombras → atmosfera → composição da cena → ajustes de imagem → FXAA**. A ordem interna e os buffers são definidos pelos programas e pelo carregador.

## Buffers de cor

| Buffer | Uso nesta implementação |
| --- | --- |
| `colortex0` | Cor da cena e resultado dos passes de composição |
| `colortex1` | Extração de brilho para bloom, com mipmaps habilitados em `composite2` |
| `colortex2` | Raios solares em RGB e distância da superfície no alfa |
| `colortex5` | Nuvens em RGB e opacidade no alfa |

Os quatro formatos são declarados como `RGBA16F` no GLSL. `colortex2` e `colortex5` têm escala `0.5 0.5` em [shaders.properties](../VanillaPlus_M1/shaders/shaders.properties): metade em cada eixo, ou um quarto do número de pixels. A composição dos raios usa pesos de profundidade para reduzir vazamento sobre contornos.

## Onde editar

| Alteração | Arquivo principal |
| --- | --- |
| Valores padrão e listas de opções | [settings.glsl](../VanillaPlus_M1/shaders/lib/settings.glsl) |
| Menus, sliders e perfis | [shaders.properties](../VanillaPlus_M1/shaders/shaders.properties) |
| Nomes e descrições de opções | [pt_br.lang](../VanillaPlus_M1/shaders/lang/pt_br.lang) e [en_us.lang](../VanillaPlus_M1/shaders/lang/en_us.lang) |
| Paleta, luz do céu e luz das mãos | [common.glsl](../VanillaPlus_M1/shaders/lib/common.glsl) |
| Ambiente e neblina por dimensão | [dimensions.glsl](../VanillaPlus_M1/shaders/lib/dimensions.glsl) |
| Sombras de superfície | [shadows.glsl](../VanillaPlus_M1/shaders/lib/shadows.glsl) |
| Oclusão de luz volumétrica | [volume_shadows.glsl](../VanillaPlus_M1/shaders/lib/volume_shadows.glsl) |
| Nuvens | [clouds.glsl](../VanillaPlus_M1/shaders/lib/clouds.glsl) |
| Céu do End e auroras | [end_sky.glsl](../VanillaPlus_M1/shaders/lib/end_sky.glsl) e [aurora.glsl](../VanillaPlus_M1/shaders/lib/aurora.glsl) |
| Água, portais e vegetação | [water_optics.glsl](../VanillaPlus_M1/shaders/lib/water_optics.glsl), [portals.glsl](../VanillaPlus_M1/shaders/lib/portals.glsl) e [wind.glsl](../VanillaPlus_M1/shaders/lib/wind.glsl) |

Ao adicionar uma opção, mantenha valor padrão, valores aceitos, menu, tradução e wiki sincronizados. Adicione-a aos perfis somente se eles precisarem controlá-la. Para novos materiais, confira tanto o arquivo `.properties` quanto a lógica que interpreta o ID.

## Limites da implementação

Não há compilador, suíte de testes ou capturas de referência incluídos no projeto. A validação visual precisa ocorrer no Minecraft com o carregador escolhido. Ao mudar efeitos compartilhados, confira Overworld, Nether e End, além de transparências, itens nas duas mãos e transições para dentro da água.

A iluminação dos blocos usa o lightmap do jogo com uma cor de tocha comum. O realce emissivo e o bloom não constituem um sistema de propagação de luz colorida por bloco. Entidades e partículas usam heurísticas de cor para alguns brilhos; não há identificação exclusiva por espécie nesses trechos.
