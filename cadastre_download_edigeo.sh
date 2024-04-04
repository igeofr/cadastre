#!/bin/sh
# ------------------------------------------------------------------------------
# A Executer de la manière suivante : sh cadastre_download_edigeo.sh 2021-07-01

# VARIABLES DATES
export DATE_YM=$(date "+%Y%m")
export DATE_YMD=$(date "+%Y%m%d")

# LECTURE DU FICHIER DE CONFIGURATION
. './config.env'

# REPERTOIRE DE TRAVAIL
cd $REPER
echo $REPER

# ------------------------------------------------------------------------------
# DEBUT DU TELECHARGEMENT
echo $DATE_YM 'Debut du téléchargement'

millesime=$1
echo $millesime
cd $REPER'/data_cadastre_ccpl_edigeo'
mkdir -p $millesime

cd $REPER'/data_cadastre_ccpl_edigeo/'$millesime'/'
#curl -s -O 'https://cadastre.data.gouv.fr/data/dgfip-pci-vecteur/'$millesime'/edigeo/departements/dep34.zip'
echo 'dep34'


for name in $COMMUNES;
do
  mkdir -p $REPER'/data_cadastre_ccpl_edigeo/'$millesime'/'$name
  for file in $(curl -s 'https://cadastre.data.gouv.fr/data/dgfip-pci-vecteur/'$millesime'/edigeo-cc/feuilles/34/'$name'/' |
                    grep href |
                    sed 's/.*href="//' |
                    sed 's/".*//' |
                    grep '^[a-zA-Z].*'); do
      cd $REPER'/data_cadastre_ccpl_edigeo/'$millesime'/'$name
      curl -s -O 'https://cadastre.data.gouv.fr/data/dgfip-pci-vecteur/'$millesime'/edigeo-cc/feuilles/34/'$name'/'$file
  done
done

# FIN DU TELECHARGEMENT
echo 'Fin du téléchargement'
# ------------------------------------------------------------------------------
