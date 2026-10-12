# Perfis e desempenho

[Início](Home.md) · [Configurações](Configuracoes.md) · [Problemas](Solucao-de-problemas.md)

## Perfis incluídos

Os três perfis alteram exatamente os oito parâmetros abaixo, conforme [shaders.properties](../VanillaPlus_M1/shaders/shaders.properties).

| Parâmetro | Desempenho | Equilibrado (M1) | Qualidade |
| --- | --- | --- | --- |
| ID do perfil | `PERFORMANCE` | `BALANCED` | `QUALITY` |
| `shadowMapResolution` | 512 | 1024 | 2048 |
| `shadowDistance` | 48.0 | 64.0 | 96.0 |
| `SHADOW_FILTER` | 0 | 1 | 2 |
| `BLOOM_STRENGTH` | 0.08 | 0.14 | 0.2 |
| `FXAA` | 1 | 2 | 3 |
| `CLOUD_STEPS` | 8 | 12 | 20 |
| `UNDERWATER_RAY_STEPS` | 8 | 12 | 20 |
| `SUN_RAY_STEPS` | 8 | 12 | 20 |

Os valores de fábrica desses oito parâmetros coincidem com o perfil Equilibrado. Os perfis não redefinem todas as opções: por exemplo, não especificam `CLOUD_STYLE`, `AURORA`, `EXPOSURE` ou as intensidades dos raios. Para restaurar o conjunto completo, use a restauração dos padrões do carregador.

## Ajustar o custo visual

As orientações abaixo são inferências a partir dos laços de amostragem e das resoluções no código, sem benchmarks:

1. Experimente o perfil **Desempenho** como ponto de partida.
2. Compare resolução, distância e filtro das sombras. Os filtros 0, 1 e 2 usam respectivamente 1, 9 e 25 leituras por consulta de sombra de superfície.
3. Com nuvens realistas, reduza `CLOUD_STEPS`; esse ajuste não altera o algoritmo Enhanced Vanilla. `CLOUD_STYLE=0` desliga o efeito.
4. Reduza `SUN_RAY_STEPS` ou desligue os raios com `SUN_RAYS=0.0`.
5. Se o custo aparecer ao mergulhar, reduza `UNDERWATER_RAY_STEPS` ou use `UNDERWATER_RAYS=0.0`.
6. Compare `FXAA=1` com os modos 2 e 3 na resolução em que você joga.

Reduzir apenas a intensidade do bloom não reduz progressivamente o número de amostras: o caminho de amostragem é o mesmo enquanto `BLOOM_STRENGTH` for maior que zero. O valor zero evita a chamada de bloom em `composite2`, mas o passe anterior ainda calcula a imagem de brilho.

## Medir na própria máquina

Use a mesma cena, posição, resolução, clima e distância de renderização para comparar perfis. Espere o carregamento dos chunks e a recompilação dos shaders terminarem. Observe uma área externa, um mergulho e o End separadamente, pois eles ativam efeitos distintos.

Não há números de FPS ou um teste de hardware M1 incluídos no repositório. A identificação “Equilibrado (M1)” é o nome localizado do perfil.
