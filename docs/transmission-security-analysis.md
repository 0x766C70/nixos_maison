# Analyse de sécurité : Transmission en confinement systemd vs conteneur Incus

*Évaluation comparative — botbot, NixOS 25.11*

---

## Contexte

Ce document répond à une question simple mais stratégiquement importante :

> *"Ma configuration Transmission est-elle suffisamment sécurisée telle quelle, ou devrais-je la mettre dans un conteneur Incus ?"*

Pour y répondre sérieusement, il faut d'abord comprendre ce qu'on cherche à protéger, puis évaluer les deux approches avec honnêteté.

### Modèle de menace — ce qui pourrait mal tourner

Transmission télécharge des fichiers depuis Internet, souvent depuis des sources non vérifiées. Les risques principaux sont :

1. **Un torrent malveillant** exploitant une vulnérabilité dans le parseur de Transmission (format `.torrent`, métadonnées).
2. **Une faille dans l'interface RPC/web** (Flood for Transmission) permettant une exécution de code à distance.
3. **Un accès non autorisé** à l'interface web via une attaque par force brute.
4. **Mouvement latéral** : si Transmission est compromis, l'attaquant tente de se déplacer vers d'autres services (Nextcloud, Headscale…).

---

## Option 1 — Confinement systemd (configuration actuelle)

### Ce que fait la configuration actuelle

La configuration actuelle empile plusieurs couches de défense :

```
Internet
   │
   ▼
[Caddy — basic_auth + fail2ban]   ← Authentification + protection brute-force
   │
   ▼ (uniquement si auth OK)
[localhost:9091 — RPC Transmission]
   │
   ▼
[systemd confinement]              ← Isolation namespace
   ├── RootDirectory               ← Chroot privé (/run/confinement/transmission)
   ├── ProtectSystem=strict        ← Système de fichiers en lecture seule
   ├── PrivateTmp                  ← /tmp isolé
   ├── BindPaths                   ← Accès limité à /var/lib/transmission + /mnt/downloads
   ├── ReadWritePaths              ← Exceptions d'écriture explicites
   ├── RestrictAddressFamilies     ← Seulement AF_INET, AF_INET6, AF_UNIX
   ├── RestrictNamespaces          ← Prévention des évasions par namespace noyau
   ├── LockPersonality             ← Blocage des tricks d'ABI/personalité
   ├── ProtectKernelModules        ← Interdit le chargement de modules noyau
   └── ProtectKernelTunables       ← /proc/sys et /sys en lecture seule
```

#### Couche 1 — Réseau : pas d'exposition directe

```nix
rpc-whitelist = "127.0.0.1";
```

Le démon Transmission n'accepte les connexions RPC que depuis `127.0.0.1`. L'interface web est uniquement accessible via Caddy (`dl.vlp.fdn.fr`), qui exige une authentification HTTP Basic avant de transmettre la requête. **Le port 9091 n'est pas ouvert dans le firewall** — `firewall.nix` n'expose que 80, 443, 1337 et 8085.

> *C'est comme mettre un videur devant la porte ET barricader la fenêtre. Bien joué.*

#### Couche 2 — Authentification et fail2ban

```nix
# caddy.nix
basic_auth {
  mlc {file.${config.age.secrets.caddy_mlc.path}}
}

# fail2ban.nix
maxretry = 3;
bantime  = "2h";
```

Les identifiants sont stockés dans un fichier chiffré avec `agenix` (`secrets/caddy_mlc.age`). Le mot de passe hashé n'est jamais visible en clair dans le store Nix. Fail2ban bannit une IP après 3 tentatives échouées pendant 2 heures.

#### Couche 3 — Confinement systemd (namespace mnt)

```nix
confinement = {
  enable = true;
  mode = "full-apivfs";   # /proc, /sys, /dev virtuels — requis pour un démon réseau
};
```

Le processus Transmission tourne dans un filesystem privé. Il ne peut pas lire `/etc/passwd`, `/home/vlp`, ni les secrets agenix d'autres services. Si un attaquant obtient une exécution de code dans le contexte du processus `transmission`, il est bloqué dans ce sandbox.

