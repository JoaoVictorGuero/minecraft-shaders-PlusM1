# Referência de configurações

[Início](Home.md) · [Efeitos](Efeitos.md) · [Perfis](Desempenho.md)

As tabelas seguem os seis menus de [shaders.properties](../VanillaPlus_M1/shaders/shaders.properties). Os padrões e valores aceitos foram extraídos de [settings.glsl](../VanillaPlus_M1/shaders/lib/settings.glsl). Use o identificador técnico para localizar uma opção mesmo quando o nome traduzido for diferente.

**Padrão** significa o valor no código, sem ajustes salvos pelo carregador. Os valores entre colchetes no GLSL são escolhas discretas: os controles deslizantes percorrem essas escolhas, não uma faixa arbitrária. Os [perfis](Desempenho.md) sobrescrevem somente oito opções.

## Iluminação (`LIGHTING`)

| Opção | Padrão | Valores aceitos | Função |
| --- | --- | --- | --- |
| `TORCH_STRENGTH` | `1.25` | `0.75`, `1.0`, `1.25`, `1.5`, `2.0` | Intensidade da luz de blocos e dos itens nas mãos. |
| `MIN_CAVE_LIGHT` | `0.035` | `0.015`, `0.025`, `0.035`, `0.045`, `0.065` | Piso de luz da cena, também usado em partículas e precipitação. |
| `NIGHT_FLAT_LIGHT` | `0.6` | `0.35`, `0.45`, `0.6`, `0.75` | Componente de iluminação noturna do Overworld. |
| `EMISSIVE_BOOST` | `2.4` | `1.4`, `1.8`, `2.4`, `3.0` | Realce de materiais emissores, portais e regiões emissivas de entidades. |
| `DYNAMIC_LIGHT` | `1.0` | `0.0`, `0.5`, `1.0`, `1.5` | Intensidade da luz dos itens nas mãos; zero desliga. |
| `DYNAMIC_FLICKER` | `1` | `0`, `1` | Tremular da luz na mão nos grupos fogo, alma e lava: 0 = desligado; 1 = ligado. |
| `END_PINK_LIGHT` | `1.0` | `0.0`, `0.25`, `0.5`, `0.75`, `1.0` | Luz ambiente do End: 0.0 = rosa suave; 1.0 = rosa intenso. |

## Sombras (`SHADOWS`)

| Opção | Padrão | Valores aceitos | Função |
| --- | --- | --- | --- |
| `shadowMapResolution` | `1024` | `512`, `1024`, `2048` | Resolução do mapa quadrado de sombras, em pixels por lado. |
| `shadowDistance` | `64.0` | `48.0`, `64.0`, `96.0` | Distância das sombras, em unidades do mundo (blocos). |
| `SHADOW_STRENGTH` | `0.7` | `0.2`, `0.35`, `0.55`, `0.7`, `0.85` | Intensidade das sombras solares. |
| `SHADOW_FILTER` | `1` | `0`, `1`, `2` | Filtro: 0 = 1 amostra; 1 = 9; 2 = 25. |

## Água (`WATER`)

| Opção | Padrão | Valores aceitos | Função |
| --- | --- | --- | --- |
| `WATER_REFLECTION` | `0.65` | `0.0`, `0.35`, `0.65`, `0.85`, `1.0` | Reflexo do céu e das auroras na água; zero desliga. |
| `WATER_DENSITY` | `0.12` | `0.06`, `0.09`, `0.12`, `0.18`, `0.25` | Absorção pela espessura da água, usada na cor e opacidade da superfície. |
| `UNDERWATER_DENSITY` | `0.045` | `0.025`, `0.035`, `0.045`, `0.065`, `0.09` | Absorção com a câmera submersa; também participa dos raios na água. |
| `WATER_CAUSTICS` | `0.65` | `0.0`, `0.35`, `0.65`, `1.0` | Padrões luminosos no terreno durante o mergulho no Overworld. |
| `UNDERWATER_DISTORTION` | `0.35` | `0.0`, `0.2`, `0.35`, `0.5`, `0.75` | Distorção da imagem submersa; zero desliga. |
| `UNDERWATER_RAYS` | `1.1` | `0.0`, `0.5`, `0.8`, `1.1`, `1.5`, `2.0` | Intensidade dos raios subaquáticos diurnos do Overworld; zero desliga. |
| `UNDERWATER_RAY_STEPS` | `12` | `8`, `12`, `20` | Quantidade de amostras dos raios subaquáticos. |

## Imagem (`POST`)

