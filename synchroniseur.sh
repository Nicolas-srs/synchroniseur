#!/bin/bash

#branches à synchroniser
chemin_absolu='/home/nicos/'
chemin_branche_A='/home/nicos/A'
chemin_branche_B='/home/nicos/B'


#test si le journal .synchro existe déjà
#Si c'est la première synchro il n'existe pas, il est créé avec en début de fichier le chemin des deux branches
#S'il existe on le laisse et on le complète avec les nouvelles synchronisations
function existence_journal_synchro {
    fichier_existant=$(ls -a | grep -x .synchro | wc -l)
    if [ $fichier_existant -eq 0 ]
    then
        echo -e "Chemin branche A : $chemin_branche_A \nChemin branche B : $chemin_branche_B \n" > .synchro
    fi
}

#Une entrée journal ressemble à la ligne ci-dessous
#cheminA,#cheminB,type,permissions,taille_octets,date heure
#prend 2 entrées de type : $1=chemin/fichier_pA $2=chemin/fichier_pB
function entree_journal {
    type=$(stat -c "%F" $1 | cut -f1 -d ' ') #cut afin d'éviter une erreur lorsque le fichier est vide (fichier vide)
    date=$(stat -c "%y" $1 | cut -f1 -d '.')
    echo -e "$(stat -c "%n,$(stat -c "%n" $2),$type,%a,%s,$date" $1)" >> .synchro
}

#comparaison des droits en valeur octale
function comparer_permissions {
    droits_pA=$(stat -c "%a" $1)
    droits_pB=$(stat -c "%a" $2)

    if [ $droits_pA -eq $droits_pB ]
    then
        echo "0"
    else
        echo "1"
    fi
}

#comparaison de la taille en octets afin d'être plus précis que des arrondis en Ko
function comparer_taille {
    taille_pA=$(stat -c "%s" $1)
    taille_pB=$(stat -c "%s" $2)

    if [ $taille_pA -eq $taille_pB ]
    then
        echo "0"
    else
        echo "1"
    fi
}

#comparaison de la date + comparaison de l'heure
function comparer_date_derniere_modif {
    date_derniere_modif_pA=$(stat -c "%y" $1 | cut -f1 -d '.' | cut -f1 -d ' ')
    heure_derniere_modif_pA=$(stat -c "%y" $1 | cut -f1 -d '.' | cut -f2 -d ' ')

    date_derniere_modif_pB=$(stat -c "%y" $2 | cut -f1 -d '.' | cut -f1 -d ' ')
    heure_derniere_modif_pB=$(stat -c "%y" $2 | cut -f1 -d '.' | cut -f2 -d ' ')

    if [ $date_derniere_modif_pA == $date_derniere_modif_pB ]
    then
        if [ $heure_derniere_modif_pA == $heure_derniere_modif_pB ]
        then
            echo "0"
        else
            echo "1"
        fi
    else
        echo "1"
    fi
}


#compare :
# - permission
# - taille
# - date et heure dernière modification
#prend en entrée 2 paramètres : $1=chemin/fichier_pA  $2=chemin/fichier_pB
function comparer_metaDonnees {
    permission=$(comparer_permissions $1 $2)
    taille=$(comparer_taille $1 $2)
    date_modif=$(comparer_date_derniere_modif $1 $2)

    if [ $permission -eq 0 -a $taille -eq 0 -a $date_modif -eq 0 ]
    then
        echo "0" #Les fichiers comparés sont identiques
    else
        echo "1" #Les fichiers comparés sont différents
    fi
}


