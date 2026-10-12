# Wiki — VanillaPlus M1

[Projeto](../README.md) · [Instalação](Instalacao.md) · [Configurações](Configuracoes.md) · [Desempenho](Desempenho.md)

Esta wiki documenta o pacote presente em `VanillaPlus_M1/shaders/`, identificado no código como **VanillaPlus M1**. Ele usa programas GLSL com `#version 330 compatibility` e configurações voltadas ao Iris.

## Por onde começar

1. Siga a [instalação](Instalacao.md) para carregar o pacote.
2. Conheça os [efeitos e as diferenças entre dimensões](Efeitos.md).
3. Compare os [três perfis](Desempenho.md) e ajuste as [configurações](Configuracoes.md).
4. Consulte a [solução de problemas](Solucao-de-problemas.md) se algo não aparecer como esperado.

Para modificar o código, veja a [arquitetura](Arquitetura.md) e o [mapeamento de materiais](Materiais.md).

## Recursos principais

| Área | Implementação presente |
| --- | --- |
| Iluminação | Ciclo de dia e noite, luz ambiente, brilho de materiais e luz colorida dos itens nas duas mãos |
| Sombras | Mapa de sombras com três níveis de filtragem e vento sincronizado com a vegetação |
| Água | Reflexo do céu, absorção pela espessura, neblina, distorção da visão, cáusticas e raios subaquáticos |
| Atmosfera | Neblina, raios solares, estrelas e controle de visibilidade da chuva e neve |
| Nuvens | Estilo volumétrico realista ou blocado Enhanced Vanilla |
| End | Céu procedural, estrelas, nebulosa, auroras e luz ambiente rosa ajustável |
| Imagem | Bloom, exposição, saturação, vivacidade, vinheta e antisserrilhado FXAA |

A superfície da água não recebe animação geométrica. As auroras aparecem somente no End. Os reflexos da água representam o céu e as auroras; não há reflexão da geometria da cena nessa implementação.

## Origem das informações

As opções e os perfis vêm de [settings.glsl](../VanillaPlus_M1/shaders/lib/settings.glsl) e [shaders.properties](../VanillaPlus_M1/shaders/shaders.properties). O comportamento foi conferido nos programas em [program/](../VanillaPlus_M1/shaders/program/) e nas bibliotecas em [lib/](../VanillaPlus_M1/shaders/lib/). Quando comentários ou traduções descrevem algo diferente da implementação, esta wiki segue o código executável.

Referência: revisão local `9615888`. A wiki não substitui uma validação dentro do jogo: compatibilidade por versão, aparência final e FPS não foram medidos durante sua criação.
