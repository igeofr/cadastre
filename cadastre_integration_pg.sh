#!/bin/sh
# ------------------------------------------------------------------------------

# VARIABLES DATES
export DATE_YM=$(date "+%Y%m")
export DATE_YMD=$(date "+%Y%m%d")

# LECTURE DU FICHIER DE CONFIGURATION
. "`dirname "$0"`/config.env"

# REPERTOIRE DE TRAVAIL
cd $REPER
echo $REPER

# MILLESIME TRAITE
millesime=$1
echo $millesime
annee=$(printf %.4s "$millesime")
echo $annee


# REPERTOIRE DE TRAVAIL
cd $REPER'/data_cadastre_ccpl_edigeo/'$millesime


# ------------------------------------------------------------------------------

rm *'.zip'
rm *'.gpkg'

for f in * ;
do [ -d "$f" ] && echo $f

  psql "service='$C_SERVICE'" -e -c "DELETE FROM $C_SCHEMA.parcelle_$annee WHERE id_com='$f'"
  psql "service='$C_SERVICE'" -e -c "DELETE FROM $C_SCHEMA.batiment_$annee WHERE id_com='$f'"
  psql "service='$C_SERVICE'" -e -c "DELETE FROM $C_SCHEMA.section_cadastrale_$annee WHERE id_com='$f'"

  for FILE in $f'/'*'.tar.bz2';
  do
    echo $FILE
    echo ${FILE%%.*}
    section=$(echo "${FILE%%.*}" | sed -r 's/\//_/g')
    mkdir ${FILE%%.*}
    tar -xf $FILE -C ${FILE%%.*}

## Intégration des parcelles
    ogr2ogr \
        -append \
        -f "PostgreSQL" PG:"service='$C_SERVICE' schemas='$C_SCHEMA'" \
        -nln 'parcelle_'$annee \
        -nlt POLYGON \
        -s_srs 'EPSG:3943' \
        -t_srs 'EPSG:2154' \
        ${FILE%%.*}/*.THF \
        -dialect SQLITE \
        -sql "SELECT CAST(IDU AS TEXT(14)) AS id_par, CAST(INDP AS TEXT(2)) AS indp_code, CAST('$f' AS TEXT(5)) AS id_com, CAST('34' AS TEXT(2)) AS dep_code, CAST(substr(IDU, -4) AS TEXT(4)) AS parcelle, CAST(substr(IDU, 7, 2) AS TEXT(2)) AS section, CAST(substr(IDU, 4, 3) AS TEXT(3)) AS pre, CAST(SUPF AS integer) AS supf, CollectionExtract(st_makevalid(geometry),3) as geom FROM PARCELLE_id WHERE ST_ISValid(st_makevalid(geometry))" \
        --debug ON \
        --config CPL_LOG $REPER'/'$REPER_LOGS'/cadastre_parcelle_'$section'.log' \
        #--config OGR_TRUNCATE YES \
        #-lco FID=id_par \
        #-nlt PROMOTE_TO_MULTI \

    sleep 6

## Intégration du bâti
    ogr2ogr \
        -append \
        -f "PostgreSQL" PG:"service='$C_SERVICE' schemas='$C_SCHEMA'" \
        -nln 'batiment_'$annee \
        -nlt POLYGON \
        -s_srs 'EPSG:3943' \
        -t_srs 'EPSG:2154' \
        ${FILE%%.*}/*.THF \
        -dialect SQLITE \
        -sql "SELECT  CAST('$f' AS TEXT(5)) AS id_com, CAST(DUR AS TEXT(2)) AS dur_code, CAST(TEX AS TEXT(255)) AS tex , CollectionExtract(st_makevalid(geometry),3) as geom FROM BATIMENT_id WHERE ST_ISValid(st_makevalid(geometry))" \
        --debug ON \
        --config CPL_LOG $REPER'/'$REPER_LOGS'/cadastre_bati_'$section'.log' \
        #--config OGR_TRUNCATE YES \
        #-lco FID=id_par \
        #-nlt PROMOTE_TO_MULTI \

    sleep 6

## Intégration des sections
    ogr2ogr \
        -append \
        -f "PostgreSQL" PG:"service='$C_SERVICE' schemas='$C_SCHEMA'" \
        -nln 'section_cadastrale_'$annee \
        -nlt POLYGON \
        -s_srs 'EPSG:3943' \
        -t_srs 'EPSG:2154' \
        ${FILE%%.*}/*.THF \
        -dialect SQLITE \
        -sql "SELECT '34'||CAST(IDU AS TEXT(8)) AS id_sec, '34'||substr(CAST(IDU AS TEXT(8)), 1, 3 ) AS id_com, substr(CAST(TEX AS TEXT(5)), -2, 2) AS section,substr(CAST(IDU AS TEXT(8)), 4, 3 ) AS pre, CollectionExtract(st_makevalid(geometry),3) as geom FROM SECTION_id WHERE ST_ISValid(st_makevalid(geometry))" \
        --debug ON \
        --config CPL_LOG $REPER'/'$REPER_LOGS'/cadastre_section_'$section'.log' \
        #--config OGR_TRUNCATE YES \
        #-lco FID=id_par \
        #-nlt PROMOTE_TO_MULTI \

    sleep 6

    rm -rf ${FILE%%.*}

  done
done
