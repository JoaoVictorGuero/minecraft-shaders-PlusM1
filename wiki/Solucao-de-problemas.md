# Solução de problemas

[Início](Home.md) · [Instalação](Instalacao.md) · [Configurações](Configuracoes.md)

## O pacote não aparece ou não carrega

Confira a [estrutura de instalação](Instalacao.md): o pacote deve conter `shaders/` diretamente em sua raiz. Use a pasta aberta pelo Iris na instância que você está executando e atualize a lista.

Se houver erro de compilação, anote a mensagem, o nome do programa e a linha indicada. Registre também as versões de Minecraft e Iris, sistema operacional, GPU e perfil escolhido. O pacote declara GLSL `330 compatibility`, mas esse dado sozinho não comprova suporte em uma combinação específica. Não há versões testadas documentadas no repositório.

## Efeitos ausentes ou diferentes do esperado

| Sintoma | O que conferir |
| --- | --- |
| Não vejo auroras no Overworld | Elas são exclusivas do End; confira `AURORA=1`, intensidade maior que zero e olhe para o norte, acima do horizonte |
| A água não tem ondas | A superfície é estática por implementação; `WIND_STRENGTH` afeta a vegetação |
| A água não reflete construções | O reflexo amostra o céu e as auroras; não há reflexão da geometria da cena |
| Não vejo raios solares | Confira Overworld, horário diurno, acesso ao céu e `SUN_RAYS>0.0`; a chuva reduz a intensidade |
| Não vejo raios ao mergulhar | Confira `UNDERWATER_RAYS>0.0`, água no Overworld, dia e acesso ao céu |
| Não vejo cáusticas | Elas aparecem com a câmera submersa, no terreno abaixo dela, com luz do céu, durante o dia e com `WATER_CAUSTICS>0.0` |
| Alterar `CLOUD_STEPS` não muda as nuvens | Essa opção só afeta `CLOUD_STYLE=1`; Enhanced Vanilla usa outro algoritmo |
| Desliguei as nuvens e as nuvens vanilla não voltaram | O programa de nuvens vanilla descarta a malha; o estilo 0 deixa o céu sem nuvens do pacote |
| Um item mapeado não ilumina | Além do ID, confira o nível de luz recebido e `DYNAMIC_LIGHT`; veja [materiais](Materiais.md) |
| Um bloco emissivo não colore os vizinhos | O realce de emissão e o bloom são separados da luz do lightmap; não há propagação de cor por bloco nessa implementação |
| Uma entidade roxa brilha inesperadamente | O programa usa uma heurística de cor, sem limitar o efeito a uma espécie |

## Ajustes de aparência

| Objetivo | Opções relacionadas |
| --- | --- |
| Diminuir claridade geral | Reduzir `EXPOSURE` |
| Reduzir halo de brilho | Reduzir `BLOOM_STRENGTH`; `EMISSIVE_BOOST` controla vários materiais emissores |
| Suavizar cores muito fortes | Reduzir `SATURATION` e/ou `VIBRANCE` |
| Deixar o End menos rosa | Reduzir `END_PINK_LIGHT`; zero mantém a paleta rosa suave |
| Melhorar visibilidade submersa | Reduzir `UNDERWATER_DENSITY`; `WATER_DENSITY` controla a aparência da superfície pela espessura |
| Reduzir movimento da visão ao mergulhar | Reduzir `UNDERWATER_DISTORTION`, até zero |
| Clarear cavernas | Aumentar `MIN_CAVE_LIGHT`, observando o efeito na cena inteira |
| Reduzir a chuva/neve na imagem | Reduzir `RAIN_OPACITY` |
| Ajustar serrilhado | Comparar os níveis de `FXAA`, observando suavização e nitidez |

Use apenas os [valores aceitos](Configuracoes.md). Altere uma opção por vez e compare a mesma cena. Para lentidão, siga o guia de [perfis e desempenho](Desempenho.md).

## Voltar ao padrão

Use a função de restauração das configurações do pacote oferecida pelo Iris. Selecionar Equilibrado modifica somente os oito parâmetros especificados no perfil; isso não equivale a restaurar todas as opções. Os padrões completos estão na [referência de configurações](Configuracoes.md).
