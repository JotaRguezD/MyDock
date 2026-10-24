<p align="center"><img src="icon/AppIcon.png" width="160" alt="Ícone do MyDock"></p>

<p align="center"><a href="README.md">English</a> · <a href="README.es.md">Español</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt.md">Português</a></p>

# MyDock

Um Dock para macOS com widgets, separadores e grupos de apps. Funciona ao lado do Dock da Apple ou no lugar dele, sem modificar o sistema.

## Download e instalação

1. Baixe **`MyDock-x.y.z.dmg`** da [versão mais recente](https://github.com/JotaRguezD/MyDock/releases/latest).
2. Abra o `.dmg` e arraste o **MyDock** para a pasta **Aplicativos**.
3. Abra o MyDock pela pasta Aplicativos.

### Na primeira vez que você abrir

O MyDock não é assinado por um desenvolvedor verificado pela Apple, então o macOS não o abrirá diretamente na primeira vez:

- **macOS 15 Sequoia ou posterior**: aparecerá um aviso; clique em **OK**. Vá em **Ajustes do Sistema › Privacidade e Segurança**, role até o final e clique em **Abrir Mesmo Assim** ao lado do MyDock. Confirme com sua senha.
- **macOS 14 Sonoma**: clique com o botão direito no MyDock em Aplicativos, escolha **Abrir** e confirme.

Só é preciso fazer isso uma vez. As atualizações são instaladas da mesma forma: baixe o novo `.dmg` e arraste o MyDock para Aplicativos para substituir o anterior. Seus ajustes e permissões são mantidos.

### Requisitos

- macOS 14 Sonoma ou posterior.
- Qualquer Mac: com processador Intel ou chip Apple (M1, M2, M3…).

## O que ele faz

### Apps, pastas e grupos

- **Fixe apps e pastas** arrastando-os do Finder. Para reorganizá-los, arraste os ícones dentro do Dock.
- **Apps abertos**: os que não estão fixados aparecem sozinhos depois dos fixados, como no Dock da Apple. Um ponto sob o ícone indica que o app está aberto.
- **Grupos**: vários apps em um só ícone; ao clicar, abre uma pequena janela com todos. Solte um app sobre um grupo para adicioná-lo.
- **Separadores e espaços**: quantos você quiser, onde quiser.
- **Lixo**, no final do Dock como no da Apple: clique para abri-lo, solte arquivos sobre ele para movê-los para o Lixo ou um ícone do Dock para removê-lo, e clique com o botão direito › **Esvaziar o Lixo…** (sempre pede confirmação). Pode ser ocultado nos ajustes.
- **Apps e widgets ficam em áreas separadas**: primeiro os apps, depois os widgets, com um separador entre eles.
- **Animações**: ao abrir um app, o ícone pula até que ele termine de abrir; os widgets dão um pequeno pulso ao serem clicados.

### Clique com o botão direito em um app

| App | Opções |
|---|---|
| Fixado | Mostrar no Finder · Mover para grupo · Remover do Dock · **Encerrar** |
| Dentro de um grupo | Tirar para o Dock · Remover do grupo · **Encerrar** |
| Aberto, não fixado | Manter no Dock · **Encerrar** |

**Encerrar** é sempre a última opção e aparece em cinza se o app não estiver aberto.

### 16 widgets

| Básicos | Produtividade | Sistema | Utilitários |
|---|---|---|---|
| Relógio e data | Próximos eventos | Bateria | Transferências |
| Tempo | Lembretes | Volume | Capturas de tela |
| Música | Pomodoro | Área de transferência | Buscar |
| CPU e memória | Nota rápida | Disco e rede | Conta-gotas |

- **Relógio e data**: ao clicar, abre o Calendário.
- **Tempo**: o da sua localização ou das suas cidades salvas; clique com o botão direito › **Cidade** para trocar rapidamente. Ao clicar, abre o app Tempo.
- **Música**: a música tocando no Spotify ou no Música, com botões de anterior, reproduzir/pausar e próxima. Ao clicar, abre o player.
- **CPU e memória**, **Disco e rede**: uso em tempo real; ao clicar, abrem o Monitor de Atividade.
- **Próximos eventos**: seu próximo evento do Calendário e quanto falta.
- **Lembretes**: suas tarefas pendentes; você pode marcá-las como concluídas no próprio Dock.
- **Pomodoro**: temporizador de foco e pausa, com aviso sonoro.
- **Nota rápida**: um texto curto que você escreve e fica salvo no Dock.
- **Bateria**: porcentagem e se está carregando.
- **Volume**: silenciar e controle de volume.
- **Área de transferência**: o que você copiou recentemente, para copiar de novo com um clique.
- **Transferências** e **Capturas de tela**: seus arquivos mais recentes, para abri-los ou arrastá-los para outro app.
- **Buscar**: encontre apps e arquivos sem abrir o Spotlight.
- **Conta-gotas**: capture uma cor de qualquer parte da tela e copie seu código.

Cada widget só pode ser adicionado uma vez.

### Personalização

- **Cada widget**: versão **compacta** (do tamanho de um ícone) ou **ampla**, **cor de fundo** e suas próprias opções: formato de 12 ou 24 horas, segundos, cidades do tempo, °C ou °F, minutos do Pomodoro, quantos itens mostrar…
- **Posição**: embaixo, à esquerda ou à direita.
- **Tamanho dos ícones**: pequeno, médio ou grande.
- **Ocultar automaticamente**: o Dock se oculta e volta quando você leva o ponteiro até a borda da tela.
- **Dock em uso**: só MyDock, MyDock e o da Apple, ou voltar ao da Apple.
- **Ajustar janelas ao Dock** (opcional): as janelas maximizadas param onde o MyDock começa, como com o Dock da Apple. Se o Dock se oculta automaticamente, as janelas ocupam a tela inteira. Com um app em tela cheia, o MyDock se oculta e aparece quando você leva o ponteiro até a borda.
- **Abrir ao iniciar sessão**.
- **Modo claro ou escuro**: segue o do seu Mac.
- **17 idiomas**: inglês, espanhol, catalão, galego, basco, francês, alemão, italiano, português, norueguês, dinamarquês, finlandês, japonês, chinês simplificado, coreano, hindi e árabe. Usa o idioma do Mac ou o que você escolher nos ajustes.

## Como usar

- **Clique com o botão direito no fundo do Dock**: adicionar separadores, espaços, grupos e widgets, além das opções principais (posição, tamanho, ocultar, Dock em uso…).
- **Clique com o botão direito em um widget**: seus ajustes, versão compacta ou ampla, e removê-lo.
- **Ajustes…** (no menu do botão direito do fundo): uma janela com todas as opções. À esquerda, **Geral** e uma seção para cada widget; o botão **+** adiciona widgets.

> O Dock da Apple não deixa arrastar seus ícones para outro app: ao arrastar um para fora, ele é removido. Adicione os apps ao MyDock pelo Finder.

## Permissões

O MyDock só pede uma permissão quando algo precisa dela, e o macOS se lembra:

| Para | Permissão |
|---|---|
| Tempo da sua localização | Localização (opcional: sem ela, adicione suas cidades manualmente) |
| Música e Lixo | Controlar o Spotify ou o Música, e o Finder (para saber se o Lixo tem itens e esvaziá-lo) |
| Próximos eventos | Calendários |
| Lembretes | Lembretes |
| Transferências | Pasta Transferências |
| Capturas de tela | Pasta Mesa (ou onde você salva as capturas) |
| Ajustar janelas ao Dock | Acessibilidade |

Se você recusar, o widget mostrará "Sem permissão"; um clique leva ao ajuste para concedê-la.

## Privacidade

- Sem contas e sem análises. Seus ajustes ficam salvos só no seu Mac.
- O widget Tempo envia ao [Open-Meteo](https://open-meteo.com) apenas coordenadas arredondadas (precisão de cerca de 1 km) para obter a temperatura. Os nomes das cidades são buscados com o serviço de mapas da Apple.
- O histórico da área de transferência fica só na memória: nunca é gravado no disco, é apagado quando o MyDock é encerrado e ignora o que os gerenciadores de senhas copiam.

## Segurança

- **Hardened Runtime do macOS**: nenhum outro programa pode injetar código no MyDock para aproveitar suas permissões. Além disso, o MyDock só pode pedir as permissões da tabela acima.
- **Assinatura**: todas as versões são assinadas com o mesmo certificado, então o macOS reconhece as atualizações como o mesmo app e mantém suas permissões.
- **Verifique se o `.dmg` é autêntico**: na página de cada versão, o GitHub mostra a impressão digital SHA-256 do `.dmg` ao lado do nome, em *Assets*. No app Terminal, digite:

  ```bash
  shasum -a 256 ~/Downloads/MyDock-x.y.z.dmg
  ```

  O resultado deve coincidir exatamente com essa impressão digital. Se não coincidir, não o abra.
- Baixe o MyDock somente da [página oficial de versões](https://github.com/JotaRguezD/MyDock/releases).

## Perguntas frequentes

**Posso deixar de ver o Dock da Apple?**
Sim: clique com o botão direito › **Dock em uso › Só MyDock**. Ao encerrar o MyDock, o Dock da Apple volta exatamente como você o tinha, mesmo que o MyDock trave ou seja forçado a encerrar.

**Ao maximizar uma janela, ela fica embaixo do MyDock.**
Ative **Ajustar janelas ao Dock** em Ajustes › Geral e conceda a permissão de Acessibilidade.

**Por que a música que estou ouvindo não aparece?**
O widget Música funciona com o Spotify e com o app Música da Apple. Outros players não são detectados.

## Desinstalar

1. Desative **Abrir ao iniciar sessão** e escolha **Encerrar MyDock**. Se você usava "Só MyDock", o Dock da Apple volta como você o tinha.
2. Apague o MyDock da pasta Aplicativos.
3. Para apagar também seus ajustes, apague a pasta `~/Library/Application Support/MyDock`.

## Licença

[MIT](LICENSE) © 2026 [JotaRguezD](https://github.com/JotaRguezD)
