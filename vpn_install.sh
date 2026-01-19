#!/bin/bash
# Script créé par Lilian Lambert, le 19/01/2026, élève de l'UMLP, en BUT1 R&T
# Fonctionne sous : Debian13

# Vérification de l'existence ou non d'une connexion VPN avec le nom donné par l'utilisateur
vpnExists=1
while [ $vpnExists -eq 1 ]; do
    echo -n "Entrez le nom de la connexion VPN : " ; read vpnName
    if [ -e "/etc/NetworkManager/system-connections/$vpnName.nmconnection" ]; then
        echo "La connexion VPN $vpnName existe déjà. Veuillez choisir un autre nom ou la supprimer."
        exit 1
    fi
    vpnExists=0
done

# Init des variables
echo -n "Entrez votre nom d'utilisateur dans le domaine (sans le @ufc) : " ; read user
address="vpn20-2.univ-fcomte.fr"
domainName="ufc"

# Ajout du nom de domaine dans le nom d'utilisateur
user=$(echo "$user@$domainName")


# Lancement de l'installation
echo -n "Appuyez sur une touche pour démarrer la configuration du VPN..."
read vartrash

# Update des dépôts et installation des prérequis
sudo apt-get update
sudo apt install -y network-manager-strongswan libstrongswan-extra-plugins libcharon-extra-plugins



# Création de la connexion vpn + récupération de l'UUID LETS GOOOO
uuid=$(sudo nmcli connection add con-name "$vpnName" type vpn vpn-type strongswan | awk -F'[()]' '{print $2}')
echo "UUID enregistré : $uuid"

# Suppression du fichier créé dans /etc/NetworkManager/system-connections
sudo rm /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Création du fichier de conf de la connexion
sudo touch /etc/NetworkManager/system-connections/"$vpnName".nmconnection

sudo echo "[connection]
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
sudo chmod 600 /etc/NetworkManager/system-connections/"$vpnName".nmconnection

# Reload des connexions NetworkManager
sudo nmcli connection reload
