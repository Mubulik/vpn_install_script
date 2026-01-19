#!/bin/bash
# Script créé par Lilian Lambert, le 19/01/2026, élève de l'UMLP, en BUT1 R&T
# Fonctionne sous : Debian13

# Faire un système de log

# Vérification de la présence ou non de NetworkManager
if [ ! -f /bin/nmcli ]; then
    echo "L'hôte ne dispose pas de NetworkManager, obligatoire pour la gestion de connexion VPN via ce script."
    exit 1
fi

# Vérification de l'existence ou non d'une connexion VPN avec le nom donné par l'utilisateur
vpnExists=1
while [ $vpnExists -eq 1 ]; do
    /bin/echo -n "Entrez le nom de la connexion VPN : " ; read vpnName
    if [ -e "/etc/NetworkManager/system-connections/$vpnName.nmconnection" ]; then
        /bin/echo "La connexion VPN $vpnName existe déjà. Veuillez choisir un autre nom ou la supprimer."
        exit 1
    fi
    vpnExists=0
done

# Init des variables
/bin/echo -n "Entrez votre nom d'utilisateur dans le domaine (sans le @ufc) : " ; read user
address="vpn20-2.univ-fcomte.fr"
domainName="ufc"

# Ajout du nom de domaine dans le nom d'utilisateur
user=$(/bin/echo "$user@$domainName")


# Lancement de l'installation
/bin/echo -n "Appuyez sur une touche pour démarrer la configuration du VPN..."
read vartrash

# Update des dépôts et installation des prérequis
echo "Mise à jour et installation des prérequis..."
$(/bin/sudo /bin/apt-get update) 2>/dev/null
$(/bin/sudo /bin/apt-get install -y network-manager-strongswan libstrongswan-extra-plugins libcharon-extra-plugins) 2>/dev/null

# Création de la connexion vpn + récupération de l'UUID
/bin/echo "Configuration de la connexion VPN..."
uuid=$(/bin/sudo /bin/nmcli connection add con-name "$vpnName" type vpn vpn-type strongswan | /bin/awk -F'[()]' '{print $2}')

# Suppression du fichier créé dans /etc/NetworkManager/system-connections
/bin/sudo /bin/rm /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Création du fichier de conf de la connexion
/bin/sudo /bin/touch /etc/NetworkManager/system-connections/"$vpnName".nmconnection

/bin/sudo /bin/echo "[connection]
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
/bin/sudo /bin/chmod 600 /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Reload des connexions NetworkManager
/bin/sudo /bin/nmcli connection reload

/bin/echo "Configuration de la connexion VPN terminée.
Lors de la connexion, le mot de passe demandé est celui de l'ENT de votre école.
"
