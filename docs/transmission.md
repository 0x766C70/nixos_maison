# Documentation de `services/transmission.nix`

*Analyse détaillée en français — confinement systemd et namespaces Linux*

---

## Vue d'ensemble

Ce fichier configure le service **Transmission** (client BitTorrent) en deux grandes parties :

1. **La configuration applicative** : les réglages propres à Transmission (dossiers de téléchargement, interface web, etc.).
2. **Le durcissement systemd** : l'isolation du processus dans un espace de noms (*namespace*) privé via le mécanisme de **confinement** de NixOS.

Le concept central à comprendre ici est le *confinement* : le processus Transmission tourne dans une **vue privée et restreinte du système de fichiers**. Si le démon est compromis (par exemple via un torrent malveillant), il ne peut pas lire ni écrire en dehors de ce qui lui est explicitement autorisé.

---

## Les namespaces Linux — une analogie rapide

> *Imagine que le serveur est un grand immeuble. Un namespace, c'est comme mettre un locataire dans un appartement dont les fenêtres donnent sur une cour virtuelle, pas sur la vraie rue. Le locataire pense voir le monde entier, mais il ne voit qu'un décor soigneusement construit pour lui.*

Un **namespace Linux** est une fonctionnalité du noyau qui crée une vue isolée d'une ressource système. Il en existe plusieurs types :

| Type de namespace | Ce qu'il isole |
|---|---|
| `mnt` | L'arborescence du système de fichiers (`/`) |
| `pid` | La liste des processus visibles |
| `net` | Les interfaces réseau, ports, pare-feux |
| `uts` | Le nom de la machine (`hostname`) |
| `ipc` | Les files de messages inter-processus |
| `user` | Les UID/GID (identifiants utilisateur) |

systemd utilise ces namespaces pour confiner les services. Le module NixOS `confinement` s'appuie essentiellement sur le namespace **`mnt`** (système de fichiers) et **`net`** (réseau).

---

## Analyse ligne par ligne

### Bloc 1 — En-tête du module Nix

```nix
{ config
, lib
, pkgs
, ...
}:
```

C'est la signature standard d'un module NixOS. Les arguments sont passés automatiquement par le système de modules :

- `config` : l'état complet de la configuration NixOS (on peut lire `config.services.transmission.home`, etc.)
- `lib` : la bibliothèque standard de Nix (`lib.mkForce`, `lib.mkDefault`…)
- `pkgs` : l'ensemble des paquets Nixpkgs
- `...` : accepte d'autres arguments sans les nommer (requis pour la compatibilité avec le système de modules)

---

### Bloc 2 — Les variables locales (`let … in`)

```nix
let
  transmissionWritePaths = [
    "/var/lib/transmission"
    "/mnt/downloads"
  ];
```

`let … in` est le mécanisme Nix pour définir des variables locales, un peu comme un `const` en JavaScript ou une affectation en Python.

