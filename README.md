# synchroniseur
Script bash de synchronisation de dossiers/fichiers.<br/>

<h3>Fichiers</h3>
Le script _synchroniseur.sh_ créér 2 fichiers pour son bon fonctionnement :<br/>
- Le fichier de journal _.synchro_, il contient les chemins des répertoires à synchroniser A et B ainsi que l'historique des synchronisations réussies.<br/>
- Le fichier de conflits _.journal_conflit_, il contient les conflits qui ont pu survenir lors d'une synchronisation.

<h3>Utilisation</h3>
Il faut commencer par changer les 3 variables qui se trouvent en début de script afin qu'elles correspondent à votre utilisation.<br/>
- _chemin_absolu_ correspond à l'endroit où se trouveront les fichiers de journalisation et de conflit.<br/>
- _chemin_branche_A_ correspond au 1er répertoire à syncrhoniser.<br/>
- _chemin_branche_B_ correspond au 2ème répertoir à syncrhoniser.

<pre><code>#branches à synchroniser
chemin_absolu='/home/nicos/'
chemin_branche_A='/home/nicos/A'
chemin_branche_B='/home/nicos/B'</code></pre>

Ensuite il suffit de lancer le script _./syncrhoniseur.sh_<br/>

<h3>Fonctionnement</h3>
Le script compare les 2 répertoires (A et B). Je considère ainsi pA un fichier/dossier de A et pB un dossier/fichier de B.<br/>
Pour tout fichier p il effectue les actions suivantes :<br/>
- Si pA existe et non pB<br/>
- Si pB existe et non pA<br/>
Dans ce cas le script vous propose un menu de 2 choix, vous pourrez --> **supprimer** le fichier/dossier existant, le **synchroniser** il sera ainsi créé dans le répertoire où il n'existe pas encore.<br/>
<br/>
- Si pA est un dossier et pB un fichier<br/>
- Si pA est un fichier et pB un dossier<br/>
Dans ce cas le script vous propose un menu de choix, vous pourrez --> **supprimer** les 2, les **transformer en fichier** (on suprime celui qui est un dossier pour copier/coller le fichier à la place), les **transformer en dossier** (on supprime celui qui est un fichier pour venir copier/coller récursivement le dossier à la place).<br/>
<br/>
- Sinon, si pA et pB sont deux fichiers identiques (taille, droit d'accès, date et heure de dernière modification). la synchronisation est réussie (journalisation dans le fichier _.synchro_).<br/>
- Si pA est conforme au fichier de journal et pB ne l'est pas, pB a été modifié (plus récent), pA est donc supprimé pour être remplacé par pB.<br/>
- Si pB est conforme au fichier de journal et pA ne l'est pas, pA a été modifié, pB est donc supprimé pour être remplacé par pA.<br/>
<br/>
Le seul conflit qui n'est pas géré c'est lorsque pA et pB sont tous les 2 différents du journal de synchronisation. A ce moment le conflit est écrit dans le fichier _.journal_conflit_. C'est à vous de le régler manuellement, ainsi vous pouvez décider de la version que vous souhaitez garder entre pA et pB.<br/>


<h3>Auteurs</h3>
Nicolas Soares | ni.soares.pro@gmail.com
