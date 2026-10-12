# Instalação

[Início](Home.md) · [Perfis](Desempenho.md) · [Problemas](Solucao-de-problemas.md)

## Preparar o Iris

O pacote contém referências explícitas ao Iris e roteamento de dimensões por `dimension.properties`. Use Minecraft Java com Iris para validar esta versão do shader; o repositório não declara versões mínimas nem compatibilidade testada com outros carregadores.

O [instalador oficial do Iris](https://www.irisshaders.dev/download/) instala Iris e Sodium e permite escolher a versão do Minecraft. Para instalação manual, consulte as dependências da versão escolhida na mesma página.

## Adicionar o pacote

1. Inicie a instância do Minecraft com Iris.
2. Nas configurações de vídeo, abra a tela de pacotes de shaders e use **Open Shader Pack Folder** para abrir a pasta usada por essa instância.
3. Copie a subpasta `VanillaPlus_M1` deste projeto para lá, preservando `shaders/` diretamente dentro da pasta do pacote.
4. Atualize a lista, habilite os shaders, selecione o pacote e aplique.
5. Abra as configurações do pacote e escolha um dos [perfis disponíveis](Desempenho.md).

O fluxo de seleção e aplicação é descrito no [guia oficial de uso do Iris](https://github.com/IrisShaders/Iris/blob/26.1/docs/guide.md#using-iris). Os nomes dos botões podem variar com o idioma e a versão.

Estrutura esperada ao usar uma pasta:

```text
shaderpacks/
└── VanillaPlus_M1/
    └── shaders/
        ├── shaders.properties
        ├── dimension.properties
        ├── lib/
        ├── program/
        ├── nether/
        └── end/
```

Também é possível preparar um ZIP com `shaders/` na raiz. A partir da raiz deste projeto, os comandos abaixo criam o arquivo para distribuição:

```sh
cd VanillaPlus_M1
zip -r ../VanillaPlus-M1.zip shaders -x '*/.DS_Store'
```

O comando é uma instrução de empacotamento; a criação desta wiki não gerou nem instalou o ZIP.

## Conferir no jogo

No Overworld, observe sombras durante o dia, nuvens e vento na vegetação. Mergulhe em uma área aberta para conferir a neblina e os raios subaquáticos. No End, observe o céu e procure as auroras na direção norte, acima do horizonte. No Nether, confira a atmosfera nos diferentes biomas.

Essa sequência é um roteiro de validação, não um registro de testes realizados. O projeto não inclui uma matriz de compatibilidade de Minecraft, Iris, sistema operacional ou GPU.