`transmissionWritePaths` est une liste de chemins que Transmission doit pouvoir **écrire**. Cette liste est utilisée **à deux endroits différents** dans le fichier (c'est pour ça qu'on l'extrait en variable, pour éviter la duplication — principe DRY) :

- Dans `BindPaths` : pour *monter* ces chemins dans le namespace privé
- Dans `ReadWritePaths` : pour *autoriser* les écritures malgré le système de fichiers en lecture seule

---

```nix
  settingsFormat = pkgs.formats.json { };
```

`pkgs.formats.json {}` retourne un **objet générateur de fichiers JSON**. C'est une abstraction NixOS qui permet de transformer un attrset Nix en fichier JSON dans le store Nix.

> *Exemple : si tu appelles `settingsFormat.generate "mon-fichier.json" { foo = "bar"; }`, tu obtiens un chemin dans `/nix/store/…-mon-fichier.json` dont le contenu est `{"foo":"bar"}`.*

---

```nix
  settingsFile = settingsFormat.generate "settings.json" config.services.transmission.settings;
```

Génère le fichier `settings.json` **à partir des options déclarées dans `config.services.transmission.settings`** (défini plus bas dans ce fichier). Le résultat est un chemin dans le store Nix, par exemple :

```
/nix/store/abc123…-settings.json
```

Ce chemin est immuable et connu au moment de la construction — c'est du Nix pur. On l'utilise ensuite dans le script de démarrage (`ExecStartPre`).

> ⚠️ **Pourquoi re-déclarer ce que le module upstream fait déjà ?**
> Le module NixOS de Transmission génère lui-même ce fichier en interne, mais ne l'expose pas. Ici on le recrée à l'identique pour pouvoir l'utiliser dans notre script de démarrage personnalisé.

---

```nix
  settingsDir = ".config/transmission-daemon";
```

Le chemin relatif (par rapport à `home`, soit `/var/lib/transmission`) où Transmission stocke sa configuration. Le fichier `settings.json` sera placé à :

```
/var/lib/transmission/.config/transmission-daemon/settings.json
```

---

### Bloc 3 — Configuration du service Transmission

```nix
services.transmission = {
  enable = true;
```

Active le service Transmission via le module NixOS standard. Sans cette ligne, tout le reste est ignoré.

---

```nix
  package = pkgs.transmission_4;
```

Utilise Transmission version 4 (au lieu de la version 3 par défaut). Transmission 4 est une réécriture en C++ avec de meilleures performances.

---

```nix
  webHome = pkgs.flood-for-transmission;
```

Remplace l'interface web par défaut de Transmission par **Flood**, une interface moderne en React. Le chemin vers les fichiers statiques de Flood est passé à Transmission via son option `--web-root`.

---

```nix
  credentialsFile = lib.mkDefault (pkgs.writeText "empty-credentials.json" "{}");
```

**Ligne importante — contournement du confinement.**

Le module upstream de Transmission définit par défaut `credentialsFile = /dev/null`. Ce fichier est utilisé dans le script de démarrage pour passer un JSON vide à `jq` (l'outil de traitement JSON).

**Le problème :** à l'intérieur du namespace privé créé par le confinement, `/dev/null` n'existe **pas** (ou plutôt, le `/dev` privé est un `tmpfs` vide — voir l'explication du mode `full-apivfs` plus bas).

**La solution :** on crée un fichier JSON vide (`{}`) dans le **store Nix** et on l'utilise à la place. Un fichier dans le store est accessible en lecture seule de partout, y compris dans un namespace confiné.

`lib.mkDefault` signifie : *"utilise cette valeur par défaut, mais laisse l'utilisateur la surcharger"*. Si quelqu'un configure un vrai fichier de credentials (avec mot de passe RPC chiffré), cette valeur sera ignorée au profit de la sienne.

> *Exemple avec `lib.mkDefault` vs `lib.mkForce` :*
> ```nix
> # lib.mkDefault → peut être écrasé par l'utilisateur ou un autre module
> credentialsFile = lib.mkDefault "/nix/store/…-empty.json";
>
> # lib.mkForce → écrase tout, personne ne peut le changer
> RootDirectory = lib.mkForce "/run/confinement/transmission";
> ```

---

```nix
  settings = {
    incomplete-dir = "/mnt/downloads/.incomplete/";
    download-dir = "/mnt/downloads/";
    rpc-bind-address = "0.0.0.0";
    rpc-host-whitelist = "dl.vlp.fdn.fr";
    rpc-whitelist = "127.0.0.1";
  };
};
```

Les réglages JSON de Transmission, déclarés en Nix et convertis automatiquement en `settings.json` par le module.

- `incomplete-dir` : dossier temporaire pendant le téléchargement
- `download-dir` : dossier final une fois le torrent terminé
- `rpc-bind-address = "0.0.0.0"` : l'interface RPC (API + web) écoute sur **toutes** les interfaces réseau (nécessaire car le reverse proxy Caddy s'y connecte)
- `rpc-host-whitelist` : seule les requêtes avec l'en-tête `Host: dl.vlp.fdn.fr` sont acceptées (protection contre les DNS rebinding attacks)
- `rpc-whitelist = "127.0.0.1"` : seul localhost peut se connecter directement à l'API (Caddy fait office de reverse proxy)

---

### Bloc 4 — Le confinement systemd 🔒

C'est ici que ça devient intéressant. Ce bloc configure l'**isolation** du processus.

```nix
systemd.services.transmission = {
  confinement = {
    enable = true;
    mode = "full-apivfs";
  };
```

#### `confinement.enable = true`

Le module NixOS `confinement` (défini dans `nixpkgs/nixos/modules/system/boot/systemd/confinement.nix`) configure systemd pour que le service tourne dans un **namespace de montage privé** avec un **répertoire racine privé** (`/run/confinement/transmission`).

Concrètement, quand le service démarre :
1. systemd crée un nouveau namespace de montage (isolé du reste du système)
2. Un répertoire temporaire est créé dans `/run/confinement/transmission`
3. Seules les dépendances nécessaires (bibliothèques, binaires) sont liées (*bind-mounted*) dans ce répertoire
4. Le processus est confiné dans ce répertoire via `RootDirectory`

> *C'est comme construire une cage dorée sur mesure : on n'y met que les outils dont le prisonnier a besoin, rien de plus.*

---

#### `mode = "full-apivfs"`

Il existe deux modes de confinement :

| Mode | Ce qu'il monte | Pour quel usage |
|---|---|---|
| `chroot-only` | Juste le chroot (`/`) | Services simples sans réseau ni `/proc` |
| `full-apivfs` | chroot + `/proc` + `/sys` + `/dev` virtuels | **Démons réseau**, services qui lisent `/proc` |

Transmission est un démon réseau. Il a besoin de :
- `/proc` : pour lire ses propres informations de processus
- `/dev` : pour accéder aux sockets réseau internes
- `/sys` : pour certaines opérations bas niveau

Sans `full-apivfs`, Transmission ne pourrait pas démarrer car ces pseudo-systèmes de fichiers seraient absents.

> **Détail technique :** `full-apivfs` monte des versions *virtuelles* de `/proc`, `/sys` et `/dev` (des `tmpfs` ou `procfs`/`sysfs` privés), pas le vrai `/proc` du système hôte. Cela garantit l'isolation tout en permettant le fonctionnement normal du démon.

---

### Bloc 5 — La configuration du service systemd

```nix
serviceConfig = {
  ProtectSystem = "strict";
```

`ProtectSystem = "strict"` monte **tout** le système de fichiers en **lecture seule** du point de vue du service. Cela inclut `/`, `/usr`, `/boot`, etc.

Combiné avec le confinement, c'est une double protection :
- Le confinement limite *quels fichiers sont visibles*
- `ProtectSystem` limite *quels fichiers sont modifiables*

Pour autoriser les écritures dans des dossiers spécifiques, on utilise `ReadWritePaths` (voir plus bas).

---

```nix
  PrivateTmp = true;
```

Crée un `/tmp` privé pour ce service, isolé du `/tmp` global du système. Deux avantages :

1. Les autres services ne peuvent pas lire les fichiers temporaires de Transmission
2. Les fichiers temporaires sont nettoyés automatiquement à l'arrêt du service

---

```nix
  BindPaths = transmissionWritePaths;
```

**Ligne clé pour comprendre le confinement.**

`BindPaths` effectue des **bind mounts** : il *monte* les chemins listés **à l'intérieur** du namespace privé du service. Sans cette directive, ces chemins n'existeraient tout simplement pas dans le namespace confiné.

> *Analogie : imagine que tu déménages dans un appartement (le namespace). La ville (le système de fichiers réel) est à l'extérieur. `BindPaths` est comme percer une fenêtre dans le mur de l'appartement qui donne directement sur ton garage dans la vraie ville. Tu peux y accéder, mais uniquement par cette fenêtre.*

Concrètement, systemd exécute quelque chose d'équivalent à :

```bash
mount --bind /var/lib/transmission /run/confinement/transmission/var/lib/transmission
mount --bind /mnt/downloads /run/confinement/transmission/mnt/downloads
```

Sans ces bind mounts, Transmission ne pourrait ni lire sa configuration dans `/var/lib/transmission` ni écrire les torrents dans `/mnt/downloads`.

---

```nix
  ReadWritePaths = transmissionWritePaths;
```

`ProtectSystem = "strict"` rend tout en lecture seule, **y compris** les chemins montés via `BindPaths`. `ReadWritePaths` crée des exceptions explicites en autorisant l'écriture sur ces chemins précis.

> *`BindPaths` dit "ce chemin existe dans le namespace". `ReadWritePaths` dit "ce chemin peut être modifié".*

Les deux sont nécessaires conjointement.

---

```nix
  RootDirectory = lib.mkForce "/run/confinement/transmission";
```

`RootDirectory` est l'équivalent systemd d'un `chroot`. Le processus "pense" que `/run/confinement/transmission` est sa racine (`/`). Il ne peut pas remonter au-dessus.

**Pourquoi `lib.mkForce` ?**

Il y a un **conflit de priorité** entre deux modules NixOS :
- Le module upstream `services.transmission` définit `RootDirectory = "/run/transmission"`
- Le module `confinement` définit `RootDirectory = "/run/confinement/transmission"`

Ces deux valeurs sont définies à la même priorité dans le système de modules NixOS, ce qui cause une erreur. `lib.mkForce` force notre valeur à un niveau de priorité supérieur (1000 vs 100 par défaut), ce qui tranche le conflit en faveur du chemin de confinement.

> *C'est comme un vote avec deux voix égales — `lib.mkForce` donne à notre déclaration deux voix de plus.*

---

```nix
  RootDirectoryStartOnly = lib.mkForce false;
```

Normalement, `RootDirectoryStartOnly = true` (valeur définie par le module upstream) signifie : *"seule la commande `ExecStart` s'exécute dans le chroot ; les phases `ExecStartPre` et `ExecStartPost` tournent dans l'environnement normal"*.

Le module `confinement` est **incompatible** avec `RootDirectoryStartOnly = true` car il a besoin de monter ses bind mounts *avant* toute exécution, et ces montages ne peuvent pas être restreints à une seule phase.

En forçant `RootDirectoryStartOnly = false`, **toutes les phases** (`ExecStartPre`, `ExecStart`, etc.) s'exécutent dans le namespace confiné.

**Mais alors, comment `ExecStartPre` peut-il avoir les droits root ?** → Voir le préfixe `"+"` expliqué ci-dessous.

---

```nix
  ExecStartPre = lib.mkForce [
    (
      "+"
      + pkgs.writeShellScript "transmission-prestart" ''
```

`lib.mkForce` remplace complètement le `ExecStartPre` défini par le module upstream. Le tableau `[…]` liste une seule commande pré-démarrage.

**Le préfixe `"+"`** est une fonctionnalité de systemd : il indique que cette commande s'exécute avec les **pleins privilèges root**, en dehors de toutes les restrictions du service (ProtectSystem, PrivateTmp, namespaces, etc.).

> *C'est l'exception à la règle : même si tout le service est dans une cage, cette commande spécifique peut sortir de la cage pour faire des préparatifs.*

Pourquoi en a-t-on besoin ici ? Le script doit :
1. Écrire dans `/var/lib/transmission/.config/…` en tant que root (le dossier appartient à root au démarrage)
2. Changer ensuite le propriétaire vers `transmission:transmission`

Ces opérations nécessitent les droits root.

**Pourquoi remplacer le script upstream ?**

Le script original du module Transmission utilise cette construction :

```bash
jq … | install -m 600 /dev/stdin /chemin/settings.json
```

La commande `install … /dev/stdin` a besoin que `/dev/stdin` existe comme un **chemin stat-able** dans le système de fichiers. Or dans le namespace privé avec `full-apivfs`, le `/dev` est un `tmpfs` vide au moment où `ExecStartPre` tourne — `/dev/stdin` n'y existe pas encore.

Notre remplacement évite complètement `/dev/stdin` :

---

```nix
        set -eu
```

Options shell de sécurité :
- `-e` : arrêt immédiat si une commande échoue (équivalent d'un try/catch global)
- `-u` : erreur si une variable non définie est utilisée

---

```nix
        ${pkgs.jq}/bin/jq --slurp add \
          '${settingsFile}' \
          '${config.services.transmission.credentialsFile}' \
          > '${config.services.transmission.home}/${settingsDir}/settings.json'
```

`jq --slurp add` lit **deux** fichiers JSON et les **fusionne** :
- `settingsFile` : la configuration générée par Nix (déclarée dans `services.transmission.settings`)
- `credentialsFile` : un fichier JSON de credentials (par défaut `{}` vide, peut contenir `{"rpc-password": "…"}`)

Le résultat est redirigé directement vers `settings.json` via `>` (redirection shell), sans passer par `/dev/stdin`.

> *Exemple de fusion par `jq --slurp add` :*
> ```bash
> # Fichier 1 : settings.json généré par Nix
> {"download-dir":"/mnt/downloads","rpc-whitelist":"127.0.0.1"}
>
> # Fichier 2 : credentials.json
> {"rpc-password":"{hash}monmotdepasse"}
>
> # Résultat fusionné :
> {"download-dir":"/mnt/downloads","rpc-whitelist":"127.0.0.1","rpc-password":"{hash}monmotdepasse"}
> ```
> Les clés du second fichier s'ajoutent (ou écrasent) celles du premier.

Les interpolations `${…}` sont évaluées **au moment de la construction Nix** (pas au runtime). Ce sont des chemins absolus dans le store Nix ou dans `/var/lib/transmission`.

---

```nix
        ${pkgs.coreutils}/bin/chmod 600 \
          '${config.services.transmission.home}/${settingsDir}/settings.json'
```

Restreint les permissions du fichier `settings.json` à **lecture/écriture pour le propriétaire uniquement** (mode octal `600`). C'est important car ce fichier peut contenir le mot de passe RPC de Transmission.

On utilise le chemin absolu vers `chmod` dans le store Nix (`${pkgs.coreutils}/bin/chmod`) plutôt que le simple `chmod` pour garantir qu'on utilise exactement la version du paquet déclaré dans le flake — pas celle du `PATH` du système.

---

```nix
        ${pkgs.coreutils}/bin/chown \
          '${config.services.transmission.user}:${config.services.transmission.group}' \
          '${config.services.transmission.home}/${settingsDir}/settings.json'
```

Transfère la propriété du fichier vers l'utilisateur et le groupe Transmission (par défaut `transmission:transmission`). Sans ça, Transmission (qui ne tourne pas en root) ne pourrait pas lire son propre fichier de configuration.

Les valeurs `config.services.transmission.user` et `.group` sont lues depuis la configuration NixOS — si quelqu'un change le nom d'utilisateur du service, ce script s'adapte automatiquement.

---

## Résumé du flux de démarrage

```
nixos-rebuild switch
       │
       ▼
Nix construit settingsFile dans /nix/store/…-settings.json
       │
       ▼
systemd démarre transmission.service
       │
       ├─► ExecStartPre (avec "+", hors confinement, en root)
       │         │
       │         ├── jq fusionne settings + credentials → settings.json
       │         ├── chmod 600 settings.json
       │         └── chown transmission:transmission settings.json
       │
       └─► ExecStart (dans le namespace confiné)
                 │
                 ├── Système de fichiers racine : /run/confinement/transmission/
                 ├── /var/lib/transmission → bind-mounted depuis le vrai FS
                 ├── /mnt/downloads       → bind-mounted depuis le vrai FS
                 ├── /proc, /sys, /dev    → montages virtuels (full-apivfs)
                 └── Tout le reste        → invisible / inaccessible
```

---

## Les couches de sécurité en résumé

| Mécanisme | Ce qu'il protège | Directive systemd |
|---|---|---|
| Confinement (namespace mnt) | Le processus ne voit qu'un sous-ensemble du FS | `confinement.enable` |
| RootDirectory | Chroot vers un répertoire minimal | `RootDirectory` |
| ProtectSystem strict | Tout le FS visible en lecture seule | `ProtectSystem` |
| PrivateTmp | `/tmp` isolé des autres services | `PrivateTmp` |
| ReadWritePaths | Exceptions d'écriture explicites | `ReadWritePaths` |
| BindPaths | Accès aux données réelles dans le namespace | `BindPaths` |
| ExecStartPre avec `+` | Préparation privilegiée hors confinement | `ExecStartPre = "+" + …` |

---

*Documentation générée par botbot — NixOS 25.11*