| Opção | Padrão | Valores aceitos | Função |
| --- | --- | --- | --- |
| `BLOOM_STRENGTH` | `0.14` | `0.0`, `0.08`, `0.14`, `0.2`, `0.3` | Intensidade do halo de brilho; zero desliga sua aplicação. |
| `EXPOSURE` | `1.1` | `0.65`, `0.8`, `0.95`, `1.1`, `1.25` | Multiplicador de exposição antes do mapeamento de tons. |
| `SATURATION` | `1.25` | `0.85`, `0.95`, `1.05`, `1.15`, `1.25` | Intensidade geral das cores, limitada à faixa de exibição. |
| `VIBRANCE` | `0.25` | `0.0`, `0.1`, `0.18`, `0.25`, `0.35` | Realce de cores pouco saturadas, reduzido em regiões muito claras. |
| `VIGNETTE` | `0.08` | `0.0`, `0.08`, `0.12`, `0.2`, `0.3` | Escurecimento das bordas; zero desliga. |
| `FXAA` | `2` | `0`, `1`, `2`, `3` | 0 = desligado; 1 = Rápido; 2 = Ultra (FXAA 3.11 no menu); 3 = Extremo. |

## Atmosfera (`ATMOSPHERE`)

| Opção | Padrão | Valores aceitos | Função |
| --- | --- | --- | --- |
| `WIND_STRENGTH` | `0.65` | `0.0`, `0.35`, `0.65`, `1.0`, `1.4` | Movimento da vegetação; não movimenta a superfície da água. |
| `FOG_DENSITY` | `0.8` | `0.6`, `0.8`, `1.0`, `1.25`, `1.5` | Densidade da neblina atmosférica e fator da dispersão dos raios solares. |
| `SUN_RAYS` | `1.0` | `0.0`, `0.35`, `0.65`, `1.0`, `1.4` | Intensidade dos raios solares no ar, no Overworld; zero desliga. |
| `SUN_RAY_STEPS` | `12` | `8`, `12`, `20` | Quantidade de amostras dos raios solares. |
| `RAIN_OPACITY` | `0.65` | `0.35`, `0.5`, `0.65`, `0.8`, `1.0` | Visibilidade da chuva e neve; valores menores deixam a precipitação mais transparente. |
| `AURORA` | `1` | `0`, `1` | Auroras exclusivas do End: 0 = desligadas; 1 = ligadas. |
| `AURORA_STRENGTH` | `0.8` | `0.0`, `0.4`, `0.6`, `0.8`, `1.0`, `1.4` | Intensidade das auroras; zero oculta o efeito. |
| `AURORA_SPEED` | `1.0` | `0.0`, `0.5`, `1.0`, `1.5`, `2.0` | Velocidade das auroras; zero congela a animação. |
| `END_STARS` | `1` | `0`, `1` | Estrelas do End: 0 = desligadas; 1 = ligadas. |
| `END_NEBULA` | `1` | `0`, `1` | Nebulosa do End: 0 = desligada; 1 = ligada. |

## Nuvens (`CLOUDS`)

| Opção | Padrão | Valores aceitos | Função |
| --- | --- | --- | --- |
| `CLOUD_STYLE` | `1` | `0`, `1`, `2` | 0 = desligadas; 1 = Realistas; 2 = Enhanced Vanilla. |
| `CLOUD_STEPS` | `12` | `8`, `12`, `20` | Amostras das nuvens realistas; não afeta Enhanced Vanilla. |
| `CLOUD_COVERAGE` | `0.55` | `0.3`, `0.4`, `0.55`, `0.7`, `0.85` | Cobertura procedural dos dois estilos de nuvens. |
| `CLOUD_HEIGHT` | `192.0` | `160.0`, `192.0`, `224.0`, `256.0` | Altitude da base da camada de nuvens, em unidades do mundo (blocos). |
| `CLOUD_SPEED` | `1.0` | `0.0`, `0.5`, `1.0`, `1.5` | Velocidade das nuvens; zero congela o deslocamento. |

## Constantes fora do menu

`sunPathRotation = -40.0` e `TORCH_COLOR = vec3(1.0, 0.58, 0.26)` estão em `settings.glsl`, mas não são opções listadas nos menus. Alterá-las exige editar o código. A segunda define a cor-base de tocha usada na iluminação.

`oldLighting=false`, `oldHandLight=false`, `vignette=false`, `underwaterOverlay=false` e `shadowTranslucent=false` são propriedades do carregador. A propriedade `vignette=false` é distinta da opção `VIGNETTE`, que controla a vinheta implementada pelo próprio pacote.

## Relações entre opções

- **Água:** `WATER_DENSITY` controla a superfície pela espessura; `UNDERWATER_DENSITY` controla a absorção quando a câmera está submersa.
- **Nuvens:** `CLOUD_STEPS` só afeta o estilo Realistas. Os dois estilos usam cobertura, altura e velocidade.
- **Raios:** os controles de intensidade ligam/desligam o efeito; os controles `*_STEPS` mudam a quantidade de amostras.
- **End:** estrelas, nebulosa, auroras e intensidade rosa têm controles separados. A luz rosa fica no menu Iluminação.
- **Imagem:** `EMISSIVE_BOOST` aumenta vários materiais brilhantes; `BLOOM_STRENGTH` ajusta o halo produzido pela imagem de brilho.
