# Efeitos e dimensões

[Início](Home.md) · [Configurações](Configuracoes.md) · [Materiais](Materiais.md)

## Iluminação e sombras

No Overworld, a paleta muda entre sol dourado, entardecer alaranjado e noite azulada. A iluminação usa as normais das superfícies e o lightmap do jogo, incluindo o acesso à luz do céu. A luz mínima das cavernas é ajustável.

A luz de itens nas mãos considera as duas mãos, a distância à câmera, a orientação da superfície e as cores de [item.properties](../VanillaPlus_M1/shaders/item.properties). O tremular se aplica aos grupos de fogo comum, alma e lava. É um efeito visual calculado pelo shader; não altera os níveis de luz do mundo.

As sombras solares atuam no Overworld e perdem intensidade ao anoitecer e perto do limite de distância. `SHADOW_FILTER` seleciona 1, 9 ou 25 amostras por consulta. A vegetação usa a mesma deformação no desenho do terreno e no mapa de sombras.

Fonte: [common.glsl](../VanillaPlus_M1/shaders/lib/common.glsl), [shadows.glsl](../VanillaPlus_M1/shaders/lib/shadows.glsl) e [wind.glsl](../VanillaPlus_M1/shaders/lib/wind.glsl).

## Água

Apenas o material `10004`, mapeado para água, recebe o tratamento específico. Vidro, gelo e outros translúcidos que passam pelo mesmo programa continuam com seu tratamento de iluminação.

| Efeito | Comportamento |
| --- | --- |
| Superfície | Posição dos vértices estática, sem ondas geométricas |
| Reflexo | Céu procedural e auroras, com intensidade dependente do ângulo de visão; desligado quando a câmera está submersa |
| Densidade da água | Usa a distância entre a superfície e a geometria atrás dela para ajustar cor e opacidade |
| Neblina subaquática | Absorve canais de cor de forma diferente; tons quentes desaparecem mais depressa |
| Distorção | Desloca suavemente a amostragem da imagem ao mergulhar, com proteção de contornos |
| Cáusticas | Padrões luminosos animados no terreno abaixo da câmera, quando o jogador está submerso no Overworld e há luz solar |
| Raios subaquáticos | Feixes com oclusão pelo mapa de sombras, atenuados pela chuva, pela absorção e pela falta de acesso ao céu |

Os raios subaquáticos desaparecem à noite. `WIND_STRENGTH` controla vegetação, e não ondas. O reflexo não consulta a geometria da cena nem inclui o volume de nuvens desenhado na composição.

Fonte: [água](../VanillaPlus_M1/shaders/program/gbuffers_water_fragment.glsl), [vértices da água](../VanillaPlus_M1/shaders/program/gbuffers_water_vertex.glsl), [óptica](../VanillaPlus_M1/shaders/lib/water_optics.glsl) e [raios subaquáticos](../VanillaPlus_M1/shaders/lib/underwater_rays.glsl).

## Nuvens e atmosfera

`CLOUD_STYLE=1` usa amostragem de um volume procedural suave. `CLOUD_STYLE=2` usa nuvens blocadas Enhanced Vanilla, com interseções com volumes de blocos e sombreamento das faces. O valor `0` desliga as nuvens; a malha de nuvens do jogo é descartada pelo pacote.

`CLOUD_STEPS` afeta somente as nuvens realistas. Cobertura, altura e velocidade afetam os dois estilos. A chuva também aumenta a cobertura no cálculo procedural.

As nuvens e os raios solares são inicialmente calculados com metade da largura e da altura da tela. A composição usa a profundidade da cena; quando a geometria corta a camada de nuvens, o trecho visível é recalculado. Os raios solares dependem da luz diurna, do acesso ao céu e das sombras, ficando mais fracos na chuva.

O shader de precipitação preserva a textura de chuva/neve e aplica iluminação, opacidade e suavização por distância. `RAIN_OPACITY` muda a visibilidade da precipitação, sem controlar o clima do mundo.

Fonte: [clouds.glsl](../VanillaPlus_M1/shaders/lib/clouds.glsl), [sun_rays.glsl](../VanillaPlus_M1/shaders/lib/sun_rays.glsl) e [precipitação](../VanillaPlus_M1/shaders/program/gbuffers_weather_fragment.glsl).

## Diferenças por dimensão

| Recurso | Overworld | Nether | End |
| --- | --- | --- | --- |
| Ambiente | Dia, entardecer e noite | Cor influenciada pela neblina do bioma | Rosa ajustável |
| Céu | Gradiente, brilhos solares/lunares e estrelas noturnas | Atmosfera baseada em `fogColor` | Atmosfera cósmica, estrelas e nebulosa |
| Nuvens próprias | Sim | Não | Não |
| Sombras e raios solares | Durante o dia | Não | Não |
| Auroras | Não | Não | Sim, em direção ao norte |
| Cáusticas e raios subaquáticos | Com as condições descritas acima | Não | Não |

No End, `END_STARS` e `END_NEBULA` controlam elementos do céu. `END_PINK_LIGHT=0.0` mantém um rosa suave; `1.0` usa um rosa mais intenso. As auroras não dependem do horário e incluem tons violetas, cianos e magentas na implementação atual. A descrição de auroras verdes no arquivo de idioma não corresponde exatamente à paleta do código.

O roteamento usa os IDs `minecraft:the_nether` e `minecraft:the_end`. Dimensões não listadas usam os programas da raiz, com atmosfera de Overworld.

Fonte: [dimension.properties](../VanillaPlus_M1/shaders/dimension.properties), [dimensions.glsl](../VanillaPlus_M1/shaders/lib/dimensions.glsl), [end_sky.glsl](../VanillaPlus_M1/shaders/lib/end_sky.glsl) e [aurora.glsl](../VanillaPlus_M1/shaders/lib/aurora.glsl).

## Pós-processamento

O bloom parte de pixels com luminância acima de `1.0`, antes do mapeamento de tons. Em seguida são aplicados exposição, compressão das cores para a faixa de exibição, saturação, vivacidade e vinheta. O último passe aplica o nível escolhido de FXAA.

O nível 2 é chamado de “Ultra (FXAA 3.11)” no menu; o nível 3 acrescenta tratamento diagonal e limitação de cor para preservar detalhes. São os nomes e comportamentos presentes no pacote, sem uma medição comparativa de qualidade.

Fonte: [composite1](../VanillaPlus_M1/shaders/program/composite1_fragment.glsl), [composite2](../VanillaPlus_M1/shaders/program/composite2_fragment.glsl) e [final](../VanillaPlus_M1/shaders/program/final_fragment.glsl).