#les j_... sont les valeurs journalisées dans le fichier .synchro
#les f_... sont les valeurs du fichier actuel
#On compare les j et les f afin de savoir si le fichier correspond toujours à la valeur dans .synchro
#prend en entrée 3 paramètres : $1=Chemin $2=fichier et (ou non) $3=Chemin_si_récursivité_dans_un_dossier
function comparer_fichier_avec_une_entree_journal {
    concatenation=$1/$2
    if [ $# -eq 2 ]
    then
        if [ $1 == $chemin_branche_A ]
        then
            #correspond au chemin A (1er champ du fichier .synchro)
            j_chemin=$(awk -F "," '$1 == "'$concatenation'" {print $1}' .synchro)
        else
            # correspond au chemin B (2ème champ du fichier .synchro)
            j_chemin=$(awk -F "," '$2 == "'$concatenation'" {print $2}' .synchro)
        fi
    else
        if [ $1 == $3 ]
        then
            j_chemin=$(awk -F "," '$1 == "'$concatenation'" {print $1}' .synchro)
        else
            j_chemin=$(awk -F "," '$2 == "'$concatenation'" {print $2}' .synchro)
        fi
    fi

    j_type=$(awk -F "," '($1 == "'$j_chemin'") || ($2 == "'$j_chemin'") {print $3}' .synchro)
    j_permission=$(awk -F "," '($1 == "'$j_chemin'") || ($2 == "'$j_chemin'") {print $4}' .synchro)
    j_taille=$(awk -F "," '($1 == "'$j_chemin'") || ($2 == "'$j_chemin'") {print $5}' .synchro)
    j_date=$(awk -F "," '($1 == "'$j_chemin'") || ($2 == "'$j_chemin'") {print $6}' .synchro | cut -f1 -d ' ')
    j_heure=$(awk -F "," '($1 == "'$j_chemin'") || ($2 == "'$j_chemin'") {print $6}' .synchro | cut -f2 -d ' ')

    f_chemin=$concatenation
    f_type=$(stat -c "%F" $concatenation | cut -f1 -d ' ')
    f_permission=$(stat -c "%a" $concatenation)
    f_taille=$(stat -c "%s" $concatenation)
    f_date=$(stat -c "%y" $concatenation | cut -f1 -d ' ')
    f_heure=$(stat -c "%y" $concatenation | cut -f2 -d ' ' | cut -f1 -d '.')

    if [ $j_chemin == $f_chemin -a $j_type == $f_type ] > /dev/null 2>&1
    then
        if [ $j_permission == $f_permission -a $j_taille == $f_taille ] > /dev/null 2>&1
        then
            if [ $j_date == $f_date -a $j_heure == $f_heure ] > /dev/null 2>&1
            then
                echo "0" #le fichier est identique à l'entrée journal
            else
                echo "1"
            fi
        else
            echo "1"
        fi
    else
        echo "1"
    fi
}


#On regarde si les fichiers présents dans arbre_A sont présents dans arbre_B.
#Dans le cas échéant on demande à l'utilisateur ce qu'il veut faire
# - supprimer pA (de manière récursive si c'est un dossier)
# - copier/coller pA dans B/ en gardant les métadonnées et le contenu
#Permet de rendre la branche A identique à la branche B
#Prends 2 paramètres : $1=Arbre_A $2=Arbre_B
function comparaison_A_par_rapport_a_B {
    for pA in $(ls $1)
    do
        pB=$(ls $2 | grep -x $pA)
        if test -z $pB
        then
            mot=$(stat -c "%F" $1/$pA | cut -f1 -d ' ')
            echo "oups le $mot \"$pA\" n'est pas présent dans l'arbre $2/, que faire ?"
            PS3="Votre choix ? "
            select choix in "Supprimer \"$pA\" de l'arbre A" "Copier/coller \"$1/$pA\" dans le répertoire \"$2/\"" 
            do
                case $REPLY in
                1)  echo -e "choix 1 - Vous avez décidé de supprimer le $mot\n"
                    rm -rf $1/$pA
                    #S'il y a une entrée dans le journal on la supprime numLigne=$(awk -F "," '(NR > 2) && ($1 == "'$1'/'$pA'") {print NR}' .synchro
                    if test ! -z $numLigne
                    then
                        sed -i ''"$numLigne"'d' .synchro
                    fi
                    break;;
                2)  echo -e "choix 2 - Vous avez décidé de copier/coller le $mot\n"
                    cp -pR $1/$pA $2/ #-p preserve les métadonées | -R récursif
                    pB=$pA
                    nom=$(grep -w "$1/$pA," .synchro | cut -f1 -d ',')
                    if test -z $nom
                    then
                        entree_journal $1/$pA $2/$pB
                    else
                        if [ $nom != $1/$pA ]
                        then
                            entree_journal $1/$pA $2/$pB
                        else
                            numLigne=$(awk -F "," '(NR > 2) && ($1 == "'$1'/'$pA'") {print NR}' .synchro)
                            sed -i ''"$numLigne"'d' .synchro
                            entree_journal $1/$pA $2/$pB
                        fi
                    fi
                    break;;
                *)  echo "ceci n'est pas une réponse valide";;
                esac
            done
        else
            nom=$(grep -w "$1/$pA," .synchro | cut -f1 -d ',')
            if test -z $nom > /dev/null 2>&1
            then
                entree_journal $1/$pA $2/$pB
            else
                if [ $nom != $1/$pA ] > /dev/null 2>&1
                then
                    entree_journal $1/$pA $2/$pB
                fi
            fi
        fi
    done
}