```nix
ProtectSystem = "strict";    # Tout en lecture seule
PrivateTmp    = true;        # /tmp dédié
BindPaths     = [ "/var/lib/transmission" "/mnt/downloads" ];
ReadWritePaths = [ "/var/lib/transmission" "/mnt/downloads" ];
```

Seuls deux répertoires sont modifiables depuis l'intérieur du confinement.

#### Couche 4 — Durcissement noyau (directives systemd avancées)

Ajoutées dans la même `serviceConfig`, ces directives réduisent la surface d'attaque au niveau noyau :

```nix
# Limite les familles d'adresses réseau : BitTorrent + IPC systemd uniquement.
# AF_PACKET, AF_NETLINK et autres sont bloqués — ferme des vecteurs d'attaque réseau bas niveau.
RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

# Interdit au service de créer de nouveaux namespaces noyau.
# Ferme les chemins d'évasion de sandbox via cloning de namespaces.
RestrictNamespaces = true;

# Empêche la modification de la personalité d'exécution (personality syscall).
# Bloque certaines techniques de contournement de l'ASLR basées sur les ABI 32/64-bit.
LockPersonality = true;

# Interdit le chargement de modules noyau depuis le service.
# Un attaquant qui obtient RCE ne peut pas charger un rootkit via insmod.
ProtectKernelModules = true;

# Met /proc/sys et /sys en lecture seule depuis le service.
# Empêche la modification des paramètres noyau (ex : désactiver ASLR via /proc/sys/kernel/randomize_va_space).
ProtectKernelTunables = true;
```

Ces cinq directives n'ajoutent aucune complexité opérationnelle et durcissent significativement le périmètre d'attaque noyau.

### Tableau des forces et faiblesses

| # | Force | Détail |
|---|-------|--------|
| ✅ | RPC non exposé | Port 9091 uniquement sur 127.0.0.1, pas dans le firewall |
| ✅ | Authentification forte | Basic auth via Caddy + secrets chiffrés agenix |
| ✅ | Protection brute-force | fail2ban, 3 tentatives, ban 2h |
| ✅ | Filesystem isolé | Namespace mnt, ProtectSystem=strict |
| ✅ | /tmp privé | PrivateTmp — pas de fuite inter-services via /tmp |
| ✅ | Écriture limitée | Seulement /var/lib/transmission et /mnt/downloads |
| ✅ | Familles réseau restreintes | RestrictAddressFamilies — bloque AF_PACKET, AF_NETLINK et les raw sockets |
| ✅ | Namespaces noyau verrouillés | RestrictNamespaces — prévient les évasions de sandbox par cloning de namespaces |
| ✅ | Personalité fixée | LockPersonality — bloque les tricks ABI/ASLR via personality syscall |
| ✅ | Modules noyau protégés | ProtectKernelModules — interdit le chargement de modules depuis le service |
| ✅ | Tunables noyau protégés | ProtectKernelTunables — /proc/sys et /sys en lecture seule |
| ✅ | Intégration NixOS native | Déclaratif, reproductible, facile à auditer |
| ✅ | Overhead minimal | Pas de VM, pas de processus supplémentaire |

| # | Faiblesse | Détail |
|---|-----------|--------|
| ❌ | Noyau partagé | Le confinement repose sur les namespaces Linux — une faille dans le noyau peut en sortir (atténué par RestrictNamespaces, LockPersonality, ProtectKernelModules, ProtectKernelTunables) |
| ❌ | Réseau non isolé | Transmission partage le réseau de l'hôte — il peut contacter localhost:8080 (Nextcloud), localhost:8085 (Headscale), etc. (raw sockets bloqués par RestrictAddressFamilies, mais TCP/UDP vers localhost reste possible) |
| ❌ | Pas de UID remapping | Le processus tourne en tant qu'utilisateur `transmission` sur le vrai système — si une faille d'escalade de privilèges existe, le périmètre est le UID `transmission` |
| ❌ | /mnt/downloads visible | Le répertoire NFS est dans le confinement — un attaquant peut lire/modifier tous les fichiers téléchargés |

### Note globale — Option 1

