#!/bin/bash
# Script créé par Lilian Lambert, le 19/01/2026, élève de l'UMLP, en BUT1 R&T
# Fonctionne sous : Debian13

# Variable contenant le chemin vers le fichier de log
logFile=/var/log/vpn_install.log

# Création des fonctions de log
log() {
  printf '%s [INFO] %s\n' "$(date +%F_%T)" "$*" | tee -a "$logFile"
}

log_error() {
  printf '%s [ERROR] %s\n' "$(date +%F_%T)" "$*" | tee -a "$logFile" >&2
}


# Vérification de la présence ou non de NetworkManager
if ! command -v nmcli 2>&1 >> /dev/null ; then
    log_error "L'hôte ne dispose pas de NetworkManager, obligatoire pour la gestion de connexion VPN via ce script."
    exit 1
fi

# Vérification de l'existence ou non d'une connexion VPN avec le nom donné par l'utilisateur
vpnExists=1
while [ $vpnExists -eq 1 ]; do
    echo -n "Entrez le nom de la connexion VPN : " ; read vpnName
    if [ -e "/etc/NetworkManager/system-connections/$vpnName.nmconnection" ]; then
        log_error "La connexion VPN $vpnName existe déjà. Veuillez choisir un autre nom ou la supprimer."
        exit 1
    fi
    vpnExists=0
done

# Init des variables
echo -n "Entrez votre nom d'utilisateur dans le domaine (sans le @ufc) : " ; read user
address="vpn20-2.univ-fcomte.fr"
domainName="ufc"

# Ajout du nom de domaine dans le nom d'utilisateur
user="$user@$domainName"


# Lancement de l'installation
echo -n "Appuyez sur une touche pour démarrer la configuration du VPN..."
read vartrash

# Update des dépôts et installation des prérequis
log "Mise à jour et installation des prérequis..."
apt-get update >>"$logFile" 2>&1
apt-get install -y network-manager-strongswan libstrongswan-extra-plugins libcharon-extra-plugins >>"$logFile" 2>&1

# Création de la connexion vpn + récupération de l'UUID
log "Configuration de la connexion VPN..."
uuid=$(nmcli connection add con-name "$vpnName" type vpn vpn-type strongswan | awk -F'[()]' '{print $2}')

# Suppression du fichier créé dans /etc/NetworkManager/system-connections
rm /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Création du fichier de conf de la connexion
touch /etc/NetworkManager/system-connections/"$vpnName".nmconnection

echo "[connection]
id=$vpnName
uuid=$uuid
type=vpn

[vpn]
address=$address
encap=yes
ipcomp=no
method=eap
password-flags=2
proposal=no
user=$user
virtual=yes
service-type=org.freedesktop.NetworkManager.strongswan

[ipv4]
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]"> /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Attributions des bons droits
chmod 600 /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Reload des connexions NetworkManager
nmcli connection reload

log "Configuration de la connexion VPN terminée."
echo "
Lors de la connexion, le mot de passe demandé est celui de l'ENT de votre école.
"