#Permet de rendre la branche B identique à la branche A
#Prends 2 paramètres : $1=Arbre_A $2=Arbre_B
function comparaison_B_par_rapport_a_A {
    for pB in $(ls $2)
    do
        pA=$(ls $1 | grep -x $pB)
        if test -z $pA
        then
            mot=$(stat -c "%F" $2/$pB | cut -f1 -d ' ')
            echo "oups le $mot \"$pB\" n'est pas présent dans l'arbre $1/, que faire ?"


            PS3="Votre choix ? "
            select choix in "Supprimer \"$pB\" de l'arbre B" "Copier/coller \"$2/$pB\" dans le répertoire \"$1/\""
            do
                case $REPLY in
                1)  echo -e "choix 1 - Vous avez décidé de supprimer le $mot\n"
                    rm -rf $2/$pB
                    numLigne=$(awk -F "," '(NR > 2) && ($2 == "'$2'/'$pB'") {print NR}' .synchro)
                    if test ! -z $numLigne
                    then
                        sed -i ''"$numLigne"'d' .synchro
                    fi
                    break;;
                2)  echo -e "choix 2 - Vous avez décidé de copier/coller le $mot\n"
                    cp -pR $2/$pB $1/ #-p preserve les métadonées | -R récursif
                    pA=$pB
                    nom=$(grep "$2/$pB," .synchro | cut -f2 -d ',')
                    if test -z $nom
                    then
                        entree_journal $1/$pA $2/$pB
                    else
                        if [ $nom != $2/$pB ]
                        then
                            entree_journal $1/$pA $2/$pB
                        else
                            numLigne=$(awk -F "," '(NR > 2) && ($2 == "'$2'/'$pB'") {print NR}' .synchro)
                            sed -i ''"$numLigne"'d' .synchro
                            entree_journal $1/$pA $2/$pB
                        fi
                    fi
                    break;;
                *)  echo "ceci n'est pas une réponse valide";;
                esac
            done
        else
            nom=$(grep "$2/$pB," .synchro | cut -f2 -d ',')
            if test -z $nom > /dev/null 2>&1
            then
                entree_journal $1/$pA $2/$pB
            else
                if [ $nom != $2/$pB ] > /dev/null 2>&1
                then
                    entree_journal $1/$pA $2/$pB
                fi
            fi
        fi
    done
}


#paramètres :
# - $1 = chemin A
# - $2 = pA
# - $3 = chemin B
# - $4 = pB
# - $5 = quel type de conflit
        #les types de conflits :
        # - 1 --> dossier fichier
        # - 2 --> fichier dossier
function gestion_conflit {
    #On commence par supprimer la ligne du journal de synchro
    numLigne=$(awk -F "," '(NR > 2) && ($1 == "'$1'/'$pA'") {print NR}' .synchro)
    if test ! -z $numLigne
    then
        sed -i ''"$numLigne"'d' .synchro
    fi
    echo "Que voulez vous faire ?"

    PS3="Votre choix ? "
    select choix in "Supprimer le conflit des deux côtés" "Je veux que ce soit des fichiers des deux côtés" "Je veux que ce soit des dossiers des deux côtés"
    do
        case $REPLY in
            1)  echo -e "choix 1 - Vous avez décidé de supprimer le conflit"
                if [ $5 -eq 1 ] #conflit de type 1 : dossier_fichier
                then
                    rm -rf $1/$2
                    rm $3/$4
                else #conflit de type 2: fichier_dossier
                    rm $1/$2
                    rm -rf $3/$4
                fi
                echo -e "tout a été supprimé correctement\n"
                break;;
            2)  echo -e "choix 2 - Vous voulez que ce soit des fichiers des deux côtés"
                if [ $5 -eq 1 ]
                then
                    rm -rf $1/$2
                    cp -p $3/$4 $1/
                else
                    rm -rf $3/$4
                    cp -p $1/$2 $3/
                fi
                entree_journal $1/$2 $3/$4
                echo -e "Ce sont désormais 2 fichiers\n"
                break;;
            3) echo -e "choix 3 - Vous voulez que ce soit des dossiers des deux côtés"
                if [ $5 -eq 1 ]
                then
                    rm $3/$4
                    cp -pR $1/$2 $3/
                else
                    rm $1/$2
                    cp -pR $3/$4 $1/ #-p preserve les métadonées | -R récursif
                fi
                entree_journal $1/$2 $3/$4
                echo -e "Ce sont désormais 2 dossiers\n"
                break;;
            *)  echo "ceci n'est pas une réponse valide";;
        esac
    done
}