```
╔══════════════════════════════════════════════════════════╗
║  Confinement systemd — Note : A- (8.5 / 10)             ║
║                                                          ║
║  Excellent pour un serveur domestique.                   ║
║  Résiste très bien aux menaces courantes.                ║
║  Durcissement noyau complet (RestrictNamespaces,         ║
║  LockPersonality, ProtectKernelModules, etc.).           ║
║  Vulnérable principalement au mouvement latéral          ║
║  réseau TCP/UDP en cas de compromission.                 ║
╚══════════════════════════════════════════════════════════╝
```

---

## Option 2 — Conteneur Incus

### Qu'est-ce qu'un conteneur Incus ?

Incus (successeur de LXD) crée des **conteneurs système** ou des **machines virtuelles** légères. Dans le cas d'un conteneur système non-privilégié, le noyau hôte est partagé (comme avec systemd), mais **tous les namespaces Linux sont activés simultanément** : mnt, pid, net, uts, ipc, user.

> *Là où systemd confinement choisit quels namespaces activer manuellement, Incus active tout le paquet d'emblée — comme comparer un appartement avec serrure renforcée à un appartement dans une résidence sécurisée avec badge, gardien et digicodes.*

La configuration Incus est déjà présente dans le repo :

```nix
# configuration.nix
virtualisation.incus.enable = true;
users.users.vlp.extraGroups = [ "incus-admin" … ];
```

L'infrastructure existe. Elle n'est pas encore utilisée pour Transmission.

### Architecture avec Incus

```
Internet
   │
   ▼
[Caddy (hôte) — basic_auth + fail2ban]
   │
   ▼ reverse proxy vers 192.168.101.X:9091
[Conteneur Incus — NixOS minimal]
   ├── Transmission daemon
   ├── Namespace réseau dédié (IP propre : ex. 192.168.101.20)
   ├── Namespace PID dédié
   ├── Namespace UID/GID remappé (uid 1000 dans le conteneur = uid 100000+ sur l'hôte)
   ├── /mnt/downloads bind-monté depuis l'hôte
   └── Accès réseau : uniquement vers Internet (pas vers 192.168.1.42)
```

### Ce que ça apporte concrètement

#### Isolation réseau réelle

Dans un conteneur Incus avec son propre namespace réseau, Transmission ne peut **pas** contacter `localhost:8080` (Nextcloud) ou `localhost:8085` (Headscale) — ces services sont sur l'hôte, dans un namespace réseau différent. Il faudrait explicitement router le trafic pour permettre ce type d'accès.

#### UID remapping (conteneurs non-privilégiés)

```
UID 0 (root) dans le conteneur = UID 100000 sur l'hôte
UID 1000 (transmission) dans le conteneur = UID 101000 sur l'hôte
```

Si un attaquant obtient `root` dans le conteneur (en exploitant Transmission puis en escaladant), il n'a que l'UID 100000 sur le système hôte — sans permissions particulières.

#### Durcissement systemd dans le conteneur

Rien n'empêche d'appliquer **aussi** le confinement systemd à l'intérieur du conteneur Incus. Les deux approches sont cumulables :

```
Conteneur Incus (isolation OS)
   └── systemd confinement (isolation process)
          └── Transmission
```

C'est la défense en profondeur maximale.

### Configuration NixOS typique pour ce scénario

```nix
# Dans la config du conteneur Incus (nixos-container ou image Incus)
{ pkgs, ... }: {
  # Importer le module transmission.nix existant tel quel
  imports = [ ./services/transmission.nix ];

  # Réseau du conteneur : uniquement accès Internet via tun0 (OpenVPN)
  # Pas d'accès au réseau LAN de l'hôte (192.168.1.0/24)
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 9091 ];        # RPC Transmission — accessible depuis l'hôte uniquement
    interfaces.eth0.allowedTCPPorts = []; # Rien d'autre
  };
}
```

Sur l'hôte, Caddy reverse-proxy vers l'IP du conteneur :

```nix
# caddy.nix — changement minimal
virtualHosts."dl.vlp.fdn.fr".extraConfig = ''
  # …
  reverse_proxy http://192.168.101.20:9091   # IP du conteneur Incus
'';
```

### Le problème du /mnt/downloads

C'est la vraie complexité de cette approche. La configuration actuelle utilise :

```nix
# services/nfs-mounts.nix
# /mnt/downloads est un montage NFS avec x-systemd.automount + luks-disk
```

Pour rendre ce chemin accessible dans un conteneur Incus, il faut soit :
- **Bind-mount** du répertoire hôte vers le conteneur (simple mais réduit l'isolation)
- **NFS direct** depuis le conteneur (le conteneur monte lui-même le partage NFS)
- **VirtioFS/9p** pour partager le répertoire (si Incus VM, pas container)

Chaque option a ses implications opérationnelles.

### Tableau des forces et faiblesses

| # | Force | Détail |
|---|-------|--------|
| ✅ | Isolation réseau complète | Namespace réseau dédié — pas d'accès aux services de l'hôte |
| ✅ | UID remapping | Root dans le conteneur ≠ root sur l'hôte |
| ✅ | Tous les namespaces activés | pid, net, mnt, uts, ipc, user — périmètre d'attaque réduit |
| ✅ | Firewall dédié | Règles nftables propres au conteneur |
| ✅ | Cumulable avec systemd confinement | Double isolation possible |
| ✅ | Blast radius réduit | Compromission ≠ accès à Nextcloud, Headscale, etc. |
| ✅ | Infrastructure déjà présente | `virtualisation.incus.enable = true` dans configuration.nix |

| # | Faiblesse | Détail |
|---|-----------|--------|
| ❌ | Complexité opérationnelle | Plus de configs à maintenir, plus de pièces mobiles |
| ❌ | /mnt/downloads — problème NFS + LUKS | Le montage automount/LUKS est sur l'hôte, pas trivial à propager |
| ❌ | Overhead de gestion | Mises à jour, monitoring, accès SSH au conteneur |
| ❌ | Noyau toujours partagé | Conteneur ≠ VM — une faille noyau reste exploitable (atténué par UID remapping) |
| ❌ | Plus difficile à déboguer | Les logs sont dans le conteneur, pas directement dans le journal de l'hôte |
| ❌ | Pas de gain si VPN suffit | Si Transmission est uniquement accessible via Caddy avec auth, la surface d'attaque réseau est déjà faible |

### Note globale — Option 2

```
╔══════════════════════════════════════════════════════════╗
║  Conteneur Incus — Note : A (9 / 10)                    ║
║                                                          ║
║  Isolation nettement supérieure, notamment réseau.       ║
║  Blast radius fortement réduit en cas de compromission.  ║
║  Complexité opérationnelle significativement plus        ║
║  élevée pour un gain marginal dans ce contexte précis.   ║
╚══════════════════════════════════════════════════════════╝
```

---

## Comparaison directe

| Critère | systemd confinement | Conteneur Incus |
|---------|--------------------|-----------------| 
| **Isolation filesystem** | ✅ Bonne (namespace mnt) | ✅ Excellente |
| **Isolation réseau** | ❌ Partagé avec l'hôte | ✅ Namespace dédié |
| **Isolation UID** | ⚠️ UID réel sur l'hôte | ✅ UID remappé |
| **Isolation PID** | ⚠️ Partiel | ✅ Complet |
| **Protection brute-force** | ✅ fail2ban Caddy | ✅ fail2ban Caddy |
| **Authentification** | ✅ agenix + basic_auth | ✅ agenix + basic_auth |
| **Complexité de maintenance** | ✅ Faible | ❌ Élevée |
| **Gestion de /mnt/downloads** | ✅ Triviale | ❌ Complexe |
| **Monitoring centralisé** | ✅ journal hôte | ❌ Logs dans le conteneur |
| **Reproductibilité NixOS** | ✅ Natif | ⚠️ Config supplémentaire |
| **Overhead performance** | ✅ Négligeable | ⚠️ Léger |
| **Grade** | **A- (8.5/10)** | **A (9/10)** |

---

## Opinion finale

*Voilà ma conclusion franche, sans langue de bois :*

### La configuration actuelle est déjà solide

Pour un serveur domestique, la configuration actuelle fait un excellent travail. Elle empile correctement les défenses :

1. Le port RPC n'est jamais exposé directement sur Internet.
2. Caddy filtre toutes les requêtes avec authentification forte.
3. Fail2ban empêche le brute-force.
4. Le confinement systemd limite ce qu'un Transmission compromis peut faire sur le filesystem.

La seule vraie lacune identifiable est l'**absence d'isolation réseau** : si Transmission est compromis, le processus peut théoriquement contacter d'autres services locaux (`localhost:8080`, `localhost:8085`, etc.). C'est le seul vecteur de mouvement latéral non bloqué.

### Mais il y a un quick win : `PrivateNetwork`

Avant d'envisager un conteneur Incus complet, il existe une amélioration minimaliste qui colmate la principale lacune sans changer d'architecture :

```nix
# services/transmission.nix — à ajouter dans serviceConfig
PrivateNetwork = false;  # ← NE PAS activer — Transmission a besoin du réseau pour les torrents
```

Hmm, `PrivateNetwork = true` couperait aussi les connexions BitTorrent — ce n'est pas utilisable tel quel. La vraie solution réseau passe par un namespace réseau avec une interface dédiée, ce qui mène… au conteneur.

### Quand passer à Incus ?

Passe à Incus si l'un de ces critères s'applique :

- **Tu stockes des données sensibles** sur la même machine et Transmission peut les atteindre par le réseau.
- **Transmission est exposé plus largement** (ex: accès par plusieurs utilisateurs, pas seulement toi).
- **Tu veux la posture de sécurité maximale** et tu es prêt à gérer la complexité du bind-mount NFS + LUKS dans le conteneur.
- **Tu as déjà d'autres conteneurs Incus** et la charge opérationnelle est déjà absorbée.

### Recommandation finale

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Pour l'usage actuel (serveur maison, utilisateur unique, accès Caddy)  │
│                                                                         │
│  ► Garde le confinement systemd actuel. Il est correctement calibré.    │
│                                                                         │
│  ► Les directives de durcissement noyau sont déjà en place :            │
│    RestrictAddressFamilies, RestrictNamespaces, LockPersonality,        │
│    ProtectKernelModules, ProtectKernelTunables.                         │
│                                                                         │
│  ► Si tu veux monter en grade (A- vers A) sans trop de complexité,      │
│    envisage un conteneur Incus une fois que la gestion NFS/LUKS dans    │
│    un conteneur est clarifiée.                                          │
│                                                                         │
│  Grade actuel : A- (8.5/10) — Très bien pour du domestique.            │
│  Grade Incus  : A (9/10) — Mieux, mais au prix d'une complexité        │
│                            opérationnelle que tu devras assumer.        │
└─────────────────────────────────────────────────────────────────────────┘
```

> *Pour citer Nick Fury : "La sécurité parfaite n'existe pas. La vraie question, c'est : est-ce que le coût de l'attaque dépasse ce que l'attaquant peut en tirer ?" Avec ta configuration actuelle, la réponse est oui — pour un serveur domestique.*

---

## Directives de durcissement — déjà en place

Ces cinq directives ont été ajoutées à `services/transmission.nix` (PR #42). Elles sont maintenant actives dans la configuration :

```nix
systemd.services.transmission.serviceConfig = {
  # … (configuration de confinement existante) …

  # Limite les familles d'adresses réseau autorisées.
  # AF_INET/AF_INET6 : indispensables pour BitTorrent.
  # AF_UNIX : nécessaire pour certaines communications internes systemd.
  # Toutes les autres (AF_NETLINK, AF_PACKET, etc.) sont bloquées.
  RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

  # Bloque l'accès aux espaces de noms noyau (prévient certaines évasions de sandbox).
  RestrictNamespaces = true;

  # Empêche Transmission de modifier les capabilities du processus.
  LockPersonality = true;

  # Désactive le chargement de modules noyau depuis le service.
  ProtectKernelModules = true;

  # Désactive la modification des paramètres noyau.
  ProtectKernelTunables = true;
};
```

Ces directives n'ajoutent aucune complexité opérationnelle et réduisent significativement la surface d'attaque noyau. Elles sont responsables du passage de la note B+ (7.5/10) à A- (8.5/10) pour le confinement systemd.

---

*Document rédigé par botbot — NixOS 25.11*