#Prends 2 paramètres : $1=Arbre_A  $2=Arbre_B
function parcourt_des_arbres {
    comparaison_A_par_rapport_a_B $1 $2
    comparaison_B_par_rapport_a_A $1 $2
    for pA in $(ls $1)
    do
        pB=$(ls $2 | grep -x $pA)
        if test -d $1/$pA -a -f $2/$pB
        then
            echo -e "Problème, $1/$pA est un dossier et $2/$pB est un fichier"
            gestion_conflit $1 $pA $2 $pB 1 #problème dossier_fichier = 1
        elif test -f $1/$pA -a -d $2/$pB
        then
            echo -e "Problème, $1/$pA est un fichier et $2/$pB est un dossier"
            gestion_conflit $1 $pA $2 $pB 2 #problème fichier_dossier = 2
        elif test -d $1/$pA -a -d $2/$pB
        then
            # ce sont des dossiers on créér des chemins temporaires
            chemin_temp_1="$1/$pA"
            chemin_temp_2="$2/$pB"
            parcourt_des_arbres $chemin_temp_1 $chemin_temp_2   #on appelle de nouveau la fonction avec les nouveaux chemins
        else #ce sont forcément des fichiers
            fichiers_similaires=$(comparer_metaDonnees $1/$pA $2/$pB)
            if [ $fichiers_similaires == 1 ]  #si les métadonées ne sont pas  identiques
            then
                if [ $chemin_temp_1 == $1 ] > /dev/null 2>&1
                then
                    #nous sommes dans un cas de récursivité
                    fichier_A_conforme=$(comparer_fichier_avec_une_entree_journal $1 $pA $chemin_temp_1)
                    fichier_B_conforme=$(comparer_fichier_avec_une_entree_journal $2 $pB $chemin_temp_1)
                else
                    fichier_A_conforme=$(comparer_fichier_avec_une_entree_journal $1 $pA)
                    fichier_B_conforme=$(comparer_fichier_avec_une_entree_journal $2 $pB)
                fi
                if [ $fichier_A_conforme -eq 0 -a $fichier_B_conforme -eq 1 ] #pA conforme à .synchro et pas pB
                then
                    rm -rf $1/$pA
                    numLigne=$(awk -F "," '(NR > 2) && ($1 == "'$1'/'$pA'") {print NR}' .synchro)
                    sed -i ''"$numLigne"'d' .synchro
                    cp -pR $2/$pB $1/
                    entree_journal $1/$pA $2/$pB #journalisation du changement
                    echo -e "$1/$pA est conforme au journal mais $2/$pB a été modifié"
                    echo -e "la synchronisation a été effectuée\n"
                elif [ $fichier_A_conforme -eq 1 -a $fichier_B_conforme -eq 0 ] #pB conforme à .synchro et pas pA
                then
                    rm -rf $2/$pB
                    numLigne=$(awk -F "," '(NR > 2) && ($1 == "'$1'/'$pA'") {print NR}' .synchro)
                    sed -i ''"$numLigne"'d' .synchro
                    cp -pR $1/$pA $2/
                    entree_journal $1/$pA $2/$pB #journalisation du changement
                    echo -e "$2/$pB est conforme au journal mais $1/$pA a été modifié"
                    echo -e "la synchronisation a été effectuée\n"
                else
                    echo "conflit, aucun des deux fichiers ($1/$pA et $2/$pB) ne correspond au journal de synchronisation. Veuillez régler ce conflit" >> .journal_conflit
                        flag=1
                fi
            fi
        fi
    done
}

flag=0
truncate -s 0 .journal_conflit || touch .journal_conflit
existence_journal_synchro
parcourt_des_arbres $chemin_branche_A $chemin_branche_B
if [ $flag -eq 1 ]
then
        echo "Suite à la synchronisation, voici la liste des conflits (consultable dans le fichier .journal_conflit) :"
        cat .journal_conflit
fi
